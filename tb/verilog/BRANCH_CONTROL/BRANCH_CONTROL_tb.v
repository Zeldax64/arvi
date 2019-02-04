

`timescale 1ns / 1ps

`include "defines.vh"

module BRANCH_CONTROL_tb;
	localparam BEQ  = 3'b000;
	localparam BNE  = 3'b001;
	localparam BLT  = 3'b100;
	localparam BGE  = 3'b101;
	localparam BLTU = 3'b110;
	localparam BGEU = 3'b111;
	
	// Inputs
	reg i_Branch;
	reg i_Z;
	reg i_Res;
	reg [2:0] i_f3;

	// Outputs
	wire o_DoBranch;

	// Instantiate the Unit Under Test (UUT)
	BRANCH_CONTROL inst_BRANCH_CONTROL
		(
			.i_Branch   (i_Branch),
			.i_Z        (i_Z),
			.i_Res      (i_Res),
			.i_f3       (i_f3),
			.o_DoBranch (o_DoBranch)
		);

	initial begin
		i_Branch = 0;
		i_Z = 0;
		i_Res = 0;
		i_f3 = 0;

		#50;

		i_Branch = 1; // Turn on branches
		
		i_f3 = BEQ; i_Z = 0; #10; // Branch not taken
		i_f3 = BEQ; i_Z = 1; #10; // Branch taken

		i_f3 = BNE; i_Z = 1; #10; // Branch not taken
		i_f3 = BNE; i_Z = 0; #10; // Branch taken

		i_f3 = BLT; i_Res = 0; #10; // Branch not taken
		i_f3 = BLT; i_Res = 1; #10; // Branch taken

		i_f3 = BLTU; i_Res = 0; #10; // Branch not taken
		i_f3 = BLTU; i_Res = 1; #10; // Branch taken

		i_f3 = BGE; i_Res = 1; #10; // Branch not taken
		i_f3 = BGE; i_Res = 0; #10; // Branch taken

		i_f3 = BGEU; i_Res = 1; #10; // Branch not taken
		i_f3 = BGEU; i_Res = 0; #10; // Branch taken

		i_f3 = 3'b010; #10; // Invalid input
		i_f3 = 3'b011; #10; // Invalid input


		$finish;

	end

endmodule