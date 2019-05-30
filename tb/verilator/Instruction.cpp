#include "Instruction.h"

Instruction::Instruction(uint32_t id, std::string name) {
	this->ID = id;
	this->name = name;
	this->counter = 0;
}

Instruction::~Instruction() { }

void Instruction::increment() {
	counter++;
}

uint32_t Instruction::get_counter() {
	return this->counter;
}

std::string Instruction::get_name() {
	return this->name;
}
