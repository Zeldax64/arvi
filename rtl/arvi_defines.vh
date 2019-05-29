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

// Extensions
`ifdef __DUAL_CORE
	`define __ATOMIC
`endif

`define __ARVI_M_EX

`include "arvi_dpi.vh"

`endif
