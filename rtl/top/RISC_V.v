`timescale 1ns / 1ps

`include "arvi_defines.vh"

/* verilator lint_off DECLFILENAME */
`ifdef __SINGLE_CORE
module RISC_V
`else
module RISC_V_
`endif	
	#(
		parameter PC_RESET = `PC_RESET,
		parameter HART_ID = 0,
		parameter I_CACHE_ENTRIES = 128
	)
	(
/* verilator lint_on DECLFILENAME */
	input i_clk,
	input i_rst,

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

	// Bus Master
	`BUS_M
	);
	
	// PC initial value

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

`ifdef __ATOMIC
	wire [6:0] MEM_operation;
	wire MEM_atomic;
	assign o_operation = MEM_operation;
	assign o_atomic = MEM_atomic;
`endif

	HART #(
			.PC_RESET(PC_RESET),
			.HART(HART_ID),
			.I_CACHE_ENTRIES(I_CACHE_ENTRIES)
		) hart(
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
		.o_DM_Wd(DM_wd),
		.o_DM_Addr(DM_addr),
		.o_DM_Wen(DM_wen),
		.o_DM_MemRead(DM_ren),
		.o_DM_f3(DM_f3),

`ifdef __ATOMIC
		.o_DM_f7        (MEM_operation),
		.o_MEM_atomic   (MEM_atomic),
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
