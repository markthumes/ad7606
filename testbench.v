`timescale 1 ns / 10 ps

module top_tb();
	reg clk = 0;
	reg pwr = 0;
	reg busy = 0;
	
	wire ADC_STBY;
	wire ADC_CONV;
	wire ADC_nCS;
	wire ADC_SCLK;
	wire ADC_RESET;

	initial begin
		#100
		pwr = 1;
		#3000
		pwr = 0;
		#100
		pwr = 1;
	end

	always @(posedge ADC_CONV) begin
		#20
		busy = 1;
		#100
		busy = 0;
	end

	ad7606 adc(
		.clk(clk),
		.power(pwr),
		.busy(busy),
		.conv(ADC_CONV),
		.n_cs(ADC_nCS),
		.sclk(ADC_SCLK),
		.reset(ADC_RESET),
		.stby(ADC_STBY)
	 );

	//sim time: 10000 * 1 ns = 10 us;
	localparam DURATION = 40000; //total sim time
	////////////////////////////////////////////////////////////////
	//                       GENERATE CLOCK                       //
	//      1 / (( 2 * 41.67) * 1 ns) = 11,999,040.08 MHz         //
	always begin
		#16.67
		clk = ~clk;
	end

	////////////////////////////////////////////////////////////////
	//                        RUN SIMULATION                      //
	initial begin
		//create sim value change dump file
		$dumpfile("top.vcd");
		//0 means dump all variable levels to watch
		$dumpvars(0, top_tb);

		//Wait for a given amount of time for sim to end
		#(DURATION)

		$display("Finished!");
		$finish;
	end

endmodule
