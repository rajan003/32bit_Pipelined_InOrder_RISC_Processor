/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module If_stage (
                input logic Clk,
  				input logic Rst_n,
  				input logic Start, // Synchronous Start Button-- Enable
  
  				output logic If_Ready_o, /// The stage is ready to accept new Data.

          ///Instruction SRAM wr Interface/// For loading SRAM 
               output logic Imem_En ,
			   output logic [INST_ADDR_WIDTH -1:0] Imem_Addr,
			   input logic [INST_DATA_WIDTH-1:0] Imem_Data,
         /// EX Stage Interface
				input logic Ex_IsBranchTaken_i,
	input logic [31:0] Ex_BranchPC_i,
	
		 ///OF Stage Interface
				//IF Stage Output
			    output logic If_Valid_o,
				output If_Of_t If_Payld_o,
  				input logic If_Ready_i

) ;
  
//--------------------------------------------------------------//
//-------------Instruction fetch Unit--------------------------//
//-------------------------------------------------------------//
logic [31:0] instr;
  /// Logic to control the Rpogram Counter register that hold the Next instruction register///
logic [31:0] pc , pc_nxt;  /// Programme counter value
always_comb 
	begin 
	   pc_nxt = Ex_IsBranchTaken_i ? Ex_BranchPC_i : pc + 32'd4 ; // /// Incrementing by 4 bytes for the next instruction
	    //---------Instruction SRAM Controls-------------//
		Imem_En= (Start && If_Ready_o)  ; // always available /// if their is address change
       Imem_Addr =  pc[INST_ADDR_WIDTH+1 : 2];  // 	•	PC[1:0] → byte offset (always 00) •	PC[2] → selects instruction 1
       instr = Imem_Data ; 
	end
//// Either PC points to same addrwss to move to Next , Depending on Enable.
	always@(posedge Clk, negedge Rst_n)
		if(!Rst_n) pc <= '0;
	else if(Start && If_Ready_o)  pc <= pc_nxt ;  /// You have input as well the Pipeline is not stalled
    else pc <= pc ;

// Pipeline Interface 
logic [31:0] pc_q;     // delayed PC to match imem_data
If_Of_t if_payld_nxt;
	
// Delay PC to align with synchronous IMEM output
always_ff @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) pc_q <= '0;
	else if (Start && If_Ready_o)  pc_q <= pc;      // pc presented to IMEM this cycle
end

// Build IF/ID input packet (aligned)
 assign if_payld_nxt.pc    = pc_q;
 assign if_payld_nxt.instr = instr;
	
///==========TO-DO//Feature// IF Flush==============//  
  logic flush_if;
  assign flush_if='0; /// Currently feature is not dialed in
  
//===========TO-DO//Feature// Stall==================//
//  Pipeline will accept only if not Stalled
  logic If_Ready_q;
  logic stall_if;
  assign stall_if = '0; /// Will be driven Once Logic designed
  assign If_Ready_q = If_Ready_i && !stall_if ;
  
  
 pipe #(.T(If_Of_t)) u_pipe_if (
  .clk(Clk), 
  .rst_n(Rst_n),
  //source
  .valid_d(Start && If_Ready_o), /// Pipe is pushed with Start 
  .data_d(if_payld_nxt), 
  .ready_d(If_Ready_o),
  //Dest   
  .valid_q(If_Valid_o),   
  .data_q(If_Payld_o), 
  .ready_q(If_Ready_q),
    
  .flush(flush_if)
);
//==================================================//

endmodule 
