// (c) Technion IIT, Department of Electrical Engineering 2021
// SystemVerilog version Alex Grinshpun May 2018
// up counter 
module	Score_addr_counter	 #(
					COUNT_SIZE = 8
		)
	
		(	
//		--////////////////////	Clock Input	 	////////////////////	
					input		logic	clk,
					input		logic	resetN,
					input		logic	collision_pacman_coin, //two enables one for a "slow clock" 
					input		logic	collision_pacman_monster, // one for external disable 
					input    logic runMode,
					
					output	logic [COUNT_SIZE-1:0]	addr, // sin table index
					output	logic [3:0] ones,
					output	logic [3:0] tens,
					output	logic [3:0] hundreds,
					output	logic [3:0] thousands,
					output	logic [COUNT_SIZE-1:0]	score // sin table index


		);



logic [COUNT_SIZE-1:0] count_limit = {COUNT_SIZE{1'b1}};
logic collision_pacman_coin_d;
logic collision_pacman_monster_d;
//
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin
		addr	<= 0;
		score	<= 0;
		collision_pacman_coin_d <= 0;
		collision_pacman_monster_d <= 0;
	end
	else begin
		collision_pacman_coin_d <= collision_pacman_coin;
		collision_pacman_monster_d <= collision_pacman_monster;
		if (collision_pacman_coin && !collision_pacman_coin_d) begin
				if (addr >= count_limit) begin // overflow 
					addr <= 0;
					end
				else if (score >= count_limit)begin
					score <= 0;
					end
				else begin
					addr <= addr + 20;
					score <= score + 20;

				end
			end
		if(collision_pacman_monster && !collision_pacman_monster_d && runMode)begin
				if (score >= count_limit)begin
					score <= 0;
					end
				else begin
					score <= score + 80;

				end
			end
			ones <= score%10;
			tens <= (score/10)%10;
			hundreds <= (score/100)%10;
			thousands <= (score/1000);
			
		end
end
endmodule

