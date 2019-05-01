`timescale 1ns / 1ps

`include "arvi_defines.vh"

module I_CACHE
	#(
		parameter BLOCK_SIZE = 1, // Block size in words (4-Bytes)
		parameter ENTRIES = 128   // Number of entries
	)
	(
    input i_clk,
    input i_rst,

    // Cache <-> Memory interface
    input [BLOCK_SIZE*32-1:0]i_DataBlock,
    input i_MemReady,
    output o_DataReq,
    output [`XLEN-1:0] o_MemAddr,

    // Cache <-> CPU interface
    input [`XLEN-1:0] i_Addr,
    output [`XLEN-1:0] o_Data,
    output o_Stall
    );

	/*----- States -----*/
	localparam COMPARE_TAG = 1'b0;
	localparam ALLOCATE = 1'b1;
	reg next_state;
	reg state;

	// Local Parameters
	localparam N = $clog2(ENTRIES);    	 // Number of index bits
	localparam M = $clog2(BLOCK_SIZE); 	 // Block size
	localparam TAG_SIZE = `XLEN-(N+M+2); // Number of tag field bits
	
	localparam INDEX_OFFSET = M+2;
	localparam TAG_OFFSET = INDEX_OFFSET + N;

	// Wire renaming
	wire [N-1:0] index = i_Addr[INDEX_OFFSET +: N];				// Index field of address
	wire [TAG_SIZE-1:0] tag = i_Addr[TAG_OFFSET +: TAG_SIZE];	// Tag field of address

	// Cache table
	reg [ENTRIES-1:0] valid; // Valid field
	reg [TAG_SIZE-1:0] tag_field [ENTRIES-1:0]; // Tag field
	reg [BLOCK_SIZE*32-1:0] data [ENTRIES-1:0]; // Cached data
	
	// General wires
	wire hit = (state == COMPARE_TAG) ? valid[index] && tag_field[index] == tag : 1'b0;
	// Is it necessary to save incomming block from memory?
	wire save_block = (state == ALLOCATE && next_state == COMPARE_TAG);
	
	// Outputs
	assign o_DataReq = (state == ALLOCATE); // Maybe it is possible to request Data when hit == 0 is known
	assign o_Stall = (state == ALLOCATE) || !hit;
	assign o_MemAddr = {i_Addr[`XLEN-1:2], 2'b00}; 

	generate
		if(BLOCK_SIZE == 1)
			assign o_Data = (valid[index]) ? data[index] : 32'b0;
		else begin
			// Stopped here! BLOCK_SIZE > 1 is not allowed
			wire [M-1:0]block = i_Addr[2 +: M];
			//assign o_Data = data[index][];
		end
	endgenerate

	// FSM - State Transition
	always@(posedge i_clk) begin
		if(!i_rst) begin
			valid <= 0;
			state <= COMPARE_TAG;
		end
		else begin
			state <= next_state;

			// If transition from Allocate to Compare Tag
			if(save_block) begin
				data[index]  <= i_DataBlock;
				valid[index] <= 1'b1;
				tag_field[index] <= tag;
			end
		end
	end

	// FSM - Next state logic
	always@(*) begin
		if(state == COMPARE_TAG) begin
			if(hit) begin
				next_state = COMPARE_TAG;
			end
			else begin
				next_state = ALLOCATE;
			end
		end
		
		//if(state == ALLOCATE) begin
		else begin // State == ALLOCATE
			if(i_MemReady) begin
				next_state = COMPARE_TAG;
			end
			else begin
				next_state = ALLOCATE;
			end

		end
	end

	/* verilator lint_off UNUSED */
	// For verification purpose ONLY
	wire [31:0]full_addr = {tag, index, i_Addr[1:0]};
	/* verilator lint_on UNUSED */
endmodule
