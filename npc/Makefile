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

BUILD_DIR = $(NPC_HOME)/build
LOG_DIR = $(NPC_HOME)/logs
# SIM_TOPNAME = top
WORK_DIR = $(shell pwd)
INC_PATH := $(WORK_DIR)/csrc/include $(WORK_DIR)/csrc/isa/include $(INC_PATH)
INCLUDES = $(addprefix -I, $(INC_PATH))
C_FLAGS += -CFLAGS "$(INCLUDES)"
C_FLAGS += -CFLAGS "-D__GUEST_ISA__=riscv32"
IMAGE ?= ~/workspace/ysyx-workbench/am-kernels/tests/cpu-tests/build/dummy-riscv32e-npc.bin
NPC_ARGS := --img $(IMAGE) --log $(LOG_DIR)/run.log --diff=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so 
VSRC= $(shell find ./vsrc -name "*.v" -o -name "*.sv")
CSRC+= $(shell find ./csrc -name "*.cpp" -o -name "*.c")


compile:
	@echo "runing simulation for test module "
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) $(CSRC)  $(VSRC)

sim: compile
	$(BUILD_DIR)/Vtop $(NPC_ARGS)

wave:
	gtkwave $(LOG_DIR)/testbench.vcd

menuconfig:
	cd csrc && make menuconfig && cd -

clean:
	rm -rf $(BUILD_DIR) $(LOG_DIR)
