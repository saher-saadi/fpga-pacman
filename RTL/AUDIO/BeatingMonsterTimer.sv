// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
// up counter 
module	BeatingMonsterTimer #(
					COUNT_SIZE = 8
		)
	
		(	
//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input		logic	en, //two enables one for a "slow clock" 
					input		logic	en1, // one for external disable 
					output	logic [COUNT_SIZE-1:0]	addr, // sin table index
					output   logic runMode

		);



logic [COUNT_SIZE-1:0] count_limit = {COUNT_SIZE{1'b1}};
//
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		addr	<= 0;
		runMode <= 0;
	end
	else if (en == 1'b1 || addr != 0) begin
				if(en == 1'b1) addr <= 1;
				if (addr >= count_limit)begin  // overflow 
					addr <= 0;
					runMode <= 0;
				end
				else begin
					addr <= addr + 1;
					runMode <= 1;
				end
			end

end
endmodule

