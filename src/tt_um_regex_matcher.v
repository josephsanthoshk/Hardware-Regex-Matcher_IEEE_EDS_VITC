`default_nettype none

module tt_um_regex_matcher (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Disable bi-directional IOs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Character comparators
    wire is_az  = (ui_in >= 8'h61) && (ui_in <= 8'h7A); // 'a' to 'z'
    wire is_at  = (ui_in == 8'h40);                     // '@'
    wire is_dot = (ui_in == 8'h2E);                     // '.'
    wire is_c   = (ui_in == 8'h63);                     // 'c'
    wire is_o   = (ui_in == 8'h6F);                     // 'o'
    wire is_m   = (ui_in == 8'h6D);                     // 'm'

    // State registers (Flip-Flops for NFA states)
    reg s_az1;  // In the first [a-z]+ block
    reg s_at;   // Just matched '@'
    reg s_az2;  // In the second [a-z]+ block
    reg s_dot;  // Just matched '.'
    reg s_c;    // Just matched 'c'
    reg s_o;    // Just matched 'o'
    reg s_m;    // Just matched 'm' (Match condition)

    // State transition logic (evaluated on every clock edge)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_az1 <= 1'b0;
            s_at  <= 1'b0;
            s_az2 <= 1'b0;
            s_dot <= 1'b0;
            s_c   <= 1'b0;
            s_o   <= 1'b0;
            s_m   <= 1'b0;
        end else begin
            // NFA transitions
            
            // s_az1 can start matching anytime we see a-z, and stays active as long as we see a-z
            s_az1 <= is_az; 
            
            // Transition to '@' only if we were already matching [a-z]+
            s_at  <= s_az1 & is_at;
            
            // Second [a-z]+ block starts after '@' OR continues from itself
            s_az2 <= (s_at & is_az) | (s_az2 & is_az);
            
            // Match literal '.com' sequentially
            s_dot <= s_az2 & is_dot;
            s_c   <= s_dot & is_c;
            s_o   <= s_c & is_o;
            s_m   <= s_o & is_m;
        end
    end

    // Output assignment
    // uo_out[0] is the match signal. It pulses high for 1 clock cycle when matched.
    assign uo_out[0] = s_m;

    // Optional: Output internal states on other pins for debug/blinkenlights
    assign uo_out[1] = s_az1;
    assign uo_out[2] = s_at;
    assign uo_out[3] = s_az2;
    assign uo_out[4] = s_dot;
    assign uo_out[5] = s_c;
    assign uo_out[6] = s_o;
    assign uo_out[7] = 1'b0; 

endmodule
