#include "ISA.h"

ISA::ISA() {
	this->build_table();
}

ISA::~ISA() {
	//delete[] this->instructions;
}

uint64_t ISA::get_inst_count() {
	uint64_t inst_issued = 0;

	for(uint32_t i = 0; i <= INVALID; i++) {
		inst_issued += instructions[i]->get_counter();
	}
	return inst_issued;
}

void ISA::inc_inst(uint32_t inst, uint32_t cycles) {
	inst_t type;

	type = this->inst_decode(inst);
	this->inc_inst_type(type, cycles);
}

void ISA::inc_inst_type(inst_t type, uint32_t cycles) {
	instructions[type]->increment(cycles);
}

inst_t ISA::inst_decode(uint32_t inst) { 
	inst_t type = INVALID;

	if(type == INVALID) { type = rv32i_dec(inst); }
	if(type == INVALID) { type = rv32m_dec(inst); }
	if(type == INVALID) { type = rv32a_dec(inst); }

	return type;
}

void ISA::print_report() {
	std::cout << "--- ISA Report ---" << std::endl;
	std::cout << "Instructions issued: " << this->get_inst_count() << std::endl;
	
	for(uint32_t i = 0; i <= INVALID; i++) {
		instructions[i]->print_report();
	}
}


void ISA::save_report(std::fstream &file) {
	file << "<isa>" << std::endl;	
	
	for(uint32_t i = 0; i <= INVALID; i++) {
		instructions[i]->save_report(file);
	}
	
	file << "</isa>" << std::endl;	
}

// --- Private Methods --- //

inst_t ISA::rv32i_dec(uint32_t inst) {
	uint32_t opcode, f3, f7;
	inst_t type = INVALID;
	opcode = get_opcode(inst);

	switch(opcode) {
		case OP_R_TYPE:  		type = dec_R_TYPE(inst); 		break;
		case OP_I_TYPE:  		type = dec_I_TYPE(inst); 		break;
		case OP_I_L_TYPE:  		type = dec_I_L_TYPE(inst); 		break;
		case OP_S_TYPE:  		type = dec_S_TYPE(inst); 		break;
		case OP_B_TYPE:  		type = dec_B_TYPE(inst); 		break;
		case OP_U_TYPE_LUI:  	type = LUI; 					break;
		case OP_U_TYPE_AUIPC:  	type = AUIPC;  					break;
		case OP_J_TYPE_JAL:  	type = JAL;  					break;
		case OP_J_TYPE_JALR:  	type = JALR; 					break;
		case OP_SYSTEM_TYPE:  	type = dec_SYSTEM_TYPE(inst); 	break;
		case OP_FENCE_TYPE:  	type = FENCE; 					break;
	}

	return type;
}

inst_t ISA::rv32m_dec(uint32_t inst) {
	uint32_t opcode, f3, f7;
	inst_t type = INVALID;
	
	opcode = get_opcode(inst);

	if(opcode == OP_R_TYPE) {
		f3 = get_f3(inst);
		switch(f3) {
			case 0b000: type = MUL;  	break;
			case 0b001: type = MULH;  	break;
			case 0b010: type = MULHSU; 	break;
			case 0b011: type = MULHU; 	break;
			case 0b100: type = DIV;	  	break;
			case 0b101: type = DIVU; 	break;
			case 0b110: type = REM; 	break;
			case 0b111: type = REMU; 	break;
		}
	}
	
	return type;
}

inst_t ISA::rv32a_dec(uint32_t inst) {
	uint32_t opcode, f7;
	inst_t type = INVALID;

	opcode = get_opcode(inst);

	if(opcode == OP_ATOMIC) {
		f7 = get_f7(inst);
		f7 = f7 >> 2; // Removing aq and rl bits

		switch(f7) {
			case 0b00010: type = LR_W; 		break;
			case 0b00011: type = SC_W; 		break;
			case 0b00001: type = AMOSWAP_W; break;
			case 0b00000: type = AMOADD_W; 	break;
			case 0b00100: type = AMOXOR_W; 	break;
			case 0b01100: type = AMOAND_W; 	break;
			case 0b01000: type = AMOOR_W; 	break;
			case 0b10000: type = AMOMIN_W;  break;
			case 0b10100: type = AMOMAX_W; 	break;
			case 0b11000: type = AMOMINU_W; break;
			case 0b11100: type = AMOMAXU_W; break;
		}
	}

	return type;
}

inst_t ISA::dec_R_TYPE(uint32_t inst) {
	uint32_t f3, f7;
	inst_t type = INVALID;

	f3 = get_f3(inst);
	f7 = get_f7(inst);
	if(f7 == 0 || f7 == 0b0100000) {
		switch(f3) {
			case 0: type = !f7 ? ADD : SUB; break;
			case 1: type = SLL; break;
			case 2: type = SLT; break;
			case 3: type = SLTU; break;
			case 4: type = XOR; break;
			case 5: type = !f7 ? SRL : SRA;  break;
			case 6: type = OR; break;
			case 7: type = AND; break;
		}
	}

	return type;
}

inst_t ISA::dec_I_TYPE(uint32_t inst) {
	uint32_t f3, f7;
	inst_t type = INVALID;

	f3 = get_f3(inst);
	f7 = get_f7(inst); 

	switch(f3) {
		case 0b000: type = ADDI; break;
		case 0b010: type = SLTI; break;
		case 0b011: type = SLTIU; break;
		case 0b100: type = XORI; break;
		case 0b110: type = ORI; break;
		case 0b111: type = ANDI; break;
		case 0b001: type = SLLI; break;
		case 0b101: type = !f7 ? SRLI : SRAI; break;
	}

	return type;
}

inst_t ISA::dec_I_L_TYPE(uint32_t inst) { // Decoding load instructions
	uint32_t f3;
	inst_t type = INVALID;

	f3 = get_f3(inst);

	switch(f3) {
		case 0b000: type = LB;  break;
		case 0b001: type = LH;  break;
		case 0b010: type = LW;  break;
		case 0b100: type = LBU; break;
		case 0b101: type = LHU; break;
	}	

	return type;
}

inst_t ISA::dec_S_TYPE(uint32_t inst) {
	uint32_t f3;
	inst_t type = INVALID;

	f3 = get_f3(inst);

	switch(f3) {
		case 0b000: type = SB;  break;
		case 0b001: type = SH;  break;
		case 0b010: type = SW;  break;
	}	

	return type;	
}

inst_t ISA::dec_B_TYPE(uint32_t inst) {
	uint32_t f3, f7;
	inst_t type = INVALID;

	f3 = get_f3(inst);
	f7 = get_f7(inst);
	
	switch(f3) {
		case 0b000: type = BEQ;  break;
		case 0b001: type = BNE;  break;
		case 0b100: type = BLT;  break;
		case 0b101: type = BGE;  break;
		case 0b110: type = BLTU; break;
		case 0b111: type = BGEU; break;
	}

	return type;
}

inst_t ISA::dec_SYSTEM_TYPE(uint32_t inst) {
	uint32_t f3, f12;
	inst_t type = INVALID;

	f3 = get_f3(inst);
	f12 = inst >> 25;

	switch(f3) {
		case 0b000: 	
			if(f12 == 0) type = ECALL;
			if(f12 == 1) type = EBREAK;
		break;
		case 0b001: type = CSRRW;  break;
		case 0b010: type = CSRRS;  break;
		case 0b011: type = CSRRC;  break;
		case 0b101: type = CSRRWI; break;
		case 0b110: type = CSRRSI; break;
		case 0b111: type = CSRRCI; break;
	}
	return type;
}

uint32_t ISA::get_opcode(uint32_t inst) {
	uint8_t mask = 0b1111111;
	return inst & mask;
} 
 
uint32_t ISA::get_f3(uint32_t inst) {
	uint8_t mask = 0b111;
	return (inst>>12) & mask;
}

uint32_t ISA::get_f7(uint32_t inst) {
	uint8_t mask = 0b1111111;
	return (inst>>25) & mask;
} 


void ISA::build_table() {
	// RV32I
	instructions[LUI]       = new Instruction(LUI, "LUI");
	instructions[AUIPC]     = new Instruction(AUIPC, "AUIPC");
	instructions[JAL]       = new Instruction(JAL, "JAL");
	instructions[JALR]      = new Instruction(JALR, "JALR");

	instructions[BEQ]       = new Instruction(BEQ, "BEQ");
	instructions[BNE]       = new Instruction(BNE, "BNE");
	instructions[BLT]       = new Instruction(BLT, "BLT");
	instructions[BGE]       = new Instruction(BGE, "BGE");
	instructions[BLTU]      = new Instruction(BLTU, "BLTU");
	instructions[BGEU]      = new Instruction(BGEU, "BGEU");

	instructions[LB]        = new Instruction(LB, "LB");
	instructions[LH]        = new Instruction(LH, "LH");
	instructions[LW]        = new Instruction(LW, "LW");
	instructions[LBU]       = new Instruction(LBU, "LBU");
	instructions[LHU]       = new Instruction(LHU, "LHU");
	instructions[SB]        = new Instruction(SB, "SB");
	instructions[SH]        = new Instruction(SH, "SH");
	instructions[SW]        = new Instruction(SW, "SW");

	instructions[ADDI]      = new Instruction(ADDI, "ADDI");
	instructions[SLTI]      = new Instruction(SLTI, "SLTI");
	instructions[SLTIU]     = new Instruction(SLTIU, "SLTIU");
	instructions[XORI]      = new Instruction(XORI, "XORI");
	instructions[ORI]       = new Instruction(ORI, "ORI");
	instructions[ANDI]      = new Instruction(ANDI, "ANDI");
	instructions[SLLI]      = new Instruction(SLLI, "SLLI");
	instructions[SRLI]      = new Instruction(SRLI, "SRLI");
	instructions[SRAI]      = new Instruction(SRAI, "SRAI");

	instructions[ADD]       = new Instruction(ADD, "ADD");
	instructions[SUB]       = new Instruction(SUB, "SUB");
	instructions[SLL]       = new Instruction(SLL, "SLL");
	instructions[SLT]       = new Instruction(SLT, "SLT");
	instructions[SLTU]      = new Instruction(SLTU, "SLTU");
	instructions[XOR]       = new Instruction(XOR, "XOR");
	instructions[SRL]       = new Instruction(SRL, "SRL");
	instructions[SRA]       = new Instruction(SRA, "SRA");
	instructions[OR]        = new Instruction(OR, "OR");
	instructions[AND]       = new Instruction(AND, "AND");

	instructions[FENCE]     = new Instruction(FENCE, "FENCE");

	instructions[ECALL]     = new Instruction(ECALL, "ECALL");
	instructions[EBREAK]    = new Instruction(EBREAK, "EBREAK");
	instructions[CSRRW]     = new Instruction(CSRRW, "CSRRW");
	instructions[CSRRS]     = new Instruction(CSRRS, "CSRRS");
	instructions[CSRRC]     = new Instruction(CSRRC, "CSRRC");
	instructions[CSRRWI]    = new Instruction(CSRRWI, "CSRRWI");
	instructions[CSRRSI]    = new Instruction(CSRRSI, "CSRRSI");
	instructions[CSRRCI]    = new Instruction(CSRRCI, "CSRRCI");

	// RV32M
	instructions[MUL]       = new Instruction(MUL, "MUL");
	instructions[MULH]      = new Instruction(MULH, "MULH");
	instructions[MULHSU]    = new Instruction(MULHSU, "MULHSU");
	instructions[MULHU]     = new Instruction(MULHU, "MULHU");
	instructions[DIV]       = new Instruction(DIV, "DIV");
	instructions[DIVU]      = new Instruction(DIVU, "DIVU");
	instructions[REM]       = new Instruction(REM, "REM");
	instructions[REMU]      = new Instruction(REMU, "REMU");

	// RV32A
	instructions[LR_W]      = new Instruction(LR_W, "LR_W");
	instructions[SC_W]      = new Instruction(SC_W, "SC_W");
	instructions[AMOSWAP_W] = new Instruction(AMOSWAP_W, "AMOSWAP_W");
	instructions[AMOADD_W]  = new Instruction(AMOADD_W, "AMOADD_W");
	instructions[AMOXOR_W]  = new Instruction(AMOXOR_W, "AMOXOR_W");
	instructions[AMOAND_W]  = new Instruction(AMOAND_W, "AMOAND_W");
	instructions[AMOOR_W]   = new Instruction(AMOOR_W, "AMOOR_W");
	instructions[AMOMIN_W]  = new Instruction(AMOMIN_W, "AMOMIN_W");
	instructions[AMOMAX_W]  = new Instruction(AMOMAX_W, "AMOMAX_W");
	instructions[AMOMINU_W] = new Instruction(AMOMINU_W, "AMOMINU_W");
	instructions[AMOMAXU_W] = new Instruction(AMOMAXU_W, "AMOMAXU_W");


	instructions[INVALID] = new Instruction(INVALID, "INVALID");
}
