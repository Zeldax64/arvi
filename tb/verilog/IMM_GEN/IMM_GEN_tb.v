`timescale 1ns / 1ps

module IMM_GEN_tb;
	/*----- Local Parameters -----*/
	localparam NUM_TESTS = 10000; // Number of tests
	
	// Opcodes
	localparam I_TYPE_LW   = 3;
	localparam I_TYPE_DATA = 19;
	localparam S_TYPE      = 35;
	localparam B_TYPE      = 99;

	localparam INSTRUCTION_SIZE = 31;
	localparam EXTENSION_SIZE   = 31;

	// Inputs
	reg [31:0] i_instr;

	// Outputs
	wire [31:0] o_ext;

	/*----- UUT instatiantion -----*/
	IMM_GEN uut (
		.i_Instr(i_instr), 
		.o_Ext(o_ext)
	);

	/*----- Functions -----*/

	/*----- Taks -----*/
	/*
		Generates a random instruction.
	*/
	task automatic gen_inst;
		input [6:0] opcode; 

		output reg [INSTRUCTION_SIZE:0] instr;
		output reg [EXTENSION_SIZE:0] ext;
		
		reg [11:0] imm;
		reg [4:0] rs1;
		reg [4:0] rs2;
		reg [4:0] rd;
		reg [2:0] f3;
		
		begin
			rs1 = $random%31;
			rs2 = $random%31;
			rd  = $random%31;
			f3  = $random%7;
			imm = $random%(2**12-1);

			ext = {{EXTENSION_SIZE - 11{imm[11]}}, imm[11:0]};
			case(opcode)
				I_TYPE_LW:	 instr = {imm, rs1, f3, rd, opcode};
				I_TYPE_DATA: instr = {imm[11:0], rs1, f3, rd, opcode};
				S_TYPE: 	 instr = {imm[11:5], rs2, rs1, f3, imm[4:0], opcode};
				B_TYPE: 	 instr = {imm[11], imm[9:4], rs2, rs1, f3, imm[3:0], imm[10], opcode};
				default: $display("TB:GEN_INST:CASE> Default reached for opcode = %d! NOT A VALID OPCODE", opcode);
			endcase // opcode
		end
	endtask

	integer i;
	task automatic test_imm;
		input [6:0] opcode;

		reg [INSTRUCTION_SIZE:0] instr;
		reg [EXTENSION_SIZE:0] ex_imm;

		begin
			i = 0;
			repeat(NUM_TESTS) begin
				gen_inst(opcode, instr, ex_imm);
				i_instr = instr;
				#10;
				$display("%d: exp: %d    got: %d", i, ex_imm, o_ext);
				if(ex_imm !== o_ext) begin
					$display("> Failed <");
					$display("Expected: %b | Got: %b", ex_imm, o_ext);
					$finish;
				end 	
				i = i+1;
			end
		end 
	endtask

	initial begin
		// Initialize Inputs
		i_instr = 0;

		// Initialize Test Variables
		#100;
        
        $display("Test: I_TYPE_LW");
	    test_imm(I_TYPE_LW);
        $display("Test: I_TYPE_DATA");
	    test_imm(I_TYPE_DATA);
        $display("Test: I_TYPE_S");
	    test_imm(S_TYPE);
        $display("Test: I_TYPE_B");
	    test_imm(B_TYPE);
    
		$finish;
	end
      
endmodule

