# BUILD_DIR = ./build
VERILATOR=verilator
VERI_F +=   --cc --exe -x-assign fast --build --trace --top-module CPU_top +incdir+vsrc/include
OBJ_DIR = ./obj_dir
# SIM_TOPNAME = top
WORK_DIR = $(shell pwd)
INC_PATH := $(WORK_DIR)/csrc/include $(INC_PATH)
INCLUDES = $(addprefix -I, $(INC_PATH))
C_F+= -CFLAGS "$(INCLUDES)"


V_FILE= $(shell find ./vsrc -name "*.v" -o -name "*.sv")


C_FILE+= $(shell find ./csrc -name "*.cpp" -o -name "*.c")


compile:
	@echo "runing simulation for test module "
	$(VERILATOR) $(C_F) $(VERI_F) $(C_FILE)  $(V_FILE)

sim: compile
	$(OBJ_DIR)/VCPU_top

gtk:sim 
	gtkwave testbench.vcd

clean:
	rm -rf obj_dir
