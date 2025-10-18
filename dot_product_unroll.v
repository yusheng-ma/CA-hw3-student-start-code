module dot_product_unroll #(
    parameter N = 1024,
    parameter UNROLL = 4
) (
    input                  clk,
    input                  rst_n,          // active-low asynchronous reset
    input                  start,          // single-cycle start pulse
    input signed [31:0]    data_a [0:UNROLL-1],  // UNROLL signed inputs A
    input signed [31:0]    data_b [0:UNROLL-1],  // UNROLL signed inputs B
    input                  valid,          // high when batch is valid
    output reg             done,           // high when result is ready
    output reg signed [63:0] result
);

// TODO: Implement your logic here

endmodule