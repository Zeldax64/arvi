/*
	This module defines interfaces used by other modules in this project.
*/

`ifndef __ARVI_INTERFACES
`define __ARVI_INTERFACES
`include "arvi_defines.svh"

// Bus master interface
/* verilator lint_off DECLFILENAME */
interface bus_if;
	logic ack; 				
	logic [31:0] rd_data; 	
	logic bus_en; 			
	logic wr_en; 			
	logic [31:0] wr_data;	
	logic [31:0] addr; 		
	logic [3:0]  byte_en;
		
`ifdef __RVA 						
	logic [6:0] operation;
	logic atomic;	
`endif 

	modport master(
		input ack, rd_data,
		output bus_en, wr_en, wr_data, addr, byte_en
	`ifdef __RVA
		, operation, atomic
	`endif
	);

	modport slave(
		output ack, rd_data,
		input bus_en, wr_en, wr_data, addr, byte_en
	`ifdef __RVA
		, operation, atomic
	`endif
	);

endinterface

`define BUS_M 					\
	input  i_ack, 				\
	input  [31:0] i_rd_data, 	\
	output o_bus_en, 			\
	output o_wr_en, 			\
	output [31:0] o_wr_data,	\
	output [31:0] o_addr, 		\
	output [3:0]  o_byte_en 	\
`ifdef __RVA 				\
	,							\
	output [6:0] o_operation, 	\
	output o_atomic 			\
`endif 

`define RV32_M_IF 					\
	output reg o_en, 				\
	output reg [`XLEN-1:0] o_rs1, 	\
	output reg [`XLEN-1:0] o_rs2, 	\
	output reg [2:0] o_f3, 			\
	input  [`XLEN-1:0] i_res, 		\
	input  i_ack 					


// Data Memory Interfaces
interface dmem_if;
    logic DM_data_ready;
	logic [`XLEN-1:0] DM_ReadData;
	logic [`XLEN-1:0] DM_Wd;
	logic [`XLEN-1:0] DM_Addr;
	logic [3:0] DM_byte_en;
	logic DM_Wen;
	logic DM_MemRead;
`ifdef __RVA
	logic DM_atomic;
	logic [6:0] DM_operation; 
`endif

modport master(
	input DM_data_ready, DM_ReadData,
`ifdef __RVA
	output DM_atomic, DM_operation,
`endif
	output DM_Wd, DM_Addr, DM_byte_en, DM_Wen, DM_MemRead
	);

modport slave(
	input  DM_Wd, DM_Addr, DM_byte_en, DM_Wen, DM_MemRead,
`ifdef __RVA
	input DM_atomic, DM_operation,
`endif
	output DM_data_ready, DM_ReadData
	);

endinterface

`define ARVI_DMEM_WIRES			\
	wire DM_mem_ready;			\
	wire DM_ren;				\
	wire DM_wen;				\
	wire [3:0] DM_byte_en;		\
	wire [`XLEN-1:0] DM_rd;		\
	wire [`XLEN-1:0] DM_wd;		\
	wire [`XLEN-1:0] DM_addr	

`define ARVI_DMEM_OUTPUTS				\
    input  i_DM_data_ready,				\
	input  [`XLEN-1:0] i_DM_ReadData,	\
	output [`XLEN-1:0] o_DM_Wd,			\
	output [`XLEN-1:0] o_DM_Addr,		\
	output [3:0] o_DM_byte_en,			\
	output o_DM_Wen,					\
	output o_DM_MemRead					

`define ARVI_DMEM_INPUTS				\
    output o_DM_data_ready,				\
	output [`XLEN-1:0] o_DM_ReadData,	\
	input  [`XLEN-1:0] i_DM_Wd,			\
	input  [`XLEN-1:0] i_DM_Addr,		\
	input  [3:0] i_DM_byte_en,			\
	input  i_DM_Wen,					\
	input  i_DM_MemRead					

`endif

/* verilator lint_on DECLFILENAME */