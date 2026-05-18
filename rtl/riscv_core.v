module riscv_core (
    input wire clk,
    input wire reset
);

wire [31:0] pc_out;
wire [31:0] pc_next;
wire [31:0] pc_plus4;
wire [31:0] branch_target;

wire [31:0] instr;

wire [6:0] opcode;
wire [4:0] rd;
wire [2:0] funct3;
wire [4:0] rs1;
wire [4:0] rs2;
wire [6:0] funct7;

wire reg_write;
wire mem_read;
wire mem_write;
wire mem_to_reg;
wire alu_src;
wire branch;
wire branch_ne;
wire [3:0] alu_ctrl;

wire [31:0] imm_out;
wire [31:0] read_data1;
wire [31:0] read_data2;
wire [31:0] alu_input_b;

/*
   Bonus power optimization wires:
   These gate ALU inputs during branch-only instructions.
   Branch decision is already handled by branch_comp, so the ALU
   does not need to actively switch for branch comparison.
*/
wire [31:0] alu_a_gated;
wire [31:0] alu_b_gated;
wire        alu_enable;

wire [31:0] alu_result;
wire alu_zero;
wire branch_taken;

wire [31:0] data_mem_read;
wire [31:0] write_data;

/* 
   Simple instruction memory and data memory for RTL simulation.
   These are synthesizable register arrays, but later we may adjust
   memory style if Design Compiler gives memory-related warnings.
*/
reg [31:0] instr_mem [0:255];
reg [31:0] data_mem  [0:255];

integer i;

assign pc_plus4 = pc_out + 32'd4;
assign branch_target = pc_out + imm_out;
assign pc_next = branch_taken ? branch_target : pc_plus4;

assign instr = instr_mem[pc_out[9:2]];

assign opcode = instr[6:0];
assign rd     = instr[11:7];
assign funct3 = instr[14:12];
assign rs1    = instr[19:15];
assign rs2    = instr[24:20];
assign funct7 = instr[31:25];

pc u_pc (
    .clk(clk),
    .reset(reset),
    .pc_next(pc_next),
    .pc_out(pc_out)
);

control_unit u_control_unit (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .branch_ne(branch_ne),
    .alu_ctrl(alu_ctrl)
);

imm_gen u_imm_gen (
    .instr(instr),
    .imm_out(imm_out)
);

regfile u_regfile (
    .clk(clk),
    .reset(reset),
    .reg_write(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

assign alu_input_b = alu_src ? imm_out : read_data2;

/*
   Bonus power optimization:
   Gate ALU inputs during branch-only instructions because branch decision
   is handled separately by branch_comp. This reduces unnecessary ALU switching.
*/
assign alu_enable  = ~branch;
assign alu_a_gated = alu_enable ? read_data1  : 32'b0;
assign alu_b_gated = alu_enable ? alu_input_b : 32'b0;

alu u_alu (
    .a(alu_a_gated),
    .b(alu_b_gated),
    .alu_ctrl(alu_ctrl),
    .result(alu_result),
    .zero(alu_zero)
);

branch_comp u_branch_comp (
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .branch(branch),
    .branch_ne(branch_ne),
    .branch_taken(branch_taken)
);

/*
   Data memory:
   Word-addressed using alu_result[9:2].
   LW reads combinationally.
   SW writes on clock edge.
*/
assign data_mem_read = mem_read ? data_mem[alu_result[9:2]] : 32'b0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 256; i = i + 1) begin
            data_mem[i] <= 32'b0;
        end
    end
    else begin
        if (mem_write) begin
            data_mem[alu_result[9:2]] <= read_data2;
        end
    end
end

assign write_data = mem_to_reg ? data_mem_read : alu_result;

endmodule