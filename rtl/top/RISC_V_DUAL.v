/*
	Broken file! Work in progress...
*/

`timescale 1ns / 1ps

`include "defines.vh"
/* verilator lint_off DECLFILENAME */
module RISC_V_DUAL(
/* verilator lint_on DECLFILENAME */
	input i_clk,
	input i_rst,

	// Bus 
	input  i_ack,
	input  [31:0] i_rd_data,
	output o_bus_en,
	output o_wr_en,
	output [31:0] o_wr_data,
	output [31:0] o_addr,
	output [3:0]  o_byte_en
	);
	
	// PC initial value
	parameter PC_RESET = `PC_RESET;

	localparam HARTS = 2;

	/* Connections */
	// Instruction Memory
	wire [HARTS-1:0] IM_data_req;
	wire [HARTS-1:0] IM_mem_ready;
	wire [31:0] IM_instr [HARTS-1:0];
	wire [`XLEN-1:0] IM_addr [HARTS-1:0];
	
	// Data Memory
	wire [HARTS-1:0] DM_mem_ready;
	wire [HARTS-1:0] DM_ren, DM_wen;
	wire [2:0] DM_f3 [HARTS-1:0]; 
	wire [`XLEN-1:0] DM_rd [HARTS-1:0];
	wire [`XLEN-1:0] DM_wd [HARTS-1:0]; 
	wire [`XLEN-1:0] DM_addr[HARTS-1:0];

	// Bus signals
	wire [HARTS-1:0] ack, wr_en, bus_en;
	wire [3:0] byte_en [HARTS-1:0];
	wire [`XLEN-1:0] rd_data [HARTS-1:0];
	wire [`XLEN-1:0] wr_data[HARTS-1:0]; 
	wire [`XLEN-1:0] addr [HARTS-1:0];

`ifdef __ATOMIC 
	wire [HARTS-1:0] MEM_atomic;	
	//wire [$clog2(HARTS)-1:0] id;	
`endif

	// Bus <-> Memory Controller
	wire MC_ack, MC_wr_en, MC_bus_en;
	wire [3:0] MC_byte_en;
	wire [`XLEN-1:0] MC_rd_data;
	wire [`XLEN-1:0] MC_wr_data; 
	wire [`XLEN-1:0] MC_addr;	

`ifdef __ATOMIC 
	wire MC_atomic;	
	wire MC_id;	
`endif

	genvar i;
	generate
		for(i = 0; i < HARTS; i = i+1) begin
			HART #(
					.PC_RESET(PC_RESET),
					.HART(i)
				) hart(
				.i_clk(i_clk),
				.i_rst(i_rst),
				
				// Instruction Memory connections
				.i_IM_Instr(IM_instr[i]),
				.i_IC_MemReady(IM_mem_ready[i]),
				.o_IM_Addr(IM_addr[i]),
				.o_IC_DataReq (IM_data_req[i]),

				// Data Memory connections
				.i_DM_data_ready(DM_mem_ready[i]),
				.i_DM_ReadData(DM_rd[i]),
				.o_DM_WriteData(DM_wd[i]),
				.o_DM_Addr(DM_addr[i]),
				.o_DM_Wen(DM_wen[i]),
				.o_DM_MemRead(DM_ren[i]),
				.o_DM_f3(DM_f3[i]),

`ifdef __ATOMIC 
				.o_MEM_atomic   (MEM_atomic[i]),		
`endif
				// Interrupt connections
				//.i_tip(tip)
				.i_tip(1'b0)
			);

			BUS bus
				(
					.i_clk          (i_clk),
					.i_rst          (i_rst),

					// Instruction Memory
					.i_IM_data_req  (IM_data_req[i]),
					.i_IM_addr      (IM_addr[i]),
					.o_IM_mem_ready (IM_mem_ready[i]),
					.o_IM_Instr     (IM_instr[i]),
					
					// Data Memory
					.o_DM_mem_ready (DM_mem_ready[i]),
					.o_DM_ReadData  (DM_rd[i]),
					.i_DM_Wd        (DM_wd[i]),
					.i_DM_Addr      (DM_addr[i]),
					.i_DM_f3        (DM_f3[i]),
					.i_DM_Wen       (DM_wen[i]),
					.i_DM_MemRead   (DM_ren[i]),
					
					// Bus signals
					.i_ack          (ack[i]),
					.i_rd_data      (rd_data[i]),
					.o_bus_en       (bus_en[i]),
					.o_wr_en        (wr_en[i]),
					.o_wr_data      (wr_data[i]),
					.o_addr         (addr[i]),
					.o_byte_en      (byte_en[i])
				);
		end
	endgenerate

	ARBITER_2X1 arbiter_2x1
		(
			.i_clk      (i_clk),
			.i_rst      (i_rst),
			
			// Bus 1
			.i_bus_en1  (bus_en[0]),
			.i_wr_rd1   (wr_en[0]),
			.i_wr_data1 (wr_data[0]),
			.i_addr1    (addr[0]),
			.i_byte_en1 (byte_en[0]),
			.o_ack1     (ack[0]),
			.o_rd_data1 (rd_data[0]),
			.i_atomic1  (MEM_atomic[0]),

			// Bus 2
			.i_bus_en2  (bus_en[1]),
			.i_wr_rd2   (wr_en[1]),
			.i_wr_data2 (wr_data[1]),
			.i_addr2    (addr[1]),
			.i_byte_en2 (byte_en[1]),
			.o_ack2     (ack[1]),
			.o_rd_data2 (rd_data[1]),
			.i_atomic2  (MEM_atomic[1]),			
			
			// To Bus
			.i_ack      (MC_ack),
			.i_rd_data  (MC_rd_data),
			.o_id       (MC_id),
			.o_bus_en   (MC_bus_en),
			.o_wr_en    (MC_wr_en),
			.o_wr_data  (MC_wr_data),
			.o_addr     (MC_addr),
			.o_byte_en  (MC_byte_en),
			.o_atomic   (MC_atomic)
		);

`ifdef __ATOMIC // Atomic extension signal for atomic operations
	memory_controller #(
			.N_IDS(HARTS)
		) memory_controller (
			.i_clk     (i_clk),
			.i_rst     (i_rst),
			
			.i_bus_en  (MC_bus_en),
			.i_wr_en   (MC_wr_en),
			.i_wr_data (MC_wr_data),
			.i_addr    (MC_addr),
			.i_byte_en (MC_byte_en),
			.o_ack     (MC_ack),
			.o_rd_data (MC_rd_data),
			
			.i_atomic  (MC_atomic),
			.i_id      (MC_id),
			.i_operation (5'b0),
			
			.i_ack     (i_ack),
			.i_rd_data (i_rd_data),
			.o_bus_en  (o_bus_en),
			.o_wr_en   (o_wr_en),
			.o_wr_data (o_wr_data),
			.o_addr    (o_addr),
			.o_byte_en (o_byte_en)
		);


`endif

endmodule
