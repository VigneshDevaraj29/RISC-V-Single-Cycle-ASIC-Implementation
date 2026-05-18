module tb_riscv_core;

reg clk;
reg reset;

integer cycle;

riscv_core dut (
    .clk(clk),
    .reset(reset)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    cycle = 0;

    $readmemh("../programs/test_program.hex", dut.instr_mem);

    reset = 1;
    #20;
    reset = 0;

    #300;

    $display("====================================");
    $display("RISC-V Single-Cycle Processor Test");
    $display("====================================");

    $display("x1  = %0d", dut.u_regfile.registers[1]);
    $display("x2  = %0d", dut.u_regfile.registers[2]);
    $display("x3  = %0d", dut.u_regfile.registers[3]);
    $display("x4  = %0d", dut.u_regfile.registers[4]);
    $display("x5  = %0d", dut.u_regfile.registers[5]);
    $display("x6  = %0d", dut.u_regfile.registers[6]);
    $display("x7  = %0d", dut.u_regfile.registers[7]);
    $display("x8  = %0d", dut.u_regfile.registers[8]);
    $display("x9  = %0d", dut.u_regfile.registers[9]);
    $display("x10 = %0d", dut.u_regfile.registers[10]);
    $display("x11 = %0d", dut.u_regfile.registers[11]);
    $display("x12 = %0d", dut.u_regfile.registers[12]);
    $display("x13 = %0d", dut.u_regfile.registers[13]);
    $display("x14 = %0d", dut.u_regfile.registers[14]);

    $display("data_mem[0] = %0d", dut.data_mem[0]);

    if (
        dut.u_regfile.registers[1]  == 32'd5  &&
        dut.u_regfile.registers[2]  == 32'd10 &&
        dut.u_regfile.registers[3]  == 32'd15 &&
        dut.u_regfile.registers[4]  == 32'd5  &&
        dut.u_regfile.registers[5]  == 32'd0  &&
        dut.u_regfile.registers[6]  == 32'd15 &&
        dut.u_regfile.registers[7]  == 32'd15 &&
        dut.u_regfile.registers[8]  == 32'd20 &&
        dut.u_regfile.registers[9]  == 32'd4  &&
        dut.u_regfile.registers[10] == 32'd15 &&
        dut.u_regfile.registers[11] == 32'd15 &&
        dut.u_regfile.registers[12] == 32'd0  &&
        dut.u_regfile.registers[13] == 32'd0  &&
        dut.u_regfile.registers[14] == 32'd7  &&
        dut.data_mem[0] == 32'd15
    ) begin
        $display("TEST PASSED");
    end
    else begin
        $display("TEST FAILED");
    end

    $display("====================================");
    $finish;
end

always @(posedge clk) begin
    if (!reset) begin
        cycle = cycle + 1;
        $display("Cycle %0d | PC = %h | Instr = %h", cycle, dut.pc_out, dut.instr);
    end
end

initial begin
    $dumpfile("../sim/riscv_core.vcd");
    $dumpvars(0, tb_riscv_core);
end

endmodule