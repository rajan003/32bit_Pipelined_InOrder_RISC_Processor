/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module Ex_Stage (
                input logic Clk,
  				input logic Rst,
  
  				input logic Start,
  		  //Of Stage Output
			  	output Of_Ex_t Of_Payld,
  				output logic Of_Valid,

       //Ex Stage Output
			  	output Ex_Ma_t Ex_Payld,
  				output logic Ex_Valid,  

	   ///Branch Control To IF Stage
	            output logic IsBranchTaken,
	            output logic [31:0] BranchPC
) ;

	
//-----------------------------------------------------------------------------//
//--------------Type-1 : Execution of Branched Instruction--------------------//
//----------------------------------------------------------------------------//
flag_t flags, flags_q;
//Now on What condition you want PC to move to Branched instruction 
/// type-1 branch inst: Unconditional Brnahc ( b , call, ret )
/// type-2, Conditional branch : beq, bne >> they depend on Last instrcution (CMP) result i.e flag 
 always@* begin 
	 isBranchTaken = Of_Payld.ctrl.isUBranch | (Of_Payld.ctrl.isBgt & flags_q.GT) | (Of_Payld.ctrl.isBeq & flags_q.ET) ;  /// (Type-1 OR Type-2) 
 
     BranchPC = Of_Payld.BranchPC ; //  BranchPC is already calculated in OF stage 
 end 
  

//-----------------------------------------------------------------------------//
//--------------Type-2 : Execution of non-Branched Instruction--------------------//
//----------------------------------------------------------------------------//
aluctrl_t aluSignal ; /// ALU control signals
logic [31:0] op1,op2;
logic [31:0] alu_result;
always_comb begin 
	op1 = Of_Payld.op1;
	op2=  Of_Payld.op2;
	aluSignal = Of_Payld.ctrl.alu_ctrl
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
	else if(Of_Valid && start) flag_q <= flag;

//EX Payld 
Ex_Ma_t ex_ma_d;

// Valid bit
logic ex_ma_valid;
// Control
//logic stall_exma;
//logic flush_exma;
	
always_comb begin
  ex_ma_d = '0;

  ex_ma_d.pc         = Of_Payld.pc;        // PC of instruction
  ex_ma_d.aluresult  = alu_result;        // ALU output
  ex_ma_d.op2        = Of_Payld.op2;        // store data (rs2)
  ex_ma_d.instr      = Of_Payld.instr;      // instruction bits
  ex_ma_d.ctrl       = Of_Payld.ctrl;       // control bundle
end
	
pipe #(.WIDTH(32*5)) u_pipe_ma (
  .clk      (Clk),
  .rst_n    (Rst),

  .en       (start),        // global pipeline enable
  .stall    (1'b0),   // usually 0 initially
  .flush    (1'b0),   // asserted on branch taken

  .ex_ma_d  (ex_ma_d),      // from EX stage (combinational)
  .ex_ma_q  (Ex_Payld),      // into MA stage (registered)
  .valid_q  (Ex_valid)   // tells MA if this is a real instruction
);

endmodule 
