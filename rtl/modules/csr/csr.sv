`timescale 1ns / 1ps

`include "arvi_defines.svh"
`include "modules/csr/csr_defines.svh"

// TODO:
// - Rework this file to achieve better synthesis results.
// - I think it is possible to optimize exception handling in this file.

module csr(
	input i_clk,
	input i_rst, 
	input i_CSR_en, // CSR enable
	input [`XLEN-1:0] i_Wd,
	input [31:0] i_inst,
	input [`XLEN-1:0] i_PC,
	input [`XLEN-1:0] i_badaddr,
	output logic [`XLEN-1:0] o_Rd,

	output logic o_eret,
	output logic [`XLEN-1:0] o_tvec, // Trap-Vector Base Address Register.
	output logic [`XLEN-1:0] o_epc, // Exception Program Counter.
	output logic o_ecall,
	output logic o_ebreak,
	// Exceptions
	input i_Ex_inst_illegal, // Illegal instruction
	input i_Ex_inst_addr,  	 // Instruction misaligned.
	input i_Ex_ld_addr,	   	 // Load misaligned.
	input i_Ex_st_addr,	   	 // Store misaligned.
	input i_Ex_ecall,		 // Ecall occurred
	input i_Ex_ebreak,

	// Interrupts
	input i_Int_tip
	);
	parameter HART_ID = 0;

	// Auxiliary signals
	// Instruction slicing
	wire [2:0] f3; 
	wire [11:0] addr;

	assign f3 = i_inst[14:12];
	assign addr = i_inst[31:20];
	
	// Events
	logic ex_ecall, ex_ebreak;
	logic push_mstatus;

	assign o_ecall  = ex_ecall;
	assign o_ebreak = ex_ebreak;
	
	// Machine Trap Setup
	// mstatus
	reg mie, mpie;
	reg [`XLEN-1:0] medeleg;
	// mie
	reg mtie;

	reg [`XLEN-1:0] mtvec;

	// Machine Trap Handling
	reg [`XLEN-1:0] mscratch;
/* verilator lint_off UNUSED */
	reg [`XLEN-1:0] mepc;
/* verilator lint_on UNUSED */
	reg [`XLEN-1:0] mcause;
	reg [`XLEN-1:0] mtval;
	wire mtip = i_Int_tip;

	// Assigning output
	assign o_tvec  = {mtvec[`XLEN-1:2], 2'b00};

	wire exception;
	wire interrupt, int_ti;

	// Get value to write according to instruction's f3
	logic [`XLEN-1:0] write_data;
	logic [`XLEN-1:0] zimm;
	logic [`XLEN-1:0] wr_data;
	assign zimm = {{`XLEN-5{1'b0}}, i_inst[19:15]};
	assign wr_data = f3[2] ? zimm : i_Wd;
	always_comb begin
		case(f3[1:0])
			2'b01: write_data =  wr_data;
			2'b10: write_data =  wr_data | o_Rd;
			2'b11: write_data = ~wr_data & o_Rd; 
			default: write_data = 0;
		endcase
	end

	// NFI => Not Fully Implemented
	// Write
	always_ff@(posedge i_clk) begin
		// Reset logic
		if(!i_rst) begin
			mie <= 0;
			mcause <= {`XLEN{1'b0}};
		end
		else 
			if(i_CSR_en) begin
				if(i_Ex_ecall) begin
						// xRET instruction
						if(addr == `MRET) begin
							mie  <= mpie;
							mpie <= 1;
						end
				end
				else begin
					case(addr)
						// Machine Status - Since only M-mode and RV32I is implemented, it is necessary to implement 
						// only mpie and mie bits from mstatus register in a write
						`mstatus : {mpie, mie} <= {write_data[7], write_data[3]};
						// Machine Trap Setup
						`medeleg : begin // NFI - Just Storing values. Its real function is not implemented
							medeleg <= write_data;
						end
						`mie : mtie <= write_data[7];
						`mtvec : begin // NFI - Ignoring "mode" field in mtvec
							mtvec <= {write_data[`XLEN-1:2], 2'b00};
						end
						// Machine Trap Handling
						`mscratch : mscratch <= write_data;
						`mepc : mepc <= {write_data[`XLEN-1:2], 2'b00};
						`mcause : begin // NFI - Missing exception when illegal value is written
							mcause <= write_data; 
						end
						`mtval : mtval <= write_data;
						default : begin
						end
					endcase
				end
			end

			// Exceptions
			if(exception) begin
				mepc <= i_PC;
				if(i_Ex_inst_illegal) begin
					mcause <= 2; // Illegal Instruction
					mtval  <= i_inst;
				end
				if(i_Ex_ecall) begin
					mcause <= 11; // Environment call from M-mode
					mtval <= 0;
				end
				if(addr == 12'h001) begin // Ebreak exception
					mcause <= 3;
					mtval <= i_PC;
				end
				if(i_Ex_inst_addr) begin
					mtval  <= i_badaddr;
					mcause <= 0; // Instruction address misaligned
				end
				if(i_Ex_ld_addr) begin
					mtval  <= i_badaddr;
					mcause <= 4; // Load address misaligned
				end
				if(i_Ex_st_addr) begin
					mtval  <= i_badaddr;
					mcause <= 6; // Store address misaligned
				end
			end

		// Interrupts
		if(interrupt) begin
			mepc <= i_PC+4; // TODO: Check this!
			mcause[`XLEN-1] <= 1'b1;
			if(int_ti) begin // Machine timer interrupt
				mcause <= mcause | 7;
			end
		end

		// If trap, then push mstatus stack
		if(push_mstatus) begin
			mie <= 0;
			mpie <= mie;
		end

	end

	always_comb begin
		o_epc = 0;
		o_Rd = 0;
		o_eret = 0;
		ex_ecall = 0;
		ex_ebreak = 0;
		if(f3 == `PRIV && i_CSR_en) begin // Checking if there is a MRET instruction
			case(addr)
				12'h000: ex_ecall  = 1; // ECALL
				12'h001: ex_ebreak = 1; // EBREAK
				`MRET : begin
					o_epc = {mepc[`XLEN-1:2], 2'b00};
					o_eret = 1'b1;
				end
				default : o_epc = 0;
			endcase
		end

	// Read
		else begin
			case(addr)
				`mhartid : o_Rd = HART_ID;
				`mstatus : o_Rd = {{19{1'b0}}, 2'b11, 3'b0, mpie, 3'b0, mie, 3'b0};
				`misa : o_Rd = {2'b01, 4'b0, 26'b0_00000_00000_00000_01000_00000}; // Read only RV32I
				`medeleg : o_Rd = medeleg; // NFI - Just Storing values
				`mie : o_Rd = {{`XLEN-9{1'b0}}, mtie, 8'b0};
				`mtvec : o_Rd = mtvec;
				`mscratch : o_Rd = mscratch;
				`mepc : o_Rd = {mepc[`XLEN-1:2], 2'b00};
				`mcause : o_Rd = mcause;
				`mtval : o_Rd = mtval;
				`mip : o_Rd = {{`XLEN-9{1'b0}}, mtip, 8'b0};
				default : o_Rd = 0;
			endcase	
		end	
	end

	// Exceptions
	assign exception = i_Ex_inst_illegal || 
					   i_Ex_inst_addr 	 ||
					   i_Ex_ld_addr		 ||
					   i_Ex_st_addr 	 ||
					   i_Ex_ebreak 		 || 
					   i_Ex_ecall;

	// Interrupts
	assign int_ti = mtie && mtip && mie; // Timer interrupt
	assign interrupt = int_ti;

	assign push_mstatus = exception || interrupt;
endmodule
