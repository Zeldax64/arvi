/*
	This file implements the instruction decode stage of processor's datapath.
*/
`include "arvi_defines.svh"

module id_stage(
	input i_clk,
	input [31:0] i_inst,
	input i_stall,

	output [`XLEN-1:0] o_rd1,
	output [`XLEN-1:0] o_rd2,
	output [`XLEN-1:0] o_imm,

	// Main Control
    output logic o_branch,
    output logic o_memread,
    output logic o_memwrite,
    output logic o_memtoreg,
    output logic [2:0] o_alu_op,
    output logic [1:0] o_alu_srca,
    output logic o_alu_srcb,
    output logic o_regwrite,
    output logic [1:0] o_jump,
    output logic o_pc_plus4,
    output logic o_csr_en,
    output logic o_ex,

`ifdef __ATOMIC
	output logic o_atomic,
`endif
`ifdef __RV32_M
	output logic o_m_en,
`endif

    // Writeback
	input i_wr_en,
	input [`XLEN-1:0] i_wr_data
	
	);

	// Main Control
	main_control main_control
	(
		.o_Branch   (o_branch),
		.o_MemRead  (o_memread),
		.o_MemWrite (o_memwrite),
		.o_MemToReg (o_memtoreg),
		.o_ALUOp    (o_alu_op),
		.o_ALUSrcA  (o_alu_srca),
		.o_ALUSrcB  (o_alu_srcb),
		.o_RegWrite (o_regwrite),
		.o_Jump     (o_jump),
		.o_PCplus4  (o_pc_plus4),
		.o_CSR_en  	(o_csr_en),
		.o_Ex 	    (o_ex),

`ifdef __ATOMIC
		.o_atomic  (o_atomic),
`endif
`ifdef __RV32_M
		.o_ALUM_en (o_m_en),
`endif

		.i_Instr   (i_inst),
		.i_Stall   (i_stall)

	);

	register_file reg_file (
    	.o_Rd1(o_rd1),
    	.o_Rd2(o_rd2),
    	.i_Rnum1(i_inst[19:15]),
    	.i_Rnum2(i_inst[24:20]),
    	.i_Wen(i_wr_en),
    	.i_Wnum(i_inst[11:7]),
    	.i_Wd(i_wr_data),
    	.i_clk(i_clk)
    );

	imm_gen  imm_gen (
		.i_Instr(i_inst),
		.o_Ext(o_imm)
	);



endmodule