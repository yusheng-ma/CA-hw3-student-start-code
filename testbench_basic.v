`timescale 1ns / 1ps

// =============================================================================
// Basic Testbench for Streaming Dot Product Accelerator
//
// This testbench verifies the correctness of a dot product hardware module
// that processes one pair of 32-bit signed integers per clock cycle.
//
// Input data format (in data/input_stream.txt):
//   a[0]
//   b[0]
//   a[1]
//   b[1]
//   ...
//   a[N-1]
//   b[N-1]
//
// The expected result is read from data/golden_output.txt.
//
// The testbench:
//   1. Initializes and resets the DUT
//   2. Loads golden reference result
//   3. Streams input data pair-by-pair
//   4. Waits for the 'done' signal
//   5. Compares result and reports pass/fail
//
// Assumptions:
//   - N = 1024 (fixed)
//   - All files exist in the ./data/ directory
//   - DUT uses synchronous active-high 'valid' and 'done' signals
// =============================================================================

module testbench_basic;

parameter N = 1024;
parameter CLK_PERIOD = 10;  // 10 ns clock period (100 MHz)

// =============================================================================
// DUT Interface Signals
//
// These signals connect directly to the dot product accelerator.
// The testbench drives inputs (clk, rst_n, start, data_a, data_b, valid)
// and observes outputs (done, result).
// =============================================================================
reg        clk, rst_n, start, valid;
reg signed [31:0] data_a, data_b;
wire       done;
wire signed [63:0] result;

// =============================================================================
// Internal Testbench State
//
// Variables used for file I/O, loop control, and result validation.
// Note: In Verilog-2001, all variables must be declared at module scope.
// =============================================================================
integer fd, i, scan_result;
reg signed [63:0] expected;
integer cycle_count;
integer wait_count;

// =============================================================================
// DUT Instantiation
//
// The dot_product module is instantiated with the default parameter N=1024.
// Students must implement this module to match the streaming interface.
// =============================================================================
dot_product #(.N(N)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_a(data_a),
    .data_b(data_b),
    .valid(valid),
    .done(done),
    .result(result)
);

// =============================================================================
// Clock Generator
//
// Generates a free-running clock with 50% duty cycle.
// Time unit is 1 ns (per `timescale).
// =============================================================================
always begin
    clk = 0; #(CLK_PERIOD/2);
    clk = 1; #(CLK_PERIOD/2);
end

// =============================================================================
// Main Test Procedure
//
// This initial block orchestrates the entire test sequence:
//   - Reset deassertion
//   - Golden result loading
//   - Input data streaming
//   - Completion wait
//   - Result verification
// =============================================================================
initial begin
    // Deassert reset after initial stabilization
    rst_n = 0; start = 0; valid = 0;
    #20; rst_n = 1;

    // Load expected result from golden file
    fd = $fopen("data/golden_output.txt", "r");
    if (fd == 0) begin
        $display("❌ Error: Cannot open data/golden_output.txt");
        $finish;
    end
    scan_result = $fscanf(fd, "%d", expected);
    $fclose(fd);
    if (scan_result != 1) begin
        $display("❌ Error: Failed to read expected result");
        $finish;
    end

    // Open input stream file (interleaved a, b pairs)
    fd = $fopen("data/input_stream.txt", "r");
    if (fd == 0) begin
        $display("❌ Error: Cannot open data/input_stream.txt");
        $finish;
    end

    // Trigger DUT start (single-cycle pulse)
    #10; start = 1; #10; start = 0;

    // Stream N input pairs to DUT, one per cycle
    cycle_count = 0;
    for (i = 0; i < N; i = i + 1) begin
        scan_result = $fscanf(fd, "%d", data_a);
        if (scan_result != 1) begin
            $display("❌ Error: Failed to read data_a[%0d]", i);
            $finish;
        end
        scan_result = $fscanf(fd, "%d", data_b);
        if (scan_result != 1) begin
            $display("❌ Error: Failed to read data_b[%0d]", i);
            $finish;
        end

        valid = 1;
        @(posedge clk);
        valid = 0;
        cycle_count = cycle_count + 1;
    end
    $fclose(fd);

    // Wait for DUT to complete computation
    wait_count = 0;
    while (!done) begin
        @(posedge clk);
        wait_count = wait_count + 1;
        if (wait_count > 1000) begin
            $display("❌ Error: Timeout waiting for 'done' signal");
            $finish;
        end
    end

    // Final result check
    if (result === expected) begin
        $display("✅ CORRECT! Result = %0d", result);
    end else begin
        $display("❌ WRONG! Got %0d, expected %0d", result, expected);
    end
    $display("Total input cycles: %0d", cycle_count);

    $finish;
end

endmodule