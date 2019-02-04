/*
	ALU.v

	Várias instruções dependem na verdade de apenas poucas operações.
	Operações implementadas:
		- ADD
		- SUB (ADD com entrada invertida)
		- SLL
		- SLT
		- SLUT
		- XOR
		- SRL (Mesmo OP de SRA mas se difere no bit30)
		- SRA
		- OR
		- AND

	ADD e SUB possuem o mesmo op (funct3 no manual do RISC-V) e são desambiguadas
	pelo sinal do bit 30 da instrução. O mesmo ocorre com SRL e SRA.
	Formato adotado de op: {bit30, fucnt3}

	Implementações de ALU no git:
	https://github.com/cliffordwolf/picorv32/blob/master/picorv32.v
	https://github.com/onchipuis/mriscvcore/blob/1e94fa95bcdddb889be205ed661b9addff1221a4/ALU/ALU.v

*/
`timescale 1ns / 1ps

`include "modules/ALU/ALU_DEFINES.vh"
`include "defines.vh"

module ALU(
	input  [3:0]  i_op,
	input  [`XLEN-1:0] i_Ra,
	input  [`XLEN-1:0] i_Rb,

	output o_Z, // Z Flag
	output reg [`XLEN-1:0] o_Rc  // Verificar se deixa o carry atrelado a Rc ou o coloca em um sinal separado
);

	always@(*) begin
		case(i_op)
			`ALU_ADD:  o_Rc = i_Ra + i_Rb;
			`ALU_SUB:  o_Rc = i_Ra - i_Rb;
			`ALU_SLL:  o_Rc = i_Ra << i_Rb[4:0];
			`ALU_SLT:  o_Rc = {{`XLEN-1{1'b0}}, $signed(i_Ra) < $signed(i_Rb)}; //($signed(i_Ra) < $signed(i_Rb)) ?
			`ALU_SLTU: o_Rc = {{`XLEN-1{1'b0}}, i_Ra < i_Rb};
			`ALU_XOR:  o_Rc = i_Ra ^ i_Rb;
			`ALU_SRL:  o_Rc = i_Ra >>  i_Rb[4:0];
			`ALU_SRA:  o_Rc = $signed(i_Ra) >>> i_Rb[4:0];
			`ALU_OR:   o_Rc = i_Ra | i_Rb;
			`ALU_AND:  o_Rc = i_Ra & i_Rb;
			default:   o_Rc = `XLEN'bx;
		endcase
	end

	assign o_Z = o_Rc == 0;

endmodule
