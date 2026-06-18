// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
// up counter 
module	addr_counterToUse	 #(
					COUNT_SIZE = 8
		)
	
		(	
//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input		logic	en, //two enables one for a "slow clock" 
					input		logic	en1, // one for external disable 
					output	logic [COUNT_SIZE-1:0]	addr, // sin table index 
					output logic [2:0] counter_third

		);


logic weAreInThebegin;
logic [COUNT_SIZE-1:0] count_limit = {COUNT_SIZE{1'b1}};
//
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		addr	<= 0;
		weAreInThebegin <= 1;
		counter_third <= 3'b100;
	end
	else if (en == 1'b1 && en1 == 1'b1) begin
				weAreInThebegin <= 0;
				if (addr >= count_limit) begin  // overflow 
					addr <= 0;
				end
				else begin 
					addr <= addr + 1;
					if(addr == 1) counter_third <= 3'b001;
					if(addr == (count_limit/3)) counter_third <= 3'b010;
					if((addr == (2*(count_limit/3))) || (addr == 0)) counter_third <= 3'b100;
				end
				
			end
			else if(en == 1'b1 && en1 == 1'b0 && !weAreInThebegin) begin
						addr <= 1;
						counter_third <= 3'b001;
			
			end

end
endmodule

