/*
	This file represents the execution stage of processor's datapath.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module EX(
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
	input i_rst,
	input i_m_en,
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
	wire mul_done, div_done, done;
	wire is_mul, is_div;
	wire [`XLEN-1:0] mul_res, div_res, m_res;

	assign is_mul = i_m_en && !i_f3[2]; 
	assign is_div = i_m_en &&  i_f3[2];

	mul_top multiplier
		(
			.i_clk   (i_clk),
			.i_start (is_mul),
			.i_f3    (i_f3),
			.i_rs1   (i_rs1),
			.i_rs2   (i_rs2),
			.o_done  (mul_done),
			.o_res   (mul_res)
		);

	wire div_en;
	reg  div_en_d;

	always@(posedge i_clk) begin
		if(!i_rst) div_en_d <= 0;
		else div_en_d <= is_div;
	end

	assign div_en = is_div && !div_en_d; 

	div_top divider
		(
			.i_clk   (i_clk),
			.i_rst   (i_rst),
			.i_start (div_en),
			.i_f3    (i_f3),
			.i_rs1   (i_rs1),
			.i_rs2   (i_rs2),
			.o_res   (div_res),
			.o_done  (div_done)
		);

	assign m_res   = is_div ? div_res : mul_res;
	assign o_res   = i_m_en ? m_res : alu_res;
	assign done    = is_div ? div_done && !div_en : mul_done; 
	assign o_stall = ~done && i_m_en;


`endif

endmodule