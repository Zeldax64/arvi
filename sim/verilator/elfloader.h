#pragma once

#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <string>
#include <stdint.h>

std::map<std::string, uint64_t> load_elf(const char* path, std::vector<uint8_t> *i_mem);
int dump_elf(const char* elf_file, const char* dump_file);