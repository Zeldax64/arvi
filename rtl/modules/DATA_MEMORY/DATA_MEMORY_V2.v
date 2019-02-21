/*
	Draft - Data Memory module
	This module assumes a asynchronous memory which can return any requested value
	in any address and in any size (according to f3) immediately. This should be 
	used for simulation purpose.
*/

`timescale 1ns / 1ps

`include "defines.vh"

module DATA_MEMORY_V2(
    input  i_clk,
    input  i_rst,

    // Datapath interface
    input  [`XLEN-1:0] i_wr_data,
    input  [`XLEN-1:0] i_addr,
    input  [2:0] i_f3,
    input  i_wr_en,
    input  i_rd_en,
    output [`XLEN-1:0] o_Rd,
    output o_stall,
    output o_ex_ld,
    output o_ex_st,

    // CPU <-> Memory
    input  i_DM_data_ready,
	input  [`XLEN-1:0] i_DM_ReadData,
	output [`XLEN-1:0] o_DM_Wd,
	output [`XLEN-1:0] o_DM_Addr,
	output [2:0] o_DM_f3,
	output o_DM_Wen,
	output o_DM_MemRead
    );

	reg [`XLEN-1:0] read_data;
	reg ex_ld_addr, ex_st_addr;
	wire ex = ex_ld_addr || ex_st_addr;

	assign o_ex_ld = ex_ld_addr;
	assign o_ex_st = ex_st_addr;
	assign o_Rd = read_data;
	
	// To memory signals
	assign o_DM_Wd      = i_wr_data;
	assign o_DM_Addr    = i_addr;
	assign o_DM_Wen     = i_wr_en && !ex_st_addr;
	assign o_DM_MemRead = i_rd_en && !ex_ld_addr;
	assign o_DM_f3      = i_f3;

	always@(*) begin
		ex_ld_addr = 0;
		ex_st_addr = 0;
		read_data  = i_DM_ReadData;
		if(i_rd_en) begin
			case(i_f3) 
				3'b000 : read_data = {{`XLEN-8{i_DM_ReadData[7]}}, i_DM_ReadData[7:0]}; 
				3'b001 : read_data = {{`XLEN-16{i_DM_ReadData[15]}}, i_DM_ReadData[15:0]}; 
				3'b010 : read_data = i_DM_ReadData;
				3'b100 : read_data = {{`XLEN-8 {1'b0}}, i_DM_ReadData[7:0]};
				3'b101 : read_data = {{`XLEN-16{1'b0}}, i_DM_ReadData[15:0]};
				default: read_data = i_DM_ReadData;
			endcase 
			case(i_f3[1:0])
				2'b01 :	ex_ld_addr = (i_addr[0]) 	 ? 1'b1 : 1'b0;
				2'b10 : ex_ld_addr = (|i_addr[1:0]) ? 1'b1 : 1'b0;
				default : ex_ld_addr = 0;
			endcase
		end
		if(i_wr_en) begin
			case(i_f3[1:0])
				2'b01 : ex_st_addr = (i_addr[0]) ? 1'b1 : 1'b0;
				2'b10 : ex_st_addr = (|i_addr[1:0]) ? 1'b1 : 1'b0;
				default : ex_st_addr = 0;
			endcase
		end
	end
	
	/* FSM */
	reg [1:0] state;
	reg [1:0] next_state;
	localparam IDLE  = 2'b00;
	localparam READ  = 2'b01;
	localparam WRITE = 2'b10;

	always@(posedge i_clk) begin
		if(!i_rst || ex) 
			state <= IDLE;
		else
			state <= next_state;
	end

	always@(*) begin
		next_state = state; // Default
		if(state == IDLE) begin
			if(i_rd_en) next_state = READ;
			if(i_wr_en) next_state = WRITE; 
		end
		if(state == READ) begin
			if(i_DM_data_ready) next_state = IDLE; 
		end
		if(state == WRITE) begin
			if(i_DM_data_ready) next_state = IDLE;
		end
	end

	wire data_req = i_wr_en || i_rd_en;
	wire o_stall = (state != IDLE || data_req) && !i_DM_data_ready && !ex;
endmodule
