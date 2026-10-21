#---------------------------------------------------------------------
# User settings  (change these as needed)
#---------------------------------------------------------------------
# top-level testbench module name
TOP        ?= tb_top
# work library name
WORK       ?= work
# random seed (for $$urandom etc.)
SEED       ?= 1
 
# Extra options (override from command line if needed)
VLOG_OPTS  ?=
VSIM_OPTS  ?=
 
#---------------------------------------------------------------------
# Folders
#---------------------------------------------------------------------
RTL_DIR    := ../RTL
TB_DIR     := ../TB
 
#---------------------------------------------------------------------
# Source files (auto-detected, both Verilog and SystemVerilog)
#---------------------------------------------------------------------
RTL_SRC    := $(sort $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*.sv))
TB_SRC     := $(sort $(wildcard $(TB_DIR)/*.v  $(TB_DIR)/*.sv))
 
# Compile order: RTL first, then testbench
ALL_SRC    := $(RTL_SRC) $(TB_SRC)
 
#---------------------------------------------------------------------
# Tool commands
#---------------------------------------------------------------------
VLIB       := vlib
VMAP       := vmap
VLOG       := vlog
VSIM       := vsim
 
VLOG_FLAGS := -work $(WORK) +incdir+$(RTL_DIR) +incdir+$(TB_DIR) \
              -timescale 1ns/1ps $(VLOG_OPTS)
 
VSIM_FLAGS := -voptargs=+acc -sv_seed $(SEED) -l sim.log $(VSIM_OPTS)
 
#---------------------------------------------------------------------
# Targets
#---------------------------------------------------------------------
.PHONY: all help lib compile sim gui wave clean check
 
all: sim
 
help:
	@echo "-------------------------------------------------------------"
	@echo " make lib       : create work library"
	@echo " make compile   : compile RTL and TB files (vlog)"
	@echo " make sim       : compile + run simulation in batch mode"
	@echo " make gui       : compile + run simulation in GUI mode"
	@echo " make wave      : open saved waveform (vsim -view wave.wlf)"
	@echo " make clean     : delete work lib, logs, wlf, transcripts"
	@echo ""
	@echo " Options  : TOP=<tb_module>  SEED=<n>  VLOG_OPTS=... VSIM_OPTS=..."
	@echo " Current  : TOP=$(TOP)"
	@echo "-------------------------------------------------------------"
 
# Make sure there are source files
check:
	@if [ -z "$(ALL_SRC)" ]; then \
		echo "ERROR: no .v/.sv files found in $(RTL_DIR) or $(TB_DIR)"; \
		exit 1; \
	fi
 
# Create and map work library
lib:
	@if [ ! -d $(WORK) ]; then \
		echo ">> Creating library: $(WORK)"; \
		$(VLIB) $(WORK); \
		$(VMAP) $(WORK) $(WORK); \
	fi
 
# Compile design + testbench
compile: check lib
	@echo ">> Compiling RTL and TB files ..."
	$(VLOG) $(VLOG_FLAGS) $(ALL_SRC) | tee compile.log
 
# Batch simulation (no GUI), dumps waveform to wave.wlf
sim: compile
	@echo ">> Running simulation (batch) : $(TOP)"
	$(VSIM) -c $(VSIM_FLAGS) -wlf wave.wlf $(WORK).$(TOP) \
		-do "log -r /*; run -all; quit -f"
 
# GUI simulation
gui: compile
	@echo ">> Running simulation (GUI) : $(TOP)"
	$(VSIM) -gui $(VSIM_FLAGS) -wlf wave.wlf $(WORK).$(TOP) \
		-do "add wave -r /*; run -all"
 
# View previously saved waveform
wave:
	$(VSIM) -view wave.wlf &
 
# Cleanup
clean:
	@echo ">> Cleaning ..."
	rm -rf $(WORK) transcript *.log *.wlf *.vcd modelsim.ini vsim.wlf \
	       vish_stacktrace.vstf wlft* .qsys_* *.ucdb covhtmlreport
