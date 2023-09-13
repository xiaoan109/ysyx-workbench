VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -x-assign fast
# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
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
VERILATOR_FLAGS += --top-module CPU_top +incdir+vsrc/include
VERILATOR_FLAGS += --build -Mdir $(BUILD_DIR)

BUILD_DIR = ./build
# SIM_TOPNAME = top
WORK_DIR = $(shell pwd)
INC_PATH := $(WORK_DIR)/csrc/include $(WORK_DIR)/csrc/isa/include $(INC_PATH)
INCLUDES = $(addprefix -I, $(INC_PATH))
C_FLAGS += -CFLAGS "$(INCLUDES)"
C_FLAGS += -CFLAGS "-D__GUEST_ISA__=riscv32"
NPC_ARGS += --log $(BUILD_DIR)/tmp.log
V_FILE= $(shell find ./vsrc -name "*.v" -o -name "*.sv")


C_FILE+= $(shell find ./csrc -name "*.cpp" -o -name "*.c")


compile:
	@echo "runing simulation for test module "
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) $(C_FILE)  $(V_FILE)

sim: compile
	$(BUILD_DIR)/VCPU_top $(NPC_ARGS)

wave:
	gtkwave $(BUILD_DIR)/testbench.vcd

menuconfig:
	cd csrc && make menuconfig && cd -

clean:
	rm -rf $(BUILD_DIR)
