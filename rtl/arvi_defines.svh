`ifndef __ARVI_DEFINES
`define __ARVI_DEFINES

`define INSTRUCTION_SIZE 31
`define XLEN 32
// Start address.
`define PC_RESET 32'h80000000

// Select number of cores.
`define __SINGLE_CORE
//`define __DUAL_CORE

`ifdef __DUAL_CORE
	`define __RVA
`endif

// Remove comments to enable extensions.
//`define __RVA
//`define __RVM
//`define __RVM_EXTERNAL

`include "arvi_interfaces.svh"

//`define __ARVI_PERFORMANCE_ANALYSIS
`ifdef __ARVI_PERFORMANCE_ANALYSIS
`include "arvi_dpi.svh"
`endif 

`endif
