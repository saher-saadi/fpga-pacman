// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
// up counter 
module	monster_mode_adjust	 #(
					COUNT_SIZE = 8
		)
	
		(	
//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input		logic	run, //two enables one for a "slow clock" 
					input		logic	chase, // one for external disable
					input		logic	scout_rnd, // one for external disable
				   input 	logic [3:0] NextChasingDir,        // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT
					input 	logic [3:0] NextRunningDir,        // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT
					input 	logic [3:0] NextRndDir,        // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT
 	
					output	logic [COUNT_SIZE-1:0]	addr, // sin table index 
					output 	logic [3:0] direction,      // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT
					output   logic runmod,
					output   logic chasemod,
					output   logic rndmod

		);



logic [COUNT_SIZE-1:0] count_limit = {COUNT_SIZE{1'b1}};

logic [3:0] RndOrChaseDir;
logic rndmod_tmp;
logic chasemod_tmp;
logic runmod_tmp;

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		addr	<= 0;
		RndOrChaseDir <= NextRndDir;
		rndmod_tmp <= 1;
		runmod_tmp <= 0;
		chasemod_tmp <= 0;
	end
	else if (chase && scout_rnd && !run) begin
				if (addr >= count_limit)  // overflow 
					addr <= 0;
				else 
					addr <= addr + 1;
					
				if(addr <= count_limit/2)  begin 
				RndOrChaseDir <= NextRndDir;
				rndmod_tmp <= 1;
				runmod_tmp <= 0;
				chasemod_tmp <= 0;
				end
				else begin
				RndOrChaseDir <= NextChasingDir;
				rndmod_tmp <= 0;
				runmod_tmp <= 0;
				chasemod_tmp <= 1;
				end
				
			end
			else addr <= 0;
end


always_comb begin
	
		if(run) begin 
		direction = NextRunningDir;
		rndmod = 0;
		runmod = 1;
		chasemod = 0;
		end
		else if(chase && scout_rnd)begin
		direction = RndOrChaseDir;
		rndmod = rndmod_tmp;
		runmod = runmod_tmp;
		chasemod = chasemod_tmp;
		end
		else if(chase) begin
		direction = NextChasingDir;
		rndmod = 0;
		runmod = 0;
		chasemod = 1;
		end
		else begin
		direction = NextRndDir;
		rndmod = 1;
		runmod = 0;
		chasemod = 0;
		end
				
end		
		
endmodule

