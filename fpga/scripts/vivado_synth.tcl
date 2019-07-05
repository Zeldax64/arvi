# Synthesis script using Vivado

set design arvi
set root "."
set rtldir $root/rtl
set projdir $root/synth/vivado
set partname "xc7k70tfbv676-1"
set reportdir $projdir/report

file mkdir $projdir
file mkdir $reportdir

create_project -force $design $projdir -part $partname
set_property target_language Verilog [current_project]
set_property source_mgmt_mode None [current_project]

add_files -scan_for_includes -fileset [get_filesets sources_1] $rtldir
set_property top RISC_V [get_filesets sources_1]

synth_design -top RISC_V -part $partname

report_utilization -file $reportdir/ultilization.rpt

exit