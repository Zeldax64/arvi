#include "arvi_dpi.h"

Profiler* profiler;

void new_instruction(int hart, int inst, int cycles) { 
	if(profiler != NULL){
		profiler->inc_inst(hart, inst, cycles);
	}
}

void cache_hit(int hart) {
	if(profiler != NULL) {
		profiler->cache_hit(hart);
	}
}

void cache_miss(int hart, int cycles) {
	if(profiler != NULL) {
		profiler->cache_miss(hart, cycles);
	}
}

void set_profiler(Profiler* p) {
	profiler = p;
}

