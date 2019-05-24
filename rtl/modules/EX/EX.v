/*
	This file represents the execution stage of the processor's datapath.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module EX(
//	input i_clk,
//	input i_rst,

	input [`XLEN-1:0] i_rs1,
	input [`XLEN-1:0] i_rs2,

	// ALU CONTROL
	input [2:0] i_aluop,
	input [2:0] i_f3,
	input [6:0] i_f7,

	output [`XLEN-1:0] o_res,
	output o_Z
	);

	wire [3:0] alu_control_lines;

	ALU_CONTROL alu_control (
		.i_Funct7          (i_f7),
		.i_Funct3          (i_f3),
		.i_ALUOp           (i_aluop),
		.o_ALUControlLines (alu_control_lines)
	);

	ALU alu (
		.i_op (alu_control_lines),
		.i_Ra (i_rs1),
		.i_Rb (i_rs2),
		.o_Z  (o_Z),
		.o_Rc (o_res)
	);
endmodule