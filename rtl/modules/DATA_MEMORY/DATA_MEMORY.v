`timescale 1ns / 1ps

`include "arvi_defines.vh"

module DATA_MEMORY(
    output [`XLEN-1:0] o_Rd,
    input  [`XLEN-1:0] i_Wd,
    input  [`XLEN-1:0] i_Addr,
    input  i_Wen,
    input  i_clk
    );

	parameter HEIGHT = 4;//Memory height
	parameter FILE = "test.r32i";

	reg [7:0] mem [HEIGHT-1:0]; //Memory: Word: 4byte

	//Just one signal must be enabled (Wen or Ren) in one clock period(That's my solution),
	//So, when the two signals are active, just the 'i_Wen' is considered.
	always @(posedge i_clk) begin
		if (i_Wen) begin
			mem[i_Addr+3] <= i_Wd[31:24];
			mem[i_Addr+2] <= i_Wd[23:16];
			mem[i_Addr+1] <= i_Wd[15:8];
			mem[i_Addr]   <= i_Wd[7:0];
		end
	end

	assign o_Rd = {mem[i_Addr+3], mem[i_Addr+2], mem[i_Addr+1], mem[i_Addr]};

endmodule
