module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        branch_ne,
    output reg [3:0]  alu_ctrl
);

always @(*) begin
    reg_write = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    mem_to_reg = 1'b0;
    alu_src = 1'b0;
    branch = 1'b0;
    branch_ne = 1'b0;
    alu_ctrl = 4'b0000;

    case (opcode)

        7'b0110011: begin
            // R-type
            reg_write = 1'b1;
            alu_src = 1'b0;
            mem_to_reg = 1'b0;

            case ({funct7, funct3})
                {7'b0000000, 3'b000}: alu_ctrl = 4'b0000; // ADD
                {7'b0100000, 3'b000}: alu_ctrl = 4'b0001; // SUB
                {7'b0000000, 3'b111}: alu_ctrl = 4'b0010; // AND
                {7'b0000000, 3'b110}: alu_ctrl = 4'b0011; // OR
                {7'b0000000, 3'b100}: alu_ctrl = 4'b0100; // XOR
                default:              alu_ctrl = 4'b0000;
            endcase
        end

        7'b0010011: begin
            // I-type ALU
            reg_write = 1'b1;
            alu_src = 1'b1;
            mem_to_reg = 1'b0;

            case (funct3)
                3'b000: alu_ctrl = 4'b0000; // ADDI
                3'b111: alu_ctrl = 4'b0010; // ANDI
                3'b110: alu_ctrl = 4'b0011; // ORI
                default: alu_ctrl = 4'b0000;
            endcase
        end

        7'b0000011: begin
            // LW
            reg_write = 1'b1;
            mem_read = 1'b1;
            mem_to_reg = 1'b1;
            alu_src = 1'b1;
            alu_ctrl = 4'b0000;
        end

        7'b0100011: begin
            // SW
            mem_write = 1'b1;
            alu_src = 1'b1;
            alu_ctrl = 4'b0000;
        end

        7'b1100011: begin
            // BEQ, BNE
            branch = 1'b1;
            alu_src = 1'b0;
            alu_ctrl = 4'b0001;

            case (funct3)
                3'b000: branch_ne = 1'b0; // BEQ
                3'b001: branch_ne = 1'b1; // BNE
                default: branch_ne = 1'b0;
            endcase
        end

        default: begin
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            mem_to_reg = 1'b0;
            alu_src = 1'b0;
            branch = 1'b0;
            branch_ne = 1'b0;
            alu_ctrl = 4'b0000;
        end

    endcase
end

endmodule