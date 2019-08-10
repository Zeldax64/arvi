`timescale 1ns / 1ps

`include "arvi_defines.vh"
`include "extensions/a/atomic.vh"

module atomic_alu(
	input  [4:0]  i_op,
	input  [`XLEN-1:0] s1,
	input  [`XLEN-1:0] s2,

	output reg [`XLEN-1:0] alu_res	
	);

	always@(*) begin
		case(i_op)
			`AMOSWAP : alu_res = s1;
			`AMOADD  : alu_res = s1 + s2;
			`AMOXOR  : alu_res = s1 ^ s2;
			`AMOAND  : alu_res = s1 & s2;
			`AMOOR   : alu_res = s1 | s2;
			`AMOMIN  : alu_res = ($signed(s1) < $signed(s2)) ? s1 : s2;
			`AMOMAX  : alu_res = ($signed(s1) < $signed(s2)) ? s2 : s1;
			`AMOMINU : alu_res = (s1 < s2) ? s1 : s2;
			`AMOMAXU : alu_res = (s1 < s2) ? s2 : s1;
			default  : alu_res = s1;
		endcase
	end

endmodule