/*
	Converts signals from the datapath to simple a bus format.
	Please notice that when an input signal is asserted and the bus is
	requested, the request signal should remains asserted until the end
	of transaction.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module BUS (
	input i_clk,  
	input i_rst,  
	
	// I-Cache 
	input i_IM_data_req,
	input [`XLEN-1:0]i_IM_addr,
	output reg o_IM_mem_ready,
	output reg [31:0] o_IM_Instr,
	
	// Data Memory
	`ARVI_DMEM_INPUTS,

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
	reg [31:0] addr;

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
			o_wr_data <= i_DM_Wd;
			o_addr    <= addr;
			o_byte_en <= i_DM_byte_en;
			o_bus_en  <= bus_req;
		end
	end
	
	always@(*) begin
		next_state = state;
		o_IM_mem_ready = 0;
		o_IM_Instr = 0;
		o_DM_data_ready = 0;
		o_DM_ReadData = 0;

		// Bus default values
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
						if(i_ack) o_DM_data_ready = 1;
					end
					if(i_DM_Wen) begin
						if(i_ack) begin
							o_DM_data_ready = 1;
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

endmodule