#include "include/include.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define TOP TOP_NAME

#ifdef NVBOARD
#include <nvboard.h>
#endif
IFDEF(NVBOARD, void nvboard_bind_all_pins(TOP* top));


bool rst_n_sync = false; //read from rtl by dpi-c.
bool dut_status = false; //read from rtl by dpi-c. true for instruction commit

VerilatedContext* contextp = new VerilatedContext;
VerilatedVcdC* tfp = new VerilatedVcdC;
TOP* top = new TOP;

static uint64_t total_inst = 0;
uint64_t ifu_pfc_r = 0;
uint64_t lsu_pfc_w = 0;
uint64_t lsu_pfc_r = 0;
uint64_t exu_pfc = 0;
uint64_t idu_cal_type = 0;
uint64_t idu_mem_type = 0;
uint64_t idu_jump_type = 0;
uint64_t idu_csr_type = 0;
uint8_t current_inst_type = 0;
double inst_time[4] = {0};
uint64_t timestap_begin = 0;
double lsu_read_delay = 0;
double lsu_write_delay = 0;
double cache_hit_rate = 0;
double cache_acc_time = 0;
double cache_miss_penalty = 0;

void step_and_dump_wave()
{
  top->eval();
  contextp->timeInc(1);
  IFDEF(TRACE_ON, tfp->dump(contextp->time()));
}

void reset(int n) {
	top->reset = 1;
 	while (n -- > 0) {
    top->clock = !top->clock;
    step_and_dump_wave();
  }
	top->reset = 0;
}

uint64_t get_sim_time() {
  return contextp->time();
}

void statistics() {
  printf("Total cycles: %ld\n", contextp->time() / 2);
  printf("Total insts: %ld\n", total_inst);
  printf("CPU IPC: %f\n", total_inst / (contextp->time() / 2.0));
  printf("CPU CPI: %f\n", (contextp->time() / 2.0) / total_inst);
  printf("IFU Read pfc: %ld\n", ifu_pfc_r);
  printf("LSU Write pfc: %ld\n", lsu_pfc_w);
  printf("LSU Read pfc: %ld\n", lsu_pfc_r);
  printf("EXU Finish pfc: %ld\n", exu_pfc);
  printf("IDU Cal pfc: %ld, %f%%, CPI: %f\n", idu_cal_type, idu_cal_type  * 100.0 / total_inst, inst_time[0] / idu_cal_type);
  printf("IDU Mem pfc: %ld, %f%%, CPI: %f\n", idu_mem_type, idu_mem_type * 100.0 / total_inst, inst_time[1] / idu_mem_type);
  printf("IDU Jump pfc: %ld, %f%%, CPI: %f\n", idu_jump_type, idu_jump_type * 100.0 / total_inst, inst_time[2] / idu_jump_type);
  printf("IDU Csr pfc: %ld, %f%%, CPI: %f\n", idu_csr_type, idu_csr_type * 100.0 / total_inst, inst_time[3] / idu_csr_type);
  printf("LSU Read Delay pfc: %f\n", lsu_read_delay / lsu_pfc_r);
  printf("LSU Write Delay pfc: %f\n", lsu_write_delay / lsu_pfc_w);
  printf("ICACHE Hit Rate pfc: %f\n", cache_hit_rate);
  printf("ICACHE Avg Access Time pfc: %f cycle(s)\n", cache_acc_time);
  printf("ICACHE Avg Miss Penalty pfc: %f cycle(s)\n", cache_miss_penalty);
  printf("ICACHE AMAT: %f\n", cache_acc_time + (1 - cache_hit_rate) * cache_miss_penalty);
  printf("ICACHE TMT: %f\n", (1 - cache_hit_rate) * cache_miss_penalty);
};

int main(int argc, char **argv) {
  ///////////////////////////////// verilator init: /////////////////////////////////

  Verilated::commandArgs(argc,argv);
  IFDEF(NVBOARD,
  nvboard_bind_all_pins(top);
  nvboard_init());

  IFDEF(TRACE_ON, contextp->traceEverOn(true); top->trace(tfp, 0); tfp->open("build/sim.vcd"));    // Trace 0 levels of hierarchy (or see below)
  ///////////////////////////////// init npc status: ////////////////////////////////
  top->clock = 0;
  step_and_dump_wave();       //init reg status,use for difftest_init.
  npc_init(argc,argv);
  reset(100);

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish() IFDEF(DEBUG_TIME, && contextp->time() < MAX_CYCLE)) {
    top->clock = !top->clock;                 // clk = ~clk;
    IFDEF(DIFFTEST_ON,
    top->eval();                              // update rst_n_sync
    if(dut_status) {
      if(top->clock && rst_n_sync){
        if(!difftest_check()){                  // check last cycle reg/mem.
          break;
        }
        difftest_step();                        // ref step and update regs/mem.
      }
    })
    step_and_dump_wave();
    IFDEF(NVBOARD, if(top->clock && rst_n_sync) nvboard_update());
    if(top->clock && dut_status) {
      total_inst ++;
      inst_time[current_inst_type] +=  (contextp->time() - timestap_begin) / 2.0;
    }
  }

  ///////////////////////////////// exit: /////////////////////////////////
  step_and_dump_wave();
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
  IFDEF(NVBOARD, nvboard_quit());
  statistics();

  return 0;
}
