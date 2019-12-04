// Verilator includes
#include "VRISC_V.h"

#include "verilated.h"
#include "verilated_vcd_c.h"

// C includes
#include <stdint.h>
#include <string>
#include <vector>
#include <iostream>

// Internals
#include "elfloader.h"
#include "riscv.h"

// Program Profiler
#include "arvi_dpi.h"
#include "profiler/Profiler.h"

#include <fesvr/memif.h>

int main(int argc, char** argv) {
	bool fail;
	uint64_t mtick = 0;
	uint64_t cycles = 0;
	uint64_t MAX_CYCLES = 2000000;
	bool trace= false;
	bool performance_profiler = false;
	bool no_print = false;
	Profiler* prof = NULL;		
	char* report_output = NULL;

	int cores_no = 1;

	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	char *mem_path = NULL;
	for(int i = 1; i < argc; i++) {
		std::string arg = argv[i];
		if(arg.substr(0,12) == "+max-cycles=")
			MAX_CYCLES = atoll(argv[i]+12);
		else if(arg.substr(0,9) == "+loadmem=")
			mem_path = argv[i]+9;
		else if(arg.substr(0, 2) == "-v")
			trace = true;
		else if(arg.substr(0, 2) == "-r") {
			prof = new Profiler(cores_no);
		}
		else if(arg.substr(0, 16) == "--report-output="){
			report_output = argv[i]+16;
		}
		else if(arg.substr(0, 10) == "--no-print"){
			no_print = true;
		}
	}
	
	std::string path(mem_path);

	// If -r flag is passed, then create a performance report of the program
	if(prof != NULL) {	
		set_profiler(prof);

		if(report_output == NULL) {
			prof->set_path(mem_path);
		}
		else {
			std::string performance_path(report_output);
			prof->set_path(performance_path);
		}
		
		prof->set_ticker(&cycles);
	}

	// Reset
    RISCV* dut = new RISCV();
    if(trace)
    	dut->open_trace((path+".vcd").c_str());
    dut->load_mem(path.c_str());
    dut->reset();

	// Simulation cycle
	while(cycles < MAX_CYCLES && !Verilated::gotFinish() && !dut->done()) {
		dut->tick();
		cycles++;
	}
	
	if(dut->success()) {
		if(!no_print) 
			std::cout << "*** PASSED ***" << std::endl;
		fail = false;
	}
	else {
		if(!no_print)
			std::cout << "*** FAILED ***" << std::endl;
		fail = true;
	}

	if(!no_print) {
		std::cout << "Elf: " << mem_path << std::endl;
		std::cout << "Cycles: " << cycles << std::endl;
	}
	
	if(prof != NULL) {
		prof->save_report();
	}

	delete dut;
	
	return fail;
}