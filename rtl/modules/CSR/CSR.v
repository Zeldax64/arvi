`timescale 1ns / 1ps

`include "defines.vh"
`include "modules/CSR/csr_defines.vh"

// TODO:
// I think it is possible to optimize exception handling in this file
module CSR(
	input i_clk,
	input i_rst, // If necessary
	input i_CSR_en, // CSR enable
	input [`XLEN-1:0] i_Wd,
	input [31:0] i_inst,
	input [`XLEN-1:0] i_PC,
	input [`XLEN-1:0] i_badaddr,
	output [`XLEN-1:0] o_Rd,

	output o_eret,
	wire o_ex,
	output [`XLEN-1:0] o_tvec, //Trap-Vector Base Address Register
	output [`XLEN-1:0] o_cause,
	output reg [`XLEN-1:0] o_epc, // Exception Program Counter

	// Exceptions
	input i_Ex,
	input i_Ex_inst_addr, // Instruction misaligned
	input i_Ex_ld_addr,	  // Load misaligned
	input i_Ex_st_addr	  // Store misaligned
	);
	// Instruction slicing
	wire [2:0] f3 = i_inst[14:12];
	wire [11:0] addr = i_inst[31:20];

	reg  [`XLEN-1:0] write_data;
	wire [`XLEN-1:0] o_cause = mcause;
	wire [`XLEN-1:0] o_tvec = mtvec;

	// Machine Trap Setup
	// mstatus
	reg mie, mpie;

	reg [`XLEN-1:0] medeleg;
	reg [`XLEN-1:0] mtvec;

	// Machine Trap Handling
	reg [`XLEN-1:0] mscratch;
	reg [`XLEN-1:0] mepc;
	reg [`XLEN-1:0] mcause;
	reg [`XLEN-1:0] mtval;

	// Getting value to write according to instruction's f3
	always@(*) begin
		case(f3[1:0])
			2'b01: write_data =  i_Wd;
			2'b10: write_data =  i_Wd | o_Rd;
			2'b11: write_data = ~i_Wd & o_Rd; 
			default: write_data = 0;
		endcase
	end

	// NFI => Not Fully Implemented
	// Write
	always@(posedge i_clk) begin
		// Reset logic
		if(!i_rst) begin
			mie <= 0;
			mcause <= {`XLEN{1'b0}};
		end
		else 
		if(i_CSR_en) begin
			// Implementing ECALL here. Please notice that i_Ex comes from
			// Main Control
			if(f3 == `PRIV) begin
					if(addr == 12'b0) begin 
						mcause <= 11; // Environment call from M-mode
						mepc <= i_PC;
						mtval <= 0;
					end
					if(addr == 12'h001) begin // Ebreak exception
						mcause <= 3;
						mepc <= i_PC;
					end
					if(addr == `MRET) begin
						mie  <= mpie;
						mpie <= 1;
					end
			end
			else begin
				case(addr)
					// Machine Status - Since only M-mode and RV32I is implemented, it is necessary to implement 
					// only mpie and mie bits from mstatus register in a write
					`mstatus : begin
						{mpie, mie} <= {write_data[7], write_data[3]};
					end
					// Machine Trap Setup
					`medeleg : begin // NFI - Just Storing values. Its real function is not implemented
						medeleg <= write_data;
					end
					`mtvec : begin // NFI - Ignoring "mode" field in mtvec
						mtvec <= {write_data[`XLEN-1:2], 2'b00};
					end
					// Machine Trap Handling
					`mscratch : begin
						mscratch <= write_data;
					end
					`mepc : begin
						mepc <= {write_data[`XLEN-1:2], 2'b00}; // NFI - Not saving PC when exception occurs
					end
					`mcause : begin // NFI - Missing exception when illegal value is written
						mcause <= write_data; 
					end
					`mtval : begin
						mtval <= write_data;
					end
					default : begin
					end
				endcase
			end
		end

		// Exceptions without enable
		else begin
			if(o_ex) begin
				mepc <= i_PC;
				if(i_Ex) begin
					mcause <= 2; // Illegal Instruction
					mtval  <= i_inst;
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
		end

	end

	reg ex_ecall, ex_ebreak;
	always@(*) begin
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
					o_epc = mepc;
					o_eret = 1'b1;
				end
				default : o_epc = 0;
			endcase
		end
	// Read
		else begin
			case(addr)
				`mstatus : o_Rd = {{19{1'b0}}, 2'b11, 3'b0, mpie, 3'b0, mie, 3'b0};
				`medeleg : o_Rd = medeleg; // NFI - Just Storing values
				`mtvec : o_Rd = mtvec;
				`mscratch : o_Rd = mscratch;
				`mepc : o_Rd = mepc;
				`mcause : o_Rd = mcause;
				`mtval : o_Rd = mtval;
				default : o_Rd = 0;
			endcase	
		end	
	end

	// Exceptions
	wire ex_ldst_addr = i_Ex_ld_addr || i_Ex_st_addr;
	assign o_ex = i_Ex || i_Ex_inst_addr || ex_ldst_addr || ex_ebreak || ex_ecall;

endmodule
