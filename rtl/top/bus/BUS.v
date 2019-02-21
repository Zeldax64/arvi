/*
	Converts signals from the datapath to simple bus format.
	Please notice that when an input signal is asserted and the bus is
	requested the request signal should remains asserted until the end
	of transaction. This is done only to simplify implementation.
*/

`timescale 1ns / 1ps

`include "defines.vh"

module BUS (
	input i_clk,  // Clock
	input i_rst,  // Asynchronous reset active low
	
	// I-Cache 
	input i_IM_data_req,
	input [`XLEN-1:0]i_IM_addr,
	output o_IM_mem_ready,
	output [31:0] o_IM_Instr,
	
	// Data Memory
	output o_DM_mem_ready,
	output [`XLEN-1:0] o_DM_ReadData,
	input  [`XLEN-1:0] i_DM_Wd,
	input  [`XLEN-1:0] i_DM_Addr,
	input  [2:0] i_DM_f3,
	input  i_DM_Wen,
	input  i_DM_MemRead,

	// Bus 
	input  i_ack,
	input  [31:0] i_rd_data,
	output o_bus_en,
	output o_wr_rd,
	output [31:0] o_wr_data,
	output [31:0] o_addr,
	output [2:0] o_size
);
	localparam READ  = 1'b0;
	localparam WRITE = 1'b1;

	reg state, next_state;
	localparam IDLE = 1'b0;
	localparam BUSY = 1'b1;

	wire bus_req = i_IM_data_req || i_DM_MemRead || i_DM_Wen;
	
	assign o_bus_en = state != IDLE;

	always@(posedge i_clk) begin
		if(!i_rst) state <= IDLE;
		else state <= next_state;
	end
	
	always@(*) begin
		next_state = state;
		o_IM_mem_ready = 0;
		o_DM_mem_ready = 0;
		case(state)
			IDLE : begin
				if(i_IM_data_req) begin
					o_addr = i_IM_addr;
					o_size = 2;
					o_wr_rd = READ;
				end
				else begin
					if(i_DM_MemRead) begin
						o_addr = i_DM_Addr;
						o_wr_rd = READ;
						o_size = i_DM_f3;
					end
					if(i_DM_Wen) begin
						o_addr = i_DM_Addr;
						o_wr_rd = WRITE;
						o_size = i_DM_f3;
						o_wr_data = i_DM_Wd;
					end
				end
				if(bus_req) next_state = BUSY;
			end
			BUSY : begin
				if(i_IM_data_req) begin
					o_IM_Instr = i_rd_data;
					o_IM_mem_ready = 1;
				end
				else begin
					if(i_DM_MemRead) begin
						o_DM_ReadData = i_rd_data;
						if(i_ack) o_DM_mem_ready = 1;
					end
					if(i_DM_Wen) begin
						if(i_ack) o_DM_mem_ready = 1;
					end
				end				

				if(i_ack) next_state = IDLE;
			end
		endcase
	end

endmodule