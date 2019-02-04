#pragma once

std::map<std::string, uint64_t> load_elf(const char* path, std::vector<uint8_t> *i_mem);