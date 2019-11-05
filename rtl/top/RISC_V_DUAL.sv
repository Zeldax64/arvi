`timescale 1ns / 1ps

`include "arvi_defines.svh"

/* verilator lint_off DECLFILENAME */
`ifndef __DUAL_CORE

`else
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

	localparam HARTS = 2;

	/* Connections */
	// Instruction Memory
	wire [HARTS-1:0] IM_data_req;
	wire [HARTS-1:0] IM_mem_ready;
	wire [31:0] IM_instr [HARTS-1:0];
	wire [`XLEN-1:0] IM_addr [HARTS-1:0];
	
	// Data Memory
	dmem_if DM_to_mem0();
	dmem_if DM_to_mem1();

	// Bus signals
	bus_if bus_m0();
	bus_if bus_m1();

	// Bus <-> Memory Controller
	wire MC_ack, MC_wr_en, MC_bus_en;
	wire [3:0] MC_byte_en;
	wire [`XLEN-1:0] MC_rd_data;
	wire [`XLEN-1:0] MC_wr_data; 
	wire [`XLEN-1:0] MC_addr;

`ifdef __ATOMIC 
	wire [6:0] MC_operation;
	wire MC_atomic;	
	wire MC_id;	
`endif

	hart #(
			.PC_RESET(PC_RESET),
			.HART(0)
		) hart0(
			.i_clk(i_clk),
			.i_rst(i_rst),
			
			// Instruction Memory connections
			.i_IM_Instr(IM_instr[0]),
			.i_IC_MemReady(IM_mem_ready[0]),
			.o_IM_Addr(IM_addr[0]),
			.o_IC_DataReq (IM_data_req[0]),

			// Data Memory connections
			.DM_to_mem    (DM_to_mem0.master),

			// Interrupt connections
			//.i_tip(tip)
			.i_tip(1'b0)
	);

	hart #(
		.PC_RESET(PC_RESET),
		.HART(1)
		) hart1(
			.i_clk(i_clk),
			.i_rst(i_rst),
			
			// Instruction Memory connections
			.i_IM_Instr(IM_instr[1]),
			.i_IC_MemReady(IM_mem_ready[1]),
			.o_IM_Addr(IM_addr[1]),
			.o_IC_DataReq (IM_data_req[1]),

			// Data Memory connections
			.DM_to_mem    (DM_to_mem1.master),

			// Interrupt connections
			//.i_tip(tip)
			.i_tip(1'b0)
	);

	bus bus_hart0
		(
			.i_clk           (i_clk),
			.i_rst           (i_rst),
			// Instruction Memory
			.i_IM_data_req   (IM_data_req[0]),
			.i_IM_addr       (IM_addr[0]),
			.o_IM_mem_ready  (IM_mem_ready[0]),
			.o_IM_Instr      (IM_instr[0]),
			// Data Memory
			.dmem          	(DM_to_mem0.slave),
			// Bus signals
			.bus_m         	(bus_m0.master)
		);


	bus bus_hart1
		(
			.i_clk           (i_clk),
			.i_rst           (i_rst),
			// Instruction Memory
			.i_IM_data_req   (IM_data_req[1]),
			.i_IM_addr       (IM_addr[1]),
			.o_IM_mem_ready  (IM_mem_ready[1]),
			.o_IM_Instr      (IM_instr[1]),
			// Data Memory
			.dmem          	(DM_to_mem1.slave),
			// Bus signals
			.bus_m         	(bus_m1.master)
		);
		
	arbiter_2x1 arbiter_2x1
		(
			.i_clk      	(i_clk),
			.i_rst      	(i_rst),
			
			// Bus 1
			.bus0       	(bus_m0.slave),
			
			// Bus 2
			.bus1       	(bus_m1.slave),
			// To Bus
			.i_ack      	(MC_ack),
			.i_rd_data  	(MC_rd_data),
			.o_id       	(MC_id),
			.o_bus_en   	(MC_bus_en),
			.o_wr_en    	(MC_wr_en),
			.o_wr_data  	(MC_wr_data),
			.o_addr     	(MC_addr),
			.o_byte_en  	(MC_byte_en),
			.o_atomic   	(MC_atomic),
			.o_operation	(MC_operation)
		);

	memory_controller #(
			.N_IDS(HARTS)
		) memory_controller (
			.i_clk     		(i_clk),
			.i_rst     		(i_rst),
			
			.i_bus_en  		(MC_bus_en),
			.i_wr_en   		(MC_wr_en),
			.i_wr_data 		(MC_wr_data),
			.i_addr    		(MC_addr),
			.i_byte_en 		(MC_byte_en),
			.o_ack     		(MC_ack),
			.o_rd_data 		(MC_rd_data),
			
			.i_atomic  		(MC_atomic),
			.i_id      		(MC_id),
			.i_operation 	(MC_operation),
			
			.i_ack     		(i_ack),
			.i_rd_data 		(i_rd_data),
			.o_bus_en  		(o_bus_en),
			.o_wr_en   		(o_wr_en),
			.o_wr_data 		(o_wr_data),
			.o_addr    		(o_addr),
			.o_byte_en 		(o_byte_en)
		);


endmodule
`endif
