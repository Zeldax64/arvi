`timescale 1ns / 1ps

//ALU Control Lines
`include "modules/ALU/ALU_DEFINES.vh"

//Funct7
`define F7_TYPE0  7'b0000000
`define F7_TYPE32 7'b0100000

//Funct3
`define F3_TYPE0 3'b000
`define F3_TYPE1 3'b001
`define F3_TYPE2 3'b010
`define F3_TYPE3 3'b011
`define F3_TYPE4 3'b100
`define F3_TYPE5 3'b101
`define F3_TYPE6 3'b110
`define F3_TYPE7 3'b111

//ALUOp
`define ALUOP_MEM 3'b000
`define ALUOP_B   3'b001
`define ALUOP_R   3'b010
`define ALUOP_I   3'b011
`define ALUOP_U	  3'b100
`define ALUOP_S1  3'b101

module ALU_CONTROL(
    output reg [3:0] o_ALUControlLines,
    input [6:0] i_Funct7,
    input [2:0] i_Funct3,
    input [2:0] i_ALUOp
    );

	always @(*) begin
		case(i_ALUOp)
			`ALUOP_MEM : o_ALUControlLines = `ALU_ADD;
			`ALUOP_B :  case(i_Funct3)
							`F3_TYPE0, `F3_TYPE1: o_ALUControlLines = `ALU_SUB;
							`F3_TYPE4, `F3_TYPE5: o_ALUControlLines = `ALU_SLT;
							`F3_TYPE6, `F3_TYPE7: o_ALUControlLines = `ALU_SLTU;
							default: o_ALUControlLines = 4'bx;
						endcase
			`ALUOP_R :
				case(i_Funct3)
					`F3_TYPE0 : 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_ADD;
							`F7_TYPE32 : o_ALUControlLines = `ALU_SUB;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE1: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_SLL;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE2: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_SLT;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE3: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_SLTU;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE4: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_XOR;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE5: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_SRL;
							`F7_TYPE32 : o_ALUControlLines = `ALU_SRA;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE6: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_OR;
							default : o_ALUControlLines = 4'bx;
						endcase
					`F3_TYPE7: 
						case(i_Funct7)
							`F7_TYPE0 : o_ALUControlLines = `ALU_AND;
							default : o_ALUControlLines = 4'bx;
						endcase
					default : o_ALUControlLines = 4'bx;
				endcase
			`ALUOP_I :
				case(i_Funct3)
				`F3_TYPE0: o_ALUControlLines = `ALU_ADD;
				`F3_TYPE1: o_ALUControlLines = `ALU_SLL;					
				`F3_TYPE2: o_ALUControlLines = `ALU_SLT;					
				`F3_TYPE3: o_ALUControlLines = `ALU_SLTU;				
				`F3_TYPE4: o_ALUControlLines = `ALU_XOR;
				`F3_TYPE5: 
					case(i_Funct7)
						`F7_TYPE0 : o_ALUControlLines = `ALU_SRL;
						`F7_TYPE32: o_ALUControlLines = `ALU_SRA;
						default : o_ALUControlLines = 4'bx;
					endcase
										
				`F3_TYPE6: o_ALUControlLines = `ALU_OR;				
				`F3_TYPE7: o_ALUControlLines = `ALU_AND;
				default : o_ALUControlLines = 4'bx;
			endcase
			`ALUOP_U: o_ALUControlLines = `ALU_ADD;
			`ALUOP_S1: o_ALUControlLines = `ALU_S1;
			default : o_ALUControlLines = 4'bx;
		endcase
	end
endmodule
