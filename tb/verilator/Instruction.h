#pragma once

#include <iostream>
#include <string>
#include <stdint.h>

class Instruction {
	std::string name;
	uint32_t counter;
	uint32_t ID;

public:
	Instruction(uint32_t id, std::string name);
	~Instruction();

	void increment();
	uint32_t get_counter();
	std::string get_name();
};
