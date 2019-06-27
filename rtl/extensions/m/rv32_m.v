/*
	This module provides RV32-M extension. It should be used in EX stage. 
*/

`include "arvi_defines.vh"

module rv32_m(
	input  i_clk,
	input  i_rst,
	input  i_en,
	input  [`XLEN-1:0] i_rs1,
	input  [`XLEN-1:0] i_rs2,
	input  [2:0] i_f3,
	output [`XLEN-1:0] o_res,
	output o_stall	
	);

	wire mul_done, div_done, done;
	wire is_mul, is_div;
	wire [`XLEN-1:0] mul_res, div_res, rv_m_res;

	assign is_mul = i_en && !i_f3[2]; 
	assign is_div = i_en &&  i_f3[2];

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

	// Divider only accepts a pulse to start. Steady enable = 1 signals don't work.
	// This should be improved
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

	assign done     = is_div ? div_done && !div_en : mul_done; 
	assign o_stall  = ~done && i_en;
	assign rv_m_res = is_div ? div_res : mul_res; // RV32-M result
	assign o_res    = rv_m_res; 

endmodule