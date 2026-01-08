//Package Importt/
`include "cpu_pkg.sv"
module Of_Stage (
                input logic Clk,
  				input logic Rst,
				//input logic Start,
			//IF Stage Output
				input If_Of_t If_Payld_i,
				input logic If_Valid_i,
  				output logic If_ready_o,
  

            /// Immediate bit output to Control Unit
                output logic Cu_Imm, /// immediate indication bi
				output logic [4:0] Cu_Opcode,  //Opcode
                input ctrl_unit_t Cu_Out,

			// GPR Reg Interface 
			  //// Read Ports-0//////
				output logic [3:0] Rd_Addr1,
				input logic [31:0] Rd_Data1,
			  ///Read Port-1///
				output logic [3:0] Rd_Addr2,
  				input logic [31:0] Rd_Data2,
			// Ex Stage 
				output Of_Ex_t Of_Payld_o,
  				output logic Of_Valid_o,
  				input logic Of_Ready_i
		);

  
//---------------------------------------------------------//
//--------------- Decode: Register read and write----------//
//---------------------------------------------------------//
  logic [3:0] Ra_Addr ; /// Return Address Register
  logic [31:0] op1, op2, op2_int ; /// Two Outputs from Register file.
  //------ Operand Generation for ALU----//
    // Format     Defition
	// branch     register op (27-31) offset (1-27) op )  
	// register   op (27-31) I (26) rd (22-25) rs1 (18-21) rs2 (14-17)
	// immediate  op (27-31) I (26) rd (22-25) rs1 (18-21) imm (0-17)
  // op-> opcode, offset-> branch offset,  I-> immediate bit, rd -> destinaton register, rs1 -> source register 1, rs2 -> source register 2, imm -> immediate operand

  always@* begin 
		Ra_Addr ='0;
	    Rd_Addr1='0;
	    Rd_Addr2='0;
	    Cu_Opcode = '0 ;
	    Cu_Imm = '0;
	  if(If_Valid_i && If_ready_o) begin 
	      Ra_Addr = 4'b1111 ; // the 16th regitser in GPR is reserved for storing PC value
		  Cu_Imm = If_Payld_i.instr[26]; /// Immediate Bit from the instruction 
		  Cu_Opcode = If_Payld_i.instr[31:27] ; /// Opcode for the Control Unit// //=====>>IF Opcode to Control Unit===>Control Signal==//
	  	  Rd_Addr1 = Cu_Out.isRet ? Ra_Addr : If_Payld_i.instr[21:18] ; ///  register Read Address Port-1// RA or RS1 always
		  Rd_Addr2 = Cu_Out.isSt ? If_Payld_i.instr[25:22] : If_Payld_i.instr[17:14] ; /// Store instructure= RD , rest are Rs2 
	    end 
   end 

///Calculaing the Immediate extension bits
	logic [31:0] immx;
	always @* begin
		case (If_Payld_i.instr[17:16])
			2'b00: immx = {{16{If_Payld_i.instr[15]}}, If_Payld_i.instr[15:0]};   // proper sign-extend
			2'b01: immx = {16'h0000, If_Payld_i.instr[15:0]};
			2'b10: immx = {16'hFFFF, If_Payld_i.instr[15:0]};
			default: immx = {16'h0000, If_Payld_i.instr[15:0]};
	  endcase
	end
	
	always_comb
		begin 
		 op1 = Rd_Data1;
		 op2_int = Rd_Data2;
		 op2 = Cu_Out.isImmediate ? immx : op2_int; /// Is Instruction is immediate than Immediate Value otherwise it's an register Instrcution(rs2)
		end 

	
//===============OF Pipeline==========================//
Of_Ex_t of_ex_d; /// OF pipeline Payload 

// OF stage (combinational build of packet)
always_comb begin
  of_ex_d = '0;

  of_ex_d.pc           = If_Payld_i.pc;       // whatever your OF input PC is
  of_ex_d.instr        = If_Payld_i.instr;       // instruction in OF
  of_ex_d.A            = op1;
  of_ex_d.B            = op2;
  of_ex_d.op2          = op2_int;      // imm/reg selected
  of_ex_d.ctrl         = Cu_Out;      // ctrl_unit_t
end

	
///==========TO-DO//Feature// IF Flush==============//  
  logic flush_of;
  assign flush_of='0; /// Currently feature is not dialed in
  
//===========TO-DO//Feature// Stall==================//
//  Pipeline will accept only if not Stalled
  logic Of_Ready_q;
  logic stall_of ;
         
  assign stall_of = 1'b0;
  assign Of_Ready_q = Of_Ready_i && !stall_of ;
  
  
 pipe #(.T(Of_Ex_t)) u_pipe_of (
  .clk(Clk), 
  .rst_n(Rst),
  //source
  .valid_d(If_Valid_i), /// Pipe is pushed with Start 
  .data_d(of_ex_d), 
    .ready_d(If_ready_o),
  //Dest   
   .valid_q(Of_Valid_o), /// Goes to Ex stage  
   .data_q(Of_Payld_o),  // Goes to EX stage
	 .ready_q(Of_Ready_q),
    
   .flush(flush_of)
);

endmodule 
