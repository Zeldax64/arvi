
module sp_ram
#(
  parameter MEM_DEPTH = 1024, // usually 2**ADDR_WIDTH, but can be lower
  parameter BYTES     = 4,
  parameter OUT_REGS  = 1    // set to 1 to enable outregs
)(
  input  i_clk,
  input  i_rst,
  input  i_cs,
  input  i_wr_en,
  input  [BYTES-1:0] i_b_en,
  input  [BYTES*8-1:0] i_wr_data,
  input  [$clog2(MEM_DEPTH*4)-1:0] i_addr,
  output reg o_ack,
  output [BYTES*8-1:0] o_rd_data
);

  reg [BYTES*8-1:0] RdData_DN;
  reg [BYTES*8-1:0] RdData_DP;

  reg [BYTES*8-1:0] mem[MEM_DEPTH-1:0];

  wire [$clog2(MEM_DEPTH)-1:0] addr;
  assign addr = i_addr[$clog2(MEM_DEPTH*4)-1:2];

  always@(posedge i_clk) begin
    if(i_cs) begin
      if(i_wr_en) begin
        if(i_b_en[0]) mem[addr][7:0]   <= i_wr_data[7:0];
        if(i_b_en[1]) mem[addr][15:8]  <= i_wr_data[15:8];
        if(i_b_en[2]) mem[addr][23:16] <= i_wr_data[23:16];
        if(i_b_en[3]) mem[addr][31:24] <= i_wr_data[31:24];
      end
      RdData_DN <= mem[addr];
      o_ack <= 1;
    end
    else begin
      o_ack <= 0;
    end
  end

  // output regs
  generate
    if (OUT_REGS>0) begin : g_outreg
      always@(posedge i_clk) begin
        if(i_rst == 1'b0) begin
          RdData_DP  <= 0;
        end
        else  begin
          RdData_DP  <= RdData_DN;
        end
      end
    end
  endgenerate // g_outreg

  /*
  // output reg bypass
  generate
    if (OUT_REGS==0) begin : g_oureg_byp
      assign RdData_DP  = RdData_DN;
    end
  endgenerate// g_oureg_byp
  */
  assign o_rd_data = RdData_DN;

  initial begin
    $readmemh("program.mem",mem);
  end
endmodule