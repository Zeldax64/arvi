`timescale 1ns / 1ps

`include "arvi_defines.vh"

module INSTRUCTION_MEMORY(
    output [`INSTRUCTION_SIZE:0] o_Instruction,
    input  [`XLEN-1:0] i_Addr
    );

	parameter HEIGHT = 8; //Memory height
	parameter FILE = "test.r32i"; // Memory file to be loaded

	reg [7:0] mem [HEIGHT-1:0];//Memory: Word: 1byte

	//This block is used for tests
	initial begin
		$readmemh(FILE, mem);//Initialize Memory
	end

	assign o_Instruction = {mem[i_Addr+3], mem[i_Addr+2], mem[i_Addr+1], mem[i_Addr]};//One instruction has 32 bits


endmodule
