
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // smiley 
					input		logic	smileyDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] smileyRGB, 
					
					 
		  // add the box here 
					input		logic	boxDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] boxRGB, 
			  
			  
		  ////////////////////////
		  // background 
					input    logic HartDrawingRequest, // box of numbers
					input		logic	[7:0] hartRGB,   
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					
			//level 1 start screen
					input		logic	[7:0] RGB_LevONE_start_screen,
					
			// coins
					input		logic	CoinsDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] CoinsRGB, 	
			//Monster
					input		logic	MonsterScoutDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] MonsterScoutRGB,
					
					input		logic	MonsterChaseDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] MonsterChaseRGB,
					
					input		logic	MonsterScoutANDChaseDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] MonsterScoutANDChaseRGB,

			//level 2 start screen		
					input		logic	[7:0] RGB_LevTWO_start_screen,
			//souls 
					input    logic SoulsDrawingRequest, // box of numbers
					input		logic	[7:0] soulsRGB,
			//level
					input		logic	[2:0] level,
			//mode
					input		logic	game_over_mode,
					input		logic	one_up_to_two_mode,
					
			// coins
					input		logic	HelperDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] HelperRGB, 		
					
				//output RGB
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (smileyDrawingRequest == 1'b1 )   
			RGBOut <= smileyRGB;  //first priority 
		 
//--- add logic for box here ------------------------------------------------------		
		else if (MonsterScoutDrawingRequest == 1'b1 )   
		RGBOut <= MonsterScoutRGB;  //second priority

		else if (MonsterChaseDrawingRequest == 1'b1 )   
		RGBOut <= MonsterChaseRGB;  //second priority

		else if (MonsterScoutANDChaseDrawingRequest == 1'b1 )   
		RGBOut <= MonsterScoutANDChaseRGB;  //second priority
		
		
		else if (SoulsDrawingRequest == 1'b1 )   
		RGBOut <= soulsRGB;  //second priority
		
		else if (boxDrawingRequest == 1'b1 )   
			RGBOut <= boxRGB;  //second priority 

		else if (CoinsDrawingRequest == 1'b1 )   
			RGBOut <= CoinsRGB;  //second priority 
			
		else if (HelperDrawingRequest == 1'b1 )   
			RGBOut <= HelperRGB;  //second priority 

		else if (HartDrawingRequest == 1'b1)
			RGBOut <= hartRGB;
//---------------------------------------------------------------------------------		

//		else if (BGDrawingRequest == 1'b1)
//				RGBOut <= backGroundRGB ;
		 else begin
					RGBOut <= backGroundRGB;
					end
		end  
	end

endmodule


