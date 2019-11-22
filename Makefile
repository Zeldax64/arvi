VL := verilator
TOP_MODULE := RISC_V

# Shared defines between Verilog and C++ code
DEFINES := -D__ARVI_PERFORMANCE_ANALYSIS
CFLAGS := -CFLAGS "-std=c++0x -Wall -O1 $(DEFINES)"
LDFLAGS := -LDFLAGS "-lfesvr"
VLFLAGS := -Wall --cc --trace -I./rtl --exe --top-module $(TOP_MODULE) $(CFLAGS) $(LDFLAGS) $(DEFINES)

VL_SRCS := $(wildcard sim/verilator/*.cpp)
VL_SRCS += $(wildcard sim/verilator/profiler/*.cpp)

# Function to find files in subfolders
subdirs = $(filter-out $1,$(sort $(dir $(wildcard $1*/))))
rfind = $(wildcard $1$2) $(foreach d,$(call subdirs,$1),$(call rfind,$d,$2))
######################################

SRC_DIR := ./rtl
SOURCES := $(call rfind,$(SRC_DIR)/,*.sv)
HEADERS := $(call rfind,$(SRC_DIR)/,*.vh)
SCRIPTS_DIR := ./sim/scripts

modules := $(basename $(call rfind,$(SRC_DIR)/,*.sv))
mods := $(patsubst %, %.mod, $(notdir $(modules)))

run: all
	@echo "--- Running ---"
	obj_dir/VRISC_V +loadmem=rv32ui-p-add -v

all: $(SOURCES) $(HEADERS)
	$(VL) $(VLFLAGS) $(SOURCES) $(VL_SRCS) $(TOP_PARAMETERS) -D__ARVI_PERFORMANCE_ANALYSIS
	make -j -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE) 

yosys: $(SOURCES) $(HEADERS)
	yosys ./sim/scripts/yosys.ys

.PHONY: clean help regression-tests benchmark performance synthesis

JUNK := $(call rfind, ./sim/,*.vcd)
JUNK += $(call rfind, ./sim/,*.signature_output)
JUNK += $(call rfind, ./sim/,*.performance_report)

clean:
	rm -rf obj_dir
	rm -rf *.vcd *.lxt2 $(JUNK)
	rm -rf synth .Xil
	rm -f *.log *.jou

performance_reports = $(wildcard sim/tests/benchmark/*.performance_report)

regression-tests: all
	python3 $(SCRIPTS_DIR)/regression.py --isa --compliance --benchmark

benchmark: all
	python3 $(SCRIPTS_DIR)/regression.py --benchmark

performance: 
	python3 $(SCRIPTS_DIR)/performance.py $(performance_reports)

# Synthesis related rules.
# Please notice that vivado is necessary to synthesize the design.
synthesis-arvi:
	mkdir -p synth
	vivado -nojournal -nolog -mode tcl -source fpga/scripts/vivado_synth.tcl -tclargs $(TOP_MODULE)

synthesis-cost: $(mods) synthesis-arvi 
	./fpga/scripts/collect_synth.sh > synth.csv

basys3:
	mkdir -p synth
	vivado -nojournal -nolog -mode tcl -source fpga/scripts/basys3.tcl


%.mod: 
	mkdir -p synth
	vivado -nojournal -nolog -mode tcl -source fpga/scripts/vivado_synth.tcl -tclargs $*	
