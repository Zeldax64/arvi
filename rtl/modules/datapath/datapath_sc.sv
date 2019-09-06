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
	input i_IC_MemReady,
	output o_IC_DataReq,
	output [`XLEN-1:0] o_IM_Addr,

	// Data Memory connections
	dmem_if.master DM_to_mem,

`ifdef __ATOMIC // Atomic extension signal for atomic operations
	output o_MEM_atomic,
	output [6:0] o_DM_f7,
`endif

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
	input i_tip,

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

	// Instruction wires renaming
	//wire [`XLEN-1:0] instr = i_IM_Instr;
	wire [`XLEN-1:0] instr;
	//wire [6:0] opcode = instr[6:0];
	wire [2:0] f3 = instr[14:12];
	wire [6:0] f7 = instr[31:25];

	// Main Control signals
	wire MC_Branch;
	wire MC_MemRead;
	wire MC_MemWrite;
	wire MC_MemtoReg;
	wire [2:0] MC_ALUOp;
	wire [1:0] MC_ALUSrcA;
	wire MC_ALUSrcB;
	wire MC_RegWrite;
	wire [1:0] MC_Jump;
	wire MC_PCplus4;
	wire MC_CSR_en;
	wire MC_Ex;
`ifdef __RV32_M
	wire MC_ALUM_en;
`endif
	// REGISTER_FILE
	wire [`XLEN-1:0] i_Wd;
	wire [`XLEN-1:0] Rd1;
	wire [`XLEN-1:0] Rd2;

	// IMM_GEN
	wire [`XLEN-1:0] Imm;

	// ALU
	wire [`XLEN-1:0] A;
	wire [`XLEN-1:0] B;
	wire [`XLEN-1:0] Alu_Res;

	// Flag
	wire Z;

	// BRANCH_CONTROL
	wire DoBranch;

	// DATA MEMORY
	wire [`XLEN-1:0] DM_Addr;
	wire [`XLEN-1:0] DM_ReadData;

`ifdef __ATOMIC
	assign o_DM_f7 = f7;
`endif


	// CSRs
	wire [`XLEN-1:0] CSR_Rd; // temporary
	wire [`XLEN-1:0] CSR_epc;
	/* verilator lint_off UNUSED */
	wire [`XLEN-1:0] CSR_tvec; 
	wire [`XLEN-1:0] CSR_cause;
	/* verilator lint_on UNUSED */
	wire CSR_eret;
	wire CSR_ex;
	wire [`XLEN-1:0] CSR_Wd;
	wire [`XLEN-1:0] badaddr;

	// Exceptions
	wire ex_inst_addr;
	wire ex_ld_addr;
	wire ex_st_addr;

	// Stalls
	//wire IF_stall;
	wire IC_stall;
	wire EX_stall;
	wire DM_stall;
	wire MEM_stall;
	//assign IF_stall = IC_stall;
	assign MEM_stall = DM_stall;

	// Possible PC's values
	reg[`XLEN-1:0] PC_jump;

	// Assigning PC
	always_ff@(posedge i_clk) begin
		if(!i_rst) PC <= PC_RESET;
		else if(IC_stall || MEM_stall || EX_stall) PC <= PC;
		else PC <= PC_next;
	end

	// IM wires
	wire [`XLEN-1:0] i_DataBlock = i_IM_Instr;
	
	// --- Fetch Stage --- //
	// Instruction Memory
	i_cache #(.BLOCK_SIZE(1),
			  .ENTRIES   (I_CACHE_ENTRIES)) 
	i_cache 
	(
		.i_clk (i_clk),
		.i_rst (i_rst),

		// Memmory interface
		.i_DataBlock (i_DataBlock),
		.i_MemReady (i_IC_MemReady),
		.o_DataReq  (o_IC_DataReq),
		.o_MemAddr	(o_IM_Addr),

		// CPU interface
		.i_Addr     (PC),
		.o_Data 	(instr),
		.o_Stall    (IC_stall)
	);

	// --- Instruction Decode Stage --- //
	wire wr_to_rf = MC_RegWrite && !EX_stall && !CSR_ex && !MEM_stall;
	
	id_stage id_stage
		(
			.i_clk      (i_clk),
			.i_inst     (instr),
			.i_stall    (IC_stall),

			// Register File
			.o_rd1      (Rd1),
			.o_rd2      (Rd2),
			// Immediate generator
			.o_imm      (Imm),
			// Main Control
			.o_branch   (MC_Branch),
			.o_memread  (MC_MemRead),
			.o_memwrite (MC_MemWrite),
			.o_memtoreg (MC_MemtoReg),
			.o_alu_op   (MC_ALUOp),
			.o_alu_srca (MC_ALUSrcA),
			.o_alu_srcb (MC_ALUSrcB),
			.o_regwrite (MC_RegWrite),
			.o_jump     (MC_Jump),
			.o_pc_plus4 (MC_PCplus4),
			.o_csr_en   (MC_CSR_en),
			.o_ex       (MC_Ex),
`ifdef __ATOMIC
			.o_atomic   (o_MEM_atomic),
`endif
`ifdef __RV32_M
			.o_m_en     (MC_ALUM_en),
`endif

			// Writeback
			.i_wr_en    (wr_to_rf),
			.i_wr_data  (i_Wd)
		);

	// --- Execute Stage --- //
	ex_stage ex_stage
		(
			.i_rs1   (A),
			.i_rs2   (B),
			.i_aluop (MC_ALUOp),
			.i_f3    (f3),
			.i_f7    (f7),
			.o_res   (Alu_Res),
			.o_Z     (Z),
`ifdef __RV32_M
			.i_clk   (i_clk),
			.i_rst   (i_rst),
			.i_m_en  (MC_ALUM_en),

`endif
`ifdef __RV32_M_EXTERNAL
			.i_res   (i_EX_res),
			.i_ack   (i_EX_ack),
			.o_en    (o_EX_en),
			.o_rs1   (o_EX_rs1),
			.o_rs2   (o_EX_rs2),
			.o_f3    (o_EX_f3),
`endif
			.o_stall (EX_stall)
		);

	branch_control branch_control (
		.i_Branch   (MC_Branch),
		.i_Z        (Z),
		.i_Res      (Alu_Res[0]),
		.i_f3       (f3),
		.o_DoBranch (DoBranch)
	);

	assign DM_Addr = Alu_Res;

	d_mem d_mem
		(
			.i_clk           (i_clk),
			.i_rst           (i_rst),
			.i_wr_data       (Rd2),
			.i_addr          (DM_Addr),
			.i_f3            (f3),
			.i_wr_en         (MC_MemWrite),
			.i_rd_en         (MC_MemRead),
			.o_Rd            (DM_ReadData),
			.o_stall       	 (DM_stall),
			.o_ex_ld       	 (ex_ld_addr),
			.o_ex_st       	 (ex_st_addr),

			// CPU <-> Memory
			.to_mem   		 (DM_to_mem)
		);



	assign CSR_Wd = (f3[2] == 1'b1) ? Imm : Rd1;
	assign badaddr = (ex_ld_addr || ex_st_addr) ? DM_Addr : PC_jump;
	
	// CSR
	csr #(.HART_ID(HART)
		) csr (
		.i_clk 			(i_clk),
		.i_rst      	(i_rst),
		.i_CSR_en 		(MC_CSR_en),
		.i_inst     	(instr),
		.i_Wd    		(CSR_Wd),
		.i_PC			(PC),
		.i_badaddr  	(badaddr),

		.o_Rd    		(CSR_Rd),
		.o_eret  		(CSR_eret),
		.o_ex    		(CSR_ex),
		.o_tvec 		(CSR_tvec),
		.o_cause 		(CSR_cause),
		.o_epc  		(CSR_epc),

		// Exceptions
		.i_Ex    		(MC_Ex),
		.i_Ex_inst_addr (ex_inst_addr),
		.i_Ex_ld_addr  	(ex_ld_addr),
		.i_Ex_st_addr 	(ex_st_addr),

		// Interrupts
		.i_Int_tip (i_tip)
	);
	
	/*----- Datapath Muxes -----*/
	// PC Mux - Chooses PC's next value
	// TODO: this code and jump/branch signals must be improved
	always_comb begin
		if(CSR_ex) begin // Illegal instruction or MC_Ex(ECALL)
			PC_next = {CSR_tvec[`XLEN-1:2], 2'b00};
		end

		else if(CSR_eret) begin // xRET instruction (only MRET implemented)
			PC_next = CSR_epc;
		end
		else
			PC_next = PC_jump;
	end
	
	// Calculate PC without CSRs interference
	assign ex_inst_addr = |PC_jump[1:0];
	always_comb begin
		if(MC_Jump == 2'b10) begin // JALR
				PC_jump = Alu_Res & 32'hFFFF_FFFE; // Ignoring LSB
		end
		else begin
			if(MC_Jump == 2'b01 || DoBranch) begin // JAL
			 	PC_jump = PC + $signed(Imm<<1);
			end
			else begin // PC increment
				PC_jump = PC + 4;
			end		
		end
	end

	// ALU input A Mux
	assign A = MC_ALUSrcA[1] ? 0  :
			  (MC_ALUSrcA[0] ? PC : Rd1);

	// ALU input B Mux
	assign B = MC_ALUSrcB ? Imm : Rd2;

	// Write Back Mux
	assign i_Wd = MC_PCplus4 ? PC+4 :
				  MC_MemtoReg ? DM_ReadData :
				  MC_CSR_en ? CSR_Rd : Alu_Res;


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
				new_instruction(HART, instr, inst_cycles+1);
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
		rvfi_insn      <= instr;
		rvfi_trap      <= CSR_ex;
		rvfi_halt      <= 0; // Permanent 0
		rvfi_intr      <= 0; // Permanent 0
		rvfi_mode      <= 3; // M mode only
		rvfi_ixl       <= 1; // 32 bits only
		rvfi_rs1_addr  <= instr[19:15]; 
		rvfi_rs2_addr  <= instr[24:20];
		rvfi_rs1_rdata <= Rd1;
		rvfi_rs2_rdata <= Rd2;
		rvfi_rd_addr   <= (instr[11:7] && wr_to_rf) ? instr[11:7] : 0;
		rvfi_rd_wdata  <= (instr[11:7] && wr_to_rf) ? i_Wd : 0; // TBD
		rvfi_pc_rdata  <= PC;
		rvfi_pc_wdata  <= PC_next;

		rvfi_mem_addr  <= 0;
		rvfi_mem_rmask <= 0;
		rvfi_mem_wmask <= 0; 
		rvfi_mem_rdata <= 0; 
		rvfi_mem_wdata <= 0; 

		if(DM_to_mem.DM_Wen || DM_to_mem.DM_MemRead) begin
			rvfi_mem_addr  <= DM_to_mem.DM_Addr; // 
			rvfi_mem_rdata <= DM_to_mem.DM_ReadData;
			rvfi_mem_wdata <= DM_to_mem.DM_Wd;
			
			case(instr[13:12]) // Case f3
				2'b00 : begin
					mask[0] = DM_Addr[1:0] == 2'b00;  
					mask[1] = DM_Addr[1:0] == 2'b01;  
					mask[2] = DM_Addr[1:0] == 2'b10;  
					mask[3] = DM_Addr[1:0] == 2'b11;  
				end
				2'b01 : begin
					mask[1:0] = (DM_Addr[1] == 1'b0) ? 2'b11 : 2'b00;
					mask[3:2] = (DM_Addr[1] == 1'b1) ? 2'b11 : 2'b00;
				end
				2'b10 : begin
					mask = 4'b1111;
				end
				default: mask = 4'b0000;
			endcase

			if(DM_to_mem.DM_MemRead) begin
				rvfi_mem_rmask <= mask;
			end
			if(DM_to_mem.DM_Wen) begin
				rvfi_mem_wmask <= mask;
			end

		end
	end
	`endif

endmodule
