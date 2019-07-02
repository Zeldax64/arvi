#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <stdint.h>
#include <vector>

#include "ISA.h"
#include "Cache.h"

class Hart {
	ISA isa;
	Cache cache;

public:
	Hart();
	~Hart();

	void save_report(std::fstream &file);
	void print_report();
	
	void set_ticker(uint64_t *ticker);
	
	// ISA
	void inc_inst(uint32_t inst, uint32_t cycles);

	// Cache
	void cache_hit();
	void cache_miss(uint32_t cycles);

private:

};