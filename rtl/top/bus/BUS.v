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
	output reg o_IM_mem_ready,
	output reg [31:0] o_IM_Instr,
	
	// Data Memory
	output reg o_DM_mem_ready,
	output reg [`XLEN-1:0] o_DM_ReadData,
	input  [`XLEN-1:0] i_DM_Wd,
	input  [`XLEN-1:0] i_DM_Addr,
	input  [2:0] i_DM_f3,
	input  i_DM_Wen,
	input  i_DM_MemRead,

	// Bus 
	input  i_ack,
	input  [31:0] i_rd_data,
	output reg o_bus_en,
	output reg o_wr_en,
	output reg [31:0] o_wr_data,
	output reg [31:0] o_addr,
	output reg [3:0] o_byte_en
);
	
	reg wr_en;
	reg [31:0] wr_data, addr;
	reg [3:0] byte_en;

	localparam READ  = 1'b0;
	localparam WRITE = 1'b1;

	reg state, next_state;
	localparam IDLE = 1'b0;
	localparam BUSY = 1'b1;

	//wire bus_req = i_IM_data_req || i_DM_MemRead || i_DM_Wen;
	reg bus_req;

	always@(posedge i_clk) begin
		if(!i_rst) state <= IDLE;
		else begin
			state     <= next_state;
			o_wr_en   <= wr_en;
			o_wr_data <= wr_data;
			o_addr    <= addr;
			o_byte_en <= byte_en;
			o_bus_en  <= bus_req;
		end
	end
	
	always@(*) begin
		next_state = state;
		o_IM_mem_ready = 0;
		o_IM_Instr = 0;
		o_DM_mem_ready = 0;
		o_DM_ReadData = 0;

		// Bus default
		bus_req = 0;
		wr_en = 0;
		addr = 0;
		case(state)
			IDLE : begin
				bus_req = i_IM_data_req || i_DM_MemRead || i_DM_Wen;
				if(i_IM_data_req) begin
					addr = i_IM_addr;
					wr_en = 1'b0;
				end
				else begin
					if(i_DM_MemRead) begin
						addr = i_DM_Addr;
						wr_en = 1'b0;
					end
					if(i_DM_Wen) begin
						addr = {i_DM_Addr[31:2], 2'b00};
						wr_en = 1'b1;
					end
				end
				if(bus_req) next_state = BUSY;
			end
			BUSY : begin
				addr    = o_addr;
				wr_en   = o_wr_en;
				bus_req = o_bus_en;
				if(i_IM_data_req) begin
					o_IM_Instr = i_rd_data;
					if(i_ack) o_IM_mem_ready = 1;
				end
				else begin
					if(i_DM_MemRead) begin
						o_DM_ReadData = i_rd_data;
						if(i_ack) o_DM_mem_ready = 1;
					end
					if(i_DM_Wen) begin
						if(i_ack) begin
							o_DM_mem_ready = 1;
							wr_en = 0;
						end
					end
				end				

				if(i_ack) begin 
					next_state = IDLE;
					bus_req = 0;
				end
			end
		endcase
	end

	// Defining byte enable output
	always@(*) begin
		case(i_DM_f3)
			3'b000 : begin
				byte_en[0] = i_DM_Addr[1:0] == 2'b00;  
				byte_en[1] = i_DM_Addr[1:0] == 2'b01;  
				byte_en[2] = i_DM_Addr[1:0] == 2'b10;  
				byte_en[3] = i_DM_Addr[1:0] == 2'b11;  
			end
			3'b001 : begin
				byte_en[1:0] = (i_DM_Addr[1] == 1'b0) ? 2'b11 : 2'b00;
				byte_en[3:2] = (i_DM_Addr[1] == 1'b1) ? 2'b11 : 2'b00;
			end
			3'b010 : begin
				byte_en = 4'b1111;
			end
			default: byte_en = 4'b0000;
		endcase

		case(byte_en)
			4'b0010 : wr_data = i_DM_Wd << 8;
			4'b0100 : wr_data = i_DM_Wd << 16;
			4'b1100 : wr_data = i_DM_Wd << 16;
			4'b1000 : wr_data = i_DM_Wd << 24;
			default : wr_data = i_DM_Wd;
		endcase
	end
endmodule