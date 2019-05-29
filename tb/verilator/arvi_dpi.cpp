#include "arvi_dpi.h"

#include <stdint.h>

static unsigned int inst_counter = 0;

void new_instruction(int inst) { 
	inst_counter++;
}

uint32_t get_inst_count() {
	return inst_counter;
}

