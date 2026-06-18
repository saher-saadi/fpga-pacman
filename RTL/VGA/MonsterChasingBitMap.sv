// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module	MonsterChasingBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle,//input that the pixel is within a bracket 
					input	logic	Y_up_key,
					input	logic	Y_down_key,
					input	logic	x_left_key, 
					input	logic	x_right_key,
					input logic [2:0] counter_third,
					input logic [2:0] level,
					input logic run,
					input logic chasemov,
					input logic rndmov,

					
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
				   output   logic	[2:0] HitEdgeCode  
 ) ;
 
 
//start of my

typedef enum logic [1:0] {
    DIR_RIGHT = 2'b00,
    DIR_UP    = 2'b01,
    DIR_DOWN  = 2'b10,
    DIR_LEFT  = 2'b11
} direction_t;

direction_t dir_reg;

//end of my


// this is the devider used to acess the right pixel 
localparam  int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
localparam  int OBJECT_NUMBER_OF_X_BITS = 5;  // 2^5 = 32 


localparam  int Check = 3'b100;

localparam  int OBJECT_HEIGHT_Y = 1 <<  OBJECT_NUMBER_OF_Y_BITS ;
localparam  int OBJECT_WIDTH_X = 1 <<  OBJECT_NUMBER_OF_X_BITS;

 logic	[10:0] HitCodeX ;// offset of Hitcode 
 logic	[10:0] HitCodeY ; 
assign HitCodeX = offsetX >> ( OBJECT_NUMBER_OF_X_BITS - 4 );	// hitedge code MSB of the offset
assign HitCodeY = offsetY >> ( OBJECT_NUMBER_OF_Y_BITS - 4 );	 	 

// generating a smiley bitmap

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hff ;// RGB value in the bitmap representing a transparent pixel 

logic [3:0] [0:31] [0:31] [7:0] pacman_fully_open = {
 {
 //up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
 {
 //down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
 {
 //left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
{
 //right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
};





logic [3:0] [0:31] [0:31] [7:0] pacman_half_open = {
{
 //up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
{
 //down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
 {
 //left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
{
 //right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
};


	
logic [3:0] [0:31] [0:31] [7:0] pacman_closed ={
{
//up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
};
logic [3:0] [0:31] [0:31] [7:0] monster_chase_mvone = {
 {
 //up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
 {
 //down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
 {
 //left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
,
{
 //right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0}
}
};





logic [3:0] [0:31] [0:31] [7:0] monster_chase_mvtwo = {
{
 //up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
{
 //down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
 {
 //left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
,
{
 //right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF}
}
};


	
logic [3:0] [0:31] [0:31] [7:0] monster_chase_mvthree ={
{
//up
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//down
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//left
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
{
//right
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'h00,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'h00,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFE,8'hFE,8'hFE,8'hFE,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0},
	{8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hF0},
	{8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hF0,8'hF0,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
};

logic [2:0][0:31] [0:31] [7:0] monster_Run ={
{
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE}
}
,
{
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF}
}
,
{
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'h00,8'h00,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE},
	{8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFE},
	{8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFE,8'hFE,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
};		
//////////--------------------------------------------------------------------------------------------------------------=
//hit bit map has one encoding per edge:  hit_colors[2:0] =   
 
logic [0:15] [0:15] [2:0] hit_colors = 
		  {48'o4433333333333344,     
			48'o4443333333333444,    
			48'o1444333333334442, 
			48'o1144433333344422,
			48'o1114443333444222,
			48'o1111444334442222,
			48'o1111144444422222,
			48'o1111114444222222,
			48'o1111114444222222,
			48'o1111144444422222,
			48'o1111444004442222,
			48'o1114440000444222,
			48'o1144400000044422,
			48'o1444000000004442,
			48'o4440000000000444,
			48'o4400000000000044};
 
 
// pipeline (ff) to get the pixel color from the array 	 

//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'hFF;
		HitEdgeCode <= 3'h0;
		dir_reg <= DIR_RIGHT;

	end  

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  
		HitEdgeCode <= 3'h0;
		
//deciding the last direction so we can chose the BITMAP
		if (Y_up_key)
            dir_reg <= DIR_UP;
        else if (Y_down_key)
            dir_reg <= DIR_DOWN;
        else if (x_left_key)
            dir_reg <= DIR_LEFT;
        else if (x_right_key)
            dir_reg <= DIR_RIGHT;
    

		if (InsideRectangle == 1'b1 ) 
		begin // inside an external bracket 
			if(run) begin
			case(counter_third)
				3'b001: RGBout <= monster_Run[0][offsetY][offsetX];
				
				3'b010: RGBout <= monster_Run[1][offsetY][offsetX];

				3'b100: RGBout <= monster_Run[2][offsetY][offsetX];
			endcase
			end
			else if(chasemov)begin 
			case (counter_third)
				3'b001: begin					
					case (dir_reg)
						DIR_RIGHT: RGBout <= monster_chase_mvone[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= monster_chase_mvone[1][offsetY][offsetX];
						DIR_UP   : RGBout <= monster_chase_mvone[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= monster_chase_mvone[2][offsetY][offsetX];
					endcase
					
				end
				
				3'b010:begin				
					case (dir_reg)
						DIR_RIGHT: RGBout <= monster_chase_mvtwo[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= monster_chase_mvtwo[1][offsetY][offsetX];
						DIR_UP   : RGBout <= monster_chase_mvtwo[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= monster_chase_mvtwo[2][offsetY][offsetX];
					endcase
					
				end
				
				3'b100:begin					
					case (dir_reg)
						DIR_RIGHT: RGBout <= monster_chase_mvthree[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= monster_chase_mvthree[1][offsetY][offsetX];
						DIR_UP   : RGBout <= monster_chase_mvthree[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= monster_chase_mvthree[2][offsetY][offsetX];
					endcase
					
				end
			endcase
			
			end
			
			else begin
			case (counter_third)
				
				3'b001: begin					
					case (dir_reg)
						DIR_RIGHT: RGBout <= pacman_fully_open[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= pacman_fully_open[1][offsetY][offsetX];
						DIR_UP   : RGBout <= pacman_fully_open[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= pacman_fully_open[2][offsetY][offsetX];
					endcase
					
				end
				
				3'b010:begin				
					case (dir_reg)
						DIR_RIGHT: RGBout <= pacman_half_open[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= pacman_half_open[1][offsetY][offsetX];
						DIR_UP   : RGBout <= pacman_half_open[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= pacman_half_open[2][offsetY][offsetX];
					endcase
					
				end
				
				3'b100:begin					
					case (dir_reg)
						DIR_RIGHT: RGBout <= pacman_closed[0][offsetY][offsetX];
						DIR_LEFT : RGBout <= pacman_closed[1][offsetY][offsetX];
						DIR_UP   : RGBout <= pacman_closed[3][offsetY][offsetX];
						DIR_DOWN : RGBout <= pacman_closed[2][offsetY][offsetX];
					endcase
					
				end
			endcase
			end

			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];	//get hitting edge code from the colors table  
		
		end  	
	end	
end

//////////--------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule