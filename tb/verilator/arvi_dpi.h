#ifndef __ARVI_DPI
#define __ARVI_DPI

#include "svdpi.h"
#include "VRISC_V__Dpi.h"

#include <iostream>
#include <stdint.h>

#include "profiler/Profiler.h"


void new_instruction(int hart, int inst, int cycles);
void cache_hit(int hart);
void cache_miss(int hart, int cycles);

Profiler* get_profiler();

#endif