module riscv_core_synth (
    input  wire        clk,
    input  wire        reset,

    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_read,
    output wire        dmem_write
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
wire [31:0] alu_result;
wire alu_zero;
wire branch_taken;

wire [31:0] write_data;

assign pc_plus4      = pc_out + 32'd4;
assign branch_target = pc_out + imm_out;
assign pc_next       = branch_taken ? branch_target : pc_plus4;

// Instruction memory interface
assign imem_addr = pc_out;
assign instr     = imem_rdata;

// Instruction decode
assign opcode = instr[6:0];
assign rd     = instr[11:7];
assign funct3 = instr[14:12];
assign rs1    = instr[19:15];
assign rs2    = instr[24:20];
assign funct7 = instr[31:25];

// Data memory interface
assign dmem_addr  = alu_result;
assign dmem_wdata = read_data2;
assign dmem_read  = mem_read;
assign dmem_write = mem_write;

// Writeback mux
assign write_data = mem_to_reg ? dmem_rdata : alu_result;

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

alu u_alu (
    .a(read_data1),
    .b(alu_input_b),
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

endmodule