/*
	File containing the Branch Control module responsible for deciding whether a
	Branch is taken or not.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module branch_control(
		input i_Branch,
		input i_Z,
		input i_Res,
		input [2:0] i_f3,

		output logic o_DoBranch
	);

	localparam BEQ  = 3'b000;
	localparam BNE  = 3'b001;
	localparam BLT  = 3'b100;
	localparam BGE  = 3'b101;
	localparam BLTU = 3'b110;
	localparam BGEU = 3'b111;

	always_comb begin
		if(i_Branch) begin
			case (i_f3)
				BEQ:  o_DoBranch =  i_Z;
				BNE:  o_DoBranch = ~i_Z;
				BLT:  o_DoBranch =  i_Res;
				BGE:  o_DoBranch = ~i_Res;
				BLTU: o_DoBranch =  i_Res;
				BGEU: o_DoBranch = ~i_Res;
				default : begin
							// TODO: Maybe create an assert here...
							$display("BRANCH_CONTROL: Invalid Branch! f3 = %b", i_f3);
							o_DoBranch = 1'bx;
						end
			endcase
		end
		else begin
			o_DoBranch = 0;
		end
	end

endmodule
