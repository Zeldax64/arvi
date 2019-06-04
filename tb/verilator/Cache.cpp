#include "Cache.h"

Cache::Cache() {
	hits = 0;
	misses = 0;
	inst_stall = 0;
}

Cache::~Cache() {
	
}

void Cache::cache_hit() {
	hits++;
}

void Cache::cache_miss(uint32_t cycles) {
	misses++;
	inst_stall += cycles;
}

uint64_t Cache::get_cache_hits() {
	return hits;
}

uint64_t Cache::get_cache_misses() {
	return misses;
}

void Cache::print_report() {
	std::cout << "--- Cache Report ---" << std::endl;
	std::cout << "Cache hits: " << this->get_cache_hits() << std::endl;
	std::cout << "Cache misses: " << this->get_cache_misses() << std::endl;
}