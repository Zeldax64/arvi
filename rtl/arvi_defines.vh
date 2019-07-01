`ifndef __ARVI_DEFINES
`define __ARVI_DEFINES
//`define SIMULATION

`define INSTRUCTION_SIZE 31
`define WORD_SIZE 31
`define XLEN 32
// Start address
`define PC_RESET 32'h80000000

`define PROGRAM_DATA "./test/asm/addi.bin"

`define __SINGLE_CORE
//`define __DUAL_CORE

`ifdef __DUAL_CORE
	`define __ATOMIC
`endif

//`define __RV32_M
//`define __RV32_M_EXTERNAL

`include "top/bus/bus_if.vh"

`define __ARVI_PERFORMANCE_ANALYSIS
`ifdef __ARVI_PERFORMANCE_ANALYSIS
`include "arvi_dpi.vh"
`endif 

`endif
