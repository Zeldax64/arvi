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

void Instruction::print_report() {
	std::cout << this->get_name() << ": " << this->get_counter() <<
	" Cycles: "  << this->cycles <<  
	" CPI: " << this->get_CPI() << 
	std::endl;
}

void Instruction::save_report(std::fstream &file) {
	file << "<inst>" << std::endl;	
	
		file << "\t";
		file << "<name>"<< name << "</name>" << std::endl;
		file << "\t";
		file << "<counter>" << counter << "</counter>" << std::endl;
		//file << "\t";
		//file << "<cycles>" << cycles << "</cycles>" << std::endl;

	file << "</inst>" << std::endl;
}

// ----- Private Methods ----- //

void Instruction::set_cycles(uint32_t cycles) {
	this->cycles += cycles;
}

