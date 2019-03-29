`timescale 1ns / 1ps

module ARBITER_2X1(
	input i_clk,
	input i_rst,

	// Bus 1
	input  i_bus_en1,
	input  i_wr_rd1,
	input  [31:0] i_wr_data1,
	input  [31:0] i_addr1,
	input  [3:0] i_byte_en1,
	input  i_atomic1,
	input  [6:0] i_operation1,
	output reg o_ack1,
	output reg [31:0] o_rd_data1,
	
	// Bus 2
	input  i_bus_en2,
	input  i_wr_rd2,
	input  [31:0] i_wr_data2,
	input  [31:0] i_addr2,
	input  [3:0] i_byte_en2,
	input  i_atomic2,
	input  [6:0] i_operation2,
	output reg  o_ack2,
	output reg  [31:0] o_rd_data2,


	// To Bus
	input  i_ack,
	input  [31:0] i_rd_data,
	output reg o_atomic,
	output reg o_id,
	output reg o_bus_en,
	output reg o_wr_en,
	output reg [31:0] o_wr_data,
	output reg [31:0] o_addr,
	output reg [6:0] o_operation,
	output reg [3:0] o_byte_en
	);
	
	reg id;
	reg bus_en;
	reg wr_en;
	reg [31:0] wr_data;
	reg [31:0] addr;
	reg [3:0] byte_en;
	reg ack1, ack2;
	reg [31:0] rd_data1, rd_data2;
	reg atomic;
	reg [6:0] operation;
	
	wire bus1_req, bus2_req;

	assign bus1_req = i_bus_en1;
	assign bus2_req = i_bus_en2;

	localparam IDLE = 2'b00;
	localparam BUS1 = 2'b01;
	localparam BUS2 = 2'b10;

	reg [1:0] state, next_state;

	always@(posedge i_clk) begin
		if(!i_rst) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;   
		end
	end

	// To output
	always@(*) begin
		o_id        = id;
		o_bus_en    = bus_en && !i_ack; // TODO: Fix this!!!
		o_wr_en     = wr_en;
		o_wr_data   = wr_data;
		o_addr      = addr;
		o_byte_en   = byte_en;
		o_ack1      = ack1;
		o_rd_data1  = rd_data1;
		o_ack2      = ack2;
		o_rd_data2  = rd_data2;
		o_atomic    = atomic;     
		o_operation = operation;
	end

	always@(*) begin
		next_state = state;
		if(state == IDLE) begin
			if(bus1_req)
				next_state = BUS1;
			if(bus2_req)
				next_state = BUS2;
		end

		if(state == BUS1) begin
			if(i_ack)
				next_state = IDLE;
			//if(bus2_req && i_ack)
			//	next_state = BUS2;
		end

		if(state == BUS2) begin
			if(i_ack)
				next_state = IDLE;
			//if(bus1_req && i_ack);
			//	next_state = BUS1;
		end
	end

	always@(*) begin
		id        = 0;
		bus_en    = 0;
		wr_en     = 0;
		wr_data   = 0;
		addr      = 0;
		byte_en   = 0;
		operation = 0;

		ack1      = 0;
		rd_data1  = 0;
		ack2      = 0; 
		rd_data2  = 0;
		if(state == BUS1) begin
			id        = 0;
			bus_en    = i_bus_en1;
			wr_en     = i_wr_rd1;
			wr_data   = i_wr_data1;
			addr      = i_addr1;
			byte_en   = i_byte_en1;
			ack1      = i_ack;
			rd_data1  = i_rd_data;
			atomic    = i_atomic1;
			operation = i_operation1;
		end
		if(state == BUS2) begin
			id        = 1;
			bus_en    = i_bus_en2;
			wr_en     = i_wr_rd2;
			wr_data   = i_wr_data2;
			addr      = i_addr2;
			byte_en   = i_byte_en2;
			ack2      = i_ack;
			rd_data2  = i_rd_data;
			atomic    = i_atomic2;
			operation = i_operation2;
		end
	end

endmodule
