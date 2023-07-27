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
VSRC = $(wildcard vsrc/*.v)
TOP = example
WORK = work

# Default target
all: compile run

# Target to compile verilog sources
compile: $(VSRC)
	if [ ! -d "$(WORK)" ]; then vlib $(WORK); fi
	vlog -work $(WORK) $^

# Target to run simulation
run:
	vsim -c -do "run -all" $(WORK).$(TOP)

# Target to clean files
clean:
	rm -rf transcript vsim.wlf $(WORK)

