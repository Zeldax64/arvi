#pragma once

#include <iostream>
#include <string>
#include <stdint.h>

#include "Instruction.h"

typedef enum inst_t {
	LUI,
	AUIPC,
	JAL,
	JALR,
	BEQ, BNE, BLT, BGE, BLTU, BGEU, // 9
	LB, LH,	LW,	LBU, LHU, // 5
	SB,	SH,	SW, // 3
	ADDI, SLTI,	SLTIU, XORI, ORI, ANDI, SLLI, SRLI,	SRAI, // 9
	ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, // 10
	FENCE,
	ECALL,
	EBREAK,
	INVALID
} inst_t;

typedef enum opcode_t {
	OP_R_TYPE 		= 0b0110011,
	OP_I_TYPE 		= 0b0010011,
	OP_I_L_TYPE		= 0b0000011,
	OP_S_TYPE 		= 0b0100011,
	OP_B_TYPE 		= 0b1100011,
	OP_U_TYPE_LUI 	= 0b0110111,
	OP_U_TYPE_AUIPC = 0b0010111,
	OP_J_TYPE_JAL	= 0b1101111,
	OP_J_TYPE_JALR	= 0b1100111,
	OP_SYSTEM_TYPE	= 0b1110011,
	OP_FENCE_TYPE	= 0b0001111	
} opcode_t;

class ISA {
	Instruction *instructions[INVALID+1];

public:
	ISA();
	~ISA();
	uint64_t get_inst_count();
	void inc_inst(uint32_t inst, uint32_t cycles);
	void inc_inst_type(inst_t type, uint32_t cycles);
	inst_t inst_decode(uint32_t inst);
	void print_report();
	
private:
	uint32_t get_opcode(uint32_t inst);
	uint32_t get_f3(uint32_t inst);
	uint32_t get_f7(uint32_t inst);
	inst_t dec_R_TYPE(uint32_t inst);
	inst_t dec_I_TYPE(uint32_t inst);
	inst_t dec_I_L_TYPE(uint32_t inst);
	inst_t dec_S_TYPE(uint32_t inst);
	inst_t dec_B_TYPE(uint32_t inst);
	inst_t dec_SYSTEM_TYPE(uint32_t inst);
	void build_table();
};