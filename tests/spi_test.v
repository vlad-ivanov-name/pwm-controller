`define SPI_CLK_CYCLE		200

module spi_test();

	reg        spi_mosi_i;
	reg        spi_ncs_i ;
	reg        spi_clk_i ;
	wire       spi_miso_o;
	wire [7:0] b_addr_o  ;
	reg  [7:0] b_data_i  ;
	wire [7:0] b_data_o  ;
	wire [1:0] b_event_o ;

	spi i_spi (
		.spi_mosi_i(spi_mosi_i),
		.spi_ncs_i (spi_ncs_i ),
		.spi_clk_i (spi_clk_i ),
		.spi_miso_o(spi_miso_o),
		.b_addr_o  (b_addr_o  ),
		.b_data_i  (b_data_i  ),
		.b_data_o  (b_data_o  ),
		.b_event_o (b_event_o )
	);

	task spi_write_byte;
		input integer data;
		integer i;
		begin
			for (i = 0; i < 8; i = i + 1) begin
				spi_mosi_i <= data[7 - i];
				#(`SPI_CLK_CYCLE / 2);
				spi_clk_i <= 1;
				#(`SPI_CLK_CYCLE / 2);
				spi_clk_i <= 0;
			end
		end
	endtask : spi_write_byte

	task spi_write_reg;
		input integer addr;
		input integer data;
		begin
			spi_ncs_i <= 0;
			spi_write_byte(addr & 'h7F);
			spi_write_byte(data);
			spi_ncs_i <= 1;
		end
	endtask : spi_write_reg

	task spi_read_reg;
		input integer addr;
		input integer data;
		begin
			spi_ncs_i <= 0;
			b_data_i <= data;
			spi_write_byte(addr | 'h80);
			spi_write_byte('hFF);
			spi_ncs_i <= 1;
		end
	endtask : spi_read_reg

	initial begin
		spi_mosi_i <= 0;
		spi_ncs_i <= 1;
		spi_clk_i <= 0;
		b_data_i <= 0;

		#200;

		spi_write_reg('hA5, 'h22);

		$display("Address: 0x%h", b_addr_o);
		$display("Data: 0x%h", b_data_o);

		#200

		spi_read_reg('h00, 'hA5);
	end
endmodule