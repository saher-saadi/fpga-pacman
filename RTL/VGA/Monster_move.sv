// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024
// good practice code - Dudy MAR 2025

module	Monster_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic Y_up_key,   //move Y Up 
					input	 logic Y_down_key,   //move Y down
					input	 logic x_left_key,      //move X left 
					input	 logic x_right_key,      //move X right
					input  logic collision,         //collision if smiley hits an object
					input  logic [2:0] HitEdgeCode, 
					input  int Rnd_Xspeed,
					input int Rnd_Yspeed,
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,		// can be negative , if the object is partliy outside 
					output logic isMoving,
					output  logic [3:0] speedDIRECTION
					
					
);


// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 560;
parameter int INITIAL_Y = 80;
parameter int INITIAL_X_SPEED = 100;
parameter int INITIAL_Y_SPEED = 100;
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
enum logic [2:0] {
    WAIT_STATE = 3'b000,
    LEFT_STATE = 3'b010,
    DOWN_STATE = 3'b100
} move_state;

int counter;

int Xspeed  ; // speed    
int Yspeed  ; 
int old_Xspeed  ; // speed    
int old_Yspeed  ; 
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
int delay;
int does_nothing;
logic collision_d;//to make a edge collision


logic [0:15][0:15] [3:0]   MazeDefaultBitMapMask= // defult table to load on reset 

//3 Wall
//1 one way left
//2 up_left_right
//4 up_left_down
//5 up_right_down
//6 down_left_right
{
{64'h3333333333333333},
{64'h3100001013100013},
{64'h3033330303033303},
{64'h3100001303033303},
{64'h3333330310100013},
{64'h3100101333333303},
{64'h3033030310000013},
{64'h3033030303333303},
{64'h3033030310000013},
{64'h3033030303333303},
{64'h3100101010000013},
{64'h3333333333333333},
{64'h0000000000000000},
{64'h0000000000000000},
{64'h0000000000000000},
{64'h0000000000000000},
};
 //---------
 
 
 
assign offsetX_pacman = Xposition/FIXED_POINT_MULTIPLIER;
assign offsetY_pacman = Yposition/FIXED_POINT_MULTIPLIER;



always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0   ; 
		Yspeed <= 0  ;
		old_Xspeed <= 0   ; 
		old_Yspeed <= 0  ;	
		Xposition <= 0  ; 
		Yposition <= 0   ; 
		toggle_x_key_D <= 0 ;
		hit_reg <= 5'b0 ;	
		collision_d <= 0;
		dir_reg<= NO_DIR;
		FirstTimeToKey <= 1;
		isMoving <= 0;
		speedDIRECTION <= 0;
		move_state <= WAIT_STATE;
		counter <= 0;
		does_nothing <= 0;
	end 	
	
	else begin
	
//		toggle_x_key_D <= toggle_x_key ;  //shift register to detect edge 
		collision_d <= collision;

	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Xspeed  <= 0 ; 
				Yspeed  <=  0; 
				dir_reg<= NO_DIR;
				delay <= 0;
				counter <= 0;
				old_Xspeed <= 0   ; 
				old_Yspeed <= 0  ;
				Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER; 
				
				speedDIRECTION <= 0;
				
				if (startOfFrame) 
					SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
			
			if(Y_up_key)begin
				Xspeed <= 0;
				Yspeed <= - INITIAL_Y_SPEED;
				old_Xspeed <= 0   ; 
				old_Yspeed <= -INITIAL_Y_SPEED  ;
				dir_reg <=NO_DIR;
				end
				if(Y_down_key)begin
				Xspeed <= 0;
				Yspeed <=  INITIAL_Y_SPEED;
				old_Xspeed <= 0;
				old_Yspeed <=  INITIAL_Y_SPEED;
				dir_reg <=NO_DIR;
				end
				if(x_left_key)begin
				Xspeed <= - INITIAL_X_SPEED;
				Yspeed <= 0;                        
				old_Xspeed <= - INITIAL_X_SPEED;
				old_Yspeed <= 0;                
				dir_reg <=NO_DIR;
				end
				if(x_right_key)begin
				Xspeed <= INITIAL_X_SPEED;
				Yspeed <= 0;                    
				old_Xspeed <= INITIAL_X_SPEED;
				old_Yspeed <= 0;              
				dir_reg <=NO_DIR;
				end
	/*		 // inside an external bracket
			if((Y_up_key + x_left_key + Y_down_key + x_right_key) > 1) FirstTimeToKey <= 0;
			else begin
			case (dir_reg)
				DIR_RIGHT: begin
					if (Y_up_key)begin//moving up
						dir_reg <= DIR_UP;
						FirstTimeToKey <= 1;
					end	
					if (x_left_key)begin //moving left 
						dir_reg <= DIR_LEFT;
						FirstTimeToKey <= 1;
					end	
					if (Y_down_key)begin//moving down
						dir_reg <= DIR_DOWN;
						FirstTimeToKey <= 1;
					end	
					if (x_right_key) begin //moving right
						FirstTimeToKey <= 0;
					end
				end
				DIR_LEFT : begin
					if (Y_up_key)begin//moving up
						dir_reg <= DIR_UP;
						FirstTimeToKey <= 1;
					end	
					if (x_left_key)begin //moving left 
						FirstTimeToKey <= 0;
					end	
					if (Y_down_key)begin//moving down
						dir_reg <= DIR_DOWN;
						FirstTimeToKey <= 1;
					end	
					if (x_right_key) begin //moving right
						dir_reg <= DIR_RIGHT;
						FirstTimeToKey <= 1;
					end
				end
				DIR_UP   : begin
					if (Y_up_key)begin//moving up
						FirstTimeToKey <= 0;
					end	
					if (x_left_key)begin //moving left 
						dir_reg <= DIR_LEFT;
						FirstTimeToKey <= 1;
					end	
					if (Y_down_key)begin//moving down
						dir_reg <= DIR_DOWN;
						FirstTimeToKey <= 1;
					end	
					if (x_right_key) begin //moving right
						dir_reg <= DIR_RIGHT;
						FirstTimeToKey <= 1;
					end
				end
				DIR_DOWN : begin
					if (Y_up_key)begin//moving up
						dir_reg <= DIR_UP;
						FirstTimeToKey <= 1;
					end	
					if (x_left_key)begin //moving left 
						dir_reg <= DIR_LEFT;
						FirstTimeToKey <= 1;
					end	
					if (Y_down_key)begin//moving down
						FirstTimeToKey <= 0;
					end	
					if (x_right_key) begin //moving right
						dir_reg <= DIR_RIGHT;
						FirstTimeToKey <= 1;
					end
				end
				NO_DIR: begin
					if (Y_up_key)begin//moving up
						dir_reg <= DIR_UP;
						FirstTimeToKey <= 1;
					end	
					if (x_left_key)begin //moving left 
						dir_reg <= DIR_LEFT;
						FirstTimeToKey <= 1;
					end	
					if (Y_down_key)begin//moving down
						dir_reg <= DIR_DOWN;
						FirstTimeToKey <= 1;
					end	
					if (x_right_key) begin //moving right
						dir_reg <= DIR_RIGHT;
						FirstTimeToKey <= 1;
					end
				end
			endcase
			end
		//------------
*/
		// keys direction change 
		

is_block_per = (((offsetX_pacman%40) == 0) && ((offsetY_pacman%40) == 0));
//				counter <= counter + 1;
	//			if(counter >= 90) counter <= 0;
	//			if(Yspeed != 0) old_Yspeed <= Yspeed;
		//		if(Xspeed != 0) old_Xspeed <= Xspeed;
			if(is_block_per)begin
				
			//dealing with 1
			
			
			if (MazeDefaultBitMapMask[(offsetY_pacman / 40)][(offsetX_pacman / 40)] == 4'h1 && !hit_reg)begin
			
					Xspeed <= 0;
					Yspeed <= 0;
			/*
				if(Yspeed != 0) Xspeed <= 0;
				if(Xspeed != 0) Yspeed <= 0;
	//			dir_reg <= NO_DIR;

				case(counter)
						0: begin
									if (old_Yspeed < 0) begin
				//						dir_reg <= DIR_LEFT;
										Xspeed <= - INITIAL_X_SPEED;
										Yspeed <= 0;
				//						old_Yspeed <= Yspeed;
					//					old_Xspeed <= Xspeed;
										speedDIRECTION <= 4'b0001;
									end
							end
						
			
						45: begin
							// Wait for the delay before checking for the next condition
									if (old_Xspeed < 0) begin
										Xspeed <= 0;
										Yspeed <= 0;
		//								dir_reg <= DIR_DOWN;
										speedDIRECTION <= 4'b0010;
									end
							end
						
			
						90: begin
								if (old_Yspeed > 0) begin
										Yspeed <= 0;
										Xspeed <=  -INITIAL_X_SPEED;
			//							dir_reg <= DIR_LEFT;
										speedDIRECTION <= 4'b0001;
									end
						end
						default: begin
								does_nothing <= 0;
						end
					endcase
			*/
			end
/*			
				if((MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1) && (Yspeed < 0) && (delay == 0))begin
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) - 1] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= 0;
						speedDIRECTION <= 4'b0001;
						dir_reg <= DIR_LEFT;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) + 1] == 4'h0)begin
						Xspeed <=  0;
						Yspeed <= 0;
						speedDIRECTION <= 4'b0100;
						dir_reg <= DIR_RIGHT;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40) - 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= 0;
						speedDIRECTION <= 4'b1000;
						dir_reg <= DIR_UP;
					end
		
				
				end
				
				else if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1 && (Xspeed < 0) && (delay == 0))begin
						Xspeed <= 0;
						Yspeed <= 0;
						speedDIRECTION <= 4'b0010;
						dir_reg <= DIR_DOWN;
				end
	
				
	*/
	/*			
				if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1) begin
				
				case(dir_reg)
					
					DIR_UP:begin
						Xspeed <= 0;
						Yspeed <= - INITIAL_Y_SPEED;
					end
					DIR_LEFT:begin
						Xspeed <= - INITIAL_X_SPEED;
						Yspeed <= 0;
					end
					DIR_DOWN:begin
						Xspeed <= 0;
						Yspeed <= INITIAL_Y_SPEED;
					end
					DIR_RIGHT:begin
						Xspeed <= INITIAL_X_SPEED;
						Yspeed <= 0;
					end
					NO_DIR: begin
						Xspeed <= 0;
						Yspeed <= 0;
					end
				endcase
				end
	*/
				/*
				else if((MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1) && (Yspeed > 0))begin
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) - 1] == 4'h0)begin
						Xspeed <= - INITIAL_X_SPEED;
						Yspeed <= 0;
	//					speedDIRECTION <= 4'b0001;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) + 1] == 4'h0)begin
						Xspeed <=  INITIAL_X_SPEED;
						Yspeed <= 0;
	//					speedDIRECTION <= 4'b0100;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40) + 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <=  0;
						Yspeed <= INITIAL_Y_SPEED;
	//					speedDIRECTION <= 4'b0010;
					end
				end	
				else if((MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1) && (Xspeed > 0))begin
					if(MazeDefaultBitMapMask[(offsetY_pacman/40) - 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= - INITIAL_Y_SPEED;
	//					speedDIRECTION <= 4'b1000;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) + 1] == 4'h0)begin
						Xspeed <=  INITIAL_X_SPEED;
						Yspeed <= 0;
	//					speedDIRECTION <= 4'b0100;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40) + 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= INITIAL_Y_SPEED;
	//					speedDIRECTION <= 4'b0010;
					end
				end
				else if((MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h1) && (Xspeed < 0))begin
					if(MazeDefaultBitMapMask[(offsetY_pacman/40) + 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <=  0;
						Yspeed <= INITIAL_Y_SPEED;
	//					speedDIRECTION <= 4'b0010;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40) - 1][(offsetX_pacman/40)] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= - INITIAL_Y_SPEED;
	//					speedDIRECTION <= 4'b1000;
					end
					else if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) - 1] == 4'h0)begin
						Xspeed <=  - INITIAL_X_SPEED;
						Yspeed <= 0;
	//					speedDIRECTION <= 4'b0001;
					end
					
				end	
		*/			
			//end of dealing with 1
			
	/*		
			//dealing with 4
				if((MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] == 4'h2) && (Yspeed > 0))begin
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40) - 1] == 4'h0)begin
						Xspeed <= 0;
						Yspeed <= 0;
					end
				end
			
			
			//end of dealing with 4
	*/	
		
			end
		
		
		
		
		
		
	/*	
		if(collision == 0) begin
				if ((dir_reg == DIR_UP) && FirstTimeToKey && is_block_per)begin//moving up
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)] != 4'h1)begin
					dir_reg <= NO_DIR;
					Yspeed <= -INITIAL_Y_SPEED;//+1 ; 
					speedDIRECTION <= 4'b1000;
					Xspeed <= 0;
					end
				end	
				if ((dir_reg == DIR_LEFT) && FirstTimeToKey && is_block_per)begin //moving left 
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)-1] != 4'h2)begin
					dir_reg <= NO_DIR;
					Xspeed <= -INITIAL_X_SPEED ;
					speedDIRECTION <= 4'b0001;
					Yspeed <= 0;	
					end
				end	
				if ((dir_reg == DIR_DOWN) && FirstTimeToKey && is_block_per)begin//moving down
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)+1][(offsetX_pacman/40)] != 4'h3)begin
					dir_reg <= NO_DIR;
					Yspeed <= INITIAL_Y_SPEED;//+1 ; 
					speedDIRECTION <= 4'b0010;
					Xspeed <= 0;
					end
				end	
				if ((dir_reg == DIR_RIGHT) && FirstTimeToKey && is_block_per) begin //moving right 
					if(MazeDefaultBitMapMask[(offsetY_pacman/40)][(offsetX_pacman/40)+1] != 4'h3)begin
					dir_reg <= NO_DIR;
					Xspeed <= INITIAL_X_SPEED ; 
					speedDIRECTION <= 4'b0100;
					Yspeed <= 0;
					end
				end
			end
*/
       // collcting collisions 	
		 
				if(Xspeed == 0 && Yspeed == 0)begin
						Xspeed <= Rnd_Xspeed;
						Yspeed <= Rnd_Yspeed;
				end
				if (collision && !collision_d) begin
					hit_reg[0]<=1'b1;

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
			hit_reg <= 5'b00000;
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
		end
		
	 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY = Yposition / FIXED_POINT_MULTIPLIER ;    
	

endmodule	
//---------------
 
