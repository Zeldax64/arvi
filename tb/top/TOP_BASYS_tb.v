/* 
	TOP_BASYS_tb.v

	Test bench for TOP_BASYS_tb.v
*/
`include "defines.vh"
`timescale 1ns / 1ps

module TOP_BASYS_tb;
	/*----- Local Parameters -----*/
	localparam SIMULATION_TIME = 250;
	/*----- Variables -----*/
	reg clk;

	/*----- DUT instatiantion -----*/
	TOP_BASYS dut (.i_clk(clk));
	
	/*----- Functions -----*/

	/*----- Tasks -----*/

	/*----- Tests -----*/
	always
		#5 clk = ~clk;

	initial begin

		clk = 0;

		#SIMULATION_TIME;
		$finish;
	end // initial

endmodule