VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -x-assign fast
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
# VERILATOR_FLAGS += --coverage
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt
VERILATOR_FLAGS += --top-module top +incdir+vsrc/include
VERILATOR_FLAGS += --build -Mdir $(BUILD_DIR)

DIFFTEST =
TRACE = 

BUILD_DIR = $(NPC_HOME)/build
# SIM_TOPNAME = top
WORK_DIR = $(shell pwd)
INC_PATH := $(WORK_DIR)/csrc/include $(WORK_DIR)/csrc/isa/include $(INC_PATH)
INCLUDES = $(addprefix -I, $(INC_PATH))
C_FLAGS += -CFLAGS "$(INCLUDES)"

IMAGE ?= $(HOME)/ysyx-workbench/am-kernels/tests/cpu-tests/build/dummy-riscv32e-npc.bin

NPC_ARGS := --img $(IMAGE)

ifneq ($(DIFFTEST),)
C_FLAGS += -CFLAGS "-D DIFFTEST_ON"
NPC_ARGS += --diff $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
endif

ifneq ($(TRACE),)  #wave trace
C_FLAGS += -CFLAGS "-D TRACE_ON"
endif

ifneq ($(MAXCYCLE), )
C_FLAGS += -CFLAGS "-D DEBUG_TIME=$(MAXCYCLE)"
endif

ifneq ($(MTRACE), ) #mem trace
C_FLAGS += -CFLAGS "-D MTRACE_ON"
endif

VSRC= $(shell find ./vsrc -name "*.v" -o -name "*.sv")
CSRC+= $(shell find ./csrc -name "*.cpp" -o -name "*.c")


compile:
	@echo "runing simulation for test module "
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) $(CSRC)  $(VSRC)

sim: compile
	$(BUILD_DIR)/Vtop $(NPC_ARGS)

wave:
	gtkwave $(BUILD_DIR)/sim.vcd &

clean:
	rm -rf $(BUILD_DIR)
