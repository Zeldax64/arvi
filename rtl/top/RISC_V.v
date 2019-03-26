`timescale 1ns / 1ps

`include "defines.vh"

/* verilator lint_off DECLFILENAME */
module RISC_V(
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

	/* Connections */
	// Instruction Memory
	wire IM_data_req;
	wire IM_mem_ready;
	wire [31:0] IM_instr;
	wire [`XLEN-1:0] IM_addr;
	
	// Data Memory
	wire DM_mem_ready;
	wire DM_ren, DM_wen;
	wire [2:0] DM_f3; 
	wire [`XLEN-1:0] DM_rd, DM_wd, DM_addr;

	HART #(
			.PC_RESET(PC_RESET),
			.HART(0)
		) hart0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		
		// Instruction Memory connections
		.i_IM_Instr(IM_instr),
		.i_IC_MemReady(IM_mem_ready),
		.o_IM_Addr(IM_addr),
		.o_IC_DataReq (IM_data_req),

		// Data Memory connections
		.i_DM_data_ready(DM_mem_ready),
		.i_DM_ReadData(DM_rd),
		.o_DM_WriteData(DM_wd),
		.o_DM_Addr(DM_addr),
		.o_DM_Wen(DM_wen),
		.o_DM_MemRead(DM_ren),
		.o_DM_f3(DM_f3),

		// Interrupt connections
		.i_tip(1'b0)
	);

	BUS bus_if
		(
			.i_clk          (i_clk),
			.i_rst          (i_rst),

			// Instruction Memory
			.i_IM_data_req  (IM_data_req),
			.i_IM_addr      (IM_addr),
			.o_IM_mem_ready (IM_mem_ready),
			.o_IM_Instr     (IM_instr),
			
			// Data Memory
			.o_DM_mem_ready (DM_mem_ready),
			.o_DM_ReadData  (DM_rd),
			.i_DM_Wd        (DM_wd),
			.i_DM_Addr      (DM_addr),
			.i_DM_f3        (DM_f3),
			.i_DM_Wen       (DM_wen),
			.i_DM_MemRead   (DM_ren),
			
			// Bus signals
			.i_ack          (i_ack),
			.i_rd_data      (i_rd_data),
			.o_bus_en      	(o_bus_en),
			.o_wr_en        (o_wr_en),
			.o_wr_data      (o_wr_data),
			.o_addr         (o_addr),
			.o_byte_en      (o_byte_en)
		);



endmodule