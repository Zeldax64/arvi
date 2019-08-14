/*
	Converts signals from the datapath to simple a bus format.
	Please notice that when an input signal is asserted and the bus is
	requested, the request signal should remains asserted until the end
	of transaction.
*/

`timescale 1ns / 1ps

`include "arvi_defines.svh"

module bus (
	input i_clk,  
	input i_rst,  
	
	// I-Cache 
	input i_IM_data_req,
	input [`XLEN-1:0]i_IM_addr,
	output logic o_IM_mem_ready,
	output logic [31:0] o_IM_Instr,
	
	// Data Memory
	`ARVI_DMEM_INPUTS,

	// Bus 
	bus_if.master bus_m
);

	logic i_ack;
	logic [31:0] i_rd_data;
	logic o_bus_en;
	logic o_wr_en;
	logic [31:0] o_wr_data;
	logic [31:0] o_addr;
	logic [3:0] o_byte_en;

	logic wr_en;
	logic [31:0] addr;

	logic DM_data_ready;
	logic [31:0] DM_ReadData;
	
	assign o_DM_data_ready = DM_data_ready;
	assign o_DM_ReadData = DM_ReadData; 

	localparam READ  = 1'b0;
	localparam WRITE = 1'b1;

	logic state, next_state;
	localparam IDLE = 1'b0;
	localparam BUSY = 1'b1;

	//wire bus_req = i_IM_data_req || i_DM_MemRead || i_DM_Wen;
	logic bus_req;

	always_ff@(posedge i_clk) begin
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
	
	always_comb begin
		next_state = state;
		o_IM_mem_ready = 0;
		o_IM_Instr = 0;
		DM_data_ready = 0;
		DM_ReadData = 0;

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
						DM_ReadData = i_rd_data;
						if(i_ack) DM_data_ready = 1;
					end
					if(i_DM_Wen) begin
						if(i_ack) begin
							DM_data_ready = 1;
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

	assign i_ack = bus_m.ack;
	assign i_rd_Data = bus_m.rd_Data;
	assign bus_m.bus_en = o_bus_en;
	assign bus_m.wr_en = o_wr_en;
	assign bus_m.wr_data = o_wr_data;
	assign bus_m.addr = o_addr;
	assign bus_m.byte_en = o_byte_en;

endmodule