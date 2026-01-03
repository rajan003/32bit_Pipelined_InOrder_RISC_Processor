/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module DataPath (
                input logic clk,
  				input logic rst,
  
  				input logic start,

                ///control signals from control unit ///
                input logic Cu_isSt, /// Store instruction 
                input logic Cu_isLd , // Load instruction 
                input logic Cu_isBeq, // Branch Equivalent
                input logic Cu_isBgt, /// branch Greater than
                input logic Cu_isRet, // Retention signa;l
                input logic Cu_isImmediate, // Immediate bit
                input logic Cu_isWb, /// Memory Write  //Possible in add, sub, mul,div,mod,and, or, not,mov, ld, lsl, lsr, asr, call
                input logic Cu_isUBranch, // Unconditiona Branch Instrcution : b, call, ret
                input logic Cu_isCall , // Call Instruction 
                input logic Cu_isAdd, /// add, ld, st
                input logic Cu_isSub, // sub
                input logic Cu_isCmp, // cmp
                input logic Cu_isMul, // mul
                input logic Cu_isDiv, // div
                input logic Cu_isMod, // mod
                input logic Cu_isLsl, // lsl
                input logic Cu_isLsr, // Lsr
                input logic Cu_isAsr, // ASR
                input logic Cu_isOr, // OR
                input logic Cu_isAnd, // AND
                input logic Cu_isNot, // Not
                input logic Cu_isMov, // Move

            /// Immediate bit output to Control Unit
                output logic Cu_imm, /// immediate indication bit

            /// Opcode to control unit
 				 output logic [4:0] Cu_opcode ,
          ///Instruction SRAM wr Interface/// For loading SRAM 
               output logic imem_en ,
 			   output logic [INST_ADDR_WIDTH -1:0] imem_addr,
 			   input logic [INST_DATA_WIDTH-1:0] imem_data,
  
  			/// Register write for testbench Monitoring
			   output  logic [3:0]  rf_wr_addr,
 			   output  logic [31:0] rf_wr_data,
			   output  logic        rf_wr_en,
  
  			/// Data memory read write interface///
               output logic [MEM_ADDR_WIDTH-1:0] dmem_waddr,   // 4K words -> 12-bit word address
               output logic [MEM_DATA_WIDTH-1:0] dmem_wdata,
			    output logic        dmem_wen,

				  // Read port
               output logic [MEM_ADDR_WIDTH-1:0] dmem_raddr,
 			   input logic  [MEM_DATA_WIDTH-1:0] dmem_rdata,	
			    output logic         dmem_ren

) ;
  
  //--------------------------------------------------------------//
  //-------------Instruction fetch Unit--------------------------//
  //-------------------------------------------------------------//
  logic [31:0] instr;
  logic isBranchTaken;
  /// Logic to control the Rpogram Counter register that hold the Next instruction register///
  logic [31:0] pc , pc_nxt;  /// Programme counter value
  
   assign  pc_nxt = isBranchTaken ? BranchPC : pc + 32'd4 ; // /// Incrementing by 4 bytes for the next instruction
  
  //// Either PC points to same addrwss to move to Next , Depending on Enable.
  always@(negedge clk, negedge rst)
    if(!rst) pc <= '0;
  else if(start)  pc <= pc_nxt ;
    else pc <= pc ;

    //---------Instruction SRAM Controls-------------//
    assign imem_en= start ; // always available /// if their is address change
    assign imem_addr =  pc[INST_ADDR_WIDTH+1 : 2];  // 	•	PC[1:0] → byte offset (always 00) •	PC[2] → selects instruction 1
    assign instr = imem_data ; 
  //-------------------------------------------------//
  ///////////-----------IF-OF Pipeline---------------//
 ////---------------------START----------------------//
// register the PC/address used for fetch (1-cycle delay)
logic [31:0] pc_fetch_q;

always_ff @(posedge clk or negedge rst) begin
  if (!rst) begin
    pc_fetch_q <= '0;
    IF_ID.pc   <= '0;
    IF_ID.instr<= 32'h00000000;   // or NOP encoding
  end else begin
    pc_fetch_q <= pc;             // PC that launched the IMEM read in this cycle

    // Next cycle imem_data corresponds to last cycle's pc_fetch_q
    IF_ID.pc    <= pc_fetch_q;
    IF_ID.instr <= imem_data;     // DON'T add another instr_q flop
  end
end
  //------------------------END---------------------//
  ///////////-----------IF-OF Pipeline---------------//
 ////------------------------------------------------//

	
  assign Cu_opcode = instr[31:27] ;
  
///Calculaing the Immediate extensioj bits
logic [31:0] immx;
always @* begin
	case (instr[17:16])
		2'b00: immx = {{16{instr[15]}}, instr[15:0]};   // proper sign-extend
		2'b01: immx = {16'h0000, instr[15:0]};
		2'b10: immx = {16'hFFFF, instr[15:0]};
		default: immx = {16'h0000, instr[15:0]};
  endcase
end
/// Immediate bit to control unit
  assign Cu_imm = instr[26] ;
//  always @(posedge clk) begin
//  if (rst) begin
//    $display("[%0t] PC=%08h IMEM_ADDR=%0d INSTR=%08h OPCODE=%05b",
//             $time, pc, imem_addr, instr, instr[31:27]);
//  end
//end

//---------------------------------------------------------//
//--------------- Decode: Register read and write----------//
//---------------------------------------------------------//
// Read Interface Control 
  logic [3:0] ra_addr ; /// Return Address Register
  logic [31:0] alu_result;
  logic [3:0] rd_addr1_int, rd_addr2_int ;
logic [31:0] op1, op2, op2_int ; /// Two Outputs from Register file.
  
assign ra_addr = 4'b1111 ; // the 16th regitser in GPR is reserved for storing PC value
  assign rd_addr1_int = Cu_isRet ? ra_addr : instr[21:18] ; ///  register Read Address Port-1// RA or RS1 always
  assign rd_addr2_int = Cu_isSt ? instr[25:22] : instr[17:14] ; /// Store instructure= RD , rest are Rs2 

/// Write interface controls and data//
  logic [3:0] wr_addr_int;
  logic [31:0] wr_data_int;
always@* begin 
	wr_addr_int = Cu_isCall ? ra_addr : instr[25:22] ; ///  Ra register addresss or Rd Register from Instruction 
  case({Cu_isCall, Cu_isLd}) 
    2'b00: wr_data_int = alu_result;  /// ALU result is saved here 
    2'b01: wr_data_int = IdResult ; /// Memory read reesult //Load instruction 
    2'b10: wr_data_int = pc + 4 ; ///Next address for PC i.e PC+ 4 Bytes 
      default: wr_data_int = alu_result;
  endcase
end 

  reg2r1w #(.WIDTH(32), .DEPTH(16) ) rf_inst (     /// 16 * 32  REGister Space
  .clk(clk), 
    .rst(rst),
  ///Write Ports///
  .wr_en(Cu_isWb),
  .wr_addr(wr_addr_int),
  .wr_data(wr_data_int),

  //// Read Ports-0//////
  .rd_addr1(rd_addr1_int),
  .rd_data1(op1),
  ///Read Port-1///
  .rd_addr2(rd_addr2_int),
  .rd_data2(op2_int)
);
  
 /// Register write Observation port to testebench//
  always_comb begin 
	 rf_wr_addr = wr_addr_int;
	 rf_wr_data = wr_data_int;
	 rf_wr_en =  Cu_isWb; /// blocking with start 
  end 
  
//------ Operand Generation for ALU----//
  // Format     Defition
  // branch     register op (28-32) offset (1-27) op )  
  // register   op (28-32) I (27) rd (23-26) rs1 (19-22) rs2 (15-18
  // immediate  op (28-32) I (27) rd (23-26) rs1 (19-22) imm (1-18)
  // op-> opcode, offset-> branch offset,  I-> immediate bit, rd -> destinaton register, rs1 -> source register 1, rs2 -> source register 2, imm -> immediate operand

 /// Operand one comes from 



//-------------------------------------------//
//-----Memory load and Store control---------//
//-------------------------------------------//
// In RISC-V , the only memory access possible is Load and Store.
  logic [31:0] mdr, mar, IdResult;
  always @* begin 
      mar = alu_result[7:0]; /// Address comnes from alu (op1+imm) for both load and store // 8 bits are selected 
      mdr = op2_int ; /// This is the destination register content which you want to store 

      dmem_waddr = mar[MEM_ADDR_WIDTH-1:0];   // 4K words -> 12-bit word address
      dmem_wdata = mdr;
	  dmem_wen = Cu_isSt;

				  // Read port
      dmem_raddr= mar[MEM_ADDR_WIDTH-1:0];
	  IdResult=dmem_rdata;	
	  dmem_ren=Cu_isLd;
  end 
  ///Creating a 1kB size SRAM 
 // sram_2p #(.ADDR_W(8) , .DATA_W(32) , .DEPTH(256))  DataMem_sram(
    // Write port  // Storing data to Memory
//    .wclk(clk),
//    .wen(Cu_isSt), /// Store Enable
//    waddr(mar),
//    wdata(mdr),
    // Read port /// Loading Data to GPR
//    rclk(clk),
//    ren(Cu_isLd), /// Load Enable 
//    raddr(mar),
//    rdata(IdResult) /// 32 bit data from 
//    );

  
  
///---------------------------------------//
//-----------Execute Unit-----------------//
//----------------------------------------//
//Execution of instruction are 2 types

//-----------------------------------------------------------------------------//
//--------------Type-1 : Execution of Branched Instruction--------------------//
//----------------------------------------------------------------------------//

logic [31:0] BranchPC;
logic [31:0] BranchTarget ,BranchTarget_int ;
flag_t flags, flags_last;
  //Holding last Instruction Flags
  always@(posedge clk, negedge rst)
    if(!rst)
      flags_last <= '0;
    else flags_last <= flags;
  
//Now on What condition you want PC to move to Branched instruction 
/// type-1 branch inst: Unconditional Brnahc ( b , call, ret )
/// type-2, Conditional branch : beq, bne >> they depend on Last instrcution (CMP) result i.e flag 
    always@* begin 
      isBranchTaken = Cu_isUBranch | (Cu_isBgt & flags_last.GT) | (Cu_isBeq & flags_last.ET) ;  /// (Type-1 OR Type-2) 
  
        //// Calculating the Branch Instruction Offset(nneded in both Conditional and Uncondiional branch instr except ret )
		BranchTarget_int = instr[26:0] >> 2 ; // Shifted Offset , This is done to make it Word Addressing 
        BranchTarget = pc + ({{5{BranchTarget_int[26]}} , BranchTarget_int[26:0]}); /// Branch Target = PC + Sign-Extension of Shifted Offset
  
       BranchPC = Cu_isRet ? op1 : BranchTarget ; //  Is the Instrcution is retention type You will read the RA register for Last saved Instruction Address to pick up 
    end 
  
//  always @(posedge clk) begin
//  $display("BRCHK: U=%b BGT=%b BEQ=%b | GT=%b ET=%b -> isBranchTaken=%b",
//           Cu_isUBranch,
//           Cu_isBgt,
//           Cu_isBeq,
//           flags.GT,
//           flags.ET,
//           isBranchTaken);
//end
//-----------------------------------------------------------------------------//
//--------------Type-2 : Execution of non-Branched Instruction--------------------//
//----------------------------------------------------------------------------//
aluctrl_t aluSignal ; /// ALU control signals
assign op2 = Cu_isImmediate ? immx : op2_int; /// Is Instruction is immediate than Immediate Value otherwise it's an register Instrcution(rs2)
always_comb begin
  aluSignal = '0;
  aluSignal.isAdd = Cu_isAdd;
  aluSignal.isSub = Cu_isSub;
  aluSignal.isCmp = Cu_isCmp;
  aluSignal.isMul = Cu_isMul;
  aluSignal.isDiv = Cu_isDiv;
  aluSignal.isMod = Cu_isMod;
  aluSignal.isLsl = Cu_isLsl;
  aluSignal.isLsr = Cu_isLsr;
  aluSignal.isAsr = Cu_isAsr;
  aluSignal.isOr  = Cu_isOr;
  aluSignal.isAnd = Cu_isAnd;
  aluSignal.isNot = Cu_isNot;
  aluSignal.isMov = Cu_isMov;
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



endmodule 
