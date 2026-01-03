//Package Importt/
`include "cpu_pkg.sv"
module Of_Stage (
                input logic clk,
  				input logic rst,
			//IF Stage Output
				input If_Of_t If_Payld,
				input logic If_valid,
  

            /// Immediate bit output to Control Unit
                output logic Cu_imm, /// immediate indication bi
                output logic [4:0] Cu_opcode  //Opcode
                input ctrl_unit_t Cu_out

			// GPR Reg Interface 
			  //// Read Ports-0//////
				output logic [3:0] rd_addr1,
				input logic [31:0] rd_data1,
			  ///Read Port-1///
				output logic [3:0] rd_addr2,
				input logic [31:0] rd_data2
			// Ex Stage 
				output Of_Ex_t of_ex_q,
  				output logic of_ex_valid
		);

  
//---------------------------------------------------------//
//--------------- Decode: Register read and write----------//
//---------------------------------------------------------//
// Read Interface Control 
 assign Cu_opcode = If_Of[31:27] ;
//=====>>IF Opcode to Control Unit===>Control Signal==//
	
  logic [3:0] ra_addr ; /// Return Address Register
  logic [3:0] rd_addr1_int, rd_addr2_int ;
  logic [31:0] op1, op2, op2_int ; /// Two Outputs from Register file.
//------ Operand Generation for ALU----//
    // Format     Defition
	// branch     register op (27-31) offset (1-27) op )  
	// register   op (27-31) I (26) rd (22-25) rs1 (18-21) rs2 (14-17)
	// immediate  op (27-31) I (26) rd (22-25) rs1 (18-21) imm (0-17)
// op-> opcode, offset-> branch offset,  I-> immediate bit, rd -> destinaton register, rs1 -> source register 1, rs2 -> source register 2, imm -> immediate operand

  always@* begin 
		ra_addr ='0;
	    rd_addr1_int='0;
	    rd_addr2_int='0;
	  if(If_vld) begin 
      ra_addr = 4'b1111 ; // the 16th regitser in GPR is reserved for storing PC value
  	  rd_addr1_int = Cu_out.isRet ? ra_addr : If_Payld.instr[21:18] ; ///  register Read Address Port-1// RA or RS1 always
	  rd_addr2_int = Cu_out.isSt ? If_Payld.instr[25:22] : If_Payld.instr[17:14] ; /// Store instructure= RD , rest are Rs2 
	  end 
  end 

///Calculaing the Immediate extension bits
	logic [31:0] immx;
	always @* begin
		case (If_Payld.instr[17:16])
			2'b00: immx = {{16{If_Payld.instr[15]}}, If_Payld.instr[15:0]};   // proper sign-extend
			2'b01: immx = {16'h0000, If_Payld.instr[15:0]};
			2'b10: immx = {16'hFFFF, If_Payld.instr[15:0]};
			default: immx = {16'h0000, If_Payld.instr[15:0]};
	  endcase
	end
	
	always_comb
		begin 
		 op1 = rd_data1;
		 op2_int = rd_data2;
		 op2 = Cu_out.isImmediate ? immx : op2_int; /// Is Instruction is immediate than Immediate Value otherwise it's an register Instrcution(rs2)
		end 

//=======Branch target========================//
//Now on What condition you want PC to move to Branched instruction 
/// type-1 branch inst: Unconditional Brnahc ( b , call, ret )
/// type-2, Conditional branch : beq, bne >> they depend on Last instrcution (CMP) result i.e flag 
	logic [31:0] BranchPC;
	logic [31:0] BranchTarget ,BranchTarget_int ;
    always@* begin 
        //// Calculating the Branch Instruction Offset(nneded in both Conditional and Uncondiional branch instr except ret )
		BranchTarget_int = If_Payld.instr[26:0] >> 2 ; // Shifted Offset , This is done to make it Word Addressing 
        BranchTarget = If_Payld.pc + ({{5{BranchTarget_int[26]}} , BranchTarget_int[26:0]}); /// Branch Target = PC + Sign-Extension of Shifted Offset
        BranchPC = Cu_out.isRet ? op1 : BranchTarget ; //  Is the Instrcution is retention type You will read the RA register for Last saved Instruction Address to pick up 
    end 
	
//===============OF Pipeline==========================//
Of_Ex_t of_ex_d, of_ex_q; /// OF pipeline Payload 
logic  of_ex_valid;

// OF stage (combinational build of packet)
always_comb begin
  of_ex_d = '0;

  of_ex_d.pc           = If_Payld.pc;       // whatever your OF input PC is
  of_ex_d.instr        = If_Payld.instr;       // instruction in OF
  of_ex_d.BranchPC     = BranchPC;
  of_ex_d.A            = op1;
  of_ex_d.B            = op2;
  of_ex_d.op2          = op2_int;      // imm/reg selected
  of_ex_d.ctrl         = Cu_out;      // ctrl_unit_t
end

// OF/EX pipeline register
pipe_of_ex u_of_ex (
  .clk      (clk),
  .rst_n    (rst_n),
  .en       (start),        // your start/enable
  .stall    ('0),   // hook later (0 for now)
  .flush    ('0),   // hook later (0 for now)
  .of_ex_d  (of_ex_d),
  .of_ex_q  (of_ex_q),
  .valid_q  (of_ex_valid)
);



endmodule 
