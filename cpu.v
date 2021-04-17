`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size
`include "opcodes.v"

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
    input clk;
    input reset_n;
    
    output reg read_m;
    output reg write_m;
    output reg [`WORD_SIZE-1:0] address;

    inout [`WORD_SIZE-1:0] data;
    wire [`WORD_SIZE-1:0] mem_data;
    wire [`WORD_SIZE-1:0] instr;
    wire [`WORD_SIZE-1:0] write_data;
    wire [`WORD_SIZE-1:0] read_data_1, read_data_2;

    output reg [`WORD_SIZE-1:0] num_inst;		// number of instruction executed (for testing purpose)
    output reg [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
    output is_halted;

    wire i_or_d;
    wire mem_write;
    wire mem_read;
    wire reg_write;
    wire PVSWriteEn;
    wire [`WORD_SIZE-1:0] A, B, C;
    wire ir_write;
    wire save_alu_out;
    wire branchType;
    wire alu_op;

    reg [2:0] ALU_func;
    reg [5:0] func;
    reg [3:0] opcode;
    reg [1:0] rs, rt, rd;
    reg [7:0] imm;
    reg [`WORD_SIZE-1:0] alu_out;
    reg [`WORD_SIZE-1:0] alu_result;
    reg [`WORD_SIZE-1:0] output_data;

    // TODO : implement multi-cycle CPU

    assign data = write_m?output_data:`WORD_SIZE'bz;

    //initialization
    initial begin
        func <= 0;
        ALU_func <= 0;
        opcode <= 0;
    end
    //num_inst update
    always @(posedge clk) begin
      if (PVSWriteEn == 1) begin
        num_inst <= num_inst + 1;
      end
      // memory logic
      if (mem_write == 1) begin
          output_data <= B;
          write_m <= 1;
      end
      if (mem_read == 1) begin
          read_m <= 1;
      end
      if (read_m == 1 && mem_read == 0) begin
          if (i_or_d) begin
              mem_data <= data;
          end
          else begin
          instr <= data;
          end
          read_m <= 0;
      end
      if (write_m == 1 && mem_write == 0) begin
      write_m <= 0;
      end
      if (ir_write) begin
        opcode <= instr[`WORD_SIZE-1:12];
        rs <= instr[11:10];
        rt <= instr[9:8];
        rd <= instr[7:6];
        func <= instr[5:0];
        imm <= instr[7:0];
      end
      if (reg_write) begin
        A <= read_data_1;
        B <= read_data_2;
      end
      if (save_alu_out) begin
        alu_out <= alu_result;
      end
    end

  control_unit cu(
    .opcode(opcode),
    .func_code(func),
    .clk(clk),
    // .pc_write_cond(pc_write_cond),
    // .pc_write(pc_write),
    .i_or_d(i_or_d),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .ir_write(ir_write),
    .pc_to_reg(pc_to_reg),
    .pc_src(pc_src),
    .halt(halt),
    .wwd(wwd),
    .new_inst(new_inst),
    .reg_write(reg_write),
    .alu_src_A(alu_src_A),
    .alu_src_B(alu_src_B),
    .alu_op(alu_op)
  );

  mux2_1 mux1(.sel(i_or_d), .i1(pc), .i2(alu_out), .o(address));

  alu_control_unit alu_control_unit(
    .funct(func), 
    .opcode(opcode), 
    .ALUOp(alu_op), 
    .clk(clk), 
    .funcCode(ALU_func), 
    .branchType(branchType)
  );

  alu alu(
    .A(A),
    .B(B),
    .func_code(ALU_func),
    .branch_type(branchType),
    .C(alu_result),
    .overflow_flag(overflow_flag),
    .bcond(bcond)
  );

  register_file reg_file(
    .read_out1(read_out1),
    .read_out2(read_out2),
    .read1(read1),
    .read2(read2),
    .write_reg((opcode == `JRL_OP || `JAL_OP) ? 2 : rd),
    .write_data(write_data),
    .reg_write(reg_write),
    .clk(clk)
  );

  mux2_1 mux2(.sel(mem_to_reg), .i1(alu_out), .i2(mem_data), .o(write_data));
  mux2_1 mux3(.sel(alu_src_A), .i1(pc_prev), .i2(read_data_1), .o(A));
  mux4_1 mux4(.sel(alu_src_B), .i1(B), .i2(1), .i3(imm_extended), .i4(0), .o(B));
  mux4_1 mux5(.sel(pc_src), .i1(alu_result), .i2(alu_out), .i3({4'd0, mem_data[11:0]}), .i4(0), .o(pc));
endmodule
