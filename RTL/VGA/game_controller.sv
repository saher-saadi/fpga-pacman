// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
			input	logic	drawing_request_smiley,
			input	logic	drawing_request_boarders,

//---------------------#1-add input drawing request of box/number
		
			input	logic	drawing_request_numberMap,
		

//---------------------#1-end input drawing request of box/number




//---------------------#2-add  drawing request of hart

			input	logic	drawing_request_Wall,
			input	logic	drawing_request_Point,
			input	logic	drawing_request_MonsterScout,
			input	logic	drawing_request_MonsterChase,
			input	logic	drawing_request_MonsterScoutANDChase,
			input	logic	drawing_request_helper,
			input	logic	drawing_request_const_wall,



//---------------------#2-end drawing request of hart		

			
			output logic collision, // active in case of collision between two objects
			
			output logic SingleHitPulse, // critical code, generating A single pulse in a frame 
			output logic SingleHitPulse_Pacman_wall_Border,
			output logic SingleHitPulse_Pacman_Points,
			

			
			output logic SingleHitPulse_Pacman_MonsterScout,
			output logic SingleHitPulse_Pacman_MonsterChase,
			output logic SingleHitPulse_Pacman_MonsterScoutANDChase,

			
			output logic SingleHitPulse_MonsterScout_wall_Border,
			output logic SingleHitPulse_MonsterChase_wall_Border,
			output logic SingleHitPulse_MonsterScoutANDChase_wall_Border,

//---------------------#3-add collision  smiley and hart   -------------------------------------


			output logic collision_Pacman_Wall_Border, // active in case of collision between Smiley and hart
			output logic collision_Pacman_Points,
			
			output logic collision_Pacman_MonsterScout,
			output logic collision_Pacman_MonsterChase,
			output logic collision_Pacman_MonsterScoutANDChase,

			output logic collision_MonsterScout_Wall_Border,
			output logic collision_MonsterChase_Wall_Border,
			output logic collision_MonsterScoutANDChase_Wall_Border,
			output logic SingleHitPulse_Pacman_helper,
			output logic collision_Pacman_helper

//---------------------#3-end collision  smiley and hart	--------------------------------------
			


);

// drawing_request_smiley   -->  smiley
// drawing_request_boarders -->  brackets
// drawing_request_number   -->  number/box 

logic flag ;
logic flag2; // a semaphore to set the output only once per frame regardless of number of collisions 
logic flag3;
logic flag4;
logic flag5;
logic flag6;
logic flag7;
logic flag8;
logic flag9;

logic collision_smiley_number; // collision between Smiley and number - is not output


//assign   collision_simley_number=(drawing_request_smiley && drawing_request_numberMap);
assign collision = (drawing_request_smiley && drawing_request_boarders) || ( drawing_request_smiley && drawing_request_numberMap );// any collision --> comment after updating with #4 or #5 

//---------------------#4-update  collision  conditions - add collision between smiley and number   ----------------------------

//assign collision = <collision_before> +<collision smiley and number>;


//---------------------#4-end update  collision  conditions	 - add collision between smiley and number	-------------------------
	
					
						

//---------------------#5-update  collision  sconditions - add collision between smiley and hart  ---------------------------------

//assign collision = <collision_before> +( drawing_request_smiley && drawing_request_hart ); 
	


//---------------------#5-end update  collision  conditions	- add collision between smiley and hart	-----------------------------
	



//-------------------------- #6-add colision between Smiley and hart-----------------

assign collision_Pacman_Wall_Border = ( drawing_request_smiley && drawing_request_Wall ) || (drawing_request_smiley && drawing_request_boarders);
assign collision_Pacman_Points = ( drawing_request_smiley && drawing_request_Point ) ;
assign collision_Pacman_helper = ( drawing_request_smiley && drawing_request_helper ) ;


assign collision_Pacman_MonsterScout = ( drawing_request_smiley && drawing_request_MonsterScout ) ;
assign collision_Pacman_MonsterChase = ( drawing_request_smiley && drawing_request_MonsterChase ) ;
assign collision_Pacman_MonsterScoutANDChase = ( drawing_request_smiley && drawing_request_MonsterScoutANDChase ) ;


assign collision_MonsterScout_Wall_Border = ( drawing_request_MonsterScout && drawing_request_const_wall );
assign collision_MonsterChase_Wall_Border = ( drawing_request_MonsterChase && drawing_request_const_wall );
assign collision_MonsterScoutANDChase_Wall_Border = ( drawing_request_MonsterScoutANDChase && drawing_request_const_wall );


//---------------------------#6-end colision betweenand Smiley and hart-----------------


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		flag	<= 1'b0;
		flag2	<= 1'b0;
		flag3	<= 1'b0;
		flag4	<= 1'b0;
		flag5	<= 1'b0;
		flag6	<= 1'b0;
		flag7	<= 1'b0;
		flag8	<= 1'b0;
		flag9	<= 1'b0;

		


		SingleHitPulse <= 1'b0 ; 
		SingleHitPulse_Pacman_Points <= 1'b0 ;
		SingleHitPulse_Pacman_helper <= 1'b0 ;
		
		SingleHitPulse_Pacman_wall_Border <= 1'b0 ;
		
		SingleHitPulse_Pacman_MonsterScout <= 1'b0;
		SingleHitPulse_Pacman_MonsterChase <= 1'b0;
		SingleHitPulse_Pacman_MonsterScoutANDChase <= 1'b0;

		SingleHitPulse_MonsterScout_wall_Border <= 1'b0;
		SingleHitPulse_MonsterChase_wall_Border <= 1'b0;
		SingleHitPulse_MonsterScoutANDChase_wall_Border <= 1'b0;

	end 
	else begin 
	
//----------------------- #7-define colision between Smiley and number to collision_smiley_number -------
		


//----------------------- #7-end colision between Smiley and number-----------------------------------	
		
		
		SingleHitPulse <= 1'b0 ; // default 
		SingleHitPulse_Pacman_Points <= 1'b0 ;
		SingleHitPulse_Pacman_helper <= 1'b0;
		SingleHitPulse_Pacman_wall_Border <= 1'b0 ;
		
		SingleHitPulse_Pacman_MonsterScout <= 1'b0;
		SingleHitPulse_Pacman_MonsterChase <= 1'b0;
		SingleHitPulse_Pacman_MonsterScoutANDChase <= 1'b0;

		SingleHitPulse_MonsterScout_wall_Border <= 1'b0;
		SingleHitPulse_MonsterChase_wall_Border <= 1'b0;
		SingleHitPulse_MonsterScoutANDChase_wall_Border <= 1'b0;

		if(startOfFrame) 
			flag <= 1'b0 ; // reset for next time 
			flag2	<= 1'b0;
			flag3	<= 1'b0;
			flag4	<= 1'b0;
			flag5	<= 1'b0;
			flag6	<= 1'b0;
			flag7	<= 1'b0;
			flag8	<= 1'b0;
			flag9	<= 1'b0;

			

//	---#7 - change the condition below to collision between Smiley and number ---------
/*		if ( collision  && (flag == 1'b0)) begin 
			flag	<= 1'b1; // to enter only once 
			SingleHitPulse <= 1'b1 ; 
		end ;
*/		
		if ( collision_Pacman_Wall_Border  && (flag == 1'b0)) begin 
			flag	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_wall_Border <= 1'b1 ; 
		end ;
		
		if ( drawing_request_smiley && drawing_request_Point  && (flag2 == 1'b0)) begin 
			flag2	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_Points <= 1'b1 ; 
		end ;
		
		if ( drawing_request_smiley && drawing_request_helper  && (flag9 == 1'b0)) begin 
			flag9	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_helper <= 1'b1 ; 
		end ;
		
		
		if ( collision_Pacman_MonsterScout  && (flag3 == 1'b0)) begin 
			flag3	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_MonsterScout <= 1'b1 ; 
		end ;
		if ( collision_Pacman_MonsterChase  && (flag4 == 1'b0)) begin 
			flag4	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_MonsterChase <= 1'b1 ; 
		end ;
		if ( collision_Pacman_MonsterScoutANDChase  && (flag5 == 1'b0)) begin 
			flag5	<= 1'b1; // to enter only once 
			SingleHitPulse_Pacman_MonsterScoutANDChase<= 1'b1 ; 
		end ;
		
		

		if ( collision_MonsterScout_Wall_Border  && (flag6 == 1'b0)) begin 
			flag6	<= 1'b1; // to enter only once 
			SingleHitPulse_MonsterScout_wall_Border <= 1'b1 ; 
		end ;
		if ( collision_MonsterChase_Wall_Border  && (flag7 == 1'b0)) begin 
			flag7	<= 1'b1; // to enter only once 
			SingleHitPulse_MonsterChase_wall_Border <= 1'b1 ; 
		end ;
		if ( collision_MonsterScoutANDChase_Wall_Border  && (flag8 == 1'b0)) begin 
			flag8	<= 1'b1; // to enter only once 
			SingleHitPulse_MonsterScoutANDChase_wall_Border <= 1'b1 ; 
		end ;
		
	end 
end

endmodule
