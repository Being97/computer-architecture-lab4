`include "opcodes.v"

module register_file(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk); 
  input [1:0] read1;
  input [1:0] read2;
  input [1:0] write_reg;
  input [15:0] write_data;
  input reg_write;
  input clk;
  output reg [15:0] read_out1;
  output reg [15:0] read_out2;

  reg [`WORD_SIZE-1:0] GPR [`NUM_REGS-1:0];

  initial begin
    GPR[0] = 0;
    GPR[1] = 0;
    GPR[2] = 0;
    GPR[3] = 0;
  end

  always @(*) begin      
    read_out1 = GPR[read1];
    read_out2 = GPR[read2];
  end

  always @(posedge clk) begin
    if(reg_write) begin
      GPR[write_reg] <= write_data;
    end
  end
endmodule