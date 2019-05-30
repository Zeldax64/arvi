#include "ISA.h"

Instruction *instructions[INVALID];
static uint32_t inst_counter = 0;
static uint32_t load_inst = 0;
static uint32_t store_inst = 0;
static uint32_t fence_inst = 0;
static uint32_t env_inst = 0;
static uint32_t branch_inst = 0;
static uint32_t imm_inst = 0;
static uint32_t r_op_inst = 0;
static uint32_t jal_inst = 0;
static uint32_t jalr_inst = 0;
static uint32_t wrong_op_inst = 0;

static uint32_t instruction_count = 0;

uint32_t get_inst_count() {
	//return inst_counter;
	return 0;
}

uint32_t get_opcode(uint32_t inst) {
	uint8_t mask = 0b1111111;
	return inst & mask;
} 
 
uint32_t get_f3(uint32_t inst) {
	uint8_t mask = 0b111;
	return (inst>>12) & mask;
}

uint32_t get_f7(uint32_t inst) {
	uint8_t mask = 0b1111111;
	return (inst>>25) & mask;
} 

void inc_inst_type(inst_t type) {
	instructions[type]->increment();
}

inst_t inst_decode(uint32_t inst) { 
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


inst_t dec_R_TYPE(uint32_t inst) {
	uint32_t f3, f7;
	inst_t type = INVALID;

	f3 = get_f3(inst);
	f7 = get_f7(inst);
	
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

	return type;
}

inst_t dec_I_TYPE(uint32_t inst) {
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

inst_t dec_I_L_TYPE(uint32_t inst) { // Decoding load instructions
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

inst_t dec_S_TYPE(uint32_t inst) {
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

inst_t dec_B_TYPE(uint32_t inst) {
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

inst_t dec_SYSTEM_TYPE(uint32_t inst) {
	uint32_t f12;
	inst_t type = INVALID;

	f12 = inst >> 25;

	if(f12 == 0) type = ECALL;
	if(f12 == 1) type = EBREAK;

	return type;
}

void print_report() {

	std::cout << "--- Program Report ---" << std::endl;
	for(uint32_t i = 0; i < INVALID; i++) {
		//std::cout << instructions[i]->get_name();
		//std::cout << instructions[i]->get_counter() << std::endl;
		std::cout << instructions[i]->get_name() << ": " << instructions[i]->get_counter() << std::endl;		
	}

	/*
	std::cout << "Instructions executed: " << inst_counter << std::endl;
	std::cout << "r_op: " << r_op_inst << std::endl;
	std::cout << "imm: " << imm_inst << std::endl;
	std::cout << "load: " << load_inst << std::endl;
	std::cout << "store: " << store_inst << std::endl;
	std::cout << "branch: " << branch_inst << std::endl;
	std::cout << "jal: " << jal_inst << std::endl;
	std::cout << "jalr: " << jalr_inst << std::endl;
	std::cout << "env: " << env_inst << std::endl;
	std::cout << "fence: " << fence_inst << std::endl;
	std::cout << "wrong_op: " << wrong_op_inst << std::endl;
	*/
	build_table();
}

void build_table() {
	instructions[LUI]		= new Instruction(LUI, "LUI");
	instructions[AUIPC]		= new Instruction(AUIPC, "AUIPC");
	instructions[JAL]		= new Instruction(JAL, "JAL");
	instructions[JALR]		= new Instruction(JALR, "JALR");
	instructions[BEQ]		= new Instruction(BEQ, "BEQ");
	instructions[BNE]		= new Instruction(BNE, "BNE");
	instructions[BLT]		= new Instruction(BLT, "BLT");
	instructions[BGE]		= new Instruction(BGE, "BGE");
	instructions[BLTU]		= new Instruction(BLTU, "BLTU");
	instructions[BGEU]		= new Instruction(BGEU, "BGEU");
	instructions[LB]		= new Instruction(LB, "LB");
	instructions[LH]		= new Instruction(LH, "LH");
	instructions[LW]		= new Instruction(LW, "LW");
	instructions[LBU]		= new Instruction(LBU, "LBU");
	instructions[LHU]		= new Instruction(LHU, "LHU");
	instructions[SB]		= new Instruction(SB, "SB");
	instructions[SH]		= new Instruction(SH, "SH");
	instructions[SW]		= new Instruction(SW, "SW");
	instructions[ADDI]		= new Instruction(ADDI, "ADDI");
	instructions[SLTI]		= new Instruction(SLTI, "SLTI");
	instructions[SLTIU]		= new Instruction(SLTIU, "SLTIU");
	instructions[XORI]		= new Instruction(XORI, "XORI");
	instructions[ORI]		= new Instruction(ORI, "ORI");
	instructions[ANDI]		= new Instruction(ANDI, "ANDI");
	instructions[SLLI]		= new Instruction(SLLI, "SLLI");
	instructions[SRLI]		= new Instruction(SRLI, "SRLI");
	instructions[SRAI]		= new Instruction(SRAI, "SRAI");
	instructions[ADD]		= new Instruction(ADD, "ADD");
	instructions[SUB]		= new Instruction(SUB, "SUB");
	instructions[SLL]		= new Instruction(SLL, "SLL");
	instructions[SLT]		= new Instruction(SLT, "SLT");
	instructions[SLTU]		= new Instruction(SLTU, "SLTU");
	instructions[XOR]		= new Instruction(XOR, "XOR");
	instructions[SRL]		= new Instruction(SRL, "SRL");
	instructions[SRA]		= new Instruction(SRA, "SRA");
	instructions[OR]		= new Instruction(OR, "OR");
	instructions[AND]		= new Instruction(AND, "AND");
	instructions[FENCE]		= new Instruction(FENCE, "FENCE");
	instructions[ECALL]		= new Instruction(ECALL, "ECALL");
	instructions[EBREAK]	= new Instruction(EBREAK, "EBREAK");
	instructions[INVALID]	= new Instruction(INVALID, "INVALID");

}
