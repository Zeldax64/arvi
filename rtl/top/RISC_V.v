`timescale 1ns / 1ps

`include "defines.vh"

/* verilator lint_off DECLFILENAME */
module RISC_V(
/* verilator lint_on DECLFILENAME */
	input i_clk,
	input i_rst,

	// Bus 
	input  i_ack,
	input  [31:0] i_rd_data,
	output o_bus_en,
	output o_wr_rd,
	output [31:0] o_wr_data,
	output [31:0] o_addr,
	output [2:0]  o_size
	);
	
	// PC initial value
	parameter PC_RESET = `PC_RESET;

	// Read data wires
	//wire [`XLEN-1:0] DM_rd,CLINT_rd;
	//wire tip;

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

	HART #(
			.PC_RESET(PC_RESET)
		) hart0(
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
		.o_DM_WriteData(DM_wd),
		.o_DM_Addr(DM_addr),
		.o_DM_Wen(DM_wen),
		.o_DM_MemRead(DM_ren),
		.o_DM_f3(DM_f3),

		// Interrupt connections
		//.i_tip(tip)
		.i_tip(1'b0)
	);

		/*
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
	*/
	// Bus 1 signals
	wire ack1, wr_rd1, bus_en1;
	wire [2:0] size1;
	wire [`XLEN-1:0] rd_data1, wr_data1, addr1;

	BUS bus_1
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
			.i_ack          (ack1),
			.i_rd_data      (rd_data1),
			.o_bus_en       (bus_en1),
			.o_wr_rd        (wr_rd1),
			.o_wr_data      (wr_data1),
			.o_addr         (addr1),
			.o_size         (size1)
		);

	ARBITER_2X1 inst_ARBITER_2X1
		(
			.i_clk      (i_clk),
			.i_rst      (i_rst),
			
			// Bus 1
			.i_bus_en1  (bus_en1),
			.i_wr_rd1   (wr_rd1),
			.i_wr_data1 (wr_data1),
			.i_addr1    (addr1),
			.i_size1    (size1),
			.o_ack1     (ack1),
			.o_rd_data1 (rd_data1),
			
			// Bus 2
			/*
			.i_bus_en2  (bus_en2),
			.i_wr_rd2   (wr_rd2),
			.i_wr_data2 (wr_data2),
			.i_addr2    (addr2),
			.i_size2    (size2),
			.o_ack2     (ack2),
			.o_rd_data2 (rd_data2),
			*/
			.i_bus_en2  (0),
			.i_wr_rd2   (0),
			.i_wr_data2 (0),
			.i_addr2    (0),
			.i_size2    (0),
			/* verilator lint_off PINCONNECTEMPTY */
			.o_ack2     ( ),
			.o_rd_data2 ( ),
			/* verilator lint_on PINCONNECTEMPTY */
			// To Bus
			.i_ack      (i_ack),
			.i_rd_data  (i_rd_data),
			.o_bus_en   (o_bus_en),
			.o_wr_rd    (o_wr_rd),
			.o_wr_data  (o_wr_data),
			.o_addr     (o_addr),
			.o_size     (o_size)
		);


endmodule
