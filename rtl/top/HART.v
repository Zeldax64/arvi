`timescale 1ns / 1ps

`include "arvi_defines.vh"

module HART
	#(
	parameter PC_RESET = `PC_RESET,
	parameter HART = 0,
	parameter I_CACHE_ENTRIES = 128
	)
	(
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

`ifdef __ATOMIC // Atomic extension signal for atomic operations
	output o_MEM_atomic,
	output [6:0] o_DM_f7,
`endif

`ifdef __RV32_M_EXTERNAL
	output o_EX_en, 
	output [`XLEN-1:0] o_EX_rs1, 
	output [`XLEN-1:0] o_EX_rs2, 
	output [2:0] o_EX_f3, 
	input  [`XLEN-1:0] i_EX_res, 
	input  i_EX_ack,
`endif

`ifdef RISCV_FORMAL
	`RVFI_OUTPUTS,
`endif
	// Interrupt connections
	input i_tip
	);

	DATAPATH_SC #(
			.PC_RESET(PC_RESET),
			.HART(HART),
			.I_CACHE_ENTRIES(I_CACHE_ENTRIES)
			
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

`ifdef __ATOMIC
		.o_MEM_atomic(o_MEM_atomic),
		.o_DM_f7     (o_DM_f7),
`endif

`ifdef __RV32_M_EXTERNAL
		.o_EX_en        (o_EX_en),
		.o_EX_rs1       (o_EX_rs1),
		.o_EX_rs2       (o_EX_rs2),
		.o_EX_f3        (o_EX_f3),
		.i_EX_res       (i_EX_res),
		.i_EX_ack       (i_EX_ack),
`endif

`ifdef RISCV_FORMAL
		`RVFI_CONN,
`endif

		// Interrupt connections
		.i_tip (i_tip)
	);

endmodule
