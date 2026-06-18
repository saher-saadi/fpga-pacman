//
// JukeBox1 - Game Sound Effects Module (Looped Version)
// Win: Happy melody (≈1 min loop)
// Lose: Sad melody (≈1 min loop)
// Monster: Short impact
// Coin: Bouncy beeps
//
module JukeBox1 (
    input  logic [3:0] melodySelect,
    input  logic [4:0] noteIndex,
    output logic [3:0] tone,
    output logic [3:0] note_length,
    output logic       silenceOutN
);

    // loopIndex extends playtime (~1 minute)
    logic [7:0] loopIndex;

    always_comb begin
        silenceOutN = 1'b1;
        tone        = 4'd0;
        note_length = 4'd1;
        loopIndex   = noteIndex % 32; // wrap every 32 notes

        unique case (melodySelect)
            //--------------------------------------------------------------
            // 0. WIN SOUND - Happy Victory Melody (loop ≈ 1 min)
            //--------------------------------------------------------------
            4'd0: begin
                case (loopIndex)
                    5'd0:  begin tone=4'd7;  note_length=4'd4; end
                    5'd1:  begin tone=4'd9;  note_length=4'd4; end
                    5'd2:  begin tone=4'd11; note_length=4'd6; end
                    5'd3:  begin tone=4'd12; note_length=4'd4; end
                    5'd4:  begin tone=4'd11; note_length=4'd3; end
                    5'd5:  begin tone=4'd9;  note_length=4'd3; end
                    5'd6:  begin tone=4'd7;  note_length=4'd5; end
                    5'd7:  begin tone=4'd0;  note_length=4'd2; end
                    5'd8:  begin tone=4'd9;  note_length=4'd4; end
                    5'd9:  begin tone=4'd11; note_length=4'd4; end
                    5'd10: begin tone=4'd12; note_length=4'd6; end
                    5'd11: begin tone=4'd11; note_length=4'd4; end
                    5'd12: begin tone=4'd9;  note_length=4'd4; end
                    5'd13: begin tone=4'd7;  note_length=4'd5; end
                    5'd14: begin tone=4'd0;  note_length=4'd2; end
                    5'd15: begin tone=4'd11; note_length=4'd4; end
                    5'd16: begin tone=4'd12; note_length=4'd4; end
                    5'd17: begin tone=4'd13; note_length=4'd6; end
                    5'd18: begin tone=4'd12; note_length=4'd4; end
                    5'd19: begin tone=4'd11; note_length=4'd4; end
                    5'd20: begin tone=4'd9;  note_length=4'd5; end
                    5'd21: begin tone=4'd0;  note_length=4'd2; end
                    5'd22: begin tone=4'd7;  note_length=4'd3; end
                    5'd23: begin tone=4'd9;  note_length=4'd3; end
                    5'd24: begin tone=4'd11; note_length=4'd3; end
                    5'd25: begin tone=4'd12; note_length=4'd8; end
                    5'd26: begin tone=4'd0;  note_length=4'd3; end
                    5'd27: begin tone=4'd11; note_length=4'd4; end
                    5'd28: begin tone=4'd9;  note_length=4'd4; end
                    5'd29: begin tone=4'd7;  note_length=4'd6; end
                    5'd30: begin tone=4'd0;  note_length=4'd3; end
                    5'd31: begin tone=4'd7;  note_length=4'd2; end
                    default: note_length = 4'd0;
                endcase

                // Loop ~40 times to reach about 1 minute
                if (noteIndex < 5'd32 * 40)
                    silenceOutN = (tone != 4'd0);
                else
                    note_length = 4'd0; // end
            end

            //--------------------------------------------------------------
            // 1. LOSE SOUND - Sad Descending Melody (loop ≈ 1 min)
            //--------------------------------------------------------------
            4'd1: begin
                case (loopIndex)
                    5'd0:  begin tone=4'd7; note_length=4'd8; end
                    5'd1:  begin tone=4'd6; note_length=4'd6; end
                    5'd2:  begin tone=4'd5; note_length=4'd6; end
                    5'd3:  begin tone=4'd4; note_length=4'd8; end
                    5'd4:  begin tone=4'd0; note_length=4'd3; end
                    5'd5:  begin tone=4'd3; note_length=4'd6; end
                    5'd6:  begin tone=4'd2; note_length=4'd6; end
                    5'd7:  begin tone=4'd1; note_length=4'd8; end
                    5'd8:  begin tone=4'd0; note_length=4'd3; end
                    5'd9:  begin tone=4'd2; note_length=4'd5; end
                    5'd10: begin tone=4'd1; note_length=4'd5; end
                    5'd11: begin tone=4'd2; note_length=4'd4; end
                    5'd12: begin tone=4'd3; note_length=4'd6; end
                    5'd13: begin tone=4'd2; note_length=4'd8; end
                    5'd14: begin tone=4'd0; note_length=4'd3; end
                    5'd15: begin tone=4'd1; note_length=4'd6; end
                    5'd16: begin tone=4'd2; note_length=4'd4; end
                    5'd17: begin tone=4'd1; note_length=4'd6; end
                    5'd18: begin tone=4'd2; note_length=4'd8; end
                    5'd19: begin tone=4'd0; note_length=4'd3; end
                    5'd20: begin tone=4'd4; note_length=4'd5; end
                    5'd21: begin tone=4'd3; note_length=4'd5; end
                    5'd22: begin tone=4'd2; note_length=4'd5; end
                    5'd23: begin tone=4'd1; note_length=4'd10; end
                    5'd24: begin tone=4'd0; note_length=4'd4; end
                    5'd25: begin tone=4'd2; note_length=4'd5; end
                    5'd26: begin tone=4'd1; note_length=4'd6; end
                    5'd27: begin tone=4'd2; note_length=4'd5; end
                    5'd28: begin tone=4'd0; note_length=4'd4; end
                    5'd29: begin tone=4'd3; note_length=4'd6; end
                    5'd30: begin tone=4'd2; note_length=4'd7; end
                    5'd31: begin tone=4'd1; note_length=4'd5; end
                    default: note_length = 4'd0;
                endcase

                if (noteIndex < 5'd32 * 40)
                    silenceOutN = (tone != 4'd0);
                else
                    note_length = 4'd0; // end
            end

            //--------------------------------------------------------------
            // 2. MONSTER COLLISION
            //--------------------------------------------------------------
            4'd2: begin
                case (noteIndex)
                    5'd0: begin tone=4'd1; note_length=4'd2; end
                    5'd1: begin tone=4'd3; note_length=4'd2; end
                    5'd2: begin tone=4'd1; note_length=4'd3; end
                    default: note_length=4'd0;
                endcase
                silenceOutN = (tone != 4'd0);
            end

            //--------------------------------------------------------------
            // 3. COIN PICKUP
            //--------------------------------------------------------------
            4'd3: begin
                case (noteIndex)
                    5'd0: begin tone=4'd7;  note_length=4'd2; end
                    5'd1: begin tone=4'd11; note_length=4'd2; end
                    5'd2: begin tone=4'd9;  note_length=4'd2; end
                    5'd3: begin tone=4'd12; note_length=4'd3; end
                    5'd4: begin tone=4'd13; note_length=4'd2; end
                    5'd5: begin tone=4'd12; note_length=4'd2; end
                    default: note_length=4'd0;
                endcase
                silenceOutN = (tone != 4'd0);
            end

            default: begin
                tone = 4'd0;
                note_length = 4'd0;
                silenceOutN = 1'b0;
            end
        endcase
    end
endmodule
