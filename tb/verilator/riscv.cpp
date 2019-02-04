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
	this->path = path;
	std::map<std::string, uint64_t> symbols;
	symbols = load_elf(path, &this->mem);
	if(mem.size() < MEM_SIZE)
	this->mem.resize(MEM_SIZE, 0);

	if(symbols.count("tohost") && symbols.count("fromhost")) {
    	tohost_addr = symbols["tohost"];
    	fromhost_addr = symbols["fromhost"];
  	} else {
    	printf("warning: tohost and fromhost symbols not in ELF; can't communicate with target\n");
  	}
  	if(symbols.count("begin_signature") && symbols.count("end_signature")) {
  		sig_addr = symbols["begin_signature"];
  		sig_len = symbols["end_signature"] - sig_addr;
  	}
  	return true;
}

void RISCV::tick() {
	mtick++;
	this->mem_access();
	this->d_access();
	dut->i_clk = 0;
	dut->eval();
	if(tfp) tfp->dump(mtick);

	mtick++;
	dut->i_clk = 1;
	this->d_access();
	// Cache
	dut->i_IC_MemReady = 0;
	dut->eval();
	if(tfp) tfp->dump(mtick);
}

void RISCV::reset() {
	this->i_fetch();
    for(uint32_t i = 0; i < 2; i++) {
		mtick++;
		dut->i_clk = 0;
    	dut->i_rst = 0;
		dut->eval();
		if(tfp) tfp->dump(mtick);

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

void RISCV::mem_access() {
	uint32_t base_addr = dut->o_IM_Addr & this->MEM_SIZE;
	 
	if(dut->o_IC_DataReq) {
		dut->i_IM_Instr = this->mem[base_addr] 		   |
					      this->mem[base_addr+1] << 8  |
					  	  this->mem[base_addr+2] << 16 |
					      this->mem[base_addr+3] << 24;		
		this->wait(0);
		dut->i_IC_MemReady = 1;
	}
}

void RISCV::i_fetch() {
	// Instruction memory max size must be 0x1000 
	// according to elf scripts in riscv-tests
	uint32_t base_addr = dut->o_IM_Addr & this->MEM_SIZE; 
	dut->i_IM_Instr = this->mem[base_addr] 		   |
					  this->mem[base_addr+1] << 8  |
					  this->mem[base_addr+2] << 16 |
					  this->mem[base_addr+3] << 24;
}

void RISCV::d_access() {
	if(dut->o_DM_Wen)
		this->d_write();
	if(dut->o_DM_MemRead)
		this->d_read();
}

void RISCV::d_write() {
	uint32_t wr_addr = dut->o_DM_Addr;
	uint32_t wr_val = dut->o_DM_WriteData;

	if(wr_addr == tohost_addr) {
		to_host(wr_val);
	}
	else {
		uint32_t base_addr = wr_addr & this->MEM_SIZE;
		uint32_t f3 = dut->o_DM_f3;
		this->mem[base_addr]   =  wr_val & 0xFF;
		this->mem[base_addr+1] = (f3 > 0) ? (wr_val & 0xFF00) >> 8 		: this->mem[base_addr+1]; 		
		this->mem[base_addr+2] = (f3 > 1) ? (wr_val & 0xFF0000) >> 16 	: this->mem[base_addr+2];
		this->mem[base_addr+3] = (f3 > 1) ? (wr_val & 0xFF000000) >> 24 : this->mem[base_addr+3];
	}
}

void RISCV::d_read() {
	uint32_t base_addr = dut->o_DM_Addr & this->MEM_SIZE; 
	uint32_t val;
	uint32_t f3 = dut->o_DM_f3;

	val  = this->mem[base_addr];
	val |= (f3 > 0) ? this->mem[base_addr+1] << 8  : 0;
	val |= (f3 > 1) ? this->mem[base_addr+2] << 16 : 0;
	val |= (f3 > 1) ? this->mem[base_addr+3] << 24 : 0;

	dut->i_DM_ReadData = val;
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
		std::string sig_file(path);
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