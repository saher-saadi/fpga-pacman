module MonsterChasing_NextDir2 (
    input logic clk,
    input logic resetN,
    input logic [10:0] offset_monster_x,        // Monster X position (pixels)
    input logic [10:0] offset_monster_y,        // Monster Y position (pixels)
    input logic [10:0] offset_pacman_x,         // Pacman X position (pixels)
    input logic [10:0] offset_pacman_y,         // Pacman Y position (pixels)

	 input logic [2:0] level,        
    input logic [2:0] rnd_mapONE,        
    input logic [2:0] rnd_mapTWO,
	 
    output logic [3:0] direction        // Output direction: bit[0]=UP, bit[1]=DOWN, bit[2]=LEFT, bit[3]=RIGHT
);
    // Internal map definition
    logic [3:0][0:14][0:19][3:0] MazeBitMapMask = {

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
	 int mapNumber;
	 assign mapNumber = (level == 1) ? rnd_mapONE : rnd_mapTWO;
	 
    int monster_x, monster_y, pacman_x, pacman_y;
    assign monster_x = offset_monster_x/32;
    assign monster_y = offset_monster_y/32;
    
    assign pacman_x = offset_pacman_x/32;
    assign pacman_y = offset_pacman_y/32;
    
    // Previous position registers - store last 4 positions
    logic [4:0] prev_x[0:3];  // Array of 4 previous X positions
    logic [3:0] prev_y[0:3];  // Array of 4 previous Y positions
    
    // Internal wires for distance calculations
    logic [9:0] up_dist, down_dist, left_dist, right_dist;
    
    // Helper function to check if position was recently visited
    function automatic logic was_visited(input int check_x, input int check_y);
        was_visited = 0;
        for (int i = 0; i < 4; i++) begin
            if (prev_x[i] == check_x && prev_y[i] == check_y) begin
                was_visited = 1;
                break;
            end
        end
    endfunction
    
    // Calculate UP distance - block if it goes back to any of the 4 previous positions
    assign up_dist = (monster_y > 0 && 
                      MazeBitMapMask[mapNumber][monster_y - 4'h1][monster_x] == 4'h0 && 
                      !was_visited(monster_x, monster_y - 1)) ?
                     10'((monster_x > pacman_x ? (monster_x - pacman_x) : (pacman_x - monster_x)) +
                      ((monster_y - 4'h1) > pacman_y ? ((monster_y - 4'h1) - pacman_y) : (pacman_y - (monster_y - 4'h1)))) :
                     10'd0;
    
    // Calculate DOWN distance - block if it goes back to any of the 4 previous positions
    assign down_dist = (monster_y < 14 && 
                        MazeBitMapMask[mapNumber][monster_y + 4'h1][monster_x] == 4'h0 && 
                        !was_visited(monster_x, monster_y + 1)) ?
                       10'((monster_x > pacman_x ? (monster_x - pacman_x) : (pacman_x - monster_x)) +
                        ((monster_y + 4'h1) > pacman_y ? ((monster_y + 4'h1) - pacman_y) : (pacman_y - (monster_y + 4'h1)))) :
                       10'd0;
    
    // Calculate LEFT distance - block if it goes back to any of the 4 previous positions
    assign left_dist = (monster_x > 0 && 
                        MazeBitMapMask[mapNumber][monster_y][monster_x - 5'h1] == 4'h0 && 
                        !was_visited(monster_x - 1, monster_y)) ?
                       10'(((monster_x - 5'h1) > pacman_x ? ((monster_x - 5'h1) - pacman_x) : (pacman_x - (monster_x - 5'h1))) +
                        (monster_y > pacman_y ? (monster_y - pacman_y) : (pacman_y - monster_y))) :
                       10'd0;
    
    // Calculate RIGHT distance - block if it goes back to any of the 4 previous positions
    assign right_dist = (monster_x < 19 && 
                         MazeBitMapMask[mapNumber][monster_y][monster_x + 5'h1] == 4'h0 && 
                         !was_visited(monster_x + 1, monster_y)) ?
                        10'(((monster_x + 5'h1) > pacman_x ? ((monster_x + 5'h1) - pacman_x) : (pacman_x - (monster_x + 5'h1))) +
                         (monster_y > pacman_y ? (monster_y - pacman_y) : (pacman_y - monster_y))) :
                        10'd0;
    
    // Logic for choosing direction
    always_comb begin
        // Priority: UP < DOWN < LEFT < RIGHT (in case of ties)
        if (up_dist >= down_dist && up_dist >= left_dist && up_dist >= right_dist) begin
            direction = 4'b0001; // UP (bit 0)
        end
        else if (down_dist >= left_dist && down_dist >= right_dist) begin
            direction = 4'b0010; // DOWN (bit 1)
        end
        else if (left_dist >= right_dist) begin
            direction = 4'b0100; // LEFT (bit 2)
        end
        else begin
            direction = 4'b1000; // RIGHT (bit 3)
        end
    end
    
    // Register to store previous 4 positions (circular buffer)
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            for (int i = 0; i < 4; i++) begin
                prev_x[i] <= 5'd0;
                prev_y[i] <= 4'd0;
            end
        end
        else begin
            // Only update history if monster moved to a different grid position
            if (monster_x != prev_x[0] || monster_y != prev_y[0]) begin
                // Shift the history: move each position to the next slot
                prev_x[3] <= prev_x[2];
                prev_y[3] <= prev_y[2];
                
                prev_x[2] <= prev_x[1];
                prev_y[2] <= prev_y[1];
                
                prev_x[1] <= prev_x[0];
                prev_y[1] <= prev_y[0];
                
                // Store current position as most recent
                prev_x[0] <= monster_x;
                prev_y[0] <= monster_y;
            end
            // If position hasn't changed, don't update the history
        end
    end

endmodule