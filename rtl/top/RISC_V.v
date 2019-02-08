`timescale 1ns / 1ps

`include "defines.vh"

/* verilator lint_off DECLFILENAME */
module RISC_V(
/* verilator lint_on DECLFILENAME */
	input i_clk,
	input i_rst,

	// Instruction Memory Access
	input i_IC_MemReady,
	input  [`INSTRUCTION_SIZE:0] i_IM_Instr,
	output [`INSTRUCTION_SIZE:0] o_IM_Addr,
	output o_IC_DataReq,

	// Data Memory Access
	input  [`INSTRUCTION_SIZE:0] i_DM_ReadData,
	output [`INSTRUCTION_SIZE:0] o_DM_WriteData,
	output [`INSTRUCTION_SIZE:0] o_DM_Addr,
	output [2:0] o_DM_f3,
	output o_DM_MemRead,
	output o_DM_Wen
	);
	
	// PC initial value
	parameter PC_RESET = `PC_RESET;

	// Read data wires
	wire [`XLEN-1:0] DM_rd,CLINT_rd;
	wire tip;

	HART #(
			.PC_RESET(PC_RESET)
		) hart0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		
		// Instruction Memory connections
		.i_IM_Instr(i_IM_Instr),
		.i_IC_MemReady(i_IC_MemReady),
		.o_IM_Addr(o_IM_Addr),
		.o_IC_DataReq (o_IC_DataReq),

		// Data Memory connections
		.i_DM_ReadData(DM_rd),
		.o_DM_WriteData(o_DM_WriteData),
		.o_DM_Addr(o_DM_Addr),
		.o_DM_Wen(o_DM_Wen),
		.o_DM_MemRead(o_DM_MemRead),
		.o_DM_f3(o_DM_f3),

		// Interrupt connections
		.i_tip(tip)
	);

	CLINT #(
			.BASE_ADDR(32'h2000_0000)
		) clint (
		.i_clk		(i_clk),
		.i_rst		(i_rst),
		.i_wen  	(o_DM_Wen),
		.i_ren  	(o_DM_MemRead),
		.i_addr 	(o_DM_Addr),
		.i_wrdata	(o_DM_WriteData),
		.o_rddata 	(CLINT_rd),
		.o_tip   	(tip)
		);

	assign DM_rd = (o_DM_Addr[`XLEN-1:`XLEN-4] == 4'h2) ? CLINT_rd : i_DM_ReadData;

endmodule
