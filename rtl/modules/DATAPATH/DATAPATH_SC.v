/*
	File containing a DATAPATH module to a single-cycle RISC-V processor.
*/

`timescale 1ns / 1ps

`include "defines.vh"

module DATAPATH_SC(
	// Instruction Memory connections
	input  [`XLEN-1:0] i_IM_Instr,
	input i_IC_MemReady,
	output o_IC_DataReq,
	output [`XLEN-1:0] o_IM_Addr,

	// Data Memory connections
	input  [`XLEN-1:0] i_DM_ReadData,
	output [`XLEN-1:0] o_DM_Wd,
	output [`XLEN-1:0] o_DM_Addr,
	output [2:0] o_DM_f3,
	output o_DM_Wen,
	output o_DM_MemRead,

	// General connections
	input i_clk,
	input i_rst
	);

	parameter PC_RESET = `PC_RESET;	

	reg [`XLEN-1:0] PC;
	reg [`XLEN-1:0] PC_next;

	// Instruction wires renaming
	//wire [`XLEN-1:0] instr = i_IM_Instr;
	wire [`XLEN-1:0] instr;
	//wire [6:0] opcode = instr[6:0];
	wire [2:0] f3     = instr[14:12];
	wire [6:0] f7     = instr[31:25];

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

	// REGISTER_FILE
	wire [`XLEN-1:0] i_Wd;
	wire [`XLEN-1:0] Rd1;
	wire [`XLEN-1:0] Rd2;

	// IMM_GEN
	wire [`XLEN-1:0] Imm;

	// ALU
	wire [3:0] alu_control_lines;
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
	reg ex_inst_addr;
	reg ex_ld_addr;
	reg ex_st_addr;

	// Assigning PC
	always@(posedge i_clk) begin
		if(!i_rst) PC <= PC_RESET;
		else if(IC_Stall) PC <= PC;
		else 			  PC <= PC_next;

		if(PC[1:0] !== 2'b00)
			$display("ERROR PC!");
	end

	// Assigning instruction to be fetched
	//assign o_IM_Addr = PC;

	// IM wires
	/* verilator lint_off UNUSED */
	wire [`XLEN-1:0] i_DataBlock = i_IM_Instr;
	//wire i_MemReady;

	wire IC_Stall;
	/* verilator lint_on UNUSED */
	
	// Instruction Memory
	I_CACHE #(.BLOCK_SIZE(1),
			  .ENTRIES   (32)) 
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

		.i_Instr   (instr),
		.i_Stall   (IC_Stall)
	);

	REGISTER_FILE reg_file (
    	.o_Rd1(Rd1),
    	.o_Rd2(Rd2),
    	.i_Rnum1(instr[19:15]),
    	.i_Rnum2(instr[24:20]),
    	.i_Wen(MC_RegWrite),
    	.i_Wnum(instr[11:7]),
    	.i_Wd(i_Wd),
    	.i_clk(i_clk)
    );

	IMM_GEN  imm_gen (
		.i_Instr(instr),
		.o_Ext(Imm)
	);

	ALU_CONTROL alu_control (
		.o_ALUControlLines (alu_control_lines),
		.i_Funct7          (f7),
		.i_Funct3          (f3),
		.i_ALUOp           (MC_ALUOp)
	);

	ALU alu (
		.i_op(alu_control_lines),
		.i_Ra(A),
		.i_Rb(B),
		.o_Z(Z),
		.o_Rc(Alu_Res)
	);

	BRANCH_CONTROL branch_control (
		.i_Branch   (MC_Branch),
		.i_Z        (Z),
		.i_Res      (Alu_Res[0]),
		.i_f3       (f3),
		.o_DoBranch (DoBranch)
	);

	assign DM_Addr = Alu_Res[`XLEN-1:0];

/*
	Data Memory signals
	Using a virtual memory for simulation purposes.
	This will be a real module when D-Cache is implemented.
*/
	assign DM_ReadData  = read_data;
	assign o_DM_Wd      = Rd2;
	assign o_DM_Addr    = DM_Addr;
	assign o_DM_Wen     = MC_MemWrite && !ex_st_addr;
	assign o_DM_MemRead = MC_MemRead  && !ex_ld_addr;
	assign o_DM_f3	    = f3;

	reg [`XLEN-1:0] read_data;
	always@(*) begin
		ex_ld_addr = 0;
		ex_st_addr = 0;
		if(MC_MemRead) begin
			case(f3) 
				3'b000 : read_data = {{`XLEN-8{i_DM_ReadData[7]}}, i_DM_ReadData[7:0]}; 
				3'b001 : read_data = {{`XLEN-16{i_DM_ReadData[15]}}, i_DM_ReadData[15:0]}; 
				3'b010 : read_data = i_DM_ReadData;
				3'b100 : read_data = {{`XLEN-8 {1'b0}}, i_DM_ReadData[7:0]};
				3'b101 : read_data = {{`XLEN-16{1'b0}}, i_DM_ReadData[15:0]};
				default: read_data = i_DM_ReadData;
			endcase 
			case(f3[1:0])
				2'b01 :	ex_ld_addr = (DM_Addr[0]) 	? 1'b1 : 1'b0;
				2'b10 : ex_ld_addr = (|DM_Addr[1:0]) ? 1'b1 : 1'b0;
				default : ex_ld_addr = 0;
			endcase
		end
		if(MC_MemWrite) begin
			case(f3[1:0])
				2'b01 : ex_st_addr = (DM_Addr[0]) ? 1'b1 : 1'b0;
				2'b10 : ex_st_addr = (|DM_Addr[1:0]) ? 1'b1 : 1'b0;
				default : ex_st_addr = 0;
			endcase
		end
	end

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
	CSR csr (
		.i_clk 		(i_clk),
		.i_rst      (i_rst),
		.i_CSR_en 	(MC_CSR_en),
		.i_Wd    	(CSR_Wd),
		.i_addr  	(instr[31:20]),
		.i_Funct3	(f3),
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
		.i_Ex_st_addr  (ex_st_addr)
	);
	/* verilator lint_on UNUSED */
	
	/*----- Datapath Muxes -----*/
	// PC Mux - Chooses PC's next value
	// NOTA: this code and jump/branch signals must be improved
	always@(*) begin
		ex_inst_addr = 0;
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
		ex_inst_addr = |PC_jump[1:0];
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

endmodule
