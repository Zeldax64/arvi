#include "arvi_dpi.h"

void new_instruction(int inst) { 
	inst_t type;

	type = inst_decode(inst);
	//inc_inst_type(type);
}

