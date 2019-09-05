# Import yosys commands into tcl interpreter
yosys -import

source ./sim/scripts/utils.tcl

# Get rtl recursively
set sources [findFiles ./rtl *.sv]

# Reading files into yosys
foreach rtl_source $sources {
	read_verilog -sv -I./rtl $rtl_source
}
