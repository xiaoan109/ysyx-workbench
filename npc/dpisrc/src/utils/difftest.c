#include <dlfcn.h>
#include <common.h>
#include <memory/paddr.h>
#include <utils.h>

enum
{
	DIFFTEST_TO_DUT,
	DIFFTEST_TO_REF
};

void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

#ifdef CONFIG_DIFFTEST
// extern NPC_state npc_state;
extern CPU_state cpu;

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref()
{
	is_skip_ref = true;
	// If such an instruction is one of the instruction packing in QEMU
	// (see below), we end the process of catching up with QEMU's pc to
	// keep the consistent behavior in our best.
	// Note that this is still not perfect: if the packed instructions
	// already write some memory, and the incoming instruction in NEMU
	// will load that memory, we will encounter false negative. But such
	// situation is infrequent.
	skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut)
{
	skip_dut_nr_inst += nr_dut;

	while (nr_ref-- > 0)
	{
		ref_difftest_exec(1);
	}
}

void init_difftest(char *ref_so_file, long img_size, int port)
{
	assert(ref_so_file != NULL);

	void *handle;
	handle = dlopen(ref_so_file, RTLD_LAZY);
	assert(handle);

	ref_difftest_memcpy = dlsym(handle, "difftest_memcpy");
	assert(ref_difftest_memcpy);

	ref_difftest_regcpy = dlsym(handle, "difftest_regcpy");
	assert(ref_difftest_regcpy);

	ref_difftest_exec = dlsym(handle, "difftest_exec");
	assert(ref_difftest_exec);

	ref_difftest_raise_intr = dlsym(handle, "difftest_raise_intr");
	assert(ref_difftest_raise_intr);

	void (*ref_difftest_init)(int) = dlsym(handle, "difftest_init");
	assert(ref_difftest_init);

	Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
	Log("The result of every instruction will be compared with %s. "
		"This will help you a lot for debugging, but also significantly reduce the performance. "
		"If it is not necessary, you can turn it off.",
		ref_so_file);

	ref_difftest_init(port);
	ref_difftest_memcpy(CONFIG_MBASE, guest_to_host(CONFIG_MBASE), img_size, DIFFTEST_TO_REF);
	ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}
static inline int check_reg_idx(int idx)
{
	assert(idx >= 0 && idx < 32);
	return idx;
}

static inline const char *reg_name(int idx, int width)
{
	extern const char *regs[];
	return regs[check_reg_idx(idx)];
}

static inline bool difftest_check_reg(const char *name, vaddr_t pc, word_t ref, word_t dut)
{
	if (ref != dut)
	{
		Log("%s is different after executing instruction at pc = " FMT_WORD
			", right = " FMT_WORD ", wrong = " FMT_WORD ", diff = " FMT_WORD,
			name, pc, ref, dut, ref ^ dut);
		return false;
	}
	return true;
}

static bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc)
{
	bool ret = true;
	for (int i = 0; i < 32; i++)
	{
		ret = difftest_check_reg(reg_name(i, 32), pc, ref_r->gpr[i], cpu.gpr[i]);
		if (!ret)
			return ret;
	}
	if (ref_r->pc != cpu.pc)
	{
		Log("NPC Program Counter " FMT_WORD " differs from NEMU! The REF PC is " FMT_WORD, cpu.pc, ref_r->pc);
		return false;
	}
	return ret;
}
static void checkregs(CPU_state *ref, vaddr_t pc)
{
	if (!isa_difftest_checkregs(ref, pc))
	{
		// npc_state.state = NPC_ABORT;
		// npc_state.halt_pc = pc;
		dump_gpr();
		assert(0);
	}
}

void difftest_step(vaddr_t pc)
{
	CPU_state ref_r;

	if (is_skip_ref)
	{
		// to skip the checking of an instruction, just copy the reg state to reference design
		ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
		is_skip_ref = false;
		return;
	}

	ref_difftest_exec(1);
	ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

	checkregs(&ref_r, pc);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port)
{
}
void difftest_step(vaddr_t pc)
{
}
#endif