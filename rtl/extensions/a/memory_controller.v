`timescale 1ns / 1ps

`include "defines.vh"
`include "rtl/extensions/a/atomic.vh"

module memory_controller
	#(
		parameter N_IDS = 1
	)
	(
	input i_clk,
	input i_rst,

	// CPU <-> MEM_CONTROLLER
	input  i_bus_en,
	input  i_wr_en,
	input  [31:0] i_wr_data,
	input  [31:0] i_addr,
	input  [3:0] i_byte_en,
	output reg  o_ack,
	output reg  [31:0] o_rd_data,

	// Bus atomic signals
	input  i_atomic,
	input [$clog2(N_IDS)-1:0] i_id,
	/* verilator lint_off UNUSED */
	input [6:0] i_operation,
	/* verilator lint_on UNUSED */
	// MEM_CONTROLLER <-> MEM
	input  i_ack,
	input  [31:0] i_rd_data,
	output reg o_bus_en,
	output reg o_wr_en,
	output reg [31:0] o_wr_data,
	output reg [31:0] o_addr,
	output reg [3:0] o_byte_en	
	);

/*
 TODO: 
	- Create ALU
*/
	wire is_lr, is_sc, is_AMO;
	assign is_lr = (i_operation[6:2] == `LR) && i_atomic;
	assign is_sc = (i_operation[6:2] == `SC) && i_atomic;
	assign is_AMO = i_atomic && !(is_lr | is_sc); 

	reg ack_d;
	reg [31:0] rd_data_d;
	reg bus_en_d;
	reg wr_en_d;
	reg [31:0] wr_data_d;
	reg [31:0] addr_d;
	reg [3:0] byte_en_d;

	reg [2:0] state, next_state;

	reg [`XLEN-1:0] s1, s2, alu_res;
	
	always@(posedge i_clk) begin
		if(!i_rst) begin
			o_ack     <= 0;
			o_rd_data <= 0;
			o_bus_en  <= 0;
			o_wr_en   <= 0;
			o_wr_data <= 0;
			o_addr    <= 0;
			o_byte_en <= 0;

			state     <= 0;

			// ALU
			s1        <= 0;
			s2        <= 0;
			alu_res   <= 0;			
		end
		else begin
			o_ack     <= ack_d;
			o_rd_data <= rd_data_d;
			o_bus_en  <= bus_en_d;
			o_wr_en   <= wr_en_d;
			o_wr_data <= wr_data_d;
			o_addr    <= addr_d;
			state     <= next_state;
			
			o_byte_en <= byte_en_d;

			// ALU
			s1        <= i_wr_data;
			s2        <= i_rd_data;
			alu_res   <= s1 + s2;
		end
	end 
	// FSM

	// States
	localparam IDLE       = 3'b000;
	localparam FETCH      = 3'b001;
	localparam EX         = 3'b010;
	localparam STORE      = 3'b011;
	localparam MEM_ACCESS = 3'b100;

	always@(*) begin
		ack_d     = 0;
		rd_data_d = o_rd_data;
		bus_en_d  = 0;
		wr_en_d   = o_wr_en;
		wr_data_d = o_wr_data;
		addr_d    = o_addr;
		byte_en_d = i_byte_en;
		case(state)
			IDLE : begin
				if(next_state == IDLE) begin
					ack_d     = 0;
					rd_data_d = 0;
					bus_en_d  = 0;
					wr_en_d   = 0;
					wr_data_d = 0;
					addr_d    = 0;    
					byte_en_d = 0;
				end
				if(next_state == FETCH) begin
					bus_en_d = 0;
					addr_d   = i_addr;
				end
				if(next_state == MEM_ACCESS) begin
					ack_d     = 0;
					rd_data_d = i_rd_data;
					bus_en_d  = 1;
					wr_en_d   = i_wr_en;
					wr_data_d = i_wr_data;
					addr_d    = i_addr;    
					byte_en_d = i_byte_en;
					if(is_sc) begin
						wr_en_d = i_wr_en && sc_grant;
					end
				end
			end
			FETCH : begin
				if(next_state == EX) begin
					bus_en_d  = 0;
				end
				else begin
					bus_en_d = 1;
					addr_d   = i_addr;
				end
			end
			EX : begin
				if(next_state == STORE) begin
					wr_data_d = alu_res;
					//wr_en_d   = 1;
					//bus_en_d  = 1;
				end
			end
			STORE : begin
				if(next_state == IDLE) begin
					rd_data_d = s2;
					ack_d = 1;
					wr_en_d = 0;
					bus_en_d = 0;
				end
				else begin
					bus_en_d = 1;
					wr_en_d  = 1;
				end
			end
			MEM_ACCESS : begin
				if(next_state == IDLE) begin
					ack_d     = 1;
					rd_data_d = i_rd_data;
					bus_en_d  = 0;
					wr_en_d   = 0;
					wr_data_d = 0;
					addr_d    = 0;    
					byte_en_d = 0;
					if(is_sc) begin
						rd_data_d = {{31{1'b0}}, ~sc_grant};
					end
				end				
			end
			default : begin end
		endcase
	end

	always@(*) begin
		next_state = state;
		case(state)
			IDLE : begin
				if(i_bus_en)
					if(is_AMO)  next_state = FETCH;
					else next_state = MEM_ACCESS;
			end
			FETCH : begin
				if(i_ack) next_state = EX;
			end
			EX : begin
				next_state = STORE;
			end
			STORE : begin
				if(i_ack) next_state = IDLE; 
			end
			MEM_ACCESS : begin
				if(i_ack) next_state = IDLE;				
			end
			default : begin end
		endcase
	end

	// End FSM
	/* verilator lint_off UNUSED */
	wire sc_grant;
	/* verilator lint_on UNUSED */
	lr_sc_tbl #(
			.ADDR_WIDTH(`XLEN-2),
			.N_IDS(N_IDS)
		) lr_sc_tbl (
			.i_clk       (i_clk),
			.i_rst       (i_rst),
			.i_wr_en     (o_wr_en),
			.i_set_res   (is_lr),
			.i_check_res (is_sc),
			.i_id        (i_id),
			.i_addr      (i_addr[`XLEN-1:2]),
			.o_gnt       (sc_grant)
		);


endmodule