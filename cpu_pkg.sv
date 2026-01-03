`ifndef CPU_PKG_SV
`define CPU_PKG_SV
// --------------------
// Global parameters
// --------------------
parameter  INST_ADDR_WIDTH = 12;
parameter  INST_DATA_WIDTH = 32;

parameter MEM_ADDR_WIDTH = 12;
parameter MEM_DATA_WIDTH = 32;

// If you want DMEM params too:
//parameter int unsigned DMEM_ADDR_WIDTH = 12;   // 4K words
//parameter int unsigned DMEM_DATA_WIDTH = 32;

// --------------------
// Common types
// --------------------
typedef struct packed {
  logic isAdd;
  logic isSub;
  logic isCmp;
  logic isMul;
  logic isDiv;
  logic isMod;
  logic isLsl;
  logic isLsr;
  logic isAsr;
  logic isOr;
  logic isAnd;
  logic isNot;
  logic isMov;
} aluctrl_t;

typedef struct packed {
                ///control signals from control unit ///
                  logic isSt, /// Store instruction 
                  logic isLd , // Load instruction 
                  logic isBeq, // Branch Equivalent
                  logic isBgt, /// branch Greater than
                  logic isRet, // Retention signa;l
                  logic isImmediate, // Immediate bit
                  logic isWb, /// Memory Write  //Possible in add, sub, mul,div,mod,and, or, not,mov, ld, lsl, lsr, asr, call
                  logic isUBranch, // Unconditiona Branch Instrcution : b, call, ret
                  logic isCall , // Call Instruction 
                // aluctrls///
                  aluctrl_t   alu_ctrl;
} ctrl_unit_t ;


typedef struct packed {
  logic GT;
  logic ET;
} flag_t;

typedef enum logic [1:0] {
  ALU_AND = 2'b00,
  ALU_OR  = 2'b01,
  ALU_NOT = 2'b10
} logic_op_t;  // For logical Calculation in ALU

// --------------------
// IF-OF Pipeline Payload
// --------------------
typedef struct packed {
  logic [31:0] pc;
  logic [31:0] instr;
} If_If_t ;

// --------------------
// Of-Ex Pipeline Payload
// --------------------
typedef struct packed {
  logic [31:0] pc;
  logic [31:0] BranchTarget ;
  logic [31:0] A;
  logic [31:0] B;
  logic [31:0] op2;
  logic [31:0] instr; 
  ctrl_unit_t ctrl; 
} Of_Ex_t
  








`endif
