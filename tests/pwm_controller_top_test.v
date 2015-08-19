`define CLK_CYCLE			100
`define SPI_CLK_CYCLE		2000
`define PWM_INSTANCES		1

module pwm_controller_top_test();

	reg clk;
	reg nrst;

	wire [`PWM_INSTANCES-1:0] pwm_o;
	
	reg spi_mosi_i;
	reg spi_ncs_i;
	reg spi_clk_i;
	wire spi_miso_o;

	pwm_controller_top i_pwm_controller_top (
		.clk_i     (clk       ),
		.nrst_i    (nrst      ),
		.pwm_o     (pwm_o     ),
		.spi_mosi_i(spi_mosi_i),
		.spi_ncs_i (spi_ncs_i ),
		.spi_clk_i (spi_clk_i ),
		.spi_miso_o(spi_miso_o)
	);

	always begin : clock
		clk <= 0;
		#(`CLK_CYCLE / 2);
		clk <= 1;
		#(`CLK_CYCLE / 2);
	end

	initial begin : reset
		#(`CLK_CYCLE);
		nrst <= 0;
		#(`CLK_CYCLE);
		nrst <= 1;
		#(`CLK_CYCLE * 4);
	end

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
			spi_write_byte(addr | 'h80);
			spi_write_byte('hFF);
			spi_ncs_i <= 1;
		end
	endtask : spi_read_reg

	initial begin
		spi_mosi_i <= 0;
		spi_ncs_i <= 1;
		spi_clk_i <= 0;

		#(`CLK_CYCLE);

		spi_write_reg('h01, 'h01);

		#(`CLK_CYCLE);

		spi_write_reg('h00, 'h81);
	end
endmodule