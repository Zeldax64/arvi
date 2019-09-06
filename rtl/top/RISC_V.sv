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

`ifdef __ATOMIC
	wire [6:0] MEM_operation;
	wire MEM_atomic;
	assign o_operation = MEM_operation;
	assign o_atomic = MEM_atomic;
`endif
	
	dmem_if DM_to_mem();
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
		.DM_to_mem    (DM_to_mem.master),

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

	bus_if bus_m();

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
			.dmem          (DM_to_mem.slave),
			
			// Bus signals
			.bus_m           (bus_m.master)
		);

	assign bus_m.ack = i_ack ;
	assign bus_m.rd_data = i_rd_data;
	assign o_bus_en = bus_m.bus_en;
	assign o_wr_en = bus_m.wr_en;
	assign o_wr_data = bus_m.wr_data;
	assign o_addr = bus_m.addr;
	assign o_byte_en = bus_m.byte_en;
	
endmodule
