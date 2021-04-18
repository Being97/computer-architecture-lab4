`include "opcodes.v"

module control_unit(opcode, func_code, clk, bcond,/*pc_write_cond, pc_write,*/ i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op, PVSWriteEn, save_alu_out, reset_n, pc_new);
  input [3:0] opcode;
  input [5:0] func_code;
  input clk;
  input bcond;
  input reset_n;

  output reg /*pc_write_cond, pc_write,*/ i_or_d, mem_read, mem_to_reg, mem_write, ir_write;
  output reg PVSWriteEn;
  output reg pc_new;
  // pc_src == 0 이면 pc+4 (alu_result) : ALU_OP || branch && !bcond
  // pc_src == 1 이면 alu_out : JRL, JPR || branch && bcond)(pc+sign_extended_imm)
  // pc_src == 2 이면 target_addr : JAL, JMP
  output reg [1:0] pc_src;
  //additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
  output reg pc_to_reg, halt, wwd, new_inst;
  // output reg [1:0] reg_write, alu_src_A, alu_src_B;
  output reg reg_write, alu_src_A;
  output reg [1:0] alu_src_B;
  output reg alu_op;
  output reg save_alu_out;

  reg [3:0] current_state;
  reg [3:0] next_state;
  reg state_updated;

  initial begin
    current_state = `IF_1;
    PVSWriteEn = 1;
    save_alu_out = 0;
    ir_write = 0;
    reg_write = 0;
    mem_read = 0;
    mem_write = 0;
    mem_to_reg = 0;
    ir_write = 0;
    // pc_to_reg = 0;
    alu_op = 0;
    state_updated = 1;
    pc_new = 0;
  end

	task initialize;
		begin
      PVSWriteEn = 0;
			reg_write = 0;
      mem_to_reg = 0;
      ir_write = 0;
      save_alu_out = 0;
      pc_new = 0;   
		end
	endtask

  // if((opcode == `ALU_OP) && (func_code == `INST_FUNC_JRL)) begin
  //   pc_to_reg = 1;
  //   next_pc = read_out1;
  // end
  // else if((opcode == `ALU_OP) && (func_code == `INST_FUNC_JPR)) begin
  //   next_pc = read_out1; 
  // end


  always @(posedge clk) begin
    if (!reset_n) begin
      $display("reset");
      current_state <= `IF_1;
      PVSWriteEn <= 0;
      save_alu_out <= 0;
      ir_write <= 0;
      reg_write <= 0;
      mem_read <= 0;
      mem_write <= 0;
      mem_to_reg <= 0;
      ir_write <= 0;
      pc_src <= 0;
      // pc_to_reg <= 0;
      alu_op <= 0;
      state_updated <= 0;   
      pc_new <= 0;   
    end
    else begin
      current_state <= next_state;
      state_updated <= 1;
    end
  end

	always @(*) begin
    if (state_updated) begin
      initialize();
      case (current_state) 
        `IF_1: begin
          alu_op = 0;
          $display("IF_1");
          alu_src_A = 0;
          alu_src_B = 1;
          next_state = `IF_2;
        end
        `IF_2: begin
          $display("IF_2");
          i_or_d = 0;
          next_state = `IF_3;
        end
        `IF_3: begin
          $display("IF_3");
          next_state = `IF_4;
        end
        `IF_4: begin
          $display("IF_4");
          mem_read = 1;
          ir_write = 1;
          next_state = `ID;
        end
        `ID: begin
          $display("ID");
          pc_new = 1;
          mem_read = 0;
          if (opcode == `JAL_OP) begin
            next_state = `WB;
          end
          else if (opcode == `JMP_OP) begin
            pc_src = 2;
            next_state = `IF_1;
            PVSWriteEn = 1;
          end else if(opcode == `WWD_OP) begin
            pc_src = 0;
            next_state = `IF_1;
            PVSWriteEn = 1;
          end
          else begin
            next_state = `EX_1;
          end
        end
        `EX_1: begin
          $display("EX_1");
          alu_src_A = 1;
          if(opcode == `LHI_OP) begin
            alu_src_B = 3;
          end
          else if(opcode == `ADI_OP || opcode == `ORI_OP) begin
            alu_src_B = 2;
          end
          else begin
            alu_src_B = 0;
          end
          alu_op = 1;
          next_state = `EX_2;
        end
        `EX_2: begin
          $display("EX_2");
          save_alu_out = 1;
          if (opcode == `LWD_OP || opcode == `SWD_OP) begin
            next_state = `MEM_1;
          end
          else if (opcode == `BNE_OP || opcode == `BEQ_OP || opcode == `BGZ_OP || opcode == `BLZ_OP) begin
            PVSWriteEn = 1;
            pc_src = bcond == 1 ? 1 : 0;
            next_state = `IF_1;
          end
          else if (opcode == `JRL_OP) begin
            pc_src = 1;
            next_state = `WB;
          end
          else if (opcode == `JPR_OP) begin
            PVSWriteEn = 1;
            pc_src = 1;
            next_state = `IF_1;
          end
          else begin
            next_state = `WB;
          end
        end
        `MEM_1: begin
          $display("MEM_1");
          i_or_d = 1;
          next_state = `MEM_2;
        end
        `MEM_2: begin
          $display("MEM_2");
          if (opcode == `LWD_OP) begin
            mem_to_reg = 1;
            mem_read = 1;
          end
          else if (opcode == `SWD_OP) begin
            mem_write = 1;
          end
          next_state = `MEM_3;        
        end
        `MEM_3: begin
          mem_read = 0;
          mem_write = 0;
          $display("MEM_3");
          next_state = `MEM_4;
        end
        `MEM_4: begin
          $display("MEM_4");
          // pc_write = 1;
          if (opcode == `LWD_OP) begin
            next_state = `WB;
          end
          else begin
            PVSWriteEn = 1;
            next_state = `IF_1;
          end
        end
        `WB: begin
          $display("WB");
          // if (opcode == `LWD_OP) begin
          //   mem_read = 0;
          // end
          reg_write = 1;
          if((opcode == `ALU_OP) && (func_code == `INST_FUNC_JRL)) begin
            pc_src = 1;
            // pc_to_reg = 1;
            // next_pc = read_out1;
          end
          else if (opcode == `JAL_OP) begin
            pc_src = 2;
          end
          else begin
            pc_src = 0;
          end
          PVSWriteEn = 1;
          next_state = `IF_1;
        end
      endcase
      state_updated = 0;
    end
  end
endmodule
