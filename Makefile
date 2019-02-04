VL := verilator
TOP_MODULE := RISC_V
CFLAGS := -CFLAGS "-std=c++0x -Wall"
LDFLAGS := -LDFLAGS "-lfesvr"
VLFLAGS := -Wall --cc --trace -I./rtl --exe --top-module $(TOP_MODULE) $(CFLAGS) $(LDFLAGS)

VL_SRCS := $(wildcard tb/verilator/*.cpp)

# Function to find files in subfolders
subdirs = $(filter-out $1,$(sort $(dir $(wildcard $1*/))))
rfind = $(wildcard $1$2) $(foreach d,$(call subdirs,$1),$(call rfind,$d,$2))
######################################
SRC_DIR := ./rtl/modules
SOURCES := $(call rfind,$(SRC_DIR)/,*.v)
SOURCES += rtl/top/RISC_V_DB.v
HEADERS := $(call rfind,$(SRC_DIR)/,*.vh)

SCRIPTS_DIR := ./tb/scripts

run: all
	@echo "--- Running ---"
	obj_dir/VRISC_V "+loadmem=I-MISALIGN_LDST-01.elf"

all: $(SOURCES) $(HEADERS)
	$(VL) $(VLFLAGS) $(SOURCES) $(VL_SRCS) 
	make -j -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)

.PHONY: clean help regression-tests

JUNK := $(call rfind, tb/,*.vcd)
JUNK += $(call rfind, tb/,*.signature_output)

clean:
	rm -rf obj_dir
	rm -f *.vcd *.lxt2 $(JUNK)

help:
	echo $(TEST_SRCS)

regression-tests: all
	python3 $(SCRIPTS_DIR)/regression.py
