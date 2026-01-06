/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module If_stage (
                input logic Clk,
  				input logic Rst_n,
  				input logic Start, // Synchronous start Button-- Enable

          ///Instruction SRAM wr Interface/// For loading SRAM 
               output logic Imem_En ,
			   output logic [INST_ADDR_WIDTH -1:0] Imem_Addr,
			   input logic [INST_DATA_WIDTH-1:0] Imem_Data,
         /// EX Stage Interface
				input logic Ex_IsBranchTaken,
	            input logic [31:0] Ex_BranchPC,
	
		 ///OF Stage Interface
				//IF Stage Output
			    output logic If_Valid,
				input If_Of_t If_Payld,

) ;
  
//--------------------------------------------------------------//
//-------------Instruction fetch Unit--------------------------//
//-------------------------------------------------------------//
  logic [31:0] instr;
  /// Logic to control the Rpogram Counter register that hold the Next instruction register///
  logic [31:0] pc , pc_nxt;  /// Programme counter value
  always_comb 
	begin 
	   pc_nxt = Ex_isBranchTaken ? Ex_BranchPC : pc + 32'd4 ; // /// Incrementing by 4 bytes for the next instruction
	    //---------Instruction SRAM Controls-------------//
       Imem_En= start ; // always available /// if their is address change
       Imem_Addr =  pc[INST_ADDR_WIDTH+1 : 2];  // 	•	PC[1:0] → byte offset (always 00) •	PC[2] → selects instruction 1
       instr = Imem_Data ; 
	end
//// Either PC points to same addrwss to move to Next , Depending on Enable.
  always@(negedge clk, negedge rst)
    if(!rst) pc <= '0;
  else if(start)  pc <= pc_nxt ;
    else pc <= pc ;

// Pipeline Interface 
logic [31:0] pc_q;     // delayed PC to match imem_data
If_Of_t if_payld_nxt;
	
// Delay PC to align with synchronous IMEM output
always_ff @(posedge clk or negedge rst_n) begin
	if (!Rst_n) pc_q <= '0;
	else if (Start)  pc_q <= pc;      // pc presented to IMEM this cycle
end

// Build IF/ID input packet (aligned)
assign if_payld_nxt.pc    = pc_q;
assign if_payld_nxt.instr = Imem_Data;
	
pipe_reg #(.T(If_Id_t)) u_if_id (
  .clk     (clk),
  .rst_n   (rst_n),
  .en      (start),
  .stall   ('0),   // 0 for now
  .flush   ('0),   // 0 for now
  .d       (if_payld_nxt),
  .q       (If_Payld),
  .valid_q (If_Valid)
);
//==================================================//

endmodule 
