#include "Profiler.h"

Profiler::Profiler() {

}

Profiler::~Profiler() {

}

void Profiler::save_report() {
	std::cout << path << std::endl;
	file.open(file_path, std::ios::out); 
	
	cache.save_report(file);
	isa.save_report(file);

	file.close();
}

void Profiler::set_path(std::string path) {
	this->path = path;
	this->file_path = path+".performance_report";
}

std::string Profiler::get_path() {
	return this->path;
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

