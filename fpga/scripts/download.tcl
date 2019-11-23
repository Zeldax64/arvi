# Simple script to download bitstream to FPGA.
# Please make sure to have only one FPGA connected
# to the computer before running this script.


if { $argc < 1} {
	puts "No bitstream file passed!"
	exit
}

set bitstream [lindex $argv 0];

open_hw;
connect_hw_server;
open_hw_target;
set_property PROGRAM.FILE $bitstream [current_hw_device];
program_hw_devices;

exit