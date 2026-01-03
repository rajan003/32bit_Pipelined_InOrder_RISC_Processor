/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module If_stage (
                input logic clk,
  				input logic rst,

          ///Instruction SRAM wr Interface/// For loading SRAM 
               output logic imem_en ,
 			   output logic [INST_ADDR_WIDTH -1:0] imem_addr,
 			   input logic [INST_DATA_WIDTH-1:0] imem_data,
         /// EX Stage Interface
				input logic Ex_isBranchTaken,
	            input logic [31:0] Ex_BranchPC,
	
		 ///OF Stage Interface
				//IF Stage Output
			    output logic If_id_valid,
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
       imem_en= start ; // always available /// if their is address change
       imem_addr =  pc[INST_ADDR_WIDTH+1 : 2];  // 	•	PC[1:0] → byte offset (always 00) •	PC[2] → selects instruction 1
       instr = imem_data ; 
	end
  //// Either PC points to same addrwss to move to Next , Depending on Enable.
  always@(negedge clk, negedge rst)
    if(!rst) pc <= '0;
  else if(start)  pc <= pc_nxt ;
    else pc <= pc ;

// Pipeline Interface 
logic [31:0] pc_q;     // delayed PC to match imem_data
If_Id_t if_id_payld_nxt, if_id_payld;
logic  If_id_valid;

// Delay PC to align with synchronous IMEM output
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) pc_q <= '0;
  else if (start)  pc_q <= pc;      // pc presented to IMEM this cycle
end

// Build IF/ID input packet (aligned)
assign if_id_d.pc    = pc_q;
assign if_id_payld_nxt.instr = imem_data;
	
pipe_reg #(.T(If_Id_t)) u_if_id (
  .clk     (clk),
  .rst_n   (rst_n),
  .en      (start),
  .stall   ('0),   // 0 for now
  .flush   ('0),   // 0 for now
  .d       (if_id_payld_nxt),
  .q       (if_id_payld),
  .valid_q (if_id_valid)
);
//==================================================//

endmodule 
