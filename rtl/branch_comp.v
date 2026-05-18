module branch_comp (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire        branch,
    input  wire        branch_ne,
    output wire        branch_taken
);

wire equal;

assign equal = (rs1_data == rs2_data);

assign branch_taken = branch && ((branch_ne && !equal) || (!branch_ne && equal));

endmodule