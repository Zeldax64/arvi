`timescale 1ns / 1ps

module ARBITER_2X1(
	input i_clk,
	input i_rst,

	// Bus 1
	input  i_bus_en1,
	input  i_wr_rd1,
	input  [31:0] i_wr_data1,
	input  [31:0] i_addr1,
	input  [2:0] i_size1,
	output o_ack1,
	output [31:0] o_rd_data1,
	
	// Bus 2
	input  i_bus_en2,
	input  i_wr_rd2,
	input  [31:0] i_wr_data2,
	input  [31:0] i_addr2,
	input  [2:0] i_size2,
	output  o_ack2,
	output  [31:0] o_rd_data2,

	// To Bus
	input  i_ack,
	input  [31:0] i_rd_data,
	output o_bus_en,
	output o_wr_rd,
	output [31:0] o_wr_data,
	output [31:0] o_addr,
	output [2:0] o_size
	);

	wire bus1_req, bus2_req;
	wire bus_req;

	assign bus1_req = i_bus_en1;
	assign bus2_req = i_bus_en2;
	assign bus_req = bus1_req || bus2_req;

	localparam BUS1 = 1'b0;
	localparam BUS2 = 1'b1;

	localparam IDLE = 1'b0;
	localparam BUSY = 1'b1;
	reg state, next_state;
	reg pri; 	 // priority
	reg selection, selected; 

	always@(posedge i_clk) begin
		if(!i_rst) begin
			state 	 <= IDLE;
			selected <= 0;
		end
		else begin
			state <= next_state;
			if(i_ack)
				pri <= ~selected;
			if(state == IDLE && bus_req)
				selected <= selection;
		end
	end

	always@(*) begin
		next_state = state;
		if(state == IDLE) begin
			if(bus1_req && bus2_req) begin
				selection = pri;
			end
			else begin
				if(bus1_req) begin
					selection = BUS1;
				end
				if(bus2_req) begin
					selection = BUS2;
				end
			end

			if(bus_req) next_state = BUSY;
		end
		if(state == BUSY) begin
			if(i_ack) next_state = IDLE;
		end
	end

	// To input busses
	assign o_ack1     = selection ? 0 : i_ack;
	assign o_ack2     = selection ? i_ack : 0;
	assign o_rd_data1 = selection ? 0 : i_rd_data;
	assign o_rd_data2 = selection ? i_rd_data : 0;

	// To output bus
	assign o_bus_en  = selection ? i_bus_en2 : i_bus_en1; 
	assign o_wr_rd   = selection ? i_wr_rd2 : i_wr_rd1;
	assign o_wr_data = selection ? i_wr_data2 : i_wr_data1;
	assign o_addr    = selection ? i_addr2 : i_addr1;
	assign o_size    = selection ? i_size2 : i_size1;
endmodule