/*
	This module provides RV32-M extension. It should be used in EX stage. 
*/

`include "arvi_defines.vh"
`include "extensions/m/m_isa.vh"

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

	logic mul_done, div_done, done;
	logic is_mul, is_div;
	logic [`XLEN-1:0] mul_res, div_res, rv_m_res;

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

	logic div_en;
	logic div_en_d;
	logic div_done_d;
	logic is_div_finished;
	
	// Edge detectors	
	assign div_en = is_div && !div_en_d; 
	assign is_div_finished = div_done && !div_done_d;
	
	always_ff@(posedge i_clk) begin
		if(!i_rst) begin 
			div_en_d   <= 0;
			div_done_d <= 0;
		end
		else begin 
			div_en_d   <= is_div && !is_div_finished; // If it is a division but the division isn't already done, then do it.
			div_done_d <= div_done;
		end
	end

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
	
`ifdef RISCV_FORMAL_ALTOPS
	assign o_res =	i_f3 == `MUL    ? (i_rs1 + i_rs2) ^ 32'h5876063e :
					i_f3 == `MULH   ? (i_rs1 + i_rs2) ^ 32'hf6583fb7 :
					i_f3 == `MULHSU ? (i_rs1 - i_rs2) ^ 32'hecfbe137 :
					i_f3 == `MULHU  ? (i_rs1 + i_rs2) ^ 32'h949ce5e8 :
					i_f3 == `DIV  	? (i_rs1 - i_rs2) ^ 32'h7f8529ec :
					i_f3 == `DIVU 	? (i_rs1 - i_rs2) ^ 32'h10e8fd70 :
					i_f3 == `REM  	? (i_rs1 - i_rs2) ^ 32'h8da68fa5 :
					i_f3 == `REMU 	? (i_rs1 - i_rs2) ^ 32'h3138d0e1 : 32'bx;
`else
	assign o_res = rv_m_res; 
`endif
endmodule