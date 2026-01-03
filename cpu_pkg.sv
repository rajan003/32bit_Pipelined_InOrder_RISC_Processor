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
} IF_ID_t ;

`endif
