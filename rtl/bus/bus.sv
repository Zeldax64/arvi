/*
	Converts signals from the datapath to simple a bus format.
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
	dmem_if.slave dmem,

	// Bus 
	bus_if.master bus_m
);

	// Data memory signals

	logic wr_en;
	logic [31:0] addr;

	localparam READ  = 1'b0;
	localparam WRITE = 1'b1;

	logic state, next_state;
	localparam IDLE = 1'b0;
	localparam BUSY = 1'b1;

	//wire bus_req = i_IM_data_req || dmem.DM_MemRead || dmem.DM_Wen;
	logic bus_req;

	always_ff@(posedge i_clk) begin
		if(!i_rst) state <= IDLE;
		else begin
			state           <= next_state;
			bus_m.wr_en     <= wr_en;
			bus_m.wr_data   <= dmem.DM_Wd;
			bus_m.addr      <= addr;
			bus_m.byte_en   <= dmem.DM_byte_en;
			bus_m.bus_en    <= bus_req;
`ifdef __ATOMIC
			bus_m.atomic    <= dmem.DM_atomic;
			bus_m.operation <= dmem.DM_operation;
`endif
		end
	end
	
	always_comb begin
		next_state = state;
		o_IM_mem_ready = 0;
		o_IM_Instr = 0;
		dmem.DM_data_ready = 0;
		dmem.DM_ReadData = 0;

		// Bus default values
		bus_req = 0;
		wr_en = 0;
		addr = 0;
		case(state)
			IDLE : begin
				bus_req = i_IM_data_req || dmem.DM_MemRead || dmem.DM_Wen;
				if(i_IM_data_req) begin
					addr = i_IM_addr;
					wr_en = 1'b0;
				end
				else begin
					if(dmem.DM_MemRead) begin
						addr = dmem.DM_Addr;
						wr_en = 1'b0;
					end
					if(dmem.DM_Wen) begin
						addr = {dmem.DM_Addr[31:2], 2'b00};
						wr_en = 1'b1;
					end
				end
				if(bus_req) next_state = BUSY;
			end
			BUSY : begin
				addr    = bus_m.addr;
				wr_en   = bus_m.wr_en;
				bus_req = bus_m.bus_en;
				if(i_IM_data_req) begin
					o_IM_Instr = bus_m.rd_data;
					if(bus_m.ack) o_IM_mem_ready = 1;
				end
				else begin
					if(dmem.DM_MemRead) begin
						dmem.DM_ReadData = bus_m.rd_data;
						if(bus_m.ack) dmem.DM_data_ready = 1;
					end
					if(dmem.DM_Wen) begin
						if(bus_m.ack) begin
							dmem.DM_data_ready = 1;
							wr_en = 0;
						end
					end
				end				

				if(bus_m.ack) begin 
					next_state = IDLE;
					bus_req = 0;
				end
			end
		endcase
	end

endmodule