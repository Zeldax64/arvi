`timescale 1ns / 1ps

`include "defines.vh"
`include "modules/CSR/csr_defines.vh"

// TODO:
// Implement ECALL support according to 3.2.1 from privileged ISA pdf.
// It should write to mepc;
// Implement return to trap handler support;
// Implement CSRxx instructions using f3
module CSR(
	input i_clk,
	//input i_rst, // If necessary
	input i_CSR_en, // CSR enable
	input [`XLEN-1:0] i_Wd,
	input [11:0] i_addr,
	input [2:0] i_Funct3,
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
	
	reg [`XLEN-1:0] write_data;
	wire [`XLEN-1:0] o_cause = mcause;
	wire [`XLEN-1:0] o_tvec = mtvec;

	// Machine Trap Setup
	reg [`XLEN-1:0] medeleg;
	reg [`XLEN-1:0] mtvec;

	// Machine Trap Handling
	reg [`XLEN-1:0] mscratch;
	reg [`XLEN-1:0] mepc;
	reg [`XLEN-1:0] mcause;
	reg [`XLEN-1:0] mtval;

	// Getting value to write according to instruction's f3
	always@(*) begin
		case(i_Funct3[1:0])
			2'b01: write_data =  i_Wd;
			2'b10: write_data =  i_Wd | o_Rd;
			2'b11: write_data = ~i_Wd & o_Rd; 
			default: write_data = 0;
		endcase
	end

	// NFI => Not Fully Implemented
	// Write
	always@(posedge i_clk) begin
		if(i_CSR_en) begin
			// Implementing ECALL here. Please notice that i_Ex comes from
			// Main Control
			if(i_Funct3 == `PRIV) begin
					if(i_addr == 12'b0) begin 
						mcause <= 11; // Environment call from M-mode
						mepc <= i_PC;
					end
					if(i_addr == 12'h001) begin // Ebreak exception
						mcause <= 3;
						mepc <= i_PC;
					end 
			end
			else begin
				case(i_addr)
					// Machine Trap Setup
					`medeleg : begin // NFI - Just Storing values. Its real function is not implemented yet
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
			if(i_Ex) begin
				mepc <= i_PC;
				mcause <= 2; // Illegal Instruction
			end
			if(i_Ex_inst_addr) begin
				mepc <= i_PC;
				mtval <= i_badaddr;
				mcause <= 0; // Instruction address misaligned
			end
			if(i_Ex_ld_addr) begin
				mepc <= i_PC;
				mtval <= i_badaddr;
				mcause <= 4; // Load address misaligned
			end
			if(i_Ex_st_addr) begin
				mepc <= i_PC;
				mtval <= i_badaddr;
				mcause <= 6; // Store address misaligned
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
		if(i_Funct3 == `PRIV && i_CSR_en) begin // Checking if there is a MRET instruction
			case(i_addr)
				12'h000: ex_ecall = 1; // ECALL
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
			case(i_addr)
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
