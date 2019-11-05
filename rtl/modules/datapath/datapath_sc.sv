/*
	File containing a DATAPATH module of a single-cycle RISC-V processor.
*/

`timescale 1ns / 1ps

`include "arvi_defines.svh"

module datapath_sc
	#(
		parameter PC_RESET = `PC_RESET,	
		parameter HART = 0,
		parameter I_CACHE_ENTRIES = 128
	)
	(
	// Instruction Memory connections
	input  [`XLEN-1:0] i_IM_Instr,
	input  i_IC_MemReady,
	output o_IC_DataReq,
	output [`XLEN-1:0] o_IM_Addr,

	// Data Memory interface
	dmem_if.master DM_to_mem,
	
	// External RV32-M implementation
`ifdef __RV32_M_EXTERNAL
	output o_EX_en, 
	output [`XLEN-1:0] o_EX_rs1, 
	output [`XLEN-1:0] o_EX_rs2, 
	output [2:0] o_EX_f3, 
	input  [`XLEN-1:0] i_EX_res, 
	input  i_EX_ack,
`endif

	// Interrupt connnections
/* verilator lint_off UNUSED */
	input i_tip,
/* verilator lint_on UNUSED */

`ifdef RISCV_FORMAL
	output logic [`RISCV_FORMAL_NRET                        - 1 : 0] rvfi_valid,      
	output logic [`RISCV_FORMAL_NRET *                 64   - 1 : 0] rvfi_order,      
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_ILEN   - 1 : 0] rvfi_insn,       
	output logic [`RISCV_FORMAL_NRET                        - 1 : 0] rvfi_trap,       
	output logic [`RISCV_FORMAL_NRET                        - 1 : 0] rvfi_halt,       
	output logic [`RISCV_FORMAL_NRET                        - 1 : 0] rvfi_intr,       
	output logic [`RISCV_FORMAL_NRET *                  2   - 1 : 0] rvfi_mode,       
	output logic [`RISCV_FORMAL_NRET *                  2   - 1 : 0] rvfi_ixl,        
	output logic [`RISCV_FORMAL_NRET *                  5   - 1 : 0] rvfi_rs1_addr,   
	output logic [`RISCV_FORMAL_NRET *                  5   - 1 : 0] rvfi_rs2_addr,   
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_rs1_rdata,  
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_rs2_rdata,  
	output logic [`RISCV_FORMAL_NRET *                  5   - 1 : 0] rvfi_rd_addr,    
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_rd_wdata,   
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_pc_rdata,   
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_pc_wdata,   
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_mem_addr,   
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN/8 - 1 : 0] rvfi_mem_rmask,  
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN/8 - 1 : 0] rvfi_mem_wmask,  
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_mem_rdata,  
	output logic [`RISCV_FORMAL_NRET * `RISCV_FORMAL_XLEN   - 1 : 0] rvfi_mem_wdata,   
`endif

	// General connections
	input i_clk,
	input i_rst
	);

	logic [`XLEN-1:0] PC;
	logic [`XLEN-1:0] PC_next;
	logic [`XLEN-1:0] id_pc, ex_pc, ex_pc_jump, mem_pc;

	// Instruction signals
	wire [`XLEN-1:0] if_inst, id_inst, ex_inst; 


////////////////////////////////////////////////////
//----- Instruction Decode Stage(ID) Signals -----//
////////////////////////////////////////////////////
	logic [`XLEN-1:0] id_rd1;
	logic [`XLEN-1:0] id_rd2;
	logic [`XLEN-1:0] id_imm;

// Main Control signals to each stage. No structs are used because Yosys
// doesn't support them and I want ARVI to be compatible with riscv-formal.
	// Main Control 
	logic id_MC_Branch;
	logic id_MC_MemRead;
	logic id_MC_MemWrite;
	logic id_MC_MemtoReg;
	logic [2:0] id_MC_ALUOp;
	logic [1:0] id_MC_ALUSrcA;
	logic id_MC_ALUSrcB;
	logic id_MC_RegWrite;
	logic [1:0] id_MC_Jump;
	logic id_MC_PCplus4;
	logic id_MC_CSR_en;
	logic id_MC_Ex_inst_illegal;
`ifdef __RV32_M
	logic id_MC_ALUM_en;
`endif
`ifdef __ATOMIC
	logic id_MC_atomic;
`endif

/////////////////////////////////////////
//----- Execute Stage(EX) Signals -----//
/////////////////////////////////////////
	logic ex_z;
	logic [`XLEN-1:0] ex_alures;
	logic [`XLEN-1:0] ex_wr_data;

	// Main Control signals exiting Execution Stage.
	logic ex_MC_Branch;
	logic ex_MC_MemRead;
	logic ex_MC_MemWrite;
	logic ex_MC_MemtoReg;
	logic ex_MC_RegWrite;
	logic [1:0] ex_MC_Jump;
	logic ex_MC_PCplus4;
	logic ex_MC_CSR_en;
	logic ex_MC_Ex_inst_illegal;
`ifdef __ATOMIC
	logic ex_MC_atomic;
`endif

/////////////////////////////////////////
//----- Memory Stage (MEM) Signals -----//
/////////////////////////////////////////
	logic [`XLEN-1:0] mem_rddata;
	logic mem_csr_eret;
	logic [`XLEN-1:0] mem_csr_tvec, mem_csr_epc;
	logic mem_ex_ld_addr, mem_ex_st_addr;
	logic mem_ex_ecall;
	logic mem_ex_ebreak;

	// Main Control signals.
	logic mem_MC_MemtoReg;
	logic mem_MC_RegWrite;
	logic mem_MC_PCplus4;
	logic mem_MC_Ex_inst_illegal;

/////////////////////////////////////////
//----- Write Back (WB) Signals -----//
/////////////////////////////////////////
	logic wb_rf_wr_en;
	logic [`XLEN-1:0] wb_wrdata;

	// Exceptions
	logic wb_ex_inst_illegal;
	logic wb_ex_inst_addr;
	logic wb_ex_ld_addr;
	logic wb_ex_st_addr;
	logic wb_ex_ecall;
	logic wb_ex_ebreak;
	logic [`XLEN-1:0] wb_badaddr;

	// Stall signals
	wire IC_stall;
	wire EX_stall;
	wire MEM_stall;

/////////////////////////////////////	
//----- Instruction Fetch(IF) -----//
/////////////////////////////////////

	// Assigning PC
	always_ff@(posedge i_clk) begin
		if(!i_rst) PC <= PC_RESET;
		else if(IC_stall || MEM_stall || EX_stall) PC <= PC;
		else PC <= PC_next;
	end

	// IM wires
	wire [`XLEN-1:0] i_DataBlock = i_IM_Instr;

	// Instruction Memory
	i_cache #(.BLOCK_SIZE	(1),
			  .ENTRIES   	(I_CACHE_ENTRIES)) 
	i_cache 
	(
		.i_clk 			(i_clk),
		.i_rst 			(i_rst),

		// Memmory interface
		.i_DataBlock 	(i_DataBlock),
		.i_MemReady 	(i_IC_MemReady),
		.o_DataReq  	(o_IC_DataReq),
		.o_MemAddr		(o_IM_Addr),

		// CPU interface
		.i_Addr     	(PC),
		.o_Data 		(if_inst),
		.o_Stall    	(IC_stall)
	);

//////////////////////////////////////	
//----- Instruction Decode(ID) -----//
//////////////////////////////////////	
	id_stage id_stage
		(
			.i_clk      		(i_clk),
			.i_inst     		(if_inst),

			.o_rd1      		(id_rd1), // Register File
			.o_rd2      		(id_rd2),
			.o_imm      		(id_imm), // Immediate 

			// Main Control
			.o_branch   		(id_MC_Branch),
			.o_memread  		(id_MC_MemRead),
			.o_memwrite 		(id_MC_MemWrite),
			.o_memtoreg 		(id_MC_MemtoReg),
			.o_alu_op   		(id_MC_ALUOp),
			.o_alu_srca 		(id_MC_ALUSrcA),
			.o_alu_srcb 		(id_MC_ALUSrcB),
			.o_regwrite 		(id_MC_RegWrite),
			.o_jump     		(id_MC_Jump),
			.o_pc_plus4 		(id_MC_PCplus4),
			.o_csr_en   		(id_MC_CSR_en),
			.o_ex_inst_illegal	(id_MC_Ex_inst_illegal),
`ifdef __ATOMIC
			.o_atomic   		(id_MC_atomic),
`endif
`ifdef __RV32_M
			.o_m_en     		(id_MC_ALUM_en),
`endif
			.o_inst     		(id_inst),
			.i_pc      			(PC),
			.o_pc       		(id_pc),	
			// Writeback
			.i_wr_en    		(wb_rf_wr_en),
			.i_wr_data  		(wb_wrdata),

			.i_stall    		(IC_stall)
		);

///////////////////////////	
//----- Execute(EX) -----//
///////////////////////////

	ex_stage ex_stage
		(
			.i_rs1   (id_rd1),
			.i_rs2   (id_rd2),
			.i_imm   (id_imm),
			.i_inst  (id_inst),
			.o_res   (ex_alures),
			.o_z     (ex_z),

			.i_pc 	 (id_pc),

`ifdef __RV32_M
			.i_clk   (i_clk),
			.i_rst   (i_rst),
`endif

`ifdef __RV32_M_EXTERNAL
			.i_res   (i_EX_res),
			.i_ack   (i_EX_ack),
			.o_en    (o_EX_en),
			.o_rs1   (o_EX_rs1),
			.o_rs2   (o_EX_rs2),
			.o_f3    (o_EX_f3),
`endif

		//----- Main Control Signals -----//
			// Input signals
			.i_branch		   (id_MC_Branch),
			.i_memread		   (id_MC_MemRead),
			.i_memwrite		   (id_MC_MemWrite),
			.i_memtoreg		   (id_MC_MemtoReg),
			.i_alu_op		   (id_MC_ALUOp),
			.i_alu_srca		   (id_MC_ALUSrcA),
			.i_alu_srcb		   (id_MC_ALUSrcB),
			.i_regwrite		   (id_MC_RegWrite),
			.i_jump			   (id_MC_Jump),
			.i_pc_plus4		   (id_MC_PCplus4),
			.i_csr_en		   (id_MC_CSR_en),
			.i_ex_inst_illegal (id_MC_Ex_inst_illegal),

`ifdef __ATOMIC
			.i_atomic		   (id_MC_atomic),
`endif
`ifdef __RV32_M
			.i_m_en			   (id_MC_ALUM_en),
`endif
			
			// Output signals
			.o_branch		   (ex_MC_Branch),
			.o_memread		   (ex_MC_MemRead),
			.o_memwrite		   (ex_MC_MemWrite),
			.o_memtoreg		   (ex_MC_MemtoReg),
			.o_regwrite		   (ex_MC_RegWrite),
			.o_jump			   (ex_MC_Jump),
			.o_pc_plus4		   (ex_MC_PCplus4),
			.o_csr_en		   (ex_MC_CSR_en),
			.o_ex_inst_illegal (ex_MC_Ex_inst_illegal),

`ifdef __ATOMIC
			.o_atomic   (ex_MC_atomic),
`endif
		//----- Forward signals -----//
			.o_inst     (ex_inst),
			.o_pc       (ex_pc),
			.o_pc_jump 	(ex_pc_jump),
			.o_wr_data  (ex_wr_data),

			.o_stall 	(EX_stall)
		);

///////////////////////////	
//----- Memory(MEM) -----//
///////////////////////////

	mem_stage #(.HART_ID(HART))
		mem_stage
	(
		.i_clk       (i_clk),
		.i_rst       (i_rst),


		.i_inst      (ex_inst),
		.i_alu_res   (ex_alures),
		.i_wr_data   (ex_wr_data),
		.i_memwrite  (ex_MC_MemWrite),
		.i_memread   (ex_MC_MemRead),
		.o_rd        (mem_rddata),
		// Data Memory generated exceptions.
		.o_ex_ld_addr (mem_ex_ld_addr),
		.o_ex_st_addr (mem_ex_st_addr),
		// CPU <-> Memory interface
		.to_mem      (DM_to_mem),
   	
   		// Branch Control
		.i_branch    (ex_MC_Branch),
		.i_z         (ex_z),

		.i_jump      (ex_MC_Jump),
		.i_pc        (ex_pc),
		.i_pc_jump   (ex_pc_jump),
		.o_pc        (mem_pc),

		// CSR signals
		.i_csr_en  	 (ex_MC_CSR_en),
		.i_csr_wd  	 (ex_alures),
		.o_csr_tvec  (mem_csr_tvec),
		.o_csr_epc   (mem_csr_epc),
		.o_csr_eret	 (mem_csr_eret),
		.o_ex_ecall 	(mem_ex_ecall),
		.o_ex_ebreak   	(mem_ex_ebreak),
		// Input control signals
		.i_mc_memtoreg (ex_MC_MemtoReg),
		.i_mc_regwrite (ex_MC_RegWrite),
		.i_mc_pcplus4  (ex_MC_PCplus4),
		.i_mc_ex_inst_illegal (ex_MC_Ex_inst_illegal),
`ifdef __ATOMIC
		.i_mc_atomic         (ex_MC_atomic),
`endif		
		// Control signals to next stage
		.o_mc_memtoreg (mem_MC_MemtoReg),
		.o_mc_regwrite (mem_MC_RegWrite),
		.o_mc_pcplus4  (mem_MC_PCplus4),
		.o_mc_ex_inst_illegal (mem_MC_Ex_inst_illegal),

    	// Write-Back Exceptions
    	.i_ex_inst_illegal 	(wb_ex_inst_illegal),
    	.i_ex_inst_addr 	(wb_ex_inst_addr),
    	.i_ex_ld_addr 		(wb_ex_ld_addr),
    	.i_ex_st_addr 		(wb_ex_st_addr),
		.i_ex_ecall			(wb_ex_ecall),
		.i_ex_ebreak        (wb_ex_ebreak),
		.i_badaddr          (wb_badaddr),

		.o_stall     		(MEM_stall)
	);

//////////////////////////////	
//----- Write Back(WB) -----//
//////////////////////////////

	/*----- Write Back Mux -----*/
	// PC Mux - Chooses PC's next value
	logic wb_ex;
	
	always_comb begin
		if(wb_ex) begin // Illegal instruction or MC_Ex(ECALL)
			PC_next = mem_csr_tvec;
		end

		else if(mem_csr_eret) begin // xRET instruction (only MRET implemented)
			PC_next = mem_csr_epc;
		end
		else
			PC_next = mem_pc;
	end

	assign wb_wrdata = mem_MC_PCplus4 ? PC+4 : 
				  	   mem_MC_MemtoReg ? mem_rddata : ex_alures;

	assign wb_rf_wr_en = mem_MC_RegWrite && !EX_stall && !MEM_stall && !wb_ex;

	// Assigining exceptions
	assign wb_ex_inst_illegal = mem_MC_Ex_inst_illegal;
	assign wb_ex_inst_addr    = |mem_pc[1:0];
	assign wb_ex_st_addr      = mem_ex_st_addr;
	assign wb_ex_ld_addr      = mem_ex_ld_addr;
	assign wb_ex_ecall        = mem_ex_ecall;
	assign wb_ex_ebreak		  = mem_ex_ebreak;
	assign wb_ex = wb_ex_inst_illegal |
				   wb_ex_inst_addr	  |
				   wb_ex_st_addr 	  |
				   wb_ex_ld_addr 	  |
				   wb_ex_ecall 		  |
				   wb_ex_ebreak;
	assign wb_badaddr = (mem_ex_ld_addr || mem_ex_st_addr) ? ex_alures : mem_pc;

`ifdef __ARVI_PERFORMANCE_ANALYSIS
	// ***** Performance Profiler DPI ***** //
	integer inst_cycles;
	integer inst_stall;
	always_ff@(posedge i_clk) begin
		if(!i_rst) begin 
			inst_cycles <= 0;
			inst_stall <= 0;
		end
		else begin
			// Cache Performance
			if(i_cache.hit && (inst_cycles == 0)) begin
				cache_hit(HART);
			end
			if(IC_stall) begin
				inst_stall <= inst_stall + 1;
			end
			// Instruction Performance
			if(IC_stall || MEM_stall || EX_stall) 
				inst_cycles <= inst_cycles+1;
			else begin // Finished instruction execution
				new_instruction(HART, if_inst, inst_cycles+1);
				if(inst_stall !== 0) begin
					cache_miss(HART, inst_stall);
				end
				inst_stall <= 0;
				inst_cycles <= 0;
			end
		end
	end
`endif


`ifdef RISCV_FORMAL
	wire stall = IC_stall || EX_stall || MEM_stall;
	wire is_valid_inst = i_rst && !stall;

	reg [3:0] mask;

	always_ff@(posedge i_clk) begin
		rvfi_valid     <= is_valid_inst;
		rvfi_order     <= i_rst ? rvfi_order + rvfi_valid : 0;
		rvfi_insn      <= if_inst;
		rvfi_trap      <= wb_ex_inst_addr | wb_ex_inst_illegal |
						  wb_ex_ld_addr | wb_ex_st_addr;
		rvfi_halt      <= 0; // Permanent 0
		rvfi_intr      <= 0; // Permanent 0
		rvfi_mode      <= 3; // M mode only
		rvfi_ixl       <= 1; // 32 bits only
		rvfi_rs1_addr  <= if_inst[19:15]; 
		rvfi_rs2_addr  <= if_inst[24:20];
		rvfi_rs1_rdata <= id_rd1;
		rvfi_rs2_rdata <= id_rd2;
		rvfi_rd_addr   <= (if_inst[11:7] && wb_rf_wr_en) ? if_inst[11:7] : 0;
		rvfi_rd_wdata  <= (if_inst[11:7] && wb_rf_wr_en) ? wb_wrdata : 0; // TBD
		rvfi_pc_rdata  <= PC;
		rvfi_pc_wdata  <= PC_next;

		rvfi_mem_addr  <= 0;
		rvfi_mem_rmask <= 0;
		rvfi_mem_wmask <= 0; 
		rvfi_mem_rdata <= 0; 
		rvfi_mem_wdata <= 0; 

		if((DM_to_mem.DM_Wen || DM_to_mem.DM_MemRead) && !(mem_ex_ld_addr || mem_ex_st_addr)) begin
			rvfi_mem_addr  <= DM_to_mem.DM_Addr; // 
			if(DM_to_mem.DM_MemRead) begin
				rvfi_mem_rmask <= DM_to_mem.DM_byte_en;
				rvfi_mem_rdata <= DM_to_mem.DM_ReadData;
			end
			if(DM_to_mem.DM_Wen) begin
				rvfi_mem_wmask <= DM_to_mem.DM_byte_en;
				rvfi_mem_wdata <= DM_to_mem.DM_Wd;
			end
		end
	end
	`endif

endmodule
