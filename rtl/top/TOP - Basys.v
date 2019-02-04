`timescale 1ns / 1ps

`define INSTRUCTION_SIZE 31
`define WORD_SIZE 31

module TOP_BASYS(
	input i_clk
	/*
`ifdef FPGA
	,
	output reg [15:0] led
`endif
*/ 
	);

	parameter IMEM_HEIGHT = `INSTRUCTION_MEMORY_SIZE; //Instruction Memory height
	parameter DMEM_HEIGHT = `DATA_MEMORY_SIZE; //Data Memory Memory height
	
	parameter FILE = `PROGRAM_DATA; // ROM - Instruction Memory

	/*----- Wire Declarations -----*/
	// Instruction Memory
	wire [`INSTRUCTION_SIZE:0] IM_Instr;
	wire [`INSTRUCTION_SIZE:0] IM_Addr;
	
	// Data Memory
	wire [`INSTRUCTION_SIZE:0] DM_ReadData;
	wire [`INSTRUCTION_SIZE:0] DM_Wd;
	wire [`INSTRUCTION_SIZE:0] DM_Addr;
	wire DM_Wen;
	wire DM_Ren;

	DATAPATH_SC datapath (
		.i_clk(i_clk),

		// Instruction Memory connections
		.i_IM_Instr(IM_Instr),
		.o_IM_Addr(IM_Addr),

		// Data Memory connections
		.i_DM_ReadData(DM_ReadData),
		.o_DM_Wd(DM_Wd),
		.o_DM_Addr(DM_Addr),
		.o_DM_Wen(DM_Wen)
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

/*
`ifdef FPGA
	always @(posedge i_clk) begin 
		if(DM_Addr == 0 && DM_Wen) begin
			led <= DM_Wd;
		end
	end
`endif
*/
endmodule