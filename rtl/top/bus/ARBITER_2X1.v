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
	output reg o_ack1,
	output reg [31:0] o_rd_data1,
	
	// Bus 2
	input  i_bus_en2,
	input  i_wr_rd2,
	input  [31:0] i_wr_data2,
	input  [31:0] i_addr2,
	input  [3:0] i_byte_en2,
	output reg  o_ack2,
	output reg  [31:0] o_rd_data2,

	// To Bus
	input  i_ack,
	input  [31:0] i_rd_data,
	output reg o_bus_en,
	output reg o_wr_en,
	output reg [31:0] o_wr_data,
	output reg [31:0] o_addr,
	output reg [3:0] o_byte_en
	);

	wire bus1_req, bus2_req;
	wire bus_req;

	assign bus1_req = i_bus_en1;
	assign bus2_req = i_bus_en2;
	assign bus_req = bus1_req || bus2_req;

	localparam IDLE = 2'b00;
	localparam BUS1 = 2'b01;
	localparam BUS2 = 2'b10;

	reg [1:0] state, next_state;

	always@(posedge i_clk) begin
		if(!i_rst) begin
			state 	 <= IDLE;
		end
		else begin
			state <= next_state;
		end
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
			if(!bus_req && i_ack)
				next_state = IDLE;
			if(bus2_req && i_ack)
				next_state = BUS2;
		end

		if(state == BUS2) begin
			if(!bus_req && i_ack)
				next_state = IDLE;
			if(bus1_req && i_ack);
				next_state = BUS1;
		end
	end

	always@(*) begin
		o_bus_en   = 0;
		o_wr_en    = 0;
		o_wr_data  = 0;
		o_addr     = 0;
		o_byte_en     = 0;

		o_ack1     = 0;
		o_rd_data1 = 0;
		o_ack2     = 0; 
		o_rd_data2 = 0;

		if(state == BUS1) begin
			o_bus_en   = i_bus_en1;
			o_wr_en    = i_wr_rd1;
			o_wr_data  = i_wr_data1;
			o_addr     = i_addr1;
			o_byte_en  = i_byte_en1;
			o_ack1     = i_ack;
			o_rd_data1 = i_rd_data;
		end
		if(state == BUS2) begin
			o_bus_en   = i_bus_en2;
			o_wr_en    = i_wr_rd2;
			o_wr_data  = i_wr_data2;
			o_addr     = i_addr2;
			o_byte_en  = i_byte_en2;
			o_ack2     = i_ack;
			o_rd_data2 = i_rd_data;
		end
	end

endmodule
