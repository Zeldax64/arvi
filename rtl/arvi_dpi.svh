`ifndef __ARVI_DPI
`define __ARVI_DPI

`ifdef __ARVI_PERFORMANCE_ANALYSIS
import "DPI-C" function void new_instruction(input int hart, input int inst, input int cycles);
import "DPI-C" function void cache_hit(input int hart);
import "DPI-C" function void cache_miss(input int hart, input int cycles);
`endif

`endif