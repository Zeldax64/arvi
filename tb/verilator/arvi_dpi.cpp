#include "arvi_dpi.h"

Profiler profiler;

void new_instruction(int inst, int cycles) { 
	profiler.inc_inst(inst, cycles);
}

void cache_hit() {
	profiler.cache_hit();
}

void cache_miss(int cycles) {
	profiler.cache_miss(cycles);
}

Profiler* get_profiler() {
	return &profiler;
}

