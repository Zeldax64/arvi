#include "Profiler.h"

Profiler::Profiler() {

}

Profiler::~Profiler() {

}


void Profiler::inc_inst(uint32_t inst, uint32_t cycles) {
	isa.inc_inst(inst, cycles);
}

uint64_t Profiler::get_inst_count() {
	return isa.get_inst_count();
}

// ----- Cache ----- //
void Profiler::cache_hit() {
	cache.cache_hit();
}

void Profiler::cache_miss(uint32_t cycles) {
	cache.cache_miss(cycles);
}

uint64_t Profiler::get_cache_hits() {
	return cache.get_cache_hits();
}

void Profiler::print_report() {
	std::cout << "*** Profiler Report ***" << std::endl;
	cache.print_report();
	isa.print_report();	
}

// --- Private Methods --- //

