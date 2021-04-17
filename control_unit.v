`include "opcodes.v"

module control_unit(opcode, func_code, clk, /*pc_write_cond, pc_write,*/ i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op, PVSWriteEn);
  input [3:0] opcode;
  input [5:0] func_code;
  input clk;

  output reg /*pc_write_cond, pc_write,*/ i_or_d, mem_read, mem_to_reg, mem_write, ir_write;
  output reg PVSWriteEn;

  // pc_src == 0 이면 pc+4 (alu_result) : ALU_OP || branch && !bcond
  // pc_src == 1 이면 alu_out : JRL, JPR || branch && bcond)(pc+sign_extended_imm)
  // pc_src == 2 이면 target_addr : JAL, JMP
  output reg [1:0] pc_src;
  //additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
  output reg pc_to_reg, halt, wwd, new_inst;
  output reg [1:0] reg_write, alu_src_A, alu_src_B;
  output reg alu_op;
  output reg save_alu_out;

  if(opcode == `ALU_OP && func_code == `INST_FUNC_JRL) begin
    pc_to_reg = 1;
    next_pc = read_out1;
  end
  else if(opcode == `ALU_OP && func_code == `INST_FUNC_JPR) begin
    next_pc = read_out1; 
  end
  
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
    pc_to_reg = 0;
  end

	task initialize;
		begin
      PVSWriteEn = 0;
			reg_write = 0;
      mem_read = 0;
      mem_write = 0;
      mem_to_reg = 0;
      ir_write = 0;
      save_alu_out = 0;
		end
	endtask

  always (@posedge clk) begin
    current_state <= next_state;
  end

	always @(*) begin
    initialize();
		case (current_state)
			`IF_1: begin
        alu_src_A = 0;
        alu_src_B = 1;
        i_or_d = 0;
        next_state = `IF_2;
			end
			`IF_2: begin
        mem_read = 1;
        next_state = `IF_3;
			end
			`IF_3: begin
        ir_write = 1;
        // mem_read = 0;
        next_state = `IF_4;
			end
			`IF_4: begin
        // ir_write = 0;
        if (opcode == `JAL_OP) begin
          pc_src = 2;
          next_state = `WB;
        end
        else if (opcode == `JMP_OP) begin
          pc_src = 2;
          PVSWriteEn = 1;
          next_state = `IF_1;
        end 
        else begin
          ir_write = 1;
          next_state = `ID;
        end
			end
			`ID: begin
        // ir_write = 0;
        next_state = `EX_1;
			end
			`EX_1: begin
        save_alu_out = 1;
        next_state = `EX_2;
			end
			`EX_2: begin
        // save_alu_out = 0;
        if (opcode == ld || opcode == sd) begin
          next_state = `MEM_1;
        end
        else if (opcode == branch) begin
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
        i_or_d = 1;
        if (opcode == `LWD_OP) begin
          mem_read = 1;
        end
        else if (opcode == `SWD_OP) begin
          mem_write = 1;
        end
        next_state = `MEM_2;
			end
			`MEM_2: begin
        // mem_read = 0;
        // mem_write = 0;
        next_state = `MEM_3;        
			end
			`MEM_3: begin
        next_state = `MEM_4;
			end
			`MEM_4: begin
        pc_write = 1;
        if (opcode == ld) begin
          next_state = `WB;
        end
        else begin
          PVSWriteEn = 1;
          next_state = `IF_1;
        end
			end
			`WB: begin
        reg_write = 1;
        if (opcode == ld) begin
          mem_to_reg = 1;
        end
        if (opcode == `JRL_OP) begin
          pc_src = 1;
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

endmodule
