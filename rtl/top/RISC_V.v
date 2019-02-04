`timescale 1ns / 1ps

`include "defines.vh"

module RISC_V(
	input i_clk
	);

	// Instruction Memory height
	parameter IMEM_HEIGHT = `INSTRUCTION_MEMORY_SIZE; 
	// Data Memory Memory height
	parameter DMEM_HEIGHT = `DATA_MEMORY_SIZE; 
	// ROM - Instruction Memory
	parameter FILE = `PROGRAM_DATA; 

	/*----- Wire Declarations -----*/
	// Instruction Memory
	wire [`INSTRUCTION_SIZE:0] IM_Instr;
	wire [`INSTRUCTION_SIZE:0] IM_Addr;

	// Data Memory
	wire [`INSTRUCTION_SIZE:0] DM_ReadData;
	wire [`INSTRUCTION_SIZE:0] DM_Wd;
	wire [`INSTRUCTION_SIZE:0] DM_Addr;
	wire DM_Wen;

	// Main Control
	wire MC_Branch;
	wire MC_MemRead;
	wire MC_MemWrite;
	wire MC_MemtoReg;
	wire [2:0] MC_ALUOp;
	wire [1:0] MC_ALUSrcA;
	wire MC_ALUSrcB;
	wire MC_RegWrite;
	wire [1:0] MC_Jump;
	wire MC_PCplus4;
	wire [6:0] MC_OPCode;

	DATAPATH_SC datapath (
		.i_clk(i_clk),

		// Instruction Memory connections
		.i_IM_Instr(IM_Instr),
		.o_IM_Addr(IM_Addr),

		// Data Memory connections
		.i_DM_ReadData(DM_ReadData),
		.o_DM_Wd(DM_Wd),
		.o_DM_Addr(DM_Addr),
		.o_DM_Wen(DM_Wen),

		// Main Control connections
		.i_MC_Branch   (MC_Branch),
		.i_MC_MemRead  (MC_MemRead),
		.i_MC_MemWrite (MC_MemWrite),
		.i_MC_MemtoReg (MC_MemtoReg),
		.i_MC_ALUOp    (MC_ALUOp),
		.i_MC_ALUSrcA  (MC_ALUSrcA),
		.i_MC_ALUSrcB  (MC_ALUSrcB),
		.i_MC_RegWrite (MC_RegWrite),
		.i_MC_Jump     (MC_Jump),
		.i_MC_PCplus4  (MC_PCplus4),
		.o_MC_OPCode   (MC_OPCode)
	);

	INSTRUCTION_MEMORY #(
		.HEIGHT(IMEM_HEIGHT),
		.FILE(FILE)
		) inst_mem (
		.o_Instruction(IM_Instr),
		.i_Addr(IM_Addr)
	);

	DATA_MEMORY #(
			.HEIGHT(DMEM_HEIGHT)
		) data_mem (
		.o_Rd   (DM_ReadData),
		.i_Wd   (DM_Wd),
		.i_Addr (DM_Addr),
		.i_Wen  (DM_Wen),
		.i_clk  (i_clk)
	);

	MAIN_CONTROL main_control
	(
		.o_Branch   (MC_Branch),
		.o_MemRead  (MC_MemRead),
		.o_MemWrite (MC_MemWrite),
		.o_MemToReg (MC_MemtoReg),
		.o_ALUOp    (MC_ALUOp),
		.o_ALUSrcA  (MC_ALUSrcA),
		.o_ALUSrcB  (MC_ALUSrcB),
		.o_RegWrite (MC_RegWrite),
		.o_Jump     (MC_Jump),
		.o_PCplus4  (MC_PCplus4),
		.i_OPCode   (MC_OPCode)
	);


endmodule
