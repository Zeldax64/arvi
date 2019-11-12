# Synthesis script using Vivado

set design [lindex $argv 0]
set root "."

puts $design
puts [lindex $argv 1]

set rtldir $root/rtl
set projdir $root/synth/$design
set partname "xc7k70tfbv676-1"
set reportdir $projdir/report

file mkdir $projdir
file mkdir $reportdir

create_project -force $design $projdir -part $partname
set_property target_language Verilog [current_project]
set_property source_mgmt_mode None [current_project]

add_files -scan_for_includes -fileset [get_filesets sources_1] $rtldir
set_property top $design [get_filesets sources_1]

synth_design -top $design -part $partname

create_clock -name i_clk -period 10.000
report_utilization -file $reportdir/ultilization.rpt
report_timing > $reportdir/timing.rpt

exit