`timescale 1ns / 1ps

`include "arvi_defines.vh"
`include "extensions/m/m-isa.vh"

module mul_top(
    input i_clk, 
    input i_start,
    input [2:0] i_f3,
	input [`XLEN-1:0] i_rs1, 
    input [`XLEN-1:0] i_rs2,
    output o_done,
    output reg [`XLEN-1:0] o_res
    );

    reg instr_mulh, instr_mulhsu;
	wire instr_rs1_signed;
	wire instr_rs2_signed;
	
	reg [32:0] mult_in_a;
    reg [32:0] mult_in_b;
    
    wire [63:0]out_s;
	      
	assign instr_rs1_signed = |{instr_mulh, instr_mulhsu};                     
	assign instr_rs2_signed = |{instr_mulh};                                           
	                         
    always @(*) begin
		instr_mulh   = 0;
		instr_mulhsu = 0;
			case (i_f3)
				`MUL : begin
				    o_res = out_s[31:0];
				end
				`MULH : begin
				    instr_mulh = 1;
				    o_res = out_s[63:32];
				end
				`MULHSU : begin
				    instr_mulhsu = 1;
				    o_res = out_s[63:32];
				end
				`MULHU : begin
				    o_res = out_s[63:32];
				end
			default: begin end
			endcase
	end
	
	always@(*)begin
	   if(i_start)
	    begin
	    	// Problema aqui!
	    	// Perceba a atribuição blocante me circuito posedge i_clk
            mult_in_a = {{i_rs1[31]&instr_rs1_signed},i_rs1};
            mult_in_b = {{i_rs2[31]&instr_rs2_signed},i_rs2};
        end
	end

multiplier m_s(
		.i_clk   (i_clk),
        .i_a     (mult_in_a), 
		.i_b 	 (mult_in_b),
		.i_start (i_start), 
		.o_c 	 (out_s),
		.o_done  (o_done)
);

endmodule
