/*
	This file implements the memory access stage of ARVI's datapath.
*/

`include "arvi_defines.svh"

module mem_stage 
	#(
		parameter HART_ID = 0
	)
	(
	input i_clk,
	input i_rst,

	input [31:0] i_inst,
	input [`XLEN-1:0] i_alu_res,
	input [`XLEN-1:0] i_wr_data,
	input i_memwrite,
	input i_memread,

	output logic [`XLEN-1:0] o_rd,
	// Data Memory generated exceptions.
	output logic o_ex_ld_addr,
	output logic o_ex_st_addr,

	// CPU <-> Memory interface
    dmem_if.master to_mem,

    // Branch Control
    input i_branch,
    input i_z,

    input [1:0] i_jump,
    input [`XLEN-1:0] i_pc,
    input [`XLEN-1:0] i_pc_jump,
    output logic [`XLEN-1:0] o_pc,

    // CSR signals
    input i_csr_en,
    input [`XLEN-1:0] i_csr_wd,
    output logic o_csr_eret,
	output logic [`XLEN-1:0] o_csr_tvec,
	output logic [`XLEN-1:0] o_csr_epc,
    output logic o_ex_ecall,
    output logic o_ex_ebreak,

    // Control signals
    input i_mc_memtoreg,
    input i_mc_regwrite,
    input i_mc_pcplus4,
    input i_mc_ex_inst_illegal,
    output logic o_mc_memtoreg,
    output logic o_mc_regwrite,
    output logic o_mc_pcplus4,
    output logic o_mc_ex_inst_illegal,

	// Write-Back Exceptions
    input i_ex_inst_illegal,
    input i_ex_inst_addr,
    input i_ex_ld_addr,
    input i_ex_st_addr,
    input i_ex_ecall,
    input i_ex_ebreak,
    input [`XLEN-1:0] i_badaddr,

	output logic o_stall
	);
	
	logic DM_stall;
	logic DoBranch;
	logic [2:0] f3;
	logic [`XLEN-1:0] dmem_rd, csr_rd;
	logic [`XLEN-1:0] pc_jump;
	
	// CSR Signals
	logic csr_eret; 
	logic [`XLEN-1:0] csr_tvec, csr_epc; 
	
	assign o_stall = DM_stall;
	assign f3 = i_inst[14:12];
	assign o_pc = pc_jump; 
	assign o_csr_tvec  = csr_tvec;
	assign o_csr_epc   = csr_epc;
	assign o_csr_eret  = csr_eret;

	// Calculate PC without CSRs interference

	// CSR
	csr #(.HART_ID(HART_ID) 
		) csr (
		.i_clk 			(i_clk),
		.i_rst      	(i_rst),
		.i_CSR_en 		(i_csr_en),
		.i_inst     	(i_inst),
		.i_Wd    		(i_csr_wd),
		.i_PC			(i_pc),
		.i_badaddr  	(i_badaddr),

		.o_Rd    		(csr_rd),
		.o_eret  		(csr_eret),
		.o_tvec 		(csr_tvec),
		.o_epc  		(csr_epc),
		.o_ecall        (o_ex_ecall),
		.o_ebreak       (o_ex_ebreak),
		
		// Exceptions
		.i_Ex_inst_illegal 	(i_ex_inst_illegal),
		.i_Ex_inst_addr 	(i_ex_inst_addr),
		.i_Ex_ld_addr  		(i_ex_ld_addr),
		.i_Ex_st_addr 		(i_ex_st_addr),
		.i_Ex_ecall         (i_ex_ecall),
		.i_Ex_ebreak        (i_ex_ebreak),
		// Interrupts
		.i_Int_tip (1'b0)
	);


	branch_control branch_control (
		.i_Branch   (i_branch),
		.i_Z        (i_z),
		.i_Res      (i_alu_res[0]),
		.i_f3       (f3),
		.o_DoBranch (DoBranch)
	);

	// Calculate PC without CSRs interference
	always_comb begin
		if(i_jump == 2'b10) begin // JALR
				pc_jump = i_alu_res & 32'hFFFF_FFFE; // Ignoring LSB
		end
		else begin
			if(i_jump == 2'b01 || DoBranch) begin // JAL
			 	pc_jump = i_pc_jump;
			end
			else begin // PC increment
				pc_jump = i_pc + 4;
			end		
		end
	end

	d_mem d_mem
		(
			.i_clk           (i_clk),
			.i_rst           (i_rst),
			.i_wr_data       (i_wr_data),
			.i_addr          (i_alu_res),
			.i_f3            (f3),
			.i_wr_en         (i_memwrite),
			.i_rd_en         (i_memread),
			.o_Rd            (dmem_rd),
			.o_stall       	 (DM_stall),
			.o_ex_ld       	 (o_ex_ld_addr),
			.o_ex_st       	 (o_ex_st_addr),

			// CPU <-> Memory
			.to_mem   		 (to_mem)
		);

	// Which data should be outputted?
	assign o_rd = i_csr_en ? csr_rd : dmem_rd;

	// Passing control signals forward.
    assign o_mc_memtoreg        = i_mc_memtoreg;
    assign o_mc_regwrite        = i_mc_regwrite;
    assign o_mc_pcplus4         = i_mc_pcplus4;   
    assign o_mc_ex_inst_illegal = i_mc_ex_inst_illegal;
endmodule