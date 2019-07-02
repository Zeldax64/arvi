#include "Profiler.h"

Profiler::Profiler() {
	int harts_no = 2;
	
	for(int i = 0; i < harts_no; i++) {
		ISA* isa = new ISA();
		harts.push_back(isa);
	} 

	this->ticker = NULL;
}

Profiler::~Profiler() {

}

void Profiler::save_report() {
	ISA* hart;

	this->file.open(file_path, std::ios::out); 
	
	this->file << "<profiler>" << std::endl; 
	this->file << "\t<path>" << this->get_path() << "</path>" << std::endl;	
	if(this->ticker != NULL) {
		this->file << "\t<cycles>" << *this->ticker << "</cycles>" << std::endl;
	}
	this->file << "</profiler>" << std::endl; 
	
	cache.save_report(this->file);
	
	for(int i=0; i < this->harts.size(); i++){
		this->file << "<hart" << i << ">" << std::endl;
		hart = get_hart(i);
		hart->save_report(this->file);
		this->file << "</hart" << i << ">" << std::endl;
	}

	this->file.close();
}

void Profiler::print_report() {
	ISA* isa = get_hart(0);
	
	std::cout << "*** Profiler Report ***" << std::endl;
	std::cout << "Program: " << this->get_path() << std::endl;
	cache.print_report();
	isa->print_report();	
	
}

void Profiler::set_path(std::string path) {
	this->path = path;
	this->file_path = path+".performance_report";
}

std::string Profiler::get_path() {
	return this->path;
}

void Profiler::set_ticker(uint64_t *ticker) {
	this->ticker = ticker;
}

void Profiler::inc_inst(uint32_t hart, uint32_t inst, uint32_t cycles) {
	ISA* isa = get_hart(hart);
	isa->inc_inst(inst,cycles);
}

// ----- Cache ----- //
void Profiler::cache_hit(uint32_t hart) {
	cache.cache_hit();
}

void Profiler::cache_miss(uint32_t hart, uint32_t cycles) {
	cache.cache_miss(cycles);
}

uint64_t Profiler::get_cache_hits() {
	return cache.get_cache_hits();
}


// --- Private Methods --- //
ISA* Profiler::get_hart(uint32_t hart) {
	return harts[hart];
}
