`timescale 1ns / 1ps

`include "arvi_defines.svh"

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
	
	// Instruction Memory
	wire IM_data_req;
	wire IM_mem_ready;
	wire [31:0] IM_instr;
	wire [`XLEN-1:0] IM_addr;
	
	// Data Memory
	`ARVI_DMEM_WIRES;

`ifdef __ATOMIC
	wire [6:0] MEM_operation;
	wire MEM_atomic;
	assign o_operation = MEM_operation;
	assign o_atomic = MEM_atomic;
`endif

	hart #(
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
		.o_DM_byte_en(DM_byte_en),

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
		/*
	logic i_ack;
	logic [31:0] i_rd_data; 	
	logic o_bus_en; 			
	logic o_wr_en; 			
	logic [31:0] o_wr_data;	
	logic [31:0] o_addr; 		
	logic [3:0]  o_byte_en;
*/
	bus_if bus_m;
	/*
	bus_if bus_m (
		.ack (i_ack),
		.rd_data(i_rd_data),
		.bus_en(o_bus_en),
		.wr_en(o_wr_en),
		.wr_data  (o_wr_data),
		.addr(o_addr),
		.byte_en(o_byte_en)
`ifdef __ATOMIC
		,
		.operation(o_operation),
		.atomic(o_atomic)
`endif
		);
	*/
	bus cpu_bus
		(
			.i_clk           (i_clk),
			.i_rst           (i_rst),

			// Instruction Memory
			.i_IM_data_req   (IM_data_req),
			.i_IM_addr       (IM_addr),
			.o_IM_mem_ready  (IM_mem_ready),
			.o_IM_Instr      (IM_instr),
			
			// Data Memory
			.o_DM_data_ready (DM_mem_ready),
			.o_DM_ReadData   (DM_rd),
			.i_DM_Wd         (DM_wd),
			.i_DM_Addr       (DM_addr),
			.i_DM_byte_en    (DM_byte_en),
			.i_DM_Wen        (DM_wen),
			.i_DM_MemRead    (DM_ren),
			
			// Bus signals
			.bus_m           (bus_m)
		);

	/*
	assign bus_m.ack = i_ack ;
	assign bus_m.rd_data = i_rd_data;
	assign bus_m.bus_en = o_bus_en;
	assign bus_m.wr_en = o_wr_en;
	assign bus_m.wr_data = o_wr_data;
	assign bus_m.addr = o_addr;
	assign bus_m.byte_en = o_byte_en;
	*/
	assign bus_m.ack = i_ack ;
	assign bus_m.rd_data = i_rd_data;
	assign o_bus_en = bus_m.bus_en;
	assign o_wr_en = bus_m.wr_en;
	assign o_wr_data = bus_m.wr_data;
	assign o_addr = bus_m.addr;
	assign o_byte_en = bus_m.byte_en;
	
endmodule
