module sync(
	input wire clk,
	input wire sig,
	output wire rise,
	output wire fall
);
	reg [2:0] detector = 2'd0;
	always @(posedge clk) detector <= {detector[1:0], sig};
	assign rise = (detector[2:1]==2'b01);
	assign fall = (detector[2:1]==2'b10);
endmodule

module delay #(
	parameter TICKS = 50
)(
	input wire clk,
	input wire start,
	output reg done
);
	initial done = 0;
	reg [$clog2(TICKS):0] ctr = 0;
	always @(posedge clk) begin
		if( start && !done ) begin
			if( ctr >= TICKS ) begin
				ctr <= 0;
				done <= 1;
			end
			else ctr <= ctr + 1;
		end
	end
endmodule

module delay2 #(
	parameter TIME_NS = 50,
	parameter TIME_PER_TICK_NS = 33
)(
	input wire clk,
	input wire start,
	output reg done
);
	initial done = 0;
	localparam T_TICKS = $ceil(50/TIME_PER_TICK_NS);
	reg [$clog2(T_TICKS):0] ctr = 0;
	always @(posedge clk) begin
		if( start && !done ) begin
			if( ctr >= T_TICKS ) begin
				ctr <= 0;
				done <= 1;
			end
			else ctr <= ctr + 1;
		end
	end
endmodule
module ad7606#(
	parameter CLK_FREQUENCY = 30_000_000
)(
	input wire clk,   //max clock 
	input wire power,  //Control signal for power up/down of device
	output reg stby
);
	initial stby = 0;

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

	wire power_rise;
	wire power_fall;
	sync powersync(clk,power,power_rise,power_fall);

	reg begin_power = 0;
	always @(posedge clk) begin
		if( power_rise ) begin
			begin_power <= 1;
			stby <= 1;
		end
		else if( power_fall ) stby <= 0;
	end

	wire powerup_complete;
	delay #(POWER_ON_TIME_TICKS)
	powerdelay(clk, begin_power, powerup_complete);

	//handle reset
	wire reset_done;
	delay #($ceil(50/TIME_PER_TICK_NS))
	resetdelay(clk, powerup_complete, reset_done);

	//handle delay before we can start program
	wire conv_ready;
	delay #($ceil(25/TIME_PER_TICK_NS))
	convdelay(clk, reset_done, conv_ready);



endmodule
