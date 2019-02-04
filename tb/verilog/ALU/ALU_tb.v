/* 
	ALU_tb.v

	Test bench para ALU.v


*/
`timescale 1ns / 1ps

`include "rtl/modules/ALU/ALU_DEFINES.vh"

module ALU_tb;
	/*----- Local Parameters -----*/
	localparam NUM_TESTS = 100000; // Number of tests

	/*----- Variables -----*/
	reg [3:0] op;
	reg [31:0] Ra;
	reg [31:0] Rb;
	wire [32:0] Rc;
	wire Z;

	/*----- Test Variables -----*/
	reg alu_ok;

	reg [32:0] Rc_expected;
	reg Z_expected;
	/*----- DUT instatiantion -----*/
	ALU dut (.i_op(op), .i_Ra(Ra), .i_Rb(Rb), .o_Z(Z), .o_Rc(Rc));

	/*----- Functions -----*/
	/*
		Função que possibiltia a execução de todas as funções da ALU a partir de uma operação
		definida por operation.
	*/
	function automatic [32:0]do_op;
		input [31:0] a, b;		// Operandos
		input [3:0] operation;  // Operação
		
		case(operation)
			`ALU_ADD:  do_op = Ra + Rb;			
			`ALU_SUB:  do_op = Ra - Rb;
			`ALU_SLL:  do_op = Ra << Rb[4:0];
			`ALU_SLT:  do_op = $signed(Ra) < $signed(Rb); //($signed(Ra) < $signed(Rb)) ?
			`ALU_SLTU: do_op = Ra < Rb;
			`ALU_XOR:  do_op = Ra ^ Rb;
			`ALU_SRL:  do_op = Ra >>  Rb[4:0];
			`ALU_SRA:  do_op = Ra >>> Rb[4:0];
			`ALU_OR:   do_op = Ra | Rb;
			`ALU_AND:  do_op = Ra & Rb;
		endcase
				
	endfunction

	/*----- Tasks -----*/
	/*
		Task para teste de operações regulares, ou seja, em que o Rb pode ser até um valor
		de 32 bits.
	*/
	integer i;
	task test_regularop;
		input [3:0] operand;

		begin
			i = 1;
			op = operand;
			repeat(NUM_TESTS) begin
				//Ra = $random % 2**32; // Test this random on Icarus Verilog
				//Rb = $random % 2**32;
				Ra = $random;
				Rb = $random;
				#10;
				Rc_expected = do_op(Ra, Rb, operand);
				update_flags();
				if(Rc_expected !== Rc) begin
					$display("Error: Rc = %d, Rc_expected = %d, op: %b", Rc, Rc_expected, op);
					alu_ok = 1;
				end
				check_flags();
			end
		end	
	endtask

	/*
		Task para o teste de operações de shift. Esse tipo de instrução se distingue das
		regulares pois apresentam um limite de Rb[4:0] representado na documentação por
		shift ammount.
	*/
	task test_shiftop;
		input [3:0] operand;

		integer i;
		begin
			op = `ALU_SRL;
			repeat(NUM_TESTS) begin
				//Ra = $random % 2**32; // Also test this random
				Ra = $random;
				for(i = 0; i < 32; i = i + 1) begin
					Rb = i;
					Rc_expected = do_op(Ra, Rb, `ALU_SRL);
					update_flags();
					#10;
					if(Rc_expected !== Rc) begin
						$display("Error: Rc = %d, Rc_expected = %d, op: %b", Rc, Rc_expected, op);
						alu_ok = 0;
					end
					check_flags();
				end	
			end
		end
	endtask

	/*
		Task to update flag signals.
	*/
	task update_flags;
		begin
			Z_expected = Rc_expected[31:0] == 0;
		end
	endtask

	/*
		Task to check flag signals.
	*/
	task check_flags;
		begin
			if(Z_expected !== Z) begin
				$display("Flag Z Failed> OP: %d Ra: %d Rb: %d", op, Ra, Rb);
				alu_ok = 0;
			end
		end
	endtask

	/*
		Task to report whether the tests were successful or not.
	*/
	task report_tests;
		begin
			if(alu_ok === 0)
				$display("--- ALU Tests Success ---");
			else
				$display("--- ALU Tests Failed ---");
		end
	endtask
	
	/*----- Tests -----*/
	initial begin
		// Initialize inputs
		op = 0;
		Ra = 0;
		Rb = 0;

		alu_ok = 1;
		Rc_expected = 0;
		Z_expected = 0;
		// Initialize test variables
		$display("--- ALU Tests Begin ---");
		#100; 
		test_regularop(`ALU_ADD);
		test_regularop(`ALU_SUB);
		test_regularop(`ALU_SLT);
		test_regularop(`ALU_SLTU);
		test_regularop(`ALU_XOR);
		test_regularop(`ALU_OR);
		test_regularop(`ALU_AND);

		test_shiftop(`ALU_SLL);
		test_shiftop(`ALU_SRL);
		test_shiftop(`ALU_SRA);
		report_tests();
		//$dumpall;
		//$dumpflush;
		$finish;
	end // initial

	// Initial to dump variables
	initial begin
		//$dumpfile("ALU_tb.vcd");
		//$dumpvars;
	end // initial

endmodule