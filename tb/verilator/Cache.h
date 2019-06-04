#pragma once


#include <iostream>
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

	void print_report();
};