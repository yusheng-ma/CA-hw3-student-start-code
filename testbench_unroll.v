`timescale 1ns / 1ps

// =============================================================================
// Testbench for Unrolled Dot Product Accelerator
//
// This testbench verifies the correctness of a dot product hardware module
// that processes UNROLL pairs of 32-bit signed integers per clock cycle.
//
// Input data format (in data/input_packed.txt):
//   a[0]
//   a[1]
//   a[2]
//   a[3]
//   b[0]
//   b[1]
//   b[2]
//   b[3]
//   a[4]
//   ...
//   b[1023]
//
// The expected result is read from data/golden_output.txt.
//
// The testbench:
//   1. Initializes and resets the DUT
//   2. Loads golden reference result
//   3. Streams input data batch-by-batch (UNROLL pairs per cycle)
//   4. Waits for the 'done' signal
//   5. Compares result and reports pass/fail
//
// Assumptions:
//   - N = 1024, UNROLL = 4 (fixed)
//   - N is divisible by UNROLL
//   - All files exist in the ./data/ directory
//   - DUT uses synchronous active-high 'valid' and 'done' signals
// =============================================================================

module testbench_unroll;

parameter N = 1024;
parameter UNROLL = 4;
localparam BATCHES = N / UNROLL;
parameter CLK_PERIOD = 10;  // 10 ns clock period (100 MHz)

// =============================================================================
// DUT Interface Signals
//
// These signals connect directly to the unrolled dot product accelerator.
// The testbench drives inputs (clk, rst_n, start, data_a[UNROLL], data_b[UNROLL], valid)
// and observes outputs (done, result).
// =============================================================================
reg        clk, rst_n, start, valid;
reg signed [31:0] data_a [0:UNROLL-1];
reg signed [31:0] data_b [0:UNROLL-1];
wire       done;
wire signed [63:0] result;

// =============================================================================
// Internal Testbench State
//
// Variables used for file I/O, loop control, and result validation.
// Note: In Verilog-2001, all variables must be declared at module scope.
// =============================================================================
integer fd, i, j, scan_result;
reg signed [63:0] expected;
integer cycle_count;
integer wait_count;

// =============================================================================
// DUT Instantiation
//
// The dot_product_unroll module is instantiated with N=1024 and UNROLL=4.
// Students must implement this module to accept UNROLL pairs per cycle.
// =============================================================================
dot_product_unroll #(.N(N), .UNROLL(UNROLL)) uut (
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
//   - Input data streaming (batched)
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

    // Open packed input file (UNROLL a's, then UNROLL b's per batch)
    fd = $fopen("data/input_packed.txt", "r");
    if (fd == 0) begin
        $display("❌ Error: Cannot open data/input_packed.txt");
        $finish;
    end

    // Trigger DUT start (single-cycle pulse)
    #10; start = 1; #10; start = 0;

    // Stream BATCHES batches to DUT, UNROLL pairs per cycle
    cycle_count = 0;
    for (i = 0; i < BATCHES; i = i + 1) begin
        // Read UNROLL a values
        for (j = 0; j < UNROLL; j = j + 1) begin
            scan_result = $fscanf(fd, "%d", data_a[j]);
            if (scan_result != 1) begin
                $display("❌ Error: Failed to read data_a[%0d][%0d]", i, j);
                $finish;
            end
        end
        // Read UNROLL b values
        for (j = 0; j < UNROLL; j = j + 1) begin
            scan_result = $fscanf(fd, "%d", data_b[j]);
            if (scan_result != 1) begin
                $display("❌ Error: Failed to read data_b[%0d][%0d]", i, j);
                $finish;
            end
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
        if (wait_count > 100) begin
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
    $display("Total cycles: %0d (expected: %0d)", cycle_count, BATCHES);

    $finish;
end

endmodule