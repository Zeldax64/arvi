VL := verilator
TOP_MODULE := RISC_V
DEFINES := -D__ARVI_PERFORMANCE_ANALYSIS
CFLAGS := -CFLAGS "-std=c++0x -Wall -O1 $(DEFINES)"
LDFLAGS := -LDFLAGS "-lfesvr"
VLFLAGS := -Wall --cc --trace -I./rtl --exe --top-module $(TOP_MODULE) $(CFLAGS) $(LDFLAGS) $(DEFINES)

VL_SRCS := $(wildcard tb/verilator/*.cpp)
VL_SRCS += $(wildcard tb/verilator/profiler/*.cpp)

# Function to find files in subfolders
subdirs = $(filter-out $1,$(sort $(dir $(wildcard $1*/))))
rfind = $(wildcard $1$2) $(foreach d,$(call subdirs,$1),$(call rfind,$d,$2))
######################################
SRC_DIR := ./rtl
SOURCES := $(call rfind,$(SRC_DIR)/,*.v)
HEADERS := $(call rfind,$(SRC_DIR)/,*.vh)

SCRIPTS_DIR := ./tb/scripts
run: all
	@echo "--- Running ---"
	obj_dir/VRISC_V +loadmem=rv32ui-p-add -v

all: $(SOURCES) $(HEADERS)
	$(VL) $(VLFLAGS) $(SOURCES) $(VL_SRCS) $(TOP_PARAMETERS) -D__ARVI_PERFORMANCE_ANALYSIS
	make -j -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE) 

.PHONY: clean help regression-tests benchmark performance 

JUNK := $(call rfind, ./tb/,*.vcd)
JUNK += $(call rfind, ./tb/,*.signature_output)
JUNK += $(call rfind, ./tb/,*.performance_report)

clean:
	rm -rf obj_dir
	rm -f *.vcd *.lxt2 $(JUNK)

reports = $(wildcard tb/tests/benchmark/*.performance_report)
reports2 = tb/tests/benchmark/*.performance_report

help:
	echo $(reports2)

regression-tests: all
	python3 $(SCRIPTS_DIR)/regression.py --isa --compliance --benchmark

benchmark: all
	python3 $(SCRIPTS_DIR)/regression.py --benchmark

performance:
	python3 $(SCRIPTS_DIR)/performance.py $(reports)

