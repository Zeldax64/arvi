`timescale 1ns / 1ps

`include "arvi_defines.svh"

//OPCodes
// RV-I
`define OP_R_TYPE 		7'b0110011
`define OP_I_TYPE 		7'b0010011
`define OP_I_L_TYPE		7'b0000011
`define OP_S_TYPE 		7'b0100011
`define OP_B_TYPE 		7'b1100011
`define OP_U_TYPE_LUI 	7'b0110111
`define OP_U_TYPE_AUIPC 7'b0010111
`define OP_J_TYPE_JAL	7'b1101111
`define OP_J_TYPE_JALR	7'b1100111
`define OP_SYSTEM_TYPE	7'b1110011
`define OP_FENCE		7'b0001111

`ifdef __RVA
// RV-A
`define OP_ATOMIC 		7'b0101111
`endif


module main_control (
	/* verilator lint_off UNUSED */
    input [`INSTRUCTION_SIZE:0] i_Instr,
	/* verilator lint_on UNUSED */
    
    output logic o_Branch,
    output logic o_MemRead,
    output logic o_MemWrite,
    output logic o_MemToReg,
    output logic [2:0] o_ALUOp,
    output logic [1:0] o_ALUSrcA,
    output logic o_ALUSrcB,
    output logic o_RegWrite,
    output logic [1:0] o_Jump,
    output logic o_PCplus4,
    output logic o_CSR_en,
    output logic o_Ex_inst_illegal,

`ifdef __RVA
	output logic o_atomic,
`endif
`ifdef __RVM
	output logic o_ALUM_en,
`endif

    input i_Stall
    );
	
	wire [6:0] OPCode = i_Instr[6:0];
	//wire [2:0] f3 = i_Instr[14:12];
	/* verilator lint_off UNUSED */
	wire [6:0] f7 = i_Instr[31:25];
	/* verilator lint_on UNUSED */
	//wire [11:0] f12 = i_Instr[31:20];
	//wire [4:0] rs1 = i_Instr[19:15];
	//wire [4:0] rd = i_Instr[11:7];

	always_comb begin
		o_Branch          = 0;
		o_MemRead         = 0;
		o_MemWrite        = 0;
		o_MemToReg        = 0;
		o_ALUSrcA         = 0;
		o_ALUSrcB         = 0;
		o_RegWrite        = 0;
		o_ALUOp           = 3'b000;
        o_Jump            = 0;
		o_PCplus4         = 0;
		o_CSR_en          = 0;
		o_Ex_inst_illegal = 0; // Illegal instruction signal

`ifdef __RVA
		o_atomic = 0; // RV-A
`endif
`ifdef __RVM
       o_ALUM_en = 0; // RV-M signal
`endif

    	if(i_Stall) begin
    	end
    	else begin
			case(OPCode)
				`OP_R_TYPE : begin
					o_RegWrite = 1;
					o_ALUOp    = 3'b010;
`ifdef __RVM
					if(f7[0]) begin
						//o_ALUOp    = 3'b000; // Don't care
						o_ALUM_en  = 1;
					end
`endif
				end

				`OP_I_TYPE : begin
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b011;
				end

				`OP_I_L_TYPE : begin
					o_MemRead  = 1;
					o_MemToReg = 1;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
				end

				`OP_S_TYPE : begin
					o_MemWrite = 1;
					o_MemToReg = 1'b0; //Don't Care
					o_ALUSrcB  = 1;
				end

				`OP_B_TYPE : begin
					o_Branch   = 1;
					o_MemToReg = 1'b0; //Don't Care
					o_ALUOp    = 3'b001;
				end

				`OP_U_TYPE_LUI : begin
					o_ALUSrcA  = 2;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100;
				end

				`OP_U_TYPE_AUIPC : begin
					o_ALUSrcA  = 1;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100;
				end

				`OP_J_TYPE_JAL : begin
					o_RegWrite = 1;
					o_ALUOp    = 3'b00; // Don't use ALU
	    			o_Jump 	   = 1;
	    			o_PCplus4  = 1;
				end

				`OP_J_TYPE_JALR : begin
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100; // Use ALU as ADD due to U-Type (Check ALU_CONTROL)
	    			o_Jump 	   = 2;
	    			o_PCplus4  = 1;
				end

				`OP_FENCE : begin // Do nothing - NOP

				end
				
				`OP_SYSTEM_TYPE : begin
					o_MemToReg = 1'b1;
					o_ALUSrcA  = 2'b0;
					o_ALUSrcB  = 1'b0;
					o_RegWrite = 1;
					o_ALUOp    = 3'b101; // Bypass Rd1 through ALU.
	    			o_CSR_en   = 1;
				end

`ifdef __RVA
				`OP_ATOMIC : begin
					o_ALUSrcA  = 2'b0;
					o_ALUSrcB  = 1'b0;
					o_ALUOp    = 3'b101;
					o_RegWrite = 1;
					o_atomic   = 1;
					if(f7[2]) begin // SC
						o_MemRead  = 1; //
						o_MemWrite = 1; //
						o_MemToReg = 1; //
					end
					else begin // LR
						o_MemRead  = 1; //
						o_MemWrite = 0; //
						o_MemToReg = 1; //
					end
				end
`endif

				default : begin // Invalid instruction!
					o_MemToReg        = 1'b0; //Don't Care
	                o_Ex_inst_illegal = 1'b1; // Go to mtvec
				end
			endcase
		end
	end

endmodule
