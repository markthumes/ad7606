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
	input wire rst,
	input wire start,
	output reg done
);
	initial done = 0;
	reg [$clog2(TICKS):0] ctr = 0;
	always @(rst) begin 
		done <= 0;
		ctr  <= 0;
	end
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

module ad7606#(
	parameter CLK_FREQUENCY = 30_000_000
)(
	input wire clk,   //max clock 
	input wire power,  //Control signal for power up/down of device
	input wire busy,
	output reg conv,
	output wire n_cs,
	output wire sclk,
	output wire reset,
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

	//_________________________________________________________//
	//                  DEFINE STATE MACHINE                   //
	localparam STATE_POWER = 2'd0;
	localparam STATE_RESET = 2'd1;
	localparam STATE_CONV  = 2'd2;
	localparam STATE_READ  = 2'd3;
	reg [1:0] state = STATE_POWER;
	//---------------------------------------------------------//

	wire power_rise;
	wire power_fall;
	sync powersync(clk,power,power_rise,power_fall);

	reg begin_power = 0;
	always @(posedge clk) begin
		if( power_rise ) begin
			begin_power <= 1;
			stby <= 1;
		end
		else if( power_fall ) begin
			begin_power <= 0;
			stby <= 0;
		end
	end
	
	wire rst;
	assign rst = begin_power;

	wire powerup_complete;
	delay #(POWER_ON_TIME_TICKS)
	powerdelay(clk, rst, begin_power, powerup_complete);

	//handle reset
	wire reset_done;
	delay #($ceil(50/TIME_PER_TICK_NS))
	resetdelay(clk, rst, powerup_complete, reset_done);

	//handle delay before we can start program
	wire conv_ready;
	delay #($ceil(25/TIME_PER_TICK_NS))
	convdelay(clk, rst, reset_done, conv_ready);

	assign reset = powerup_complete && !reset_done;

	//_________________________________________________________//
	//                   HANDLE CONVERSION                     //
	always @(posedge clk) begin
		if( state == STATE_CONV && cycle_ctr == 0 )begin
			conv <= 1;
		end
		else conv <= 0;
	end
	//---------------------------------------------------------//

	//_________________________________________________________//
	//   Sync busy to the FPGA using a 3 bit shift register    //
	wire busy_falling;
	wire busy_rising;
	sync busysync(clk, busy, busy_rising, busy_falling);
	//---------------------------------------------------------//

	//_________________________________________________________//
	//                     CHANGE STATES                       //
	always @(rst) begin
		state <= STATE_POWER;
	end
	always @(posedge clk) begin
		if( state == STATE_POWER ) begin
			if( powerup_complete ) state <= STATE_RESET;
		end
		if( state == STATE_RESET ) begin
			if( conv_ready ) state <= STATE_CONV;
		end
		if( busy_falling ) state <= STATE_READ;
		if( cycle_ctr >= 4 ) state <= STATE_CONV;
	end
	//---------------------------------------------------------//

	//_________________________________________________________//
	//                    CS AND CLOCK
	//This does not guarantee timing is met per data sheet     //
	localparam CYCLES = 4;
	localparam COUNTS = 17; //16 bits and a chip select
	reg [$clog2(CYCLES):0] cycle_ctr = 0;
	reg [$clog2(COUNTS):0] data_ctr = 0;
	always @(posedge clk) begin
		if( state == STATE_READ )begin
			if( data_ctr < COUNTS ) begin
				data_ctr  <= data_ctr + 1;
			end
			else begin
				data_ctr  <= 0;
				cycle_ctr <= cycle_ctr + 1;
			end
		end
		else begin
			cycle_ctr <= 0;
			data_ctr  <= 0;
		end
	end
	
	assign n_cs = (clk && (data_ctr >= 1) && (data_ctr <   2)) || (state == STATE_CONV);
	assign sclk = (clk && (data_ctr >= 2) && (data_ctr <  18));

endmodule
