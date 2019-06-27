`ifndef __ALU_DEFINES
`define __ALU_DEFINES

/*----- ALU Operations -----*/

	`define ALU_ADD  4'b0000
	`define ALU_SUB  4'b1000
	`define ALU_SLL  4'b0001
	`define ALU_SLT  4'b0010
	`define ALU_SLTU 4'b0011
	`define ALU_XOR  4'b0100
	`define ALU_SRL  4'b0101
	`define ALU_SRA  4'b1101
	`define ALU_OR   4'b0110
	`define ALU_AND  4'b0111	
	`define ALU_S1   4'b1001 // Source 1 valu bypasses ALU
/*
	localparam ALU_ADD  = 3'b000
	localparam ALU_SUB  = 3'b000
	localparam ALU_SLL  = 3'b001
	localparam ALU_SLT  = 3'b010
	localparam ALU_SLTU = 3'b011
	localparam ALU_XOR  = 3'b100
	localparam ALU_SRL  = 3'b101
	localparam ALU_SRA  = 3'b101
	localparam ALU_OR   = 3'b110
	localparam ALU_AND  = 3'b111
*/
`endif