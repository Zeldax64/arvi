#include "riscv.h"

RISCV::RISCV() {
	this->dut = new VRISC_V;
	this->io_success = false;
	this->sim_done = false;
	mtick = 0;
	tfp = NULL;

	this->sig_len = 0;
}

RISCV::~RISCV() {
	if(tfp) tfp->close();
	this->dump_sig();
}

bool RISCV::load_mem(const char* path) {
	this->program_path = path;
	std::map<std::string, uint64_t> symbols;
	symbols = load_elf(path, &this->mem);
	if(mem.size() < MEM_SIZE)
	this->mem.resize(MEM_SIZE, 0);

	if(symbols.count("tohost") && symbols.count("fromhost")) {
    	tohost_addr = symbols["tohost"];
    	fromhost_addr = symbols["fromhost"];
  	} else {
    	std::cout << "warning: tohost and fromhost symbols not in ELF; can't communicate with target\n";
  	}
  	if(symbols.count("begin_signature") && symbols.count("end_signature")) {
  		sig_addr = symbols["begin_signature"];
  		sig_len = symbols["end_signature"] - sig_addr;
  	}
  	//std::string dump_path(path);
  	//dump_elf(path, (dump_path+".elf_dump").c_str());

  	return true;
}

void RISCV::tick() {
	mtick++;
	this->mem_access();
	dut->i_clk = 0;
	dut->eval();
	if(tfp) tfp->dump(mtick);

	mtick++;
	dut->i_clk = 1;
	dut->i_ack = 0;
	dut->eval();
	if(tfp) tfp->dump(mtick);
}

void RISCV::reset() {
	//this->i_fetch();
    for(uint32_t i = 0; i < 2; i++) {
		mtick++;
		dut->i_clk = 0;
    	dut->i_rst = 0;
		dut->eval();
		if(tfp) tfp->dump(mtick);

		mtick++;
		dut->i_clk = 1;
    	dut->i_rst = 0;
		dut->eval();
		if(tfp) tfp->dump(mtick);

    	dut->i_rst = 1;
    }
}

bool RISCV::done() {
	return this->sim_done;
}

bool RISCV::success() {
	return this->io_success;
}

void RISCV::open_trace(const char* path) {
	if (!tfp) {
		tfp = new VerilatedVcdC;
		dut->trace(tfp, 99);
		tfp->open(path);
	}

}

void RISCV::wait(uint32_t cycles) {
	for(uint32_t i = 0; i < cycles; i++) {
		dut->i_clk = !dut->i_clk;
		dut->eval();
		if(tfp) tfp->dump(mtick);
		mtick++;
	
		dut->i_clk = !dut->i_clk;
		dut->eval();
		if(tfp) tfp->dump(mtick);
		mtick++;
	}
}

uint32_t RISCV::mem_read(uint32_t addr) {
	uint32_t base_addr = addr & this->MEM_SIZE;
	uint32_t val;
	val  = this->mem[base_addr];
	val |= this->mem[base_addr+1] << 8;
	val |= this->mem[base_addr+2] << 16;
	val |= this->mem[base_addr+3] << 24;

	return val;
}

void RISCV::mem_access() {
	uint32_t base_addr = dut->o_addr & this->MEM_SIZE;

	if(dut->o_bus_en) {
		if(dut->o_wr_en) {
			uint32_t byte_en = dut->o_byte_en;
		
			uint32_t wr_val = dut->o_wr_data;
			if(dut->o_addr == tohost_addr) {
				to_host(wr_val);
			}
			else {
				if(byte_en & 0x1) this->mem[base_addr]   = (wr_val & 0xFF);
				if(byte_en & 0x2) this->mem[base_addr+1] = (wr_val & 0xFF00) >> 8; 				
				if(byte_en & 0x4) this->mem[base_addr+2] = (wr_val & 0xFF0000) >> 16; 	
				if(byte_en & 0x8) this->mem[base_addr+3] = (wr_val & 0xFF000000) >> 24;
			}
		}
		// Read
		uint32_t val;
		val = mem_read(dut->o_addr);
		dut->i_rd_data = val;
		dut->i_ack = 1;
	}

}

void RISCV::to_host(uint32_t val) {
	if(val == 1) { // Test passed
		this->io_success = true;
		this->sim_done = true;
	}
	else { // Test failed
		this->sim_done = true;
	}
}

// Dump test signature
void RISCV::dump_sig() {
	if(sig_len) {
		std::string sig_file(this->program_path);
		if(sig_file.find_last_of("."))
			sig_file = sig_file.substr(0, sig_file.find_last_of("."));
		
		sig_file = sig_file + ".signature_output";
		std::ofstream sigs(sig_file);

		const uint32_t incr = 4;
		sigs << std::setfill('0') << std::hex;
		for(uint64_t i = 0; i < sig_len; i=i+incr) {
			for(uint64_t j = incr; j > 0; j--) {
				sigs << std::setw(2) << (uint16_t) mem[(sig_addr+i+j-1) & MEM_SIZE];
			}
			sigs << std::endl;
		}

		sigs.close();
	}

}