// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024
// good practice code - Dudy MAR 2025

module	monsterChasing_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic Y_up_key,   //move Y Up 
					input	 logic Y_down_key,   //move Y down
					input	 logic x_left_key,      //move X left 
					input	 logic x_right_key,      //move X right
					input  logic collision,         //collision if smiley hits an object
					input  logic [2:0] HitEdgeCode, 
					
					input  logic [2:0] level,
					input logic	[2:0] rnd_mapONE,
					input logic	[2:0] rnd_mapTWO,
					
					input logic runMode,
					input logic collision_pacman_monster,
					
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,		// can be negative , if the object is partliy outside 
					output logic isMoving,
					output  logic [3:0] speedDIRECTION,
					output  logic [3:0] old_speedDIRECTION,

					output    logic signed [10:0] monsterXindex,
					output    logic signed [10:0] monsterYindex
);


// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 32;
parameter int INITIAL_Y = 352;
parameter int INITIAL_X_SPEED = 64;
parameter int INITIAL_Y_SPEED = 64;
parameter int Y_ACCEL = 0;

const int MAX_Y_SPEED = 500;
const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 32;
const int   OBJECT_HIGHT_Y = 32;
const int	SafetyMargin   =	2;

const int	x_FRAME_LEFT	=	(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

//edges 
	//------------
	//			 434
	//			 1x2
	//			 404
	//

const logic [4:0] CORNER =	5'b10000; 
const logic [3:0] TOP =		 4'b1000; 
const logic [3:0] RIGHT =   4'b0100; 
const logic [3:0] LEFT =	 4'b0010; 
const logic [3:0] BOTTOM =  4'b0001; 


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  
int offsetX_pacman;
int offsetY_pacman;

logic toggle_x_key_D ;
logic is_block_per;

 logic [4:0] hit_reg = 5'b00000;
 
 typedef enum logic [2:0] {
    DIR_RIGHT = 3'b001,
    DIR_UP    = 3'b010,
    DIR_DOWN  = 3'b011,
    DIR_LEFT  = 3'b100,
	 NO_DIR    = 3'b000
} direction_t;

direction_t dir_reg;
int FirstTimeToKey;

logic collision_d;//to make a edge collision


logic [0:14][0:19] [3:0]  MazeBitMapMask;

logic [3:0][0:14][0:19] [3:0]   MazeDefaultBitMapMask= // defult table to load on reset 
{

{
{80'h33333333333333333333},
{80'h30000000000000000003},
{80'h30333000303330003003},
{80'h30030030300000333003},
{80'h30030330000300003303},
{80'h30030030300303300003},
{80'h30000000330003000303},
{80'h30033000000000030303},
{80'h30330033033300330303},
{80'h30000000033300000003},
{80'h30303030000003330303},
{80'h30300030033300030003},
{80'h30303033033303033303},
{80'h30000000000000000003},
{80'h33333333333333333333}
},

{
{80'h33333333333333333333},
{80'h30000000000030000003},
{80'h30333300030030033303},
{80'h30000300330330330003},
{80'h30300300030000300303},
{80'h30300333030300003303},
{80'h30300000030303000003},
{80'h30330000000000003333},
{80'h30000333300333000003},
{80'h30330003003300033303},
{80'h30033000000000330003},
{80'h30000033033300300303},
{80'h30330033033300003303},
{80'h30000000000000000003},
{80'h33333333333333333333}
},


{
{80'h33333333333333333333},
{80'h30000000000000000003},
{80'h30330303303030303303},
{80'h30300300000000000003},
{80'h30300333330303330303},
{80'h30000000000003000003},
{80'h30330030333003030303},
{80'h30300330003000030003},
{80'h30000000303033330303},
{80'h30330303303000000003},
{80'h30000003000000303303},
{80'h30300300033303300303},
{80'h30303303033300300303},
{80'h30000000000000000003},
{80'h33333333333333333333}
},

{
{80'h33333333333333333333},
{80'h30000000000000000003},
{80'h30330303303030303303},
{80'h30300300303030300303},
{80'h30300330000030000003},
{80'h30330000000330330303},
{80'h30000033003300300303},
{80'h30300003003003303303},
{80'h30003300000000000303},
{80'h30303303303330330003},
{80'h30303000000000000303},
{80'h30300033033303303303},
{80'h30333003033303000303},
{80'h30000000000000000003},
{80'h33333333333333333333}
}

};

 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0   ; 
		Yspeed <= 0  ; 
		Xposition <= 2048  ; 
		Yposition <= 22528   ; 
		toggle_x_key_D <= 0 ;
		hit_reg <= 5'b0 ;	
		collision_d <= 0;
		dir_reg<= NO_DIR;
		FirstTimeToKey <= 1;
		isMoving <= 0;
		speedDIRECTION <= 0;
		old_speedDIRECTION <= 0;
	end 	
	
	else begin
			
			if(level == 0)MazeBitMapMask  <=  MazeDefaultBitMapMask[rnd_mapONE] ;
			else if(level == 2)MazeBitMapMask  <=  MazeDefaultBitMapMask[rnd_mapTWO] ;
			
//		toggle_x_key_D <= toggle_x_key ;  //shift register to detect edge 
		collision_d <= collision;

	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Xspeed  <= 0 ; 
				Yspeed  <= 0  ; 
				Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER; 
				
				speedDIRECTION <= 0;
				old_speedDIRECTION <= 0;
				
				if (startOfFrame) 
					SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 

		   if (Y_up_key)
            dir_reg <= DIR_UP;
        else if (Y_down_key)
            dir_reg <= DIR_DOWN;
        else if (x_left_key)
            dir_reg <= DIR_LEFT;
        else if (x_right_key)
            dir_reg <= DIR_RIGHT;
				
	
		// keys direction change 
		
offsetX_pacman <= Xposition/FIXED_POINT_MULTIPLIER;
offsetY_pacman <= Yposition/FIXED_POINT_MULTIPLIER;

is_block_per = (((offsetX_pacman%32) == 0) && ((offsetY_pacman%32) == 0));
		
		if(collision == 0) begin
				if ((dir_reg == DIR_UP) && FirstTimeToKey && is_block_per)begin//moving up
					if(MazeBitMapMask[(offsetY_pacman/32)-1][(offsetX_pacman/32)] != 4'h3)begin
					dir_reg <= NO_DIR;
					Yspeed <= -INITIAL_Y_SPEED;//+1 ; 
					speedDIRECTION <= 4'b1000;
					Xspeed <= 0;
					end
				end	
				if ((dir_reg == DIR_LEFT) && FirstTimeToKey && is_block_per)begin //moving left 
					if(MazeBitMapMask[(offsetY_pacman/32)][(offsetX_pacman/32)-1] != 4'h3)begin
					dir_reg <= NO_DIR;
					Xspeed <= -INITIAL_X_SPEED ;
					speedDIRECTION <= 4'b0001;
					Yspeed <= 0;	
					end
				end	
				if ((dir_reg == DIR_DOWN) && FirstTimeToKey && is_block_per)begin//moving down
					if(MazeBitMapMask[(offsetY_pacman/32)+1][(offsetX_pacman/32)] != 4'h3)begin
					dir_reg <= NO_DIR;
					Yspeed <= INITIAL_Y_SPEED;//+1 ; 
					speedDIRECTION <= 4'b0010;
					Xspeed <= 0;
					end
				end	
				if ((dir_reg == DIR_RIGHT) && FirstTimeToKey && is_block_per) begin //moving right 
					if(MazeBitMapMask[(offsetY_pacman/32)][(offsetX_pacman/32)+1] != 4'h3)begin
					dir_reg <= NO_DIR;
					Xspeed <= INITIAL_X_SPEED ; 
					speedDIRECTION <= 4'b0100;
					Yspeed <= 0;
					end
				end
			end
       // collcting collisions 	
				if (collision && !collision_d) begin
					hit_reg[HitEdgeCode]<=1'b1;

				end
				
				isMoving <= (Xspeed) || (Yspeed);                     // check if isMoving

				if (startOfFrame )
					SM_Motion <= START_OF_FRAME_ST ; 
					
					
				
		end 
		
		//------------
			START_OF_FRAME_ST:  begin      //check if any colisin was detected 
		//------------
		
		
		if (hit_reg) begin
		
			if (Xspeed > 0) Xposition <= Xposition - Xspeed;// Xposition - FIXED_POINT_MULTIPLIER;
			if (Xspeed < 0) Xposition <= Xposition - Xspeed;//Xposition + FIXED_POINT_MULTIPLIER;
			if (Yspeed > 0) Yposition <= Yposition - Yspeed;//Yposition - FIXED_POINT_MULTIPLIER;
			if (Yspeed < 0) Yposition <= Yposition - Yspeed;//Yposition + FIXED_POINT_MULTIPLIER;
			
			Xspeed <= 0;
			Yspeed <= 0;
			old_speedDIRECTION <= speedDIRECTION;
			speedDIRECTION <= 0;
			
		end

/*		//PACMAN stops
			if (hit_reg) begin
				if (Xspeed!=0 || Yspeed!=0) begin
					Yspeed <= 0;
					Xspeed <= 0;
				end 
		end
*/
/*
			if (hit_reg == CORNER)   // pure corner 
					begin
//							Yspeed <= 0-Xspeed ;
//							Xspeed <= 0-Yspeed ;
              Yspeed <= 0-Yspeed ;
				  Xspeed <= 0-Xspeed ;
					end
			else begin 
				case (hit_reg[3:0] )  // test sides 
	
					TOP+RIGHT, LEFT+BOTTOM, TOP+LEFT, BOTTOM+RIGHT :  // two sides - corner 
					begin
							 Yspeed <= 0-Yspeed ;
				          Xspeed <= 0-Xspeed ;
					end
					LEFT, TOP+RIGHT+BOTTOM : // left side or cavity  
					begin
						if (Xspeed < 0) // left 
							  Xspeed <= 0-Xspeed ;
					end
	
					RIGHT, LEFT+BOTTOM +TOP :   // right side or cavity  
					begin
						if (Xspeed > 0) // right 
							  Xspeed <= 0-Xspeed ;
					end
					
					TOP, RIGHT+LEFT+BOTTOM :  // top side or cavity  
					begin
						if (Yspeed < 0) // up 
							  Yspeed <= 0-Yspeed ;
					end
				
				BOTTOM, TOP+LEFT+RIGHT :  // bottom side or cavity  
					begin
						if (Yspeed > 0) // doun 
							  Yspeed <= -Yspeed ;
					end
					
					default: ; 
	
			  endcase
			end // else 
*/
			hit_reg <= 5'b00000;						
			SM_Motion <= POSITION_CHANGE_ST ; 
		end 

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + Xspeed ; 
				Yposition <= Yposition + Yspeed ;
			 
/*				// accelerate 
			
				if (Yspeed < MAX_Y_SPEED ) //  limit the speed while going down 
   				Yspeed <= Yspeed - Y_ACCEL ; // deAccelerate : slow the speed down every clock tick 
	
*/				
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
		if (Xposition < x_FRAME_LEFT) 
						Xposition <= x_FRAME_LEFT ; 
		if (Xposition > x_FRAME_RIGHT)
						Xposition <= x_FRAME_RIGHT ; 
		if (Yposition < y_FRAME_TOP) 
						Yposition <= y_FRAME_TOP ; 
		if (Yposition > y_FRAME_BOTTOM) 
						Yposition <= y_FRAME_BOTTOM ; 

				SM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 
		if(collision_pacman_monster && runMode)begin
			Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
			Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
			
		end
		end
		
	 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
assign MonsterXindex = ((Xposition / FIXED_POINT_MULTIPLIER) / 32);
assign MonsterYindex = ((Yposition / FIXED_POINT_MULTIPLIER) / 32);

  
assign 	topLeftX = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY = Yposition / FIXED_POINT_MULTIPLIER ;    

//assign MonsterXindex = topLeftX / 32;
//assign MonsterYindex = topLeftY / 32;


endmodule	
//---------------
 
