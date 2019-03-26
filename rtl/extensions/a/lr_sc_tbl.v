`timescale 1ns / 1ps

`include "defines.vh"

module lr_sc_tbl 
	#(
		parameter ADDR_WIDTH = `XLEN,
		parameter N_IDS = 1
	)
	(
	input i_clk,
	input i_rst,
	input i_wr_en,
	input i_set_res,
	input i_check_res,
	input [$clog2(N_IDS)-1:0]i_id,
	input [ADDR_WIDTH-1:0]i_addr,
	output o_gnt
	);

	reg [ADDR_WIDTH-1:0] tbl [N_IDS-1:0];
	wire [N_IDS-1:0] hit, rst;

	genvar i;
	generate
		for(i = 0; i < N_IDS; i = i+1) begin
			assign hit[i] = tbl[i] == i_addr;
			assign rst[i] = hit[i] && i_wr_en;
		end
	endgenerate

	assign o_gnt = (i_check_res) ? hit[i_id] : 1'b0;

	integer j;
	always@(posedge i_clk) begin
		// Set reservation
		if(i_set_res) 
			tbl[i_id] <= i_addr;

		// Reset logic
		for(j = 0; j < N_IDS; j = j+1) begin
			tbl[j] <= (rst[j] || ~i_rst) ? {ADDR_WIDTH{1'b0}} : tbl[j];
		end
		if(i_check_res && !hit[i_id]) // If any SC occurs after an LR
			tbl[i_id] <= {ADDR_WIDTH{1'b0}}; 
	end

endmodule