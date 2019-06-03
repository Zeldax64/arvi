#ifndef __ARVI_DPI
#define __ARVI_DPI

#include "svdpi.h"
#include "VRISC_V__Dpi.h"

#include <iostream>
#include <stdint.h>

#include "Profiler.h"


void new_instruction(int inst, int cycles);
Profiler* get_profiler();

#endif