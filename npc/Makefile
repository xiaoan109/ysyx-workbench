ARCH = riscv32e-npc
ifeq ($(ARCH), riscv32e-npc)
TOPNAME = top
else
ifeq ($(ARCH), riscv32e-ysyxsoc)
TOPNAME = ysyxSoCFull
CXXFLAGS += -DYSYXSOC
VERILATOR_FLAGS += +define+YSYXSOC
endif
endif
NXDC_FILES = constr/ysyxSoCFull.nxdc
SYN_TOP = top

VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -x-assign fast --x-initial fast
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
VERILATOR_FLAGS += +incdir+$(NPC_HOME)/vsrc/include +incdir+$(SOC_HOME)/perip/uart16550/rtl +incdir+$(SOC_HOME)/perip/spi/rtl
VERILATOR_FLAGS += --build -Mdir $(BUILD_DIR)

# This ensures verilog normal display but reduces performance
VERILATOR_FLAGS += --autoflush

VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing

BUILD_DIR = $(NPC_HOME)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
IMAGE ?= $(HOME)/ysyx-workbench/am-kernels/tests/cpu-tests/build/dummy-$(ARCH).bin
MEM_INIT_FILE = /tmp/mem.hex
NPC_ARGS := --img $(IMAGE)

ifneq ($(DIFFTEST), )
CXXFLAGS += -DDIFFTEST_ON
NPC_ARGS += --diff $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
endif

ifneq ($(WAVE), )  #wave trace
CXXFLAGS += -DTRACE_ON
endif

ifneq ($(MAXCYCLE), )
CXXFLAGS += -DDEBUG_TIME -DMAX_CYCLE=$(MAXCYCLE)
endif

ifneq ($(MTRACE), ) #mem trace
CXXFLAGS += -DMTRACE_ON
endif

ifneq ($(BOARD), ) #NVBOARD
CXXFLAGS += -DNVBOARD
endif

ifneq ($(MEM_INIT_FILE), )
VERILATOR_FLAGS += +define+MEM_INIT_FILE=\"$(MEM_INIT_FILE)\"
endif

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
ifeq ($(ARCH), riscv32e-ysyxsoc)
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
CSRCS += $(SRC_AUTO_BIND)
endif

# project source
VSRCS = $(shell find ./vsrc -path $(NPC_HOME)/vsrc/deprecated -path $(NPC_HOME)/include -prune -o -name "*.v" -o -name "*.sv")
ifeq ($(ARCH), riscv32e-ysyxsoc)
VSRCS += $(shell find $(SOC_HOME)/perip -name "*.v")
VSRCS += $(SOC_HOME)/build/ysyxSoCFull.v
endif
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")


WAVE_CFG = $(shell find . -name "*.gtkw")

# rules for verilator
INC_PATH += $(abspath ./csrc/include)
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

run: $(BIN)
	@echo ARCH=$(ARCH)
	@$^ $(NPC_ARGS)

wave:
ifneq ($(WAVE_CFG), )
	gtkwave $(BUILD_DIR)/sim.vcd -a $(WAVE_CFG) &
else
	gtkwave $(BUILD_DIR)/sim.vcd &
endif

syn:
	@echo "Synthesis NPC using yosys-sta "
	cd $(NPC_HOME)/../yosys-sta && make sta DESIGN=$(SYN_TOP) SDC_FILE=$(NPC_HOME)/top.sdc \
																 RTL_FILES="$(shell find $(NPC_HOME)/vsrc -path $(NPC_HOME)/vsrc/deprecated -prune -o -name "*.v")" \
																 CLK_FREQ_MHZ=100 INCLUDE_PATH=$(NPC_HOME)/vsrc/include
	cd $(NPC_HOME)

bin2hex:
	hexdump -v -e '4/1 "%02x" "\n"' $(IMAGE) > $(MEM_INIT_FILE)

clean:
	rm -rf $(BUILD_DIR)

clean_syn:
	cd $(NPC_HOME)/../yosys-sta && make clean
	cd $(NPC_HOME)

.PHONY: default all clean run wave syn clean_syn bin2hex