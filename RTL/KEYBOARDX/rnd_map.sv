// (c) Technion IIT, Department of Electrical Engineering 2025 
module rnd_map 	
 ( 
	input	logic  clk,
	input	logic  resetN,
	input	logic  restart, 	
	input	logic	 rise,
	output logic unsigned [SIZE_BITS-1:0] rnd_map_lvl_1,
	output logic unsigned [SIZE_BITS-1:0] rnd_map_lvl_2	
	
  ) ;

// Generating a random number by latching a fast counter with the rising edge of an input ( e.g. key pressed )
  
parameter SIZE_BITS = 8;
parameter unsigned MIN_VAL = 0;  //set the min and max values 
parameter unsigned MAX_VAL = 255;

	logic unsigned  [SIZE_BITS-1:0] counter1/* synthesis keep = 1 */;
	logic unsigned  [SIZE_BITS-1:0] counter2/* synthesis keep = 1 */;

	logic rise_d /* synthesis keep = 1 */;
	logic already_chosen;
	
always_ff @(posedge clk or negedge resetN) begin
		if (!resetN) begin
			rnd_map_lvl_1 <= (MAX_VAL+MIN_VAL)/2;
			rnd_map_lvl_2 <= ((MAX_VAL+MIN_VAL)/2) + 1;
			counter1 <= MIN_VAL;
			counter2 <= MIN_VAL + 1;
			already_chosen <= 0;
			rise_d <= 1'b0;
		end
		
		else begin
			counter1 <= counter1 + 1;
			counter2 <= (counter2 + 3)%(MAX_VAL+1);
			if(!restart) already_chosen <= 0;
			if ( counter1 >= MAX_VAL ) // the +1 is done on the next clock 
				counter1 <=  MIN_VAL ;	// set min and max mvalues 
			if ( counter2 >= (MAX_VAL+1) )
				counter2 <=  MIN_VAL ;
				
			rise_d <= rise;
			
			if (rise && !rise_d && !already_chosen)begin // rising edge 
				already_chosen <= 1;
				rnd_map_lvl_1 <= counter1;
				if(counter1 == counter2) rnd_map_lvl_2 <= (counter2+1)%(MAX_VAL + 1);
				else rnd_map_lvl_2 <= counter2;

			end
		end
	
	end
 
endmodule

