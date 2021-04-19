`timescale 1ns/1ns
`include "opcodes.v"

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
    input clk;
    input reset_n;
    
    output reg read_m;
    output reg write_m;
    output reg [`WORD_SIZE-1:0] address;

    inout [`WORD_SIZE-1:0] data;
    // wire [`WORD_SIZE-1:0] mem_data;
    reg [`WORD_SIZE-1:0] instr;
    wire [`WORD_SIZE-1:0] write_data;
    // wire [`WORD_SIZE-1:0] read_data_1, read_data_2;


    output reg [`WORD_SIZE-1:0] num_inst;		// number of instruction executed (for testing purpose)
    output reg [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
    output is_halted;

    wire alu_src_A;
    wire [1:0] alu_src_B;
    wire i_or_d;
    wire mem_write;
    wire mem_read;
    wire reg_write;
    wire PVSWriteEn;
    wire mem_to_reg;
    reg [`WORD_SIZE-1:0] A;
    reg [`WORD_SIZE-1:0] B;
    // reg [`WORD_SIZE-1:0] C;
    wire [`WORD_SIZE-1:0] alu_input_1;
    wire [`WORD_SIZE-1:0] alu_input_2;
    wire [`WORD_SIZE-1:0] address_update = 16'b0;
    wire ir_write;
    wire save_alu_out;
    wire [1:0] branchType;
    wire alu_op;
    wire [1:0] pc_src;
    wire [2:0] ALU_func;
    wire wwd;

    reg [5:0] func;
    reg [3:0] opcode;
    reg [1:0] rs, rt, rd;
    reg [7:0] imm;
    reg [`WORD_SIZE-1:0] imm_extended;
    reg [`WORD_SIZE-1:0] alu_out;
    wire [`WORD_SIZE-1:0] alu_result;
    reg [`WORD_SIZE-1:0] output_data;
    reg [`WORD_SIZE-1:0] pc;
    wire [`WORD_SIZE-1:0] pc_update;
    reg [`WORD_SIZE-1:0] tmp_pc_update;
    wire [`WORD_SIZE-1:0] read_out1;
    wire [`WORD_SIZE-1:0] read_out2;
    reg [`WORD_SIZE-1:0] target_addr;
    reg [`WORD_SIZE-1:0] mem_data;
    wire pc_new;

    // TODO : implement multi-cycle CPU

    assign data = write_m?output_data:`WORD_SIZE'bz;
    assign read_m = mem_read;
    assign write_m = mem_write;
    // assign pc_wire = pc;
    // assign output_port = (func == `INST_FUNC_WWD) ? read_out2 : 0;
    // WWD instruction에서 outputport로 rs를 내보냄 -> tb에서 테스트용으로 쓰임

    //initialization
    initial begin
      num_inst <= -1;
      func <= 6'b0;
      opcode <= 4'b0;
      pc <= 0;
    end

    always @(posedge reset_n) begin
      num_inst <= -1;
      func <= 6'b0;
      opcode <= 4'b0;
      write_m <= 0;
      pc <= 0;
      address <= 0;
    end

    always @(*) begin
      if (pc_new) begin
        pc = tmp_pc_update;
      end
    end
    // always @(*) begin
    //   if (update_wwd) begin
    //     $display("[WWD] read_out2: %d", read_out2);
    //     output_port = read_out2;
    //   end
    // end
    // always @(negedge PVSWriteEn) begin
    // end

    always @(posedge clk) begin
      if (reset_n) begin
        // WWD instruction에서 outputport로 rs를 내보냄 -> tb에서 테스트용으로 쓰임
        if (wwd) begin
          $display("[WWD] read_out2: %d", read_out2);
          output_port <= read_out2;
        end
        // memory logic
        if (mem_write == 1) begin
          address <= address_update;
          output_data <= B;
          // write_m <= 1;
        end
        if (mem_read == 1) begin
          $display("[MEM_READ] i_or_d: %b, address %b, pc_src: %b, pc_update: %b", i_or_d, address_update, pc_src, pc_update);
          if (!i_or_d) begin
            address <= pc_update;
            tmp_pc_update <= pc_update;
          end else begin
            address <= address_update;
          end
        end
        // if (read_m == 1 && mem_read == 0) begin
        //   read_m <= 0;
        // end 
        // if (write_m == 1 && mem_write == 0) begin
        //   write_m <= 0;
        // end
        if (ir_write) begin
          output_port <= 0;
          opcode <= data[`WORD_SIZE-1:12];
          rs <= data[11:10];
          rt <= data[9:8];
          rd <= data[7:6];
          func <= data[5:0];
          target_addr <= {4'd0, data[11:0]};
          imm <= data[7:0];
          if (opcode != `ORI_OP) begin
            imm_extended <= $signed(data[7:0]);
          end
          else begin
            imm_extended[15:0] <= {{8{data[7]}}, data[7:0]};
          end
          $display("[ID] data: %b", data);
        end
        if (PVSWriteEn == 1) begin
          num_inst <= num_inst + 1;
          $display("======================== %d =========================", num_inst);
        end
        if (mem_to_reg) begin
          mem_data <= data;
        end
        // if (reg_write) begin
        //   A <= read_data_1;
        //   B <= read_data_2;
        // end
        if (save_alu_out) begin
          alu_out <= alu_result;
        end
      end
      //$display("---------CPU--------- data: %b pc_update: %b alu_input_2: %b, alu_result: %b, read_out1: %b, read_out2: %b", data, pc_update, alu_input_2, alu_result, read_out1, read_out2);
    end

  control_unit cu(
    .opcode(opcode),
    .func_code(func),
    .clk(clk),
    .bcond(bcond),
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
    .alu_op(alu_op),
    .PVSWriteEn(PVSWriteEn),
    .save_alu_out(save_alu_out),
    .reset_n(reset_n),
    .pc_new(pc_new)
  );

  mux2_1 mux1(.sel(i_or_d), .i1(pc), .i2(alu_out), .o(address_update));

  alu_control_unit alu_control_unit(
    .funct(func), 
    .opcode(opcode), 
    .ALUOp(alu_op), 
    .clk(clk), 
    .funcCode(ALU_func), 
    .branchType(branchType)
  );

  alu alu(
    .A(alu_input_1),
    .B(alu_input_2),
    .func_code(ALU_func),
    .branch_type(branchType),
    .C(alu_result),
    .overflow_flag(overflow_flag),
    .bcond(bcond)
  );

  register_file reg_file(
    .read_out1(read_out1),
    .read_out2(read_out2),
    .read1(rt),
    .read2(rs),
    .write_reg((opcode == `JRL_OP || opcode == `JAL_OP) ? 2'b10 : rd),
    .write_data(write_data),
    .reg_write(reg_write),
    .clk(clk)
  );

  mux2_1 mux2(.sel(mem_to_reg), .i1(alu_out), .i2((opcode == `JAL_OP) ? pc : mem_data), .o(write_data));
  mux2_1 mux3(.sel(alu_src_A), .i1(pc), .i2(read_out1), .o(alu_input_1));
  mux4_1 mux4(.sel(alu_src_B), .i1(read_out2), .i2(16'b1), .i3(imm_extended), .i4(16'b1000), .o(alu_input_2));
  mux4_1 mux5(.sel(pc_src), .i1(alu_result), .i2(alu_out), .i3(target_addr), .i4(16'b0), .o(pc_update));
endmodule
