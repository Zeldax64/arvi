/*
	Same as the rv32_m module but this module creates an interface to be used 
	in an external module (out of the Datapath).
*/

`timescale 1ns / 1ps

`include "arvi_defines.svh"

module rv32_m_external(
	input  i_clk,
	input  i_rst,
	input  i_en,
	input  [`XLEN-1:0] i_rs1,
	input  [`XLEN-1:0] i_rs2,
	input  [2:0] i_f3,
	output logic [`XLEN-1:0] o_res,
	output logic o_ack
	);
	
	logic finished, stall;
	logic [`XLEN-1:0] res;
	logic rv32_m_en, stall_dly;

	always_ff@(posedge i_clk) begin
		if(!i_rst) begin
			rv32_m_en <= 0;
			stall_dly <= 0;
			o_ack     <= 0;
		end
		else begin
			if(i_en) rv32_m_en <= 1; 	 // Creates a steady enable signal
			if(finished) rv32_m_en <= 0;

			stall_dly <= stall;
			o_res <= res;
		    o_ack <= finished;
		end
	end

	// Is the computation finished?
	assign finished = stall_dly && !stall;

	rv32_m rv32_m
	(
		.i_clk   (i_clk),
		.i_rst   (i_rst),
		.i_en    (rv32_m_en),
		.i_rs1   (i_rs1),
		.i_rs2   (i_rs2),
		.i_f3    (i_f3),
		.o_res   (res),
		.o_stall (stall)
	);	

endmodule 