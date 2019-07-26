/*
	This module defines interfaces used by other modules in this project.
*/

`ifndef __ARVI_INTERFACES
`define __ARVI_INTERFACES
`include "arvi_defines.vh"

// Bus master interface
`define BUS_M 					\
	input  i_ack, 				\
	input  [31:0] i_rd_data, 	\
	output o_bus_en, 			\
	output o_wr_en, 			\
	output [31:0] o_wr_data,	\
	output [31:0] o_addr, 		\
	output [3:0]  o_byte_en 	\
`ifdef __ATOMIC 				\
	,							\
	output [6:0] o_operation, 	\
	output o_atomic 			\
`endif 


`define RV32_M_IF 					\
	output reg o_en, 				\
	output reg [`XLEN-1:0] o_rs1, 	\
	output reg [`XLEN-1:0] o_rs2, 	\
	output reg [2:0] o_f3, 			\
	input  [`XLEN-1:0] i_res, 		\
	input  i_ack 					


`endif
