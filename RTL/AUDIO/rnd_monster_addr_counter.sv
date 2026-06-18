// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
// up counter 
module	rnd_monster_addr_counter	 #(
					COUNT_SIZE = 8
		)
	
		(	
//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input		logic	en, //two enables one for a "slow clock" 
					input		logic	en1, // one for external disable 
					input    logic [3:0] speedDIRECTION,
					input    logic [3:0] old_speedDIRECTION,

					output	logic [COUNT_SIZE-1:0]	addr, // sin table index 
					output   int   Rnd_Xspeed,
					output   int   Rnd_Yspeed,
					
					
					output   logic	Y_up_key, 
					output	logic	Y_down_key,
					output	logic	X_left_key, 
					output	logic	X_right_key,
					output logic [3:0] direction        // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT

		);

//		up		    	speedDIRECTION <= 4'b1000;
//		left			speedDIRECTION <= 4'b0001;
//		down	  		speedDIRECTION <= 4'b0010;
//		right			speedDIRECTION <= 4'b0100;



logic [COUNT_SIZE-1:0] count_limit = {COUNT_SIZE{1'b1}};
 int counter_for_stop;
//
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		addr	<= 0;
		counter_for_stop <= 0;
	end
	else  begin
				if(counter_for_stop >= 5) counter_for_stop <= 0;
				else counter_for_stop <= counter_for_stop + 1;
				if (addr > 268435452)  // overflow 
					addr <= 0;
					
					
				else begin
				
				
					
			if(speedDIRECTION != 0) begin	
			
			
				if(en) addr <= addr + 20000;
					else if(en1) addr <= addr + 48632;
					else begin
					addr <= addr + 1;
					end	
					
					
				if(addr == 1 && (speedDIRECTION != 4'b0010))begin
//					Rnd_Xspeed <=  0;
//					Rnd_Yspeed <=  -256;
						Y_up_key <= 1;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0001; // UP (bit 0)
				end
				else if(addr == 67108863 && (speedDIRECTION != 4'b1000))begin
//					Rnd_Xspeed <=  0;
//					Rnd_Yspeed <=  64;
						Y_up_key <= 0;
						Y_down_key <= 1;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0010; // DOWN (bit 1)

				end
				else if(addr == 134217726 && (speedDIRECTION != 4'b0100))begin
//					Rnd_Xspeed <=  -64;
//					Rnd_Yspeed <=  0;
						Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 1;
						X_right_key <= 0;
                  direction <= 4'b0100; // LEFT (bit 2)
				end
				else if(addr == 201326589 && (speedDIRECTION != 4'b0001))begin
//					Rnd_Xspeed <=  64;
//					Rnd_Yspeed <=  0;
						Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 1;
						direction <= 4'b1000; // RIGHT (bit 3)
				end
				else begin
//					Rnd_Xspeed <=  0;
//					Rnd_Yspeed <=  0;
						Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0000;

				end
			end
			
			else if(speedDIRECTION == 0)begin
				if(counter_for_stop == 1 && (old_speedDIRECTION != 4'b0010) )begin
					Y_up_key <= 1;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0001; // UP (bit 0)
				end
				else if(counter_for_stop == 2 && (old_speedDIRECTION != 4'b1000))begin
					Y_up_key <= 0;
						Y_down_key <= 1;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0010; // DOWN (bit 1)

				end
				else if(counter_for_stop == 3 && (old_speedDIRECTION != 4'b0100))begin
					Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 1;
						X_right_key <= 0;
		            direction <= 4'b0100; // LEFT (bit 2)

				end
				else if(counter_for_stop == 4 && (old_speedDIRECTION != 4'b0001))begin
					Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 1;
						direction <= 4'b1000; // RIGHT (bit 3)

				end
				else begin
					Y_up_key <= 0;
						Y_down_key <= 0;
						X_left_key <= 0;
						X_right_key <= 0;
						direction <= 4'b0000;
				end
			end
			end
	end
end
endmodule

