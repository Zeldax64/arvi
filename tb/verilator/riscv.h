// DUT processor interface
#pragma once

#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <string>
#include <stdint.h>

#include "VRISC_V.h"
#include "verilated_vcd_c.h"

#include "elfloader.h"


class RISCV {
	VRISC_V* dut; 
	std::vector<uint8_t> mem; // Memory map
	bool io_success;
	bool sim_done;

	VerilatedVcdC *tfp;
	uint64_t mtick; // Tick counter

	const uint32_t MEM_SIZE = 0xFFFFFF;
	std::string path;

	// Elf symbols
	uint64_t tohost_addr;
	uint64_t fromhost_addr;
	uint64_t sig_addr;
	uint64_t sig_len;
public:
	RISCV();
	~RISCV();

	bool load_mem(const char* path);
	void tick();
	void reset();
	bool done();
	bool success();
	void open_trace(const char* path);

private:
	void wait(uint32_t cycles);
	void mem_access();
	void to_host(uint32_t val);
	void dump_sig();
};