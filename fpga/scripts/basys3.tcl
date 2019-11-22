# Synthesis script using Vivado. This script generates bitstream
# to a basys3 board.

set design basys3
set root "."

set rtldir $root/rtl
set partdir $root/fpga/part/$design
set ipdir $root/fpga/ip
set projdir $root/synth/$design
set partname "xc7a35tcpg236-1"
set reportdir $projdir/report

file mkdir $projdir
file mkdir $reportdir

# Create project
create_project -force $design $projdir -part $partname
set_property target_language Verilog [current_project]
set_property source_mgmt_mode None [current_project]

# Add ARVI rtl files.
add_files -scan_for_includes -fileset [get_filesets sources_1] $rtldir
# Add modules in fpga/ip directory.
add_files -scan_for_includes -fileset [get_filesets sources_1] $ipdir
# Add constraint file.
add_files -fileset constrs_1 -norecurse $partdir/basys3.xdc
# Add all verilog files in part/basys3.
add_files -scan_for_includes $partdir

add_files -norecurse -scan_for_includes $partdir/program.mem

# Set top module
#set_property top top [get_filesets sources_1]

synth_design -top top -part $partname
opt_design
power_opt_design
place_design
route_design
phys_opt_design
write_bitstream -force $projdir/basys3.bit

exit