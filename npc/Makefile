SRAM_DELAY = 1
SRAM_LFSR_DELAY =
SYNTHESIS =
DIFFTEST =
TRACE =
SIM_TOPNAME = ysyxSoCFull
SIM_EXEC = V$(SIM_TOPNAME)
ARCH = riscv32e-ysyxsoc

VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -x-assign fast
# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += -Wno-fatal
# VERILATOR_FLAGS += -Wno-PINCONNECTEMPTY -Wno-DECLFILENAME -Wno-DEFPARAM -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-UNUSEDPARAM -Wno-ASSIGNDLY -Wno-SYNCASYNCNET
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
# VERILATOR_FLAGS += --coverage
# Run Verilator in debug mode
# VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
# VERILATOR_FLAGS += --gdbbt
VERILATOR_FLAGS += --top-module $(SIM_TOPNAME) +incdir+$(NPC_HOME)/vsrc/include +incdir+$(SOC_HOME)/perip/uart16550/rtl +incdir+$(SOC_HOME)/perip/spi/rtl
VERILATOR_FLAGS += --build -Mdir $(BUILD_DIR)
# VERILATOR_FLAGS += +define+SRAM_DELAY=$(SRAM_DELAY)
# ifneq ($(SRAM_LFSR_DELAY), )
# VERILATOR_FLAGS += +define+LFSR
# endif
ifneq ($(SYNTHESIS), )
VERILATOR_FLAGS += +define+SYNTHESIS
endif

ifneq ($(MEM_INIT_FILE), )
VERILATOR_FLAGS += +define+MEM_INIT_FILE=\"$(MEM_INIT_FILE)\"
endif

# This ensures verilog normal display but reduces performance
VERILATOR_FLAGS += --autoflush

VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing


BUILD_DIR = $(NPC_HOME)/build
WORK_DIR = $(shell pwd)
INC_PATH := $(WORK_DIR)/csrc/include
INCLUDES = $(addprefix -I, $(INC_PATH))
C_FLAGS += -CFLAGS "$(INCLUDES)"

IMAGE ?= $(HOME)/ysyx-workbench/am-kernels/tests/cpu-tests/build/dummy-$(ARCH).bin

NPC_ARGS := --img $(IMAGE)

ifneq ($(DIFFTEST),)
C_FLAGS += -CFLAGS "-D DIFFTEST_ON"
NPC_ARGS += --diff $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
endif

ifneq ($(WAVE),)  #wave trace
C_FLAGS += -CFLAGS "-D TRACE_ON"
endif

ifneq ($(MAXCYCLE), )
C_FLAGS += -CFLAGS "-D DEBUG_TIME=$(MAXCYCLE)"
endif

ifneq ($(MTRACE), ) #mem trace
C_FLAGS += -CFLAGS "-D MTRACE_ON"
endif

VSRC = $(shell find ./vsrc -name "*.v" -o -name "*.sv")
VSRC += $(shell find $(SOC_HOME)/perip -name "*.v")
VSRC += $(SOC_HOME)/build/ysyxSoCFull.v
CSRC+= $(shell find ./csrc -name "*.cpp" -o -name "*.c")

WAVE_CFG = $(shell find . -name "*.gtkw")


compile:
	@echo "compiling for test module "
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) $(CSRC)  $(VSRC)

run: compile
ifneq ($(MEM_INIT_FILE), )
	bin2hex
endif
	@echo "runing simulation for test module "
	$(BUILD_DIR)/$(SIM_EXEC) $(NPC_ARGS)

wave:
ifneq ($(WAVE_CFG), )
	gtkwave $(BUILD_DIR)/sim.vcd -a $(WAVE_CFG) &
else
	gtkwave $(BUILD_DIR)/sim.vcd &
endif

syn:
	@echo "Synthesis NPC using yosys-sta "
	cd $(NPC_HOME)/../yosys-sta && make sta DESIGN=top SDC_FILE=$(NPC_HOME)/top.sdc RTL_FILES="$(shell find $(NPC_HOME)/vsrc -name "*.v")" CLK_FREQ_MHZ=100 INCLUDE_PATH=$(NPC_HOME)/vsrc/include
	cd $(NPC_HOME)

bin2hex:
	hexdump -v -e '4/1 "%02x" "\n"' $(IMAGE) > $(MEM_INIT_FILE)

clean:
	rm -rf $(BUILD_DIR) *.hex

clean_syn:
	cd $(NPC_HOME)/../yosys-sta && make clean
