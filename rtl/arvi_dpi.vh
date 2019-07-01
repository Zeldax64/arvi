`ifndef __ARVI_DPI
`define __ARVI_DPI

import "DPI-C" function void new_instruction (input int inst, input int cycles);
import "DPI-C" function void cache_hit ();
import "DPI-C" function void cache_miss(input int cycles);

`endif