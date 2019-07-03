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

#ifdef __ARVI_PERFORMANCE_ANALYSIS
#include "arvi_dpi.h"
#include "profiler/Profiler.h"
#endif

int main(int argc, char** argv) {
	bool fail;
	uint64_t mtick = 0;
	uint64_t cycles = 0;
	uint64_t MAX_CYCLES = 2000000;
	bool trace= false;

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
	}
	
	std::string path(mem_path);

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
	
	//std::cout << "*** " << mem_path << " ***" << std::endl;
	if(dut->success()) {
		//std::cout << "*** PASSED ***" << std::endl;
		fail = false;
	}
	else {
		//std::cout << "*** FAILED ***" << std::endl;
		fail = true;
	}
	//std::cout << "Cycles: " << cycles << std::endl;

#ifdef __ARVI_PERFORMANCE_ANALYSIS
	Profiler* prof = get_profiler();
	prof->set_path(mem_path);
	prof->set_ticker(&cycles);
	prof->save_report();
#endif	

	delete dut;
	
	return fail;
}