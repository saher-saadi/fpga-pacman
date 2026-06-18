// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module	HelperMatrixBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic [2:0] level,
					input logic collision_pacman_helper,
					
					input logic	[2:0] rnd_mapONE,
					input logic	[2:0] rnd_mapTWO,

					output	logic	drawingRequest,
					output	logic	unsafe_walk_on_street,	//output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
					
					output	logic	[7:0] coins_numONE, 
					output	logic	[7:0] coins_numTWO  
							
 ) ;
 

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

localparam  int TILE_NUMBER_OF_X_BITS = 5;  // 2^5 = 32  everu object 
localparam  int TILE_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 

localparam  int MAZE_NUMBER_OF__X_BITS = 4;  // 2^4 = 16 / /the maze of the objects 
localparam  int MAZE_NUMBER_OF__Y_BITS = 4;  // 2^4 = 16

//-----

localparam  int TILE_WIDTH_X = 1 << TILE_NUMBER_OF_X_BITS ;
localparam  int TILE_HEIGHT_Y = 1 <<  TILE_NUMBER_OF_Y_BITS ;
localparam  int MAZE_WIDTH_X = 20 ;
localparam  int MAZE_HEIGHT_Y = 15 ;


 logic [10:0] offsetX_LSB  ;
 logic [10:0] offsetY_LSB  ; 
 logic [10:0] offsetX_MSB ;
 logic [10:0] offsetY_MSB  ;

 assign offsetX_LSB  = offsetX % 32 ; // get lower bits 
 assign offsetY_LSB  = offsetY % 32 ; // get lower bits 
 assign offsetX_MSB  = offsetX / 32 ; // get higher bits 
 assign offsetY_MSB  = offsetY / 32 ; // get higher bits 
 

 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ;  

logic [3:0][0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   MazeDefaultBitMapMask= // defult table to load on reset 
{

{
{80'h33333333333333333333},
{80'h30000000000000000003},
{80'h30333000303330013003},
{80'h30030030300000333003},
{80'h30030330000300003303},
{80'h30030030300303300003},
{80'h30000000330003000303},
{80'h30033000000000030303},
{80'h30330033033300330303},
{80'h30000000033300000003},
{80'h30303030000003330303},
{80'h30300030034300030003},
{80'h30303033033303033303},
{80'h31000000000000000003},
{80'h33333333333333333333}
},

{
{80'h33333333333333333333},
{80'h31000000000030000003},
{80'h30333300030030033303},
{80'h30000300330330330003},
{80'h30300300030000300303},
{80'h30300333030300003303},
{80'h30300000030303000003},
{80'h30330000000000003333},
{80'h30000333300333000003},
{80'h30330003003300033303},
{80'h30033000000000330103},
{80'h30000033034300300303},
{80'h30330033033300003303},
{80'h30000000000000000003},
{80'h33333333333333333333}
},


{
{80'h33333333333333333333},
{80'h30000000000000000013},
{80'h30330303303030303303},
{80'h30300300000000000003},
{80'h30300333330303330303},
{80'h30000000000003000003},
{80'h30330030333003030303},
{80'h31300330003000030003},
{80'h30000000303033330303},
{80'h30330303303000000003},
{80'h30000003000000303303},
{80'h30300300034303300303},
{80'h30303303033300300303},
{80'h30000000000000000003},
{80'h33333333333333333333}
},

{
{80'h33333333333333333333},
{80'h30000000000000000003},
{80'h30330303303030303303},
{80'h30310300303030300303},
{80'h30300330000030000003},
{80'h30330000000330330303},
{80'h30000033003300300303},
{80'h30300003003003303303},
{80'h30003300000000000303},
{80'h30303303303330330003},
{80'h30303000000000000303},
{80'h30300033034303303303},
{80'h30333003033303000303},
{80'h30000000000000000013},
{80'h33333333333333333333}
}

};


 logic [0:3][7:0]  coins_number_arr  = {8'b10011110/*158*/, 8'b10100010/*162*/, 8'b10100000/*160*/, 8'b10100011/*163*/};
 

 logic [1:0] [0:31][0:31] [7:0]  helper_colors  = {
 { 
   {8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
,
 { 
   {8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'h00,8'h00,8'h00,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'he4,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}
}
};
 
 
 
 logic chosen1;
 logic chosen2;
 
int counter;
//
// pipeline (ff) to get the pixel color from the array 	 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'hFF;
//		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
		counter <= 0;
		unsafe_walk_on_street <= 0;
		
		
		chosen1 <= 0;
		chosen2 <= 0;
	end
	else begin
	
			if(level == 0 && !chosen1)begin 
			chosen1 <= 1;
			MazeBitMapMask  <=  MazeDefaultBitMapMask[rnd_mapONE] ;
			coins_numONE <= coins_number_arr[rnd_mapONE];
			end
			else if(level == 2 && !chosen2)begin 
			chosen2 <= 1;
			MazeBitMapMask  <=  MazeDefaultBitMapMask[rnd_mapTWO] ;
			coins_numTWO <= coins_number_arr[rnd_mapTWO];
			end
			
			
		RGBout <= TRANSPARENT_ENCODING ; // default 
		
		if (collision_pacman_helper)begin
			MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h4;  // clear entry 
		end
		if (InsideRectangle == 1'b1 )	
			begin 
		   	case (MazeBitMapMask[offsetY_MSB][offsetX_MSB])
					 4'h4 : RGBout <= TRANSPARENT_ENCODING ;
					 4'h3 : RGBout <= TRANSPARENT_ENCODING ;
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
					 4'h1 : RGBout <= helper_colors[level - 1][offsetY_LSB][offsetX_LSB] ; 

					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
			end 

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule

