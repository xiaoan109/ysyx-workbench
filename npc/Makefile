# all:
# 	@echo "Write this Makefile by your self."
# 
# sim:
# 	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
# 	@echo "Write this Makefile by your self."
# 
# include ../Makefile

### Questasim Makefile ###

# Variables
VSRC = $(shell find vsrc -name "*.v")
CSRC = $(shell find dpisrc -name "*.c")
TOP = testbench_cpu
WORK = work
INCDIR = vsrc/include
# Simulator type (mti/vcs/nc)
SIMULATOR = vcs
# MTI option
MTI_COMPILE_OPTIONS  = +acc=blnr -noincr +incdir+$(INCDIR) -sv
MTI_RUN_OPTIONS      = -voptargs="+acc=blnr"
ifdef TESTNAME
	MTI_RUN_OPTIONS += +TESTNAME=$(TESTNAME)
endif
MTI_VC_OPTIONS = $(VSRC)

# VCS option
VCS_OPTIONS    = +vcs+lic+wait +v2k +lint=all,noTMR,noVCDE -debug_acc+all \
				 +incdir+$(INCDIR) -sverilog \
				 -timescale=1ns/1ps -LDFLAGS -Wl,--no-as-needed \
				 -fsdb
VCS_SIM_OPTION = +vcs+lic+wait +vcs+flush+log -assert nopostproc \
				 -sv_lib dpilib +DUMP_FSDB
ifdef TESTNAME
	VCS_SIM_OPTION += +TESTNAME=$(TESTNAME)
endif
VCS_VC_OPTIONS = $(VSRC)

# Default Target

default : all

# ------- Simulator redirect -----------

compile : compile_$(SIMULATOR)


run     : run_$(SIMULATOR)


sim     : sim_$(SIMULATOR)


all     : all_$(SIMULATOR)

# ------- VCS -----------

# Compile RTL
compile_vcs :
	vcs $(VCS_OPTIONS) $(VCS_VC_OPTIONS) | tee compile_vcs.log
	gcc -I$(VCS_HOME)/include -Idpisrc/include -shared -fPIC -g -o dpilib.so $(CSRC)


# Run simulation in batch mode
run_vcs :
	@if [ ! -d logs ] ; then \
	  mkdir logs; \
	fi
	@echo quit > quit.do
	./simv $(VCS_SIM_OPTION)  < quit.do | tee logs/run_$(TESTNAME).log ;

# Run simulation in interactive mode
sim_vcs :
	./simv -gui +vcs+lic+wait +vcs+flush+log -sv_lib dpilib &

all_vcs : compile_vcs run_vcs

# Verdi
wave_verdi :
	verdi +v2k -sverilog +incdir+$(INCDIR) $(VSRC) -ssf wave.fsdb &

# ------- MTI -----------

# Compile RTL
compile_mti :
	@if [ -d work ] ; then \
          true ; \
	else \
	  vlib work; \
	fi
	vlog -incr -lint +v2k $(MTI_COMPILE_OPTIONS) $(MTI_VC_OPTIONS) | tee compile_mti.log
	gcc -I$(QUESTA_HOME)/include -Idpisrc/include -shared -fPIC -g -o dpilib.so $(CSRC)

# Run simulation in batch mode
run_mti :
	@if [ ! -d logs ] ; then \
	  mkdir logs; \
	fi
	vsim $(MTI_RUN_OPTIONS) -c $(TOP) -do "radix hex;run -all;quit -f" -sv_lib dpilib | tee logs/run_$(TESTNAME).log ;

# Run simulation in interactive mode
sim_mti :
	vsim $(MTI_RUN_OPTIONS) -gui $(TOP) -sv_lib dpilib &

# Create work directory
lib_mti :
	vlib work

all_mti : compile_mti run_mti

# Target to clean files
clean:
	rm -rf transcript $(WORK) *.log *.vcd *.wlf *.so *.vstf \
	simv simv.daidir csrc ucli.key vc_hdrs.h logs \
	*.fsdb verdiLog stack.info* tests/*.bin
