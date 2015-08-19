`define PWM_BITS	10

module pwm (
	input  wire [7:0] b_addr_i ,
	input  wire [7:0] b_data_i ,
	output wire [7:0] b_data_o ,
	input  wire [1:0] b_event_i,
	input  wire       clk_i    ,
	input  wire       nrst_i   ,
	output wire       pwm_o
);

	reg [`PWM_BITS - 1:0] duty_cycle;
	reg [`PWM_BITS - 1:0] counter   ;

	reg  [ 7:0] ctl0          ;
	wire [12:0] counter_next  ;
	reg  [ 7:0] lfsr          ;
	wire        lfsr_feedback ;
	wire        lfsr_clk      ;
	wire [ 7:0] lfsr_shifted  ;
	reg  [ 2:0] lfsr_shift    ;
	wire        cycle_complete;
	wire        ctl0_enable   ;
	wire [ 3:0] ctl0_ss       ;

	// register i/o
	always @(posedge clk_i or negedge nrst_i) begin
		if(~nrst_i) begin
			ctl0 <= 0;
			duty_cycle <= 0;
			lfsr_shift <= 0;
		end else begin
			if (b_event_i[1]) begin
				case (b_addr_i)
					'h00: begin
						ctl0 <= b_data_i;
						lfsr_shift <= ((3 - b_data_i[1:0]) << 1) + (3 - b_data_i[1:0]);
					end
					'h01: begin
						duty_cycle[`PWM_BITS - 1:8] <= b_data_i[3:0];
					end
					'h10: begin
						duty_cycle[7:0] <= b_data_i;
					end
				endcase
			end
		end
	end

	// pwm output
	always @(posedge clk_i or negedge nrst_i) begin
		if(~nrst_i) begin
			counter <= 0;
		end else begin
			if (ctl0_enable) begin
				counter <= counter_next[`PWM_BITS - 1:0];
			end
		end
	end

	// lfsr
	always @(posedge lfsr_clk or negedge nrst_i) begin
		if(~nrst_i) begin
			lfsr <= 8'hFF;
		end else begin
			lfsr[0] <= lfsr_feedback;
			lfsr[1] <= lfsr[0];
			lfsr[2] <= lfsr[1] ^ lfsr_feedback;
			lfsr[3] <= lfsr[2] ^ lfsr_feedback;
			lfsr[4] <= lfsr[3] ^ lfsr_feedback;
			lfsr[5] <= lfsr[4];
			lfsr[6] <= lfsr[5];
			lfsr[7] <= lfsr[6];
		end
	end

	assign lfsr_feedback  = lfsr[7];
	assign cycle_complete = counter == ('b1 << `PWM_BITS) - 1;
	assign lfsr_clk       = clk_i & (ctl0_ss != 0) & cycle_complete;

	assign b_data_o =
		(b_addr_i == 'h00) ? ctl0 :
		(b_addr_i == 'h01) ? { `PWM_BITS - 8 'b0, duty_cycle[`PWM_BITS - 1:8] } :
		(b_addr_i == 'h10) ? duty_cycle[7:0] : 8'h00;

	assign lfsr_shifted = lfsr >> lfsr_shift;
	assign counter_next = counter + 1;
	assign pwm_o        = counter < duty_cycle + lfsr_shifted;

	assign ctl0_enable  = ctl0[7];
	assign ctl0_ss[1:0] = ctl0[1:0];

endmodule