module ad7606#(
	parameter CLK_FREQUENCY = 30_000_000
)(
	input wire clk,   //max clock 
	input wire power  //Control signal for power up/down of device
);
	localparam TICKS_PER_S  = CLK_FREQUENCY;
	localparam TICKS_PER_MS = TICKS_PER_S /1_000;
	localparam TICKS_PER_US = TICKS_PER_MS/1_000;

	localparam TIME_PER_TICK_NS = 1e9/CLK_FREQUENCY;
	localparam TIME_PER_TICK_US = 1e6/CLK_FREQUENCY;
	localparam TIME_PER_TICK_MS = 1e3/CLK_FREQUENCY;
	localparam TIME_PER_TICK_S  =   1/CLK_FREQUENCY;


`ifdef SIM
	localparam POWER_ON_TIME_MS = 30;
	localparam POWER_ON_TIME_TICKS = POWER_ON_TIME_MS * 1;
`else
	localparam POWER_ON_TIME_MS = 30;
	localparam POWER_ON_TIME_TICKS = POWER_ON_TIME_MS * TICKS_PER_MS;
`endif

	reg [$clog2(POWER_ON_TIME_TICKS):0] pwr_ctr = 0;
	always @(posedge clk) begin
		if( pwr_ctr >= POWER_ON_TIME_TICKS ) begin
			pwr_ctr <= 0;
		end
		else if(power == 1) begin
			pwr_ctr <= pwr_ctr+1;
		end
	end

endmodule
