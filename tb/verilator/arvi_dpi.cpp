#include "arvi_dpi.h"

Profiler profiler;

void new_instruction(int inst, int cycles) { 
	profiler.inc_inst(inst, cycles);
}

Profiler* get_profiler() {
	return &profiler;
}

