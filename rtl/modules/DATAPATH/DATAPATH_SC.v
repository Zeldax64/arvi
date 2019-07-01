/*
	File containing a DATAPATH module of a single-cycle RISC-V processor.
*/

`timescale 1ns / 1ps

`include "arvi_defines.vh"

module DATAPATH_SC
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
	input  i_DM_data_ready,
	input  [`XLEN-1:0] i_DM_ReadData,
	output [`XLEN-1:0] o_DM_Wd,
	output [`XLEN-1:0] o_DM_Addr,
	output [2:0] o_DM_f3,
	output o_DM_Wen,
	output o_DM_MemRead,

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

	// General connections
	input i_clk,
	input i_rst
	);
	// TODO: find a place to this signal
`ifdef __ATOMIC
	assign o_DM_f7 = f7;
`endif

	reg [`XLEN-1:0] PC;
	reg [`XLEN-1:0] PC_next;

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

	// Exceptions
	wire ex_inst_addr;
	wire ex_ld_addr;
	wire ex_st_addr;

	// Stalls
	//wire IF_stall;
	wire MEM_stall;
	//assign IF_stall = IC_stall;
	assign MEM_stall = DM_stall;

	// Assigning PC
	always@(posedge i_clk) begin
		if(!i_rst) PC <= PC_RESET;
		else if(IC_Stall || MEM_stall || EX_stall) PC <= PC;
		else PC <= PC_next;
	end

	// IM wires
	wire [`XLEN-1:0] i_DataBlock = i_IM_Instr;
	wire IC_Stall;
	
	// --- Fetch Stage --- //
	// Instruction Memory
	I_CACHE #(.BLOCK_SIZE(1),
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
		.o_Stall    (IC_Stall)
	);

	// --- Decode Stage --- //
	// Main Control
	MAIN_CONTROL main_control
	(
		.o_Branch   (MC_Branch),
		.o_MemRead  (MC_MemRead),
		.o_MemWrite (MC_MemWrite),
		.o_MemToReg (MC_MemtoReg),
		.o_ALUOp    (MC_ALUOp),
		.o_ALUSrcA  (MC_ALUSrcA),
		.o_ALUSrcB  (MC_ALUSrcB),
		.o_RegWrite (MC_RegWrite),
		.o_Jump     (MC_Jump),
		.o_PCplus4  (MC_PCplus4),
		.o_CSR_en  	(MC_CSR_en),
		.o_Ex 	    (MC_Ex),

`ifdef __ATOMIC
		.o_atomic  (o_MEM_atomic),
`endif
`ifdef __RV32_M
		.o_ALUM_en (MC_ALUM_en),
`endif

		.i_Instr   (instr),
		.i_Stall   (IC_Stall)

	);

	wire wr_to_rf = MC_RegWrite && !CSR_ex && !MEM_stall;
	REGISTER_FILE reg_file (
    	.o_Rd1(Rd1),
    	.o_Rd2(Rd2),
    	.i_Rnum1(instr[19:15]),
    	.i_Rnum2(instr[24:20]),
    	.i_Wen(wr_to_rf),
    	.i_Wnum(instr[11:7]),
    	.i_Wd(i_Wd),
    	.i_clk(i_clk)
    );

	IMM_GEN  imm_gen (
		.i_Instr(instr),
		.o_Ext(Imm)
	);


	// --- Execute Stage --- //
	wire EX_stall;

	EX ex_stage
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

	BRANCH_CONTROL branch_control (
		.i_Branch   (MC_Branch),
		.i_Z        (Z),
		.i_Res      (Alu_Res[0]),
		.i_f3       (f3),
		.o_DoBranch (DoBranch)
	);

	assign DM_Addr = Alu_Res;
	/* verilator lint_off UNUSED */
	wire DM_stall;
	/* verilator lint_on UNUSED */
	DATA_MEMORY_V2 d_mem
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
			.i_DM_data_ready (i_DM_data_ready),
			.i_DM_ReadData   (i_DM_ReadData),
			.o_DM_Wd         (o_DM_Wd),
			.o_DM_Addr       (o_DM_Addr),
			.o_DM_f3       	 (o_DM_f3),
			.o_DM_Wen      	 (o_DM_Wen),
			.o_DM_MemRead  	 (o_DM_MemRead)
		);


	/* verilator lint_off UNUSED */
	wire [`XLEN-1:0] CSR_Rd; // temporary
	wire [`XLEN-1:0] CSR_tvec; 
	wire [`XLEN-1:0] CSR_epc;
	wire [`XLEN-1:0] CSR_cause;
	wire CSR_eret;
	wire CSR_ex;
	wire [`XLEN-1:0] CSR_Wd = (f3[2] == 1'b1) ? Imm : Rd1;
	wire [`XLEN-1:0] badaddr = (ex_ld_addr || ex_st_addr) ? DM_Addr : PC_jump;
	
	// CSR
	CSR #(.HART_ID(HART)
		) csr (
		.i_clk 		(i_clk),
		.i_rst      (i_rst),
		.i_CSR_en 	(MC_CSR_en),
		.i_inst     (instr),
		.i_Wd    	(CSR_Wd),
		.i_PC		(PC),
		.i_badaddr  (badaddr),

		.o_Rd    	(CSR_Rd),
		.o_eret  	(CSR_eret),
		.o_ex    	(CSR_ex),
		.o_tvec 	(CSR_tvec),
		.o_cause 	(CSR_cause),
		.o_epc  	(CSR_epc),

		// Exceptions
		.i_Ex    	(MC_Ex),
		.i_Ex_inst_addr (ex_inst_addr),
		.i_Ex_ld_addr  (ex_ld_addr),
		.i_Ex_st_addr  (ex_st_addr),

		// Interrupts
		.i_Int_tip (i_tip)
	);
	/* verilator lint_on UNUSED */
	
	/*----- Datapath Muxes -----*/
	// PC Mux - Chooses PC's next value
	// NOTA: this code and jump/branch signals must be improved
	always@(*) begin
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
	reg[`XLEN-1:0] PC_jump;
	assign ex_inst_addr = |PC_jump[1:0];
	always@(*) begin
		if(MC_Jump == 2'b10) begin // JALR
				PC_jump = Alu_Res & 32'hFFFF_FFFE;
		end
		else
			if(MC_Jump == 2'b01 || DoBranch) begin // JAL
			 	PC_jump = PC + $signed(Imm<<1);
			end
			else begin // PC increment
				PC_jump = PC + 4;
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
	// ***** Performance DPI ***** //
	integer inst_cycles;
	integer inst_stall;
	always@(posedge i_clk) begin
		if(!i_rst) begin 
			inst_cycles <= 0;
			inst_stall <= 0;
		end
		else begin
			// Cache Performance
			if(i_cache.hit && (inst_cycles == 0)) begin
				cache_hit();
			end
			if(IC_Stall) begin
				inst_stall <= inst_stall + 1;
			end
			// Instruction Performance
			if(IC_Stall || MEM_stall || EX_stall) 
				inst_cycles <= inst_cycles+1;
			else begin // Finished instruction execution
				new_instruction(instr, inst_cycles+1);
				if(inst_stall !== 0) begin
					cache_miss(inst_stall);
				end
				inst_stall <= 0;
				inst_cycles <= 0;
			end
		end
	end
`endif

endmodule
