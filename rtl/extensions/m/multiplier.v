`timescale 1ns / 1ps

module multiplier(
    input i_clk, 
    input i_start, 
    input [32:0] i_a,
    input [32:0] i_b, 
    output reg [63:0] o_c, 
    output reg o_done);
    always@(posedge i_clk) begin
        if(i_start) begin
            o_c  <= $signed(i_a)*$signed(i_b);
            o_done <= 1;
        end
        else begin
            o_done <= 0;
        end
    end
    
    
endmodule
