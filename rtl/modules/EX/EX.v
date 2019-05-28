/*
	This file represents the execution stage of processor's datapath.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module EX(
//	input i_rst,
	input [`XLEN-1:0] i_rs1,
	input [`XLEN-1:0] i_rs2,

	// ALU CONTROL
	input [2:0] i_aluop,
	input [2:0] i_f3,
	input [6:0] i_f7,

	output [`XLEN-1:0] o_res,
	output o_Z,

`ifdef __ARVI_M_EX
	input i_clk,
	input i_m_start,
`endif
	output o_stall
	);

	wire [3:0] alu_control_lines;
	wire [`XLEN-1:0] alu_res;

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
		.o_Rc (alu_res)
	);

`ifndef __ARVI_M_EX
	assign o_res = alu_res;
	assign o_stall = 0;
`else
	wire done;
	wire [`XLEN-1:0] mul_res;
	assign o_stall = ~done && i_m_start;

	mul_top multiplier
		(
			.i_clk   (i_clk),
			.i_start (i_m_start),
			.i_f3    (i_f3),
			.i_rs1   (i_rs1),
			.i_rs2   (i_rs2),
			.o_done  (done),
			.o_res   (mul_res)
		);

	assign o_res = i_m_start ? mul_res : alu_res;
`endif

endmodule