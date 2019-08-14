`timescale 1ns / 1ps

`include "arvi_defines.svh"

module div_top(
    input i_clk,
    input i_rst, 
    input i_start, 
    input [2:0] i_f3,
    input [`XLEN-1:0] i_rs1,
    input [`XLEN-1:0] i_rs2,
    output reg [`XLEN-1:0] o_res,
    output o_done
    );
       
        reg aux;  
        reg valid;
        reg done_invalid;
        reg i_rs1_sign,i_rs2_sign;
        reg [31:0] A;  
        reg [31:0] B;  
        wire [31:0] D;  
        wire [31:0] R;
        reg [31:0] div_out_inv, o_res_reg;
        wire done;
        wire enable;  

 
        divider divider
        (
            .i_clk   (i_clk),
            .i_rst   (i_rst),
            .i_start (enable),
            .i_rs1   (A),
            .i_rs2   (B),
            .o_res   (D),
            .o_rem   (R),
            .ok      (done)
        );

        always@(*) begin
            valid = 0;
            i_rs1_sign = 0;
            i_rs2_sign = 0;
            A = 0;
            B = 0;
            aux = 0;
            div_out_inv = 0;
            if(i_rs2!=0) begin
                if(i_f3==3'b100 | i_f3==3'b110) begin
                    // Invalid Operation: Overflow
                    if(i_rs1==32'h80000000 && i_rs2==32'hFFFFFFFF) begin
                        div_out_inv = i_f3[1]?0:32'h80000000;
                        valid = 1'b0;
                        aux = !i_start;
                    end    
                    // SIGNED DIVISION
                    else begin
                        valid = 1'b1;
                        if(i_rs1[31]==1'b1) begin
                            A = (~i_rs1)+1;
                            i_rs1_sign = 1'b1;
                        end
                        else begin
                            A = i_rs1;
                            i_rs1_sign = 0;
                        end
                        if(i_rs2[31]==1'b1) begin
                            B = (~i_rs2)+1;
                            i_rs2_sign = 1'b1;
                        end
                        else begin
                            B = i_rs2;
                            i_rs2_sign = 0;
                        end
                    end
                end 
                                             
                // UNSIGNED DIVISION
                if(i_f3==3'b101 | i_f3==3'b111) begin
                    valid = 1'b1;
                    i_rs1_sign = 0;
                    i_rs2_sign = 0;
                    A = i_rs1;
                    B = i_rs2;
                end

            end
            //Invalid Operation: Division by 0
            else begin
                div_out_inv = i_f3[1]?i_rs1:32'hFFFFFFFF;
                valid = 1'b0;
                aux = !i_start;
            end
        end
            
        always@(*) begin
            o_res = 0;
            if(done & valid) begin
                if(i_f3[1]) //REMU or REM
                    o_res = ((~i_rs1_sign & ~i_rs2_sign)|(~i_rs1_sign & i_rs2_sign))?R:(~R)+1;
                else //DIVU or DIV
                    o_res = (i_rs1_sign ^ i_rs2_sign)?(~D)+1:D;
            end
            else if(!valid)
                o_res = o_res_reg;
        end
        
        always@(posedge i_clk)begin
            if(!i_rst)
                done_invalid <= 1'b1;
            else
                if(!valid) begin
                    done_invalid <= aux;
                    o_res_reg <= div_out_inv;
                end
        end 
       
        assign o_done = valid?done:done_invalid;
        assign enable = valid?i_start:1'b0;

endmodule