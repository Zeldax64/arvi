/*
	This file implements the execution stage of ARVI's datapath.
*/

`include "arvi_defines.svh"

module ex_stage (
	input [`XLEN-1:0] i_rs1,
	input [`XLEN-1:0] i_rs2,
	input [`XLEN-1:0] i_imm,

	output [`XLEN-1:0] o_res,
	output o_z,

`ifdef __RV32_M
	input i_clk,
	input i_rst,
	input i_m_en,
	`ifdef __RV32_M_EXTERNAL
		`RV32_M_IF,
	`endif
`endif	

	input [31:0] i_inst,
	input [`XLEN-1:0] i_pc,

//----- Main Control Signals -----//
	// Input signals
    input i_branch,
    input i_memread,
    input i_memwrite,
    input i_memtoreg,
    input [2:0] i_alu_op,
    input [1:0] i_alu_srca,
    input i_alu_srcb,
    input i_regwrite,
    input [1:0] i_jump,
    input i_pc_plus4,
    input i_csr_en,
    input i_ex_inst_illegal,

`ifdef __ATOMIC
	input i_atomic,
`endif
`ifdef __RV32_M
	input i_m_en,
`endif
	
	// Output signals
    output logic o_branch,
    output logic o_memread,
    output logic o_memwrite,
    output logic o_memtoreg,
    output logic o_regwrite,
    output logic [1:0] o_jump,
    output logic o_pc_plus4,
    output logic o_csr_en,
    output logic o_ex_inst_illegal,

`ifdef __ATOMIC
	output logic o_atomic,
`endif

//----- Forward signals -----//

	output logic [31:0] o_inst,
	output logic [`XLEN-1:0] o_pc,
	output logic [`XLEN-1:0] o_pc_jump,
	output logic [`XLEN-1:0] o_wr_data,

	output o_stall
	);

	logic [3:0] alu_control_lines;
	logic [`XLEN-1:0] alu_res;

	alu_control alu_control (
		.i_Funct7          (f7),
		.i_Funct3          (f3),
		.i_ALUOp           (i_alu_op),
		.o_ALUControlLines (alu_control_lines)
	);

	logic [2:0] f3 = i_inst[14:12];
	logic [6:0] f7 = i_inst[31:25];

	// ALU input A Mux
	logic [`XLEN-1:0] A, B;
	assign A = i_alu_srca[1] ? 0  :
			  (i_alu_srca[0] ? i_pc : i_rs1);

	// ALU input B Mux
	assign B = i_alu_srcb ? i_imm : i_rs2;

	alu alu (
		.i_op (alu_control_lines),
		.i_Ra (A),
		.i_Rb (B),
		.o_Z  (o_z),
		.o_Rc (alu_res)
	);


`ifdef __RV32_M
	wire [`XLEN-1:0] rv_m_res;

	`ifndef __RV32_M_EXTERNAL
		// Code for internal RV32M.

		rv32_m rv32_m
			(
				.i_clk   (i_clk),
				.i_rst   (i_rst),
				.i_en    (i_m_en),
				.i_rs1   (i_rs1),
				.i_rs2   (i_rs2),
				.i_f3    (f3),
				.o_res   (rv_m_res),
				.o_stall (o_stall)
			);
	`else 
		// Code for external RV32_M.

		reg enable;
		reg en_delayed;
		
		always_ff@(posedge i_clk) begin
			if(!i_rst || i_ack) begin
				en_delayed <= 0;
				enable <= 0;
			end
			else begin
				if(i_m_en) begin
					o_rs1 <= i_rs1;
					o_rs2 <= i_rs2;
					o_f3  <= f3;
					en_delayed <= i_m_en; 
				end
				enable <= !en_delayed && i_m_en; // Create a 0->1 pulse.
			end
		end		
		
		always_comb begin
			o_en  = enable; // Create a 0->1 pulse.
		end
		
		assign o_stall  = !i_ack && i_m_en;
		assign rv_m_res = i_res; 
	`endif

	assign o_res = i_m_en ? rv_m_res : alu_res; // Ex stage result.

`else
	assign o_res = alu_res;
	assign o_stall = 0;
`endif


	/*----- Forwarding Signals -----*/
	// Main Control
    assign o_branch          = i_branch;
    assign o_memread         = i_memread;
    assign o_memwrite        = i_memwrite;
    assign o_memtoreg        = i_memtoreg;
    assign o_regwrite        = i_regwrite;
    assign o_jump            = i_jump;
    assign o_pc_plus4        = i_pc_plus4;
    assign o_csr_en          = i_csr_en;
    assign o_ex_inst_illegal = i_ex_inst_illegal;

`ifdef __ATOMIC
	assign i_atomic   = i_atomic;
	assign o_atomic   = i_atomic;
`endif

	assign o_inst     = i_inst;
	assign o_pc       = i_pc;
	assign o_pc_jump  = i_pc + $signed(i_imm<<1);
	assign o_wr_data  = i_rs2;

endmodule
