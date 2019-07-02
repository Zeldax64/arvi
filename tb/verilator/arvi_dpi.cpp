#include "arvi_dpi.h"

Profiler profiler(2);

void new_instruction(int hart, int inst, int cycles) { 
	profiler.inc_inst(hart, inst, cycles);
}

void cache_hit(int hart) {
	profiler.cache_hit(hart);
}

void cache_miss(int hart, int cycles) {
	profiler.cache_miss(hart, cycles);
}

Profiler* get_profiler() {
	return &profiler;
}

