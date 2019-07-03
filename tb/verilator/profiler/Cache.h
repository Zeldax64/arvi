#pragma once

#include <iostream>
#include <fstream>
#include <stdint.h>

class Cache {
	uint64_t hits;
	uint64_t misses;
	uint64_t inst_stall;

public:
	Cache();
	~Cache();
	void cache_hit();
	void cache_miss(uint32_t cycles);

	uint64_t get_cache_hits();
	uint64_t get_cache_misses();
	float get_miss_penalty();

	void print_report();
	void save_report(std::fstream &file);
};