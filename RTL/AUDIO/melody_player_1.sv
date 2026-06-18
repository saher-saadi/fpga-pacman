// 
// (c) Technion IIT, The Faculty of Electrical and Computer Engineering, 2025 
// 
//  MODIFIED VERSION - Multi-Sound Support for Game Events
//  Supports: Win, Lose, Coin Collision, Monster Collision
// 
module melody_player_1      
(     
    // Declare wires and regs :  
    input logic resetN,
    input logic CLOCK_31p5,
    
    // Four separate trigger inputs for different sounds
    input logic player_Win,           // Trigger for win melody (~1 min)
    input logic player_lose,          // Trigger for lose melody (~1 min)
    input logic coin_collision,       // Trigger for coin sound (short)
    input logic monster_collision,    // Trigger for monster sound (short)
    
    input logic [3:0] melodySelect,  // selector of one melody from Jukebox
         
    // Outputs
    output logic [3:0] tone,
    output logic EnableSoundOut,     // controls AUDIO module on/off    
    output logic melodyEnded         // indicates end of melody. Also outputs to LED3            
);

    // Serial number of current note (maximum 63 for longer melodies)
    localparam logic [5:0] beat_duration = 6'd12;    // duration of each beat, in 1/100 seconds. max 63
    localparam logic [4:0] gap_duration = 5'd3;      // duration of inter-note gap, in 1/100 seconds. max 31
    
    // Maestro state machine declaration
    enum logic [1:0] {s_idle, s_playNote, s_gap, s_ended} SM_Maestro;
    
    // Parameters declarations 
    logic [9:0] noteTimeCounter;     // count down 1/100 seconds timer (maximum 1024)
    logic [9:0] noteDuration;        // total length of current note in 1/100 seconds (max 1024)
    logic hundredthSecPulse;         // A short pulse, once every 1/100 second
    
    // Juke box interface signals 
    logic [3:0] note_length;         // length of notes, in beats. determined by noteIndex via JukeBox
    logic silenceN;
    logic [5:0] noteIndex;           // Extended to 6 bits for longer melodies (0-63)
    
    // Internal melody selector (mapped from game events)
    logic [3:0] currentMelodySelect;
    
    assign noteDuration = beat_duration * note_length;  // total duration of current note, in 1/100 seconds
    
    //----------------------------------------------------------------------------------------------------------
    // Melody mapping: Map game events to melody indices
    // Adjust these values based on your JukeBox implementation
    //----------------------------------------------------------------------------------------------------------
    localparam logic [3:0] MELODY_WIN = 4'd0;       // Long win melody
    localparam logic [3:0] MELODY_LOSE = 4'd1;      // Long lose melody  
    localparam logic [3:0] MELODY_COIN = 4'd2;      // Short coin sound
    localparam logic [3:0] MELODY_MONSTER = 4'd3;   // Short monster sound
    
    //----------------------------------------------------------------------------------------------------------
    // Instances of slow counter. pulse every 10 mSec
    //----------------------------------------------------------------------------------------------------------
    Mili_sec_counter #(
        .SIMULATION_MODE(1'h0), 
        .mSecPerTick(10), 
        .PLLClock(315)
    ) mili_sec_counter_inst (
        .clk(CLOCK_31p5),
        .resetN(resetN),
        .turbo(1'h0),
        .hundredth_sec(hundredthSecPulse)
    );
    
    //----------------------------------------------------------------------------------------------------------
    // Instances of Music options
    //----------------------------------------------------------------------------------------------------------
    JukeBox1 JukeBox1 (
        .melodySelect(currentMelodySelect),
        .noteIndex(noteIndex),
        .tone(tone),
        .note_length(note_length),
        .silenceOutN(silenceN)
    );
    
    //----------------------------------------------------------------------------------------------------------
    // Synchronous code, executed once every clock to update the current state and outputs
    //----------------------------------------------------------------------------------------------------------
    always_ff @(posedge CLOCK_31p5 or negedge resetN)
    begin
        if (!resetN) begin
            // Asynchronous reset, initialize the state machine
            SM_Maestro <= s_idle;
            noteIndex <= 6'b0;
            noteTimeCounter <= noteDuration;
            EnableSoundOut <= 1'b0;
            melodyEnded <= 1'b0;
            currentMelodySelect <= 4'b0;
        end 
        else begin
            // Synchronous logic of the state machine; once every clock
            //--------------------------------------------------------------------------------------------------------------------
            // State machine
            
            // Default outputs
            EnableSoundOut <= 1'b0;
            melodyEnded <= 1'b0;
            
            case (SM_Maestro)
                //================================================
                s_idle: begin
                    noteIndex <= 6'b0;
                    
                    // Priority-based sound trigger detection
                    // Win and Lose have highest priority (game-ending sounds)
                    if (player_Win) begin
                        currentMelodySelect <= MELODY_WIN;
                        noteTimeCounter <= noteDuration;
                        SM_Maestro <= s_playNote;
                    end
                    else if (player_lose) begin
                        currentMelodySelect <= MELODY_LOSE;
                        noteTimeCounter <= noteDuration;
                        SM_Maestro <= s_playNote;
                    end
                    else if (coin_collision) begin
                        currentMelodySelect <= MELODY_COIN;
                        noteTimeCounter <= noteDuration;
                        SM_Maestro <= s_playNote;
                    end
                    else if (monster_collision) begin
                        currentMelodySelect <= MELODY_MONSTER;
                        noteTimeCounter <= noteDuration;
                        SM_Maestro <= s_playNote;
                    end
                end // s_idle
                
                //================================================
                s_playNote: begin
                    EnableSoundOut <= silenceN;  // enable sound, unless jukebox says "silence"
                    
                    if (!(note_length == 4'b0)) begin  // if did not reach the end of the song
                        if (hundredthSecPulse) 
                            noteTimeCounter <= noteTimeCounter - 10'b1;  // decrement counter
                        
                        if (noteTimeCounter == 10'b0) begin  // timer finished
                            noteIndex <= noteIndex + 1'b1;    // increment note Index
                            SM_Maestro <= s_gap;              // next state
                            noteTimeCounter <= gap_duration;  // preset counter for gap
                        end  // if timer ended
                    end  // if not end of song
                    else begin  // reached end of song
                        SM_Maestro <= s_ended;
                    end
                end // s_playNote
                
                //================================================
                s_gap: begin
                    if (hundredthSecPulse) 
                        noteTimeCounter <= noteTimeCounter - 10'b1;  // decrement counter
                    
                    if (noteTimeCounter == 10'b0) begin  // timer finished
                        SM_Maestro <= s_playNote;         // back to playnote state
                        noteTimeCounter <= noteDuration;  // preset counter
                    end  // if
                end // s_gap
                
                //================================================
                s_ended: begin
                    melodyEnded <= 1'b1;
                    SM_Maestro <= s_idle;
                end //s_end
                
                //================================================
                default: begin
                    SM_Maestro <= s_idle;
                end // default
            endcase
        end // if reset else
    end // always_ff state machine
    
endmodule