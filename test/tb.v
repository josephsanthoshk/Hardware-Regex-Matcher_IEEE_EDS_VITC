`default_nettype none
`timescale 1ns / 1ps

module tb ();

    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena;
    reg        clk;
    reg        rst_n;

    tt_um_regex_matcher uut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    wire match = uo_out[0];

    // ------------------------------------------------------------
    // Clock generation
    // 100 MHz clock -> 10 ns period
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task: send a string, one character per clock cycle
    // ------------------------------------------------------------
    task send_string;
        input [8*32-1:0] str;
        integer i;
        reg [7:0] char;

        begin
            for (i = 31; i >= 0; i = i - 1) begin
                char = str[i*8 +: 8];

                if (char != 8'h00) begin
                    ui_in = char;
                    @(posedge clk);
                end
            end

            ui_in = 8'h00;
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin

        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // Initialize
        ui_in  = 8'h00;
        uio_in = 8'h00;
        ena    = 1'b1;
        rst_n  = 1'b0;

        // Reset
        #20;
        rst_n = 1'b1;
        @(posedge clk);

        // --------------------------------------------------------
        // TEST 1: Valid email
        // Expected: MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 1: hello@tapeout.com");
        $display("Expected: MATCH");
        $display("==============================================");

        send_string("hello@tapeout.com");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 2: Another valid email
        // Expected: MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 2: me@x.com");
        $display("Expected: MATCH");
        $display("==============================================");

        send_string("me@x.com");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 3: Missing '.'
        // Expected: NO MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 3: hello@tapeoutcom");
        $display("Expected: NO MATCH");
        $display("==============================================");

        send_string("hello@tapeoutcom");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 4: Valid pattern followed by extra characters
        //
        // The RTL may detect the pattern before the trailing xyz.
        // Expected for current RTL: MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 4: hello@domain.comxyz");
        $display("Expected: MATCH");
        $display("==============================================");

        send_string("hello@domain.comxyz");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 5: Missing '.'
        // Expected: NO MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 5: hello@domaincomxyz");
        $display("Expected: NO MATCH");
        $display("==============================================");

        send_string("hello@domaincomxyz");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 6: Wrong ordering
        // Expected: NO MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 6: hello.domain@comxyz");
        $display("Expected: NO MATCH");
        $display("==============================================");

        send_string("hello.domain@comxyz");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 7: Minimal valid pattern
        // Expected: MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 7: a@b.com");
        $display("Expected: MATCH");
        $display("==============================================");

        send_string("a@b.com");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // TEST 8: Invalid characters in first block
        // Expected: NO MATCH
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("TEST 8: hello123@domain.com");
        $display("Expected: NO MATCH");
        $display("==============================================");

        send_string("hello123@domain.com");
        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // Finish
        // --------------------------------------------------------
        #50;

        $display("");
        $display("==============================================");
        $display("Simulation finished.");
        $display("==============================================");

        $finish;
    end

    // ------------------------------------------------------------
    // Monitor match output
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (match) begin
            $display(
                ">> MATCH DETECTED at time %0t ns",
                $time
            );
        end
    end

endmodule
