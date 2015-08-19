`define CLK_CYCLE	200

module pwm_test();

	reg  [7:0] b_addr_i ;
	reg  [7:0] b_data_i ;
	wire [7:0] b_data_o ;
	reg  [1:0] b_event_i;
	reg        clk_i    ;
	reg        nrst_i   ;
	wire       pwm_o    ;

	integer counter = 0;
	integer out_state = 0;

	pwm i_pwm (
		.b_addr_i (b_addr_i ),
		.b_data_i (b_data_i ),
		.b_data_o (b_data_o ),
		.b_event_i(b_event_i),
		.clk_i    (clk_i    ),
		.nrst_i   (nrst_i   ),
		.pwm_o    (pwm_o    )
	);

	always begin : clock
		clk_i <= 0;
		#(`CLK_CYCLE / 2);
		clk_i <= 1;
		#(`CLK_CYCLE / 2);
	end

	always @(posedge clk_i) begin: cycle_length
		if (out_state && !pwm_o) begin
			$display("Cycle: %d", counter);
		end else if (!out_state && pwm_o) begin
			counter <= 0;
		end else begin
			counter <= counter + 1;
		end
		out_state <= pwm_o;
	end

	task bus_write();
		input integer addr;
		input integer data;
		begin
			b_data_i <= data;
			b_addr_i <= addr;
			b_event_i <= 2'b11;

			#(`CLK_CYCLE);

			b_event_i <= 0;

			#(`CLK_CYCLE);
		end
	endtask : bus_write

	initial begin
		nrst_i <= 0;
		b_addr_i <= 0;
		b_data_i <= 0;
		b_event_i <= 0;

		#(`CLK_CYCLE);

		nrst_i <= 1;

		#(`CLK_CYCLE * 4);

		bus_write('h00, 'h82);
		bus_write('h01, 'h01);

		#200;
		#200;
	end
endmodule