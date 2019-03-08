`timescale 1ns / 1ps

`include "defines.vh"

//OPCodes
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

module MAIN_CONTROL(
    output reg o_Branch,
    output reg o_MemRead,
    output reg o_MemWrite,
    output reg o_MemToReg,
    output reg [2:0] o_ALUOp,
    output reg [1:0] o_ALUSrcA,
    output reg o_ALUSrcB,
    output reg o_RegWrite,
    output reg [1:0] o_Jump,
    output reg o_PCplus4,
    output reg o_CSR_en,
    output reg o_Ex,

    /* verilator lint_off UNUSED */
    input [`INSTRUCTION_SIZE:0] i_Instr,
    /* verilator lint_on UNUSED */
    input i_Stall
    );
	
	wire [6:0] OPCode = i_Instr[6:0];
	wire [2:0] f3 = i_Instr[14:12];
	wire [11:0] f12 = i_Instr[31:20];
	wire [4:0] rs1 = i_Instr[19:15];
	wire [4:0] rd = i_Instr[11:7];

	always @(*) begin
    	o_Ex = 0; // No exception
    	if(i_Stall) begin
			o_Branch   = 0;
			o_MemRead  = 0;
			o_MemWrite = 0;
			o_MemToReg = 0;
			o_ALUSrcA  = 0;
			o_ALUSrcB  = 0;
			o_RegWrite = 0;
			o_ALUOp    = 3'b000;
	    	o_Jump 	   = 0;
	    	o_PCplus4  = 0;
	    	o_CSR_en   = 0;
    	end
    	else begin
			case(OPCode)
				`OP_R_TYPE : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 0;
					o_RegWrite = 1;
					o_ALUOp    = 3'b010;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;
				end

				`OP_I_TYPE : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b011;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;
				end

				`OP_I_L_TYPE : begin
					o_Branch   = 0;
					o_MemRead  = 1;
					o_MemWrite = 0;
					o_MemToReg = 1;
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b000;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;
				end

				`OP_S_TYPE : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 1;
					o_MemToReg = 1'bx; //Don't Care
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 1;
					o_RegWrite = 0;
					o_ALUOp    = 3'b000;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;    			
				end

				`OP_B_TYPE : begin
					o_Branch   = 1;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 1'bx; //Don't Care
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 0;
					o_RegWrite = 0;
					o_ALUOp    = 3'b001;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;    			
				end

				`OP_U_TYPE_LUI : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 2;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;    			
				end

				`OP_U_TYPE_AUIPC : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 1;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;
				end

				`OP_J_TYPE_JAL : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 1'bx;
					o_ALUSrcA  = 2'bx;
					o_ALUSrcB  = 1'bx;
					o_RegWrite = 1;
					o_ALUOp    = 3'bxxx; // Don't use ALU
	    			o_Jump 	   = 1;
	    			o_PCplus4  = 1;
	    			o_CSR_en   = 0;
				end

				`OP_J_TYPE_JALR : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 1'bx;
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 1;
					o_RegWrite = 1;
					o_ALUOp    = 3'b100; // Use ALU as ADD due to U-Type (Check ALU_CONTROL)
	    			o_Jump 	   = 2;
	    			o_PCplus4  = 1;
	    			o_CSR_en   = 0;
				end

				`OP_FENCE : begin // Do nothing - NOP
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 0;
					o_ALUSrcB  = 0;
					o_RegWrite = 0;
					o_ALUOp    = 3'b000;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 0;

				end
				
				`OP_SYSTEM_TYPE : begin
					o_Branch   = 0;
					o_MemRead  = 0;
					o_MemWrite = 0;
					o_MemToReg = 0;
					o_ALUSrcA  = 2'bx;
					o_ALUSrcB  = 1'bx;
					o_RegWrite = 1;
					o_ALUOp    = 3'bxxx;
	    			o_Jump 	   = 0;
	    			o_PCplus4  = 0;
	    			o_CSR_en   = 1;
	    			o_Ex	   = (f3 == 0 && (f12 == 0 || f12 == 1) && rs1 == 0 && rd == 0) ? 1 : 0; // Checking if it was an ECALL or not

				end

				default : begin // Invalid instruction!
					o_Branch   = 1'b0;
					o_MemRead  = 1'b0;
					o_MemWrite = 1'b0;
					o_MemToReg = 1'b0; //Don't Care
					o_ALUSrcA  = 2'b0;
					o_ALUSrcB  = 1'b0;
					o_RegWrite = 1'b0;
					o_ALUOp    = 3'b0;
	    			o_Jump 	   = 2'b00; 
	    			o_PCplus4  = 1'b0;
	    			o_CSR_en   = 0;
	    			o_Ex	   = 1'b1; // Go to mtvec
				end
			endcase
		end
	end

endmodule
