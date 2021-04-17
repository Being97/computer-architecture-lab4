`include "opcodes.v"

`define NumBits 16

module alu (A, B, func_code, branch_type, C, overflow_flag, bcond);
  input [`NumBits-1:0] A; //input data A
  input [`NumBits-1:0] B; //input data B
  input [2:0] func_code; //function code for the operation
  input [1:0] branch_type; //branch type for bne, beq, bgz, blz
  output reg [`NumBits-1:0] C; //output data C
  output reg overflow_flag;
  output reg bcond; //1 if branch condition met, else 0

  //TODO: implement ALU
  initial begin 
    C = 0;
    overflow_flag = 0;
    bcond = 0;
  end

  always @(A or B or func_code or branch_type) begin
      overflow_flag = 0;

      case(func_code)
         `FUNC_ADD: begin 
            if (A + B > `NumBits'b1111111111111111) begin
               overflow_flag = 1;
            end
            else begin 
               C = A + B;
            end
         end
         `FUNC_SUB: begin C = A - B; end
         `FUNC_NOT: begin C = ~A; end
         `FUNC_AND: begin C = A & B; end
         `FUNC_ORR: begin C = A | B; end
         `FUNC_TCP: begin 
            if (A == 0) begin overflow_flag = 1; end
            else begin 
               C = ~A + 1;
            end
         `FUNC_SHL: begin C = A << 1; end
         `FUNC_SHR: begin C = $signed(A) >> 1; end
      endcase

      case(branch_type)
         2'b00: begin bcond = A != B; end
         2'b01: begin bcond = A == B; end
         2'b10: begin bcond = A > 0; end
         2'b11: begin bcond = A < 0; end
      endcase
   end
endmodule