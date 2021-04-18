`include "opcodes.v"

module alu_control_unit(funct, opcode, ALUOp, clk, funcCode, branchType);
  input ALUOp;
  input clk;
  input [5:0] funct;
  input [3:0] opcode;

  output reg [2:0] funcCode;
  output reg [1:0] branchType;

  initial begin
    branchType = 2'b0;
    funcCode = 3'b0;
  end

	always @(posedge clk) begin
    funcCode = 0;
    if (ALUOp) begin
      if (opcode == `ALU_OP) begin
        case(funct)
          `INST_FUNC_ADD: begin funcCode = `FUNC_ADD; end
          `INST_FUNC_SUB: begin funcCode = `FUNC_SUB; end
          `INST_FUNC_AND: begin funcCode = `FUNC_AND; end
          `INST_FUNC_ORR: begin funcCode = `FUNC_ORR; end
          `INST_FUNC_NOT: begin funcCode = `FUNC_NOT; end
          `INST_FUNC_TCP: begin funcCode = `FUNC_TCP; end
          `INST_FUNC_SHL: begin funcCode = `FUNC_SHL; end
          `INST_FUNC_SHR: begin funcCode = `FUNC_SHR; end
        endcase
      end
      else if(opcode == `ADI_OP) begin funcCode = `FUNC_ADD; end
      else if(opcode == `ORI_OP) begin funcCode = `FUNC_ORR; end
      else if(opcode == `LHI_OP) begin funcCode = `FUNC_SHL; end
      else if(opcode == `BNE_OP) begin branchType = 2'b00; end
      else if(opcode == `BEQ_OP) begin branchType = 2'b01; end
      else if(opcode == `BGZ_OP) begin branchType = 2'b10; end
      else if(opcode == `BLZ_OP) begin branchType = 2'b11; end
    end

    //$display("-----ALU CONTROL----- opcode: %b, funct: %b, funcCode: %b, ALUOp: %b", opcode, funct, funcCode, ALUOp);
	end
endmodule