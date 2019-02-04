`ifndef __DEFINES
`define __DEFINES
//`define SIMULATION
`define FPGA

`define INSTRUCTION_SIZE 31
`define WORD_SIZE 31
`define XLEN 32
// Start address
`define PC_RESET 32'h80000000 

`define INSTRUCTION_MEMORY_SIZE 256
`define DATA_MEMORY_SIZE 256

`define PROGRAM_DATA "./test/asm/addi.bin"
`endif