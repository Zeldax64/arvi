`timescale 1ns / 1ps

`include "defines.vh"
`define EXTENSION_SIZE (`XLEN-1)

// Instruction types
`define I_TYPE_LW (3) 	  // 3 to LW and 19 to other immeadite instructions
`define I_TYPE_DATA (19)  // 19 to data instructions
`define I_TYPE `I_TYPE_LW, `I_TYPE_DATA

`define S_TYPE (35) 	  // Store
`define B_TYPE (99) 	  // Branches

`define U_TYPE_LUI (55)	  // LUI
`define U_TYPE_AUIPC (23) // AUIPC
`define U_TYPE `U_TYPE_LUI, `U_TYPE_AUIPC

`define J_TYPE_JAL (111)  // JAL  - J-immediate
`define J_TYPE_JALR (103) // JALR - I-immediate

`define SYSTEM_TYPE 7'b1110011

module IMM_GEN(
	input  [`INSTRUCTION_SIZE:0] i_Instr,
	output reg [`XLEN-1:0] o_Ext
    );

	wire [6:0]op;

	assign op = i_Instr[6:0];

	/*----- Taks -----*/
	// Sign extension with 12 bits - I-immediate
	task extend_I;
		input [11:0] imm;
		begin
			o_Ext = { {`EXTENSION_SIZE - 11{imm[11]}}, imm[11:0] };
		end
	endtask

	// Sign extension with 19 bits - J-immediate
	task extend_J;
		input [19:0] imm;
		begin
			o_Ext = { {`EXTENSION_SIZE - 19{imm[19]}}, imm[19:0] };
		end
	endtask

	// Sign extension with 20 bits - U-immediate
	task extend_U;
		input [19:0] imm;
		begin
			o_Ext = { imm[19:0], 12'b0 };
		end
	endtask
	/*----------------*/

	always@(*) begin
		case(op)
			`I_TYPE: 	  extend_I(i_Instr[31:20]);
			`S_TYPE: 	  extend_I({i_Instr[31:25], i_Instr[11:7]});
			`B_TYPE: 	  extend_I({i_Instr[31], i_Instr[7], i_Instr[30:25], i_Instr[11:8]});
			`U_TYPE: 	  extend_U(i_Instr[31:12]);
			`J_TYPE_JAL:  extend_J({i_Instr[31], i_Instr[19:12], i_Instr[20], i_Instr[30:21]});
			`J_TYPE_JALR: extend_I(i_Instr[31:20]);
			`SYSTEM_TYPE: o_Ext = {{`XLEN-5{1'b0}}, i_Instr[19:15]};
			default: extend_I(12'b0);
		endcase
	end


endmodule
