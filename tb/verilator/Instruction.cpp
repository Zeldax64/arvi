#include "Instruction.h"

Instruction::Instruction(uint32_t id, std::string name) {
	this->ID = id;
	this->name = name;
	this->counter = 0;
	cycles = 0;
	min_cycles = 0;
	max_cycles = 0;
}

Instruction::~Instruction() { }

void Instruction::increment(uint32_t cycles) {
	counter++;
	this->set_cycles(cycles);
}

std::string Instruction::get_name() {
	return this->name;
}

uint32_t Instruction::get_counter() {
	return this->counter;
}

float Instruction::get_CPI() {
	if(counter != 0) {
		return (float) cycles/counter;
	}
	else {
		return 0.0;
	}
}

void Instruction::print() {
	std::cout << this->get_name() << ": " << this->get_counter() <<
	" Cycles: "  << this->cycles <<  
	" CPI: " << this->get_CPI() << 
	//" Minimum: " << this->min_cycles << 
	//" Maximum: " << max_cycles << 
	std::endl;
}

void Instruction::set_cycles(uint32_t cycles) {
	this->cycles += cycles;
	/*
	if(cycles > 0) {
		if(cycles < min_cycles) min_cycles = cycles;
		if(cycles > max_cycles) max_cycles = cycles;
	}
	*/
}