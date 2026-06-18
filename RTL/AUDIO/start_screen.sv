// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
//start_screen
module	start_screen(	

//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN_original,
					input    logic start_with_enter,
					input    logic [2:0] level,
					input    logic game_over,
					input    logic YOU_WON,

					
					output	logic	resetN,
					output	logic	restart,
					output	logic	one_up_to_two_mode,
					output	logic	game_over_mode,
					output   logic YOU_WON_mode

		);



logic [2:0] level_d;

//
always_ff@(posedge clk or negedge resetN_original)
begin
	if(!resetN_original)
	begin
		level_d <= 0;
		resetN <= 0;
		restart <= 0;
		one_up_to_two_mode <= 0;
		game_over_mode <= 0;
		YOU_WON_mode <= 0;
	end
	else if(YOU_WON)begin
		level_d <= 0;
		resetN <= 0;
		restart <= 0;
		YOU_WON_mode <= 1;
		one_up_to_two_mode <= 0;
		game_over_mode <= 0;

	end
	else if(game_over)begin
		level_d <= 0;
		resetN <= 0;
		restart <= 0;
		game_over_mode <= 1;
		one_up_to_two_mode <= 0;

	end
	else begin
		level_d <= level;
		if(start_with_enter)begin
			resetN <= 1;
			restart <= 1;
			game_over_mode <= 0;
			YOU_WON_mode <= 0;
		end
		
		
		if(level == 2 && level_d == 1)begin
			resetN <= 0;
			one_up_to_two_mode <= 1;
		end
		end
end
endmodule

