#include "Hart.h"

Hart::Hart() {
}

Hart::~Hart() {

}

void Hart::save_report(std::fstream &file) {
	this->cache.save_report(file);
	this->isa.save_report(file);
}

void Hart::print_report() {
	std::cout << "*** Hart Report ***" << std::endl;
	cache.print_report();
	isa.print_report();	
}

void Hart::inc_inst(uint32_t inst, uint32_t cycles) {
	isa.inc_inst(inst,cycles);
}

// ----- Cache ----- //
void Hart::cache_hit() {
	cache.cache_hit();
}

void Hart::cache_miss(uint32_t cycles) {
	cache.cache_miss(cycles);
}

