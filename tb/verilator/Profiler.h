#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <stdint.h>

#include "ISA.h"
#include "Cache.h"

class Profiler {
	std::string path;
	std::string file_path;
	std::fstream file;
	ISA isa;
	Cache cache;

public:
	Profiler();
	~Profiler();

	void save_report();
	void set_path(std::string path);
	std::string get_path();

	// ISA
	void inc_inst(uint32_t inst, uint32_t cycles);
	uint64_t get_inst_count();
	
	// Cache
	void cache_hit();
	void cache_miss(uint32_t cycles);
	uint64_t get_cache_hits();

	void print_report();
	
private:

};