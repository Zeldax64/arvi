`ifndef __CSR_DEFINES
`define __CSR_DEFINES

/*
	Contants used to implement CSRs in CSR.v
*/
`define PRIV	3'b000
`define CSRRW 	3'b001
`define CSRRS 	3'b010
`define CSRRC 	3'b011
`define CSRRWI 	3'b101
`define CSRRSI 	3'b110
`define CSRRCI 	3'b111


// Machine Information Registers
`define mvendorid 	12'hF11
`define marchid 	12'hF12
`define mimpid 		12'hF13
`define mhartid 	12'hF14

// Machine Trap Setup
`define mstatus 	12'h300
`define misa 		12'h301
`define medeleg 	12'h302
`define mideleg 	12'h303
`define mie 		12'h304
`define mtvec 		12'h305
`define mcounteren 	12'h306

// Machine Trap Handling
`define mscratch 	12'h340
`define mepc 		12'h341
`define mcause 		12'h342
`define mtval 		12'h343
`define mip 		12'h344

// Machine Counter/Timers
`define mcycle 		12'hB00
`define minstret 	12'hB02
`define mcycleh 	12'hB80
`define minstreth 	12'hB82

// Trap-Return Instructions
`define URET 12'b001100000010
`define SRET 12'b000100000010
`define MRET 12'b001100000010

`endif