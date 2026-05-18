module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);

wire [6:0] opcode;

assign opcode = instr[6:0];

always @(*) begin
    case (opcode)

        7'b0010011,   // I-type ALU
        7'b0000011:   // LW
            imm_out = {{20{instr[31]}}, instr[31:20]};

        7'b0100011:   // SW
            imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        7'b1100011:   // BEQ, BNE
            imm_out = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

        default:
            imm_out = 32'b0;

    endcase
end

endmodule