/*
	Data Memory module.
*/

`timescale 1ns / 1ps

`include "arvi_defines.svh"

module d_mem(
    input  i_clk,
    input  i_rst,

    // Datapath interface
    input  [`XLEN-1:0] i_wr_data,
    input  [`XLEN-1:0] i_addr,
    input  [2:0] i_f3,
    input  i_wr_en,
    input  i_rd_en,
`ifdef __RVA
	input i_atomic,
	input [6:0] i_operation,
`endif
    output logic [`XLEN-1:0] o_Rd,
    output logic o_stall,
    output logic o_ex_ld,
    output logic o_ex_st,

    // CPU <-> Memory
    dmem_if.master to_mem
    );

    logic i_DM_data_ready;
	logic [`XLEN-1:0] i_DM_ReadData;
	logic [`XLEN-1:0] o_DM_Wd;
	logic [`XLEN-1:0] o_DM_Addr;
	logic [3:0] o_DM_byte_en;
	logic o_DM_Wen;
	logic o_DM_MemRead;

	// Assign dmem interface signals.
	assign i_DM_data_ready = to_mem.DM_data_ready;
	assign i_DM_ReadData = to_mem.DM_ReadData;
	assign to_mem.DM_Wd = o_DM_Wd;
	assign to_mem.DM_Addr = o_DM_Addr;
	assign to_mem.DM_byte_en = o_DM_byte_en;
	assign to_mem.DM_Wen = o_DM_Wen;
	assign to_mem.DM_MemRead = o_DM_MemRead; 
`ifdef __RVA
	assign to_mem.DM_atomic    = i_atomic;
	assign to_mem.DM_operation = i_operation;
`endif

	reg [`XLEN-1:0] read_data, shifted_rd, wr_data;
	reg ex_ld_addr, ex_st_addr;
	wire ex; 
	reg [3:0] byte_en;

	assign o_Rd = read_data;

	// Exception signals.
	assign o_ex_ld = ex_ld_addr;
	assign o_ex_st = ex_st_addr;
	assign ex = ex_ld_addr || ex_st_addr;
	
	// To memory signals.
	assign o_DM_Wd      = wr_data;
	assign o_DM_Addr    = {i_addr[`XLEN-1:2], 2'b00};
	assign o_DM_Wen     = i_wr_en && !ex_st_addr;
	assign o_DM_MemRead = i_rd_en && !ex_ld_addr;
	assign o_DM_byte_en = byte_en;
	
	always_comb begin
		ex_ld_addr = 0;
		ex_st_addr = 0;

		case(i_f3[1:0])
			2'b00 : begin
				byte_en[0] = i_addr[1:0] == 2'b00;  
				byte_en[1] = i_addr[1:0] == 2'b01;  
				byte_en[2] = i_addr[1:0] == 2'b10;  
				byte_en[3] = i_addr[1:0] == 2'b11;  
			end
			2'b01 : begin
				byte_en[1:0] = (i_addr[1] == 1'b0) ? 2'b11 : 2'b00;
				byte_en[3:2] = (i_addr[1] == 1'b1) ? 2'b11 : 2'b00;
			end
			2'b10 : begin
				byte_en = 4'b1111;
			end
			default: byte_en = 4'b0000;
		endcase

		// Read data handler.
		case(byte_en)
			4'b0010 : shifted_rd = i_DM_ReadData >> 8;
			4'b0100 : shifted_rd = i_DM_ReadData >> 16;
			4'b1100 : shifted_rd = i_DM_ReadData >> 16;
			4'b1000 : shifted_rd = i_DM_ReadData >> 24;
			default : shifted_rd = i_DM_ReadData;
		endcase

		case(i_f3) 
			3'b000 : read_data = {{`XLEN-8{shifted_rd[7]}}, shifted_rd[7:0]}; 		// LB
			3'b001 : read_data = {{`XLEN-16{shifted_rd[15]}}, shifted_rd[15:0]}; 	// LH
			3'b100 : read_data = {{`XLEN-8 {1'b0}}, shifted_rd[7:0]}; 				// LBU
			3'b101 : read_data = {{`XLEN-16{1'b0}}, shifted_rd[15:0]}; 				// LHU
			default : read_data = shifted_rd;
		endcase 
		// Checking if a exception is raised.
		if(i_rd_en) begin
			case(i_f3[1:0])
				2'b01 :	ex_ld_addr = (i_addr[0]) 	? 1'b1 : 1'b0;
				2'b10 : ex_ld_addr = (|i_addr[1:0]) ? 1'b1 : 1'b0;
				default : ex_ld_addr = 0;
			endcase
		end

		// Write data handler
		// Checking which bytes must be written (SB, SH, SW).
		// Shifting the data to be written since the two LSB bits of
		// the accessed address are always 2'b00. 
		case(byte_en)
			4'b0010 : wr_data = i_wr_data << 8;
			4'b0100 : wr_data = i_wr_data << 16;
			4'b1100 : wr_data = i_wr_data << 16;
			4'b1000 : wr_data = i_wr_data << 24;
			default : wr_data = i_wr_data;
		endcase

		// Checking if a exception is raised.
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

	always_ff@(posedge i_clk) begin
		if(!i_rst || ex) 
			state <= IDLE;
		else
			state <= next_state;
	end

	always_comb begin
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

	assign o_stall = (state != IDLE || data_req) && !i_DM_data_ready && !ex;

endmodule
