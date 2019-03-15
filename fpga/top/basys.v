module basys(
	input i_clk,
	input i_rst
	);

	localparam PC_RESET = 32'h8000_0000;
	RISC_V #(
			.PC_RESET(PC_RESET)
		) inst_RISC_V (
			.i_clk     (i_clk),
			.i_rst     (i_rst),
			.i_ack     (i_ack),
			.i_rd_data (i_rd_data),
			.o_bus_en  (o_bus_en),
			.o_wr_rd   (o_wr_rd),
			.o_wr_data (o_wr_data),
			.o_addr    (o_addr),
			.o_size    (o_size)
		);
	
	sp_ram #(
			.MEM_DEPTH(4096),
			.BYTES(4),
			.OUT_REGS(1)
		) inst_sp_ram (
			.i_clk     (i_clk),
			.i_rst     (i_rst),
			.i_cs      (i_cs),
			.i_wr_en   (i_wr_en),
			.i_b_en    (i_b_en),
			.i_wr_data (i_wr_data),
			.i_addr    (i_addr),
			.o_rd_data (o_rd_data)
		);


endmodule // basys