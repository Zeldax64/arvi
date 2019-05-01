/*
	ALU.v
*/
`timescale 1ns / 1ps

`include "modules/ALU/ALU_DEFINES.vh"
`include "arvi_defines.vh"

module ALU(
	input  [3:0]  i_op,
	input  [`XLEN-1:0] i_Ra,
	input  [`XLEN-1:0] i_Rb,

	output o_Z, // Z Flag
	output reg [`XLEN-1:0] o_Rc 
);

	always@(*) begin
		case(i_op)
			`ALU_ADD:  o_Rc = i_Ra + i_Rb;
			`ALU_SUB:  o_Rc = i_Ra - i_Rb;
			`ALU_SLL:  o_Rc = i_Ra << i_Rb[4:0];
			`ALU_SLT:  o_Rc = {{`XLEN-1{1'b0}}, $signed(i_Ra) < $signed(i_Rb)}; 
			`ALU_SLTU: o_Rc = {{`XLEN-1{1'b0}}, i_Ra < i_Rb};
			`ALU_XOR:  o_Rc = i_Ra ^ i_Rb;
			`ALU_SRL:  o_Rc = i_Ra >>  i_Rb[4:0];
			`ALU_SRA:  o_Rc = $signed(i_Ra) >>> i_Rb[4:0];
			`ALU_OR:   o_Rc = i_Ra | i_Rb;
			`ALU_AND:  o_Rc = i_Ra & i_Rb;
			`ALU_S1:   o_Rc = i_Ra;
			default:   o_Rc = `XLEN'b0;
		endcase
	end

	assign o_Z = o_Rc == 0;

endmodule
