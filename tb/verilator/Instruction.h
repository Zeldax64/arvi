#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <stdint.h>

class Instruction {
	uint32_t ID; // Identification number of the instruction
	std::string name; // Name of the instruction
	uint32_t counter; // How many times it was issued
	uint32_t cycles;
	uint32_t min_cycles; // Minimum number of cycles necessary to execute the instruction
	uint32_t max_cycles; // Maximum number of cycles necessary to execute the instruction

public:
	Instruction(uint32_t id, std::string name);
	~Instruction();

	void increment(uint32_t cycles);
	std::string get_name();
	uint32_t get_counter();
	float get_CPI();
	void print_report();
	void save_report(std::fstream &file);

private:
	void set_cycles(uint32_t cycles);
};
