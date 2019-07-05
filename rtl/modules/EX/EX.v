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

`ifdef __RV32_M
	input i_clk,
	input i_rst,
	input i_m_en,
	`ifdef __RV32_M_EXTERNAL
		`RV32_M_IF,
	`endif
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


`ifdef __RV32_M
	wire [`XLEN-1:0] rv_m_res;

	`ifndef __RV32_M_EXTERNAL
		rv32_m rv32_m
			(
				.i_clk   (i_clk),
				.i_rst   (i_rst),
				.i_en    (i_m_en),
				.i_rs1   (i_rs1),
				.i_rs2   (i_rs2),
				.i_f3    (i_f3),
				.o_res   (rv_m_res),
				.o_stall (o_stall)
			);
	`else 
		// Code for external RV32_M
		reg enable;
		reg en_delayed;
		always@(posedge i_clk) begin
			if(!i_rst || i_ack) begin
				en_delayed <= 0;
				enable <= 0;
			end
			else begin
				if(i_m_en) begin
					o_rs1 <= i_rs1;
					o_rs2 <= i_rs2;
					o_f3  <= i_f3;
					en_delayed <= i_m_en; 
				end
				enable <= !en_delayed && i_m_en; // Create a 0->1 pulse
			end
		end		
		
		always@(*) begin
			o_en  = enable; // Create a 0->1 pulse
		end
		
		assign o_stall  = !i_ack && i_m_en;
		assign rv_m_res = i_res; 
	`endif

	assign o_res = i_m_en ? rv_m_res : alu_res; // Ex stage result	

`else
	assign o_res = alu_res;
	assign o_stall = 0;
`endif

endmodule
