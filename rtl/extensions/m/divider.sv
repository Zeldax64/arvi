`timescale 1ns / 1ps


module divider(  
   input  i_clk,  
   input  i_rst,  
   input  i_start,  
   input  [31:0] i_rs1,  
   input  [31:0] i_rs2,  
   output [31:0] o_res,  
   output [31:0] o_rem,  
   output ok   
  );

    reg active;   
    reg startreg;
    reg [4:0] cycle;   
    reg signed [31:0] result;    
    reg signed [31:0] denom;   
    reg signed [31:0] work;       
    wire [32:0] sub; 
    
    always_ff@(posedge i_clk) begin  
      if (!i_rst) begin  
        active <= 0;  
        cycle  <= 0;  
        result <= 0;  
        denom  <= 0;  
        work   <= 0;  
      end  
      else if(startreg) begin  
        if (active) begin  
          if (sub[32] == 0) begin  
            work <= sub[31:0];  
            result <= {result[30:0], 1'b1};  
          end  
          else begin  
            work <= {work[30:0], result[31]};  
            result <= {result[30:0], 1'b0};  
          end
          if (cycle == 0) begin  
            active <= 0;  
          end  
          cycle <= cycle - 5'd1;  
        end  
        else begin  
          cycle  <= 5'd31;  
          result <= i_rs1;  
          denom  <= i_rs2;  
          work   <= 32'b0;  
          active <= 1;  
       end  
     end  
    end  
   
    always_comb begin
      startreg = 1;
      if(i_start)
        startreg = 1;
      else if(ok)
        startreg = 0;
    end

    assign sub   = { work[30:0], result[31] } - denom; 
    assign o_res = result;  
    assign o_rem = work;  
    assign ok    = ~active;

  
 endmodule   
 