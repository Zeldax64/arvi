/* 
	***Unmainteined file***
	Please notice that this project uses only Verilator as simulator.

	RISC_V_tb.v

	Testbench for TOP_BASYS_tb.v
*/
`include "arvi_defines.vh"
`timescale 1ns / 1ps

module RISC_V_tb;
	/*----- Local Parameters -----*/
	localparam SIMULATION_TIME = 250;
	/*----- Variables -----*/
	reg clk;

	/*----- DUT instatiantion -----*/
	RISC_V dut (.i_clk(clk));
	
	/*----- Functions -----*/

	/*----- Tasks -----*/

	/*----- Tests -----*/
	always
		#5 clk = ~clk;

	initial begin

		clk = 0;

		//#SIMULATION_TIME;
		//wait(dut.data_mem.mem[0] === 0)
		$finish;
	end // initial

endmodule