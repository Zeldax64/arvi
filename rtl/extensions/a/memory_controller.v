`timescale 1ns / 1ps

`include "defines.vh"

module memory_controller(
	input  i_bus_en,
	input  i_wr_rd,
	input  [31:0] i_wr_data,
	input  [31:0] i_addr,
	input  [3:0] i_byte_en,
	input  i_atomic,
	output reg  o_ack,
	output reg  [31:0] o_rd_data
	);