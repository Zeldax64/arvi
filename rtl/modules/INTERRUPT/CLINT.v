/*
	Draft CLINT implementation supporting only one hart and
	time interrupt
	Memory size: 0x0000 - 0xbffc
	TODO: implement interrupt bits
*/

`include "defines.vh"

module CLINT #(
	parameter BASE_ADDR = 32'h2000_0000
	)
	(
	input i_clk,
	input i_rst,
	input i_wen,
	input i_ren,
	input  [`XLEN-1:0] i_addr,
	input  [`XLEN-1:0] i_wrdata,
	output [`XLEN-1:0] o_rddata,

	// Interrupts
	output o_tip
	);

	localparam MTIMECMP0_LO = BASE_ADDR+32'h4000;
	localparam MTIMECMP0_HI = BASE_ADDR+32'h4004;
	localparam MTIME_LO = BASE_ADDR+32'hBFF8;
	localparam MTIME_HI = BASE_ADDR+32'hBFFB;

	reg [63:0] mtime, mtimecmp0;

	assign o_tip = mtime >= mtimecmp0;
	always@(posedge i_clk) begin
		if(!i_rst)
			mtime <= 0;
		else begin
			if(i_wen) begin
				if(i_addr == MTIMECMP0_LO)
					mtimecmp0[31:0] <= i_wrdata;
				if(i_addr == MTIMECMP0_HI)
					mtimecmp0[63:32] <= i_wrdata;
			end
		end
		mtime <= mtime+1'b1;
	end

	always@(*) begin
		if(i_ren) begin
			case(i_addr)
				MTIMECMP0_LO : o_rddata = mtimecmp0[31:0];
				MTIMECMP0_HI : o_rddata = mtimecmp0[63:32];
				MTIME_LO : o_rddata = mtime[31:0];
				MTIME_HI : o_rddata = mtime[63:32];
				default : o_rddata = 0;
			endcase
		end
		else
			o_rddata = 0;
	end

endmodule