module dot_product #(
    parameter N = 1024
) (
    input        clk,
    input        rst_n,          // active-low async reset
    input        start,          // single-cycle start pulse
    input signed [31:0] data_a,  // signed input A
    input signed [31:0] data_b,  // signed input B
    input        valid,          // high when data is valid
    output reg   done,           // high when result ready
    output reg signed [63:0] result
);

// TODO: Implement your logic here

endmodule