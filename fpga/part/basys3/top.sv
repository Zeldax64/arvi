module top(
	input i_clk,
	input i_rst,
	output [15:0] led
	);
	
	localparam PC_RESET = 32'h8000_0000;
	
	reg [1:0] clk_div;
	wire clk;
	wire rst = ~i_rst;
	reg [31:0] to_host;

	wire ack, wr_en, bus_en;
	wire [3:0] byte_en;
	wire [31:0] rd_data, wr_data, addr;

	always@(posedge i_clk) begin
		if(!i_rst)
			clk_div <= 0;
		else 
			clk_div <= clk_div+1;
	end

	assign clk = clk_div[1];

	RISC_V #(
			.PC_RESET(PC_RESET)
		) inst_RISC_V (
			.i_clk     (clk),
			.i_rst     (rst),
			.i_ack     (ack),
			.i_rd_data (rd_data),
			.o_bus_en  (bus_en),
			.o_wr_en   (wr_en),
			.o_wr_data (wr_data),
			.o_addr    (addr),
			.o_byte_en (byte_en)
		);

	sp_ram #(
			.MEM_DEPTH(4096),
			.BYTES(4),
			.OUT_REGS(0)
		) inst_sp_ram (
			.i_clk     (clk),
			.i_rst     (rst),
			.i_cs      (bus_en),
			.i_wr_en   (wr_en),
			.i_b_en    (byte_en),
			.i_wr_data (wr_data),
			.i_addr    (addr),
			.o_ack     (ack),
			.o_rd_data (rd_data)
		);

	always@(posedge clk) begin
		if(!rst) begin
			to_host <= 0;
		end
		else if(bus_en && wr_en && addr == 32'h8000_1000) begin
			to_host <= wr_data;
		end
	end 

	assign led = to_host[15:0];

endmodule // basys