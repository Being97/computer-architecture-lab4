`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;

	output read_m;
	output write_m;
	output [`WORD_SIZE-1:0] address;

	inout [`WORD_SIZE-1:0] data;

	output [`WORD_SIZE-1:0] num_inst;		// number of instruction executed (for testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	// TODO : implement multi-cycle CPU

	wire [1:0] rs;
	wire [1:0] rt;
	wire [1:0] rd;
	wire [3:0] opcode;
	wire [5:0] func_code;
	wire bcond;
	
	wire [`WORD_SIZE-1:0] read_out1;
	wire [`WORD_SIZE-1:0] read_out2;
	wire [`WORD_SIZE-1:0] alu_output;
	//FSM

	always @(*) begin
		case (current_state)
			`IF_1: begin

			end
			`IF_2: begin

			end
			`IF_3: begin

			end
			`IF_4: begin

			end
			`ID: begin

			end
			`EX_1: begin

			end
			`EX_2: begin

			end
			`MEM_1: begin

			end
			`MEM_2: begin

			end
			`MEM_3: begin

			end
			`MEM_4: begin

			end
			`WB: begin

			end
	end

	//register_file
	register_file register_file_module(
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.read1(rs), 
		.read2(rt), 
		.write_reg(rd), 
		.write_data(    ), 
		.reg_write(    ), 
		.clk(clk)
	);

	control_unit control_unit_module(
		.opcode(opcode), 
		.func_code(func_code), 
		.clk(clk), 
		.pc_write_cond(    ), 
		.pc_write(    ), 
		.i_or_d(    ), 
		.mem_read(    ), 
		.mem_to_reg(    ), 
		.mem_write(    ), 
		.ir_write(    ), 
		.pc_to_reg(    ), 
		.pc_src(    ), 
		.halt(    ), 
		.wwd(    ), 
		.new_inst(), 
		.reg_write(    ), 
		.alu_src_A(    ), 
		.alu_src_B(    ), 
		.alu_op(    ) 
	);

	alu alu_module(
		.A(read_out1), 
		.B(alu_src ? imm_extended : read_out2), 
		.func_code(func_code), 
		.branch_type(    ), 
		.C(alu_output), 
		.overflow_flag(    ), 
		.bcond(bcond;)
	);

	alu_control_unit alu_control_unit_module(
		.funct(    ),
		.opcode(opcode),
		.ALUOp(    ),
		.clk(clk),
		.funcCode(    ),
		.branchType(    )
	);

	memory memory_module(
		.clk(clk),
		.reset_n(reset_n),
		.read_m(read_m),
		.write_m(write_m),
		.address(    ),
		.data(    )
	);
endmodule
