/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module Ex_Stage (
                input logic clk,
  				input logic rst,
  
  				input logic start,
  		  //Of Stage Output
			  	output Of_Ex_t Of_Ex_q,
  				output logic Of_Ex_Valid

       //Ex Stage Output
			  	output Ex_Ma_t ex_ma_q,
  				output logic ex_ma_valid,  

	   ///Branch Control To IF Stage
	            output logic isBranchTaken,
	            output logic [31:0] BranchPC
) ;


	
///---------------------------------------//
//-----------Execute Unit-----------------//
//----------------------------------------//
//Execution of instruction are 2 types

//-----------------------------------------------------------------------------//
//--------------Type-1 : Execution of Branched Instruction--------------------//
//----------------------------------------------------------------------------//

logic [31:0] BranchPC;
flag_t flags, flags;
//Now on What condition you want PC to move to Branched instruction 
/// type-1 branch inst: Unconditional Brnahc ( b , call, ret )
/// type-2, Conditional branch : beq, bne >> they depend on Last instrcution (CMP) result i.e flag 
    always@* begin 
      isBranchTaken = Of_Ex_q.ctrl.isUBranch | (Of_Ex_q.ctrl.isBgt & flags.GT) | (Of_Ex_q.ctrl.isBeq & flags.ET) ;  /// (Type-1 OR Type-2) 
 
       BranchPC = Of_Ex_q.BranchPC ; //  BranchPC is already calculated in OF stage 
    end 
  

//-----------------------------------------------------------------------------//
//--------------Type-2 : Execution of non-Branched Instruction--------------------//
//----------------------------------------------------------------------------//
aluctrl_t aluSignal ; /// ALU control signals
logic [31:0] op1,op2;
always_comb begin 
	op1 = Of_Ex_q.op1;
	op2= Of_Ex_q.op2;
	aluSignal = Of_Ex_q.ctrl.alu_ctrl
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

// EX stage outputs (combinational)
Ex_Ma_t ex_ma_d;
// MA stage inputs (registered)
Ex_Ma_t ex_ma_q;
// Valid bit
logic ex_ma_valid;
// Control
//logic stall_exma;
//logic flush_exma;
	
always_comb begin
  ex_ma_d = '0;

  ex_ma_d.pc         = of_ex_q.pc;        // PC of instruction
  ex_ma_d.aluresult  = alu_result;        // ALU output
  ex_ma_d.op2        = of_ex_q.op2;        // store data (rs2)
  ex_ma_d.instr      = of_ex_q.instr;      // instruction bits
  ex_ma_d.ctrl       = of_ex_q.ctrl;       // control bundle
end
	
pipe u_pipe_ma (
  .clk      (clk),
  .rst_n    (rst_n),

  .en       (start),        // global pipeline enable
  .stall    (1'b0),   // usually 0 initially
  .flush    (1'b0),   // asserted on branch taken

  .ex_ma_d  (ex_ma_d),      // from EX stage (combinational)
  .ex_ma_q  (ex_ma_q),      // into MA stage (registered)

  .valid_q  (ex_ma_valid)   // tells MA if this is a real instruction
);

endmodule 
