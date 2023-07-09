`timescale 1 ns / 10 ps

module top_tb();
	reg clk = 0;
	reg pwr = 0;

	initial begin
		#100
		pwr = 1;
	end

	ad7606 adc(
		.clk(clk),
		.power(pwr) );

	//sim time: 10000 * 1 ns = 10 us;
	localparam DURATION = 10000; //total sim time
	////////////////////////////////////////////////////////////////
	//                       GENERATE CLOCK                       //
	//      1 / (( 2 * 41.67) * 1 ns) = 11,999,040.08 MHz         //
	always begin
		#10
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
