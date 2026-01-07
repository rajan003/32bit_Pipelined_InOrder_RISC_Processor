/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module Ex_Stage (
                input logic Clk,
  				input logic Rst,
  
  		//input logic Start,
  		//Of Stage Output
			  	input Of_Ex_t Of_Payld_i,
  				input logic Of_Valid_i,
				output logic Of_Ready_o,

       //Ex Stage Output
			  	output Ex_Ma_t Ex_Payld_o,
  				output logic Ex_Valid_o, 
				input logic Ex_Ready_i,

	   ///Branch Control To IF Stage
	            output logic IsBranchTaken_o,
	output logic [31:0] BranchPC_o
) ;

	
//-----------------------------------------------------------------------------//
//--------------Type-1 : Execution of Branched Instruction--------------------//
//----------------------------------------------------------------------------//
flag_t flags, flags_q;
//Now on What condition you want PC to move to Branched instruction 
/// type-1 branch inst: Unconditional Brnahc ( b , call, ret )
/// type-2, Conditional branch : beq, bne >> they depend on Last instrcution (CMP) result i.e flag 
 always@* begin 
	 isBranchTaken_o = '0;
	 BranchPC_o = '0;
	 if(Of_Valid_i==1'b1) begin 
		 isBranchTaken_o = Of_Payld_i.ctrl.isUBranch | (Of_Payld_i.ctrl.isBgt & flags_q.GT) | (Of_Payld_i.ctrl.isBeq & flags_q.ET) ;  /// (Type-1 OR Type-2) 
         BranchPC_o = Of_Payld_i.BranchPC ; //  BranchPC is already calculated in OF stage 
 end 
  

//-----------------------------------------------------------------------------//
//--------------Type-2 : Execution of non-Branched Instruction--------------------//
//----------------------------------------------------------------------------//
aluctrl_t aluSignal ; /// ALU control signals
logic [31:0] op1,op2;
logic [31:0] alu_result;
always_comb begin 
	op1 = Of_Payld_i.A;
	op2=  Of_Payld_i.B;
	aluSignal = Of_Payld_i.ctrl.alu_ctrl
end 
  
ALU  alu_unit (
   .aluSignal(aluSignal) , //isAdd, isSub, isCmp, isMul, isDiv, isMod, isLsl, isLsr, isAsr, isOr, isAnd, isNot, isMov, //// ALu Signal
  //where 
  //typedef struct {
  //                logic isAdd;
  //                logic isSub;
  //                logic isCmp;
  //                logic isMul;
  //                logic isDiv;
  //                logic isMod;
  //                logic isLsl;
  //                logic isLsr;
  //                logic isAsr;
  //                logic isOr;
  //                logic isAnd;
  //                logic isNot;
  //                logic isMov } aluctrl ;
   .A(op1),
   .B(op2),

  .aluResult(alu_result),
  .flag(flags)
  //typedef struct {
                    // logic GT ;
                    // logic ET ;
  // } flg;
);
 always@(posedeg Clk, negesge Rst)
	if(!Rst) flag_q <= '0;
	 else if(Of_Valid_i) flag_q <= flag;

//EX Payld 
Ex_Ma_t ex_ma_d;
	
always_comb begin
  ex_ma_d = '0;

  ex_ma_d.pc         = Of_Payld_i.pc;        // PC of instruction
  ex_ma_d.aluresult  = alu_result;        // ALU output
  ex_ma_d.op2        = Of_Payld_i.op2;        // store data (rs2)
  ex_ma_d.instr      = Of_Payld_i.instr;      // instruction bits
  ex_ma_d.ctrl       = Of_Payld_i.ctrl;       // control bundle
end
	
///==========TO-DO//Feature// IF Flush==============//  
  logic flush_ex;
  assign flush_ex='0; /// Currently feature is not dialed in
  
//===========TO-DO//Feature// Stall==================//
//  Pipeline will accept only if not Stalled
  logic Ex_Ready_q;
  logic stall_ex ;
         
  assign stall_of = 1'b0;
  assign Ex_Ready_q = Ex_Ready_i && !stall_ex ;
  
  
 pipe #(.T(Of_Ex_t)) u_pipe_of (
  .clk(Clk), 
  .rst_n(Rst),
  //source
   .valid_d(Of_Valid_i), /// Pipe is pushed with Start 
   .data_d(ex_ma_d), 
   .ready_d(Of_Ready_o),
  //Dest   
	 .valid_q(Ex_Valid_o), /// Goes to Ex stage  
	 .data_q(Ex_Payld_o),  // Goes to EX stage
	 .ready_q(Ex_Ready_q),
    
   .flush(flush_of)
);
  
endmodule 
