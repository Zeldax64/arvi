`include "arvi_defines.vh"

`define BUS_M \
	input  i_ack, \
	input  [31:0] i_rd_data, \
	output o_bus_en, \
	output o_wr_en, \
	output [31:0] o_wr_data, \
	output [31:0] o_addr, \
	output [3:0]  o_byte_en \
`ifdef __ATOMIC \
	,\
	output [6:0] o_operation, \
	output o_atomic \
`endif 
