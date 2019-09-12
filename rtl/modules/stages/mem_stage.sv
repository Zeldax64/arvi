/*
	This file implements the memory access stage of processor's datapath.
*/

`include "arvi_defines.svh"

module mem_stage (
	input i_clk,
	input i_rst,
/* verilator lint_off UNUSED */
	input [31:0] i_inst,
/* verilator lint_on UNUSED */
	input [`XLEN-1:0] i_alu_res,
	input [`XLEN-1:0] i_wr_data,
	//input i_wr_en,
	//input i_rd_en,
	input MC_MemWrite,
	input MC_MemRead,

	output logic [`XLEN-1:0] o_rd,
	// CPU <-> Memory interface
    dmem_if.master to_mem,

    output logic ex_ld_addr,
    output logic ex_st_addr,

    // Branch Control
    input i_branch,
    input i_z,

    input [1:0] i_jump,
    input [`XLEN-1:0] i_pc,
    input [`XLEN-1:0] i_pc_jump,
    output logic [`XLEN-1:0] o_pc,

	output logic o_stall
	);
	
	logic DM_stall;
	assign o_stall = DM_stall;
	logic [2:0] f3 = i_inst[14:12];
	//logic ex_ld_addr, ex_st_addr;

/* verilator lint_off UNUSED */
	logic DoBranch;
/* verilator lint_on UNUSED */

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
				o_pc = i_alu_res & 32'hFFFF_FFFE; // Ignoring LSB
		end
		else begin
			if(i_jump == 2'b01 || DoBranch) begin // JAL
			 	o_pc = i_pc_jump;
			end
			else begin // PC increment
				o_pc = i_pc + 4;
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
			.i_wr_en         (MC_MemWrite),
			.i_rd_en         (MC_MemRead),
			.o_Rd            (o_rd),
			.o_stall       	 (DM_stall),
			.o_ex_ld       	 (ex_ld_addr),
			.o_ex_st       	 (ex_st_addr),

			// CPU <-> Memory
			.to_mem   		 (to_mem)
		);

endmodule