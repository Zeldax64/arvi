`timescale 1ns / 1ps

`include "defines.vh"

/* verilator lint_off DECLFILENAME */
module HART(
/* verilator lint_on DECLFILENAME */

	input i_clk,
	input i_rst,

	// Instruction Memory Access
	input i_IC_MemReady,
	input  [`INSTRUCTION_SIZE:0] i_IM_Instr,
	output [`INSTRUCTION_SIZE:0] o_IM_Addr,
	output o_IC_DataReq,

	// Data Memory Access
	input  i_DM_data_ready,
	input  [`INSTRUCTION_SIZE:0] i_DM_ReadData,
	output [`INSTRUCTION_SIZE:0] o_DM_WriteData,
	output [`INSTRUCTION_SIZE:0] o_DM_Addr,
	output [2:0] o_DM_f3,
	output o_DM_MemRead,
	output o_DM_Wen,

	// Interrupt connections
	input i_tip
	);
	
	// PC initial value
	parameter PC_RESET = `PC_RESET;

	DATAPATH_SC #(
			.PC_RESET(PC_RESET)
		) datapath (
		.i_clk(i_clk),
		.i_rst(i_rst),
		
		// Instruction Memory connections
		.i_IM_Instr(i_IM_Instr),
		.i_IC_MemReady(i_IC_MemReady),
		.o_IM_Addr(o_IM_Addr),
		.o_IC_DataReq (o_IC_DataReq),

		// Data Memory connections
		.i_DM_data_ready(i_DM_data_ready),
		.i_DM_ReadData(i_DM_ReadData),
		.o_DM_Wd(o_DM_WriteData),
		.o_DM_Addr(o_DM_Addr),
		.o_DM_Wen(o_DM_Wen),
		.o_DM_MemRead(o_DM_MemRead),
		.o_DM_f3(o_DM_f3),

		// Interrupt connections
		.i_tip (i_tip)
	);

endmodule
