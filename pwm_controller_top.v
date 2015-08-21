`define PWM_INSTANCES 1

module pwm_controller_top (
	input  wire clk_i,
	input  wire nrst_i,
	output wire [`PWM_INSTANCES - 1:0] pwm_o,
	input  wire spi_mosi_i,
	input  wire spi_ncs_i,
	input  wire spi_clk_i,
	output wire spi_miso_o
);

	wire [7:0] b_addr;
	wire [7:0] b_data_r;
	wire [7:0] b_data_w;
	wire       b_write;
	
	wire [4:0] instance_addr;
	wire [`PWM_INSTANCES - 1:0] instance_select;
	wire [7:0] instance_rdata [`PWM_INSTANCES - 1:0];

	genvar instance_index;

	spi i_spi (
		.spi_mosi_i(spi_mosi_i),
		.spi_ncs_i (spi_ncs_i ),
		.spi_clk_i (spi_clk_i ),
		.spi_miso_o(spi_miso_o),
		.b_addr_o  (b_addr    ),
		.b_data_i  (b_data_r  ),
		.b_data_o  (b_data_w  ),
		.b_write_o (b_write   ),
		.pwm_clk_i (clk_i     ),
		.pwm_rst_i (nrst_i    )
	);

	generate
		for (instance_index = 0; instance_index < `PWM_INSTANCES; instance_index = instance_index + 1) begin: i_pwm_gen
			assign instance_select[instance_index] = instance_addr == instance_index;
			pwm i_pwm (
				.b_addr_i (b_addr  ),
				.b_data_i (b_data_w),
				.b_data_o (instance_rdata[instance_index]),
				.b_write_i(b_write & instance_select[instance_index]),
				.clk_i    (clk_i   ),
				.nrst_i   (nrst_i  ),
				.pwm_o    (pwm_o   )
			);
		end
	endgenerate

	assign instance_addr[4:0] =  b_addr[6:3];
	assign b_data_r = instance_rdata[instance_addr];

endmodule
