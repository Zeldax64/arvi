`timescale 1ns / 1ps

module ARBITER_2X1(
	input i_clk,
	input i_rst,

	// Bus 1
	input  i_bus_en1,
	input  i_wr_rd1,
	input  [31:0] i_wr_data1,
	input  [31:0] i_addr1,
	input  [2:0] i_size1,
	output o_ack1,
	output [31:0] o_rd_data1,
	
	// Bus 2
	input  i_bus_en2,
	input  i_wr_rd2,
	input  [31:0] i_wr_data2,
	input  [31:0] i_addr2,
	input  [2:0] i_size,
	output  o_ack2,
	output  [31:0] o_rd_data2,

	// To Bus
	input  i_ack,
	input  [31:0] i_rd_data,
	output o_bus_en,
	output o_wr_rd,
	output [31:0] o_wr_data,
	output [31:0] o_addr,
	output [2:0] o_size
	);

	wire bus1_req, bus2_req;
	wire bus1_grant, bus2_grant;

	assign bus1_req = i_bus_en1;
	assign bus2_req = i_bus_en2;



endmodule