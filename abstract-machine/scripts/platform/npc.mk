AM_SRCS := riscv/npc/start.S \
           riscv/npc/trm.c \
           riscv/npc/ioe.c \
           riscv/npc/timer.c \
           riscv/npc/input.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/linker.ld \
						 --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
.PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin
	@cp $(IMAGE).bin $(NPC_HOME)/tests

IMAGE_BASE = $(basename $(notdir $(IMAGE_REL)))

IMAGE_REV = $(shell echo $(IMAGE_BASE) | rev)

IMAGE_CUTTED_REV = $(shell echo $(IMAGE_REV) | cut -d'-' -f3-)

IMAGE_CUTTED = $(shell echo $(IMAGE_CUTTED_REV) | rev)

run: image
	echo $(IMAGE_BASE) $(IMAGE_REV) $(IMAGE_CUTTED_REV) $(IMAGE_CUTTED)
	$(MAKE) -C $(NPC_HOME) compile run TESTNAME=$(IMAGE_CUTTED)

