`default_nettype none
`timescale 1ns / 1ps

module tb ();
    reg [7:0] ui_in;
    wire [7:0] uo_out;
    reg [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg ena;
    reg clk;
    reg rst_n;

    tt_um_regex_matcher uut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    wire match = uo_out[0];

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Task to send a string
    task send_string;
        input [8*32-1:0] str; // Up to 32 chars
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
        end
    endtask

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
        
        // Initialize inputs
        ui_in = 0;
        uio_in = 0;
        ena = 1;
        rst_n = 0;

        // Reset
        #20 rst_n = 1;
        @(posedge clk);

        // Test 1: Valid email
        $display("Testing: hello@tapeout.com");
        send_string("hello@tapeout.com");
        repeat(5) @(posedge clk);
        $display("---");
        
        // Test 2: Another valid email
        $display("Testing: me@x.com");
        send_string("me@x.com");
        repeat(5) @(posedge clk);
        $display("---");

        // Test 3: Invalid email (missing dot)
        $display("Testing: hello@tapeoutcom (SHOULD FAIL)");
        send_string("hello@tapeoutcom");
        repeat(5) @(posedge clk);
        $display("---");

        // Test 4: Unanchored string
        $display("Testing: blah123email@domain.comxyz");
        send_string("blah123email@domain.comxyz");
        repeat(5) @(posedge clk);
        $display("---");
        
        // Test 5: Unanchored string
        $display("Testing: blah123email@domaincomxyz (FAIL)");
        send_string("blah123email@domaincomxyz");
        repeat(5) @(posedge clk);
        $display("---");
        
        // Test 6: Unanchored string
        $display("Testing: blah123email.domain@comxyz (FAIL)");
        send_string("blah123email.domain@comxyz");
        repeat(5) @(posedge clk);
        $display("---");

        #50;
        $display("Simulation finished.");
        // We let Cocotb kill the simulation instead of calling $finish.
    end

    // Monitor match output
    always @(posedge clk) begin
        if (match) begin
            $display(">> MATCH DETECTED at time %0t!", $time);
        end
    end
endmodule
