#!/bin/bash

# Collect data from ultilization reports in all projects inside 'synth/' folder
# and print them in a csv fashion. 

echo 'Module,LUTs,FFs'

for proj in $(ls synth/)
do
	entry=$(
	grep -E "Slice LUTs|Register as Flip Flop" synth/$proj/report/ultilization.rpt | # Filter data. 
	awk -F '|' '{print $3}' | # Get "Used" column in Vivado report.
	tr '\n' ',' | sed '$s/ $/\n/') # Change new line to '|' and create an entry.
	
	echo "$proj,$entry" # Print {<module_name>|$entry}.
done
