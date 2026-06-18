// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
//start_screen
module	level_adjust(	

//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input    logic start_with_enter,
					input	   logic [12:0]	addr,
					input    logic [2:0] level,
					
					input    logic [7:0] coins_numONE,
					input    logic [7:0] coins_numTWO,

					
					output logic [2:0] NextLevel,
					output logic YOU_WON

		);




//
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		NextLevel <= 0;
		YOU_WON <= 0;
		
	end
	else begin
		if(NextLevel == 0)NextLevel <= 1;
		else if((NextLevel == 1) && (addr >= 20* coins_numONE) && (addr < (20*(coins_numONE + coins_numTWO))))begin
			NextLevel <= 2;
		end
		else if((NextLevel == 2) && (addr >= (20 * (coins_numONE + coins_numTWO))))begin
			YOU_WON <= 1;
		end
		end
end
endmodule

