`timescale 1ns/1ps
`include "cpu_pkg.sv"

// Blocks
`include "Move.sv"
`include "Logical.sv"
`include "Adder.sv"
`include "DivMod.sv"
`include "Multiplier.sv"
`include "Shift.sv"
`include "Ctrl_Unit.sv"
`include "REG2R1W.sv"
`include "pipe.sv"
`include "ALU.sv"

// Stages
`include "If_Stage.sv"
`include "Of_Stage.sv"
`include "Ex_Stage.sv"
`include "Ma_Stage.sv"
`include "Wb_Stage.sv"



//============================================================
// 5-Stage Pipelined CPU Top (IF -> OF -> EX -> MA -> WB)
// - Ready/Valid chain wired end-to-end
// - Control_Unit sits “beside” OF (opcode/imm out of OF -> CU -> ctrl back into OF)
// - Regfile sits “beside” OF/WB (OF reads, WB writes)
//============================================================
module CPU_Top (
  input  logic Clk,
  input  logic Rst_n,
  input  logic Start,

  // -------------------------
  // IMEM (read-only)
  // -------------------------
  output logic                      Imem_En,
  output logic [INST_ADDR_WIDTH-1:0] Imem_Addr,
  input  logic [INST_DATA_WIDTH-1:0] Imem_Data,

  // -------------------------
  // DMEM (2-port style)
  // -------------------------
  output logic [MEM_ADDR_WIDTH-1:0]  Dmem_Waddr,
  output logic [MEM_DATA_WIDTH-1:0]  Dmem_Wdata,
  output logic                       Dmem_Wen,

  output logic [MEM_ADDR_WIDTH-1:0]  Dmem_Raddr,
  input  logic [MEM_DATA_WIDTH-1:0]  Dmem_Rdata,
  output logic                       Dmem_Ren,

  // -------------------------
  // Optional monitor taps
  // -------------------------
  output logic                       rf_wr_en,
  output logic [3:0]                 rf_wr_addr,
  output logic [31:0]                rf_wr_data
);

  //============================================================
  // IF <-> OF
  //============================================================
  If_Of_t if_payld;
  logic   if_valid;
  logic   if_ready;     // comes from OF (backpressure)

  //============================================================
  // OF <-> EX
  //============================================================
  Of_Ex_t of_payld;
  logic   of_valid;
  logic   of_ready;     // comes from EX

  //============================================================
  // EX <-> MA
  //============================================================
  Ex_Ma_t ex_payld;
  logic   ex_valid;
  logic   ex_ready;     // comes from MA

  //============================================================
  // MA <-> WB
  //============================================================
  Ma_Wb_t ma_payld;
  logic   ma_valid;
  logic   ma_ready;     // comes from WB

  //============================================================
  // Branch feedback EX -> IF
  //============================================================
  logic        ex_isBranchTaken;
  logic [31:0] ex_branchPC;

  //============================================================
  // Control Unit wiring (OF -> CU -> OF)
  //============================================================
  logic        cu_imm;
  logic [4:0]  cu_opcode;
  ctrl_unit_t  cu_out;

  //============================================================
  // Regfile wiring (OF reads, WB writes)
  //============================================================
  logic [3:0]  rd_addr1, rd_addr2;
  logic [31:0] rd_data1, rd_data2;

  //============================================================
  // IF stage
  //============================================================
  // NOTE: Your IF module port names are a bit inconsistent (“If_Ready_i” is an output),
  // so we just wire the real backpressure input: .If_Ready(if_ready).
  logic if_stage_ready_unused;

  If_stage u_if (
    .Clk            (Clk),
    .Rst_n          (Rst_n),
    .Start          (Start),

    .If_Ready_o     (if_stage_ready_unused), // not used upstream
    .Imem_En        (Imem_En),
    .Imem_Addr      (Imem_Addr),
    .Imem_Data      (Imem_Data),

    .Ex_IsBranchTaken_i (ex_isBranchTaken),
    .Ex_BranchPC_i      (ex_branchPC),

    .If_Valid_o       (if_valid),
    .If_Payld_o       (if_payld),
    .If_Ready_i       (if_ready)
  );

  //============================================================
  // Control Unit (pure combinational decode)
  //============================================================
  Control_Unit u_cu (
    .imm     (cu_imm),
    .opcode  (cu_opcode),
    .Cu_out  (cu_out)
  );

  //============================================================
  // OF stage
  //============================================================
  Of_Stage u_of (
    .Clk        (Clk),
    .Rst_n      (Rst_n),

    // from IF
    .If_Payld_i (if_payld),
    .If_Valid_i (if_valid),
    .If_ready_o (if_ready),

    // to Control Unit
    .Cu_Imm     (cu_imm),
    .Cu_Opcode  (cu_opcode),
    .Cu_Out     (cu_out),

    // regfile reads
    .Rd_Addr1   (rd_addr1),
    .Rd_Data1   (rd_data1),
    .Rd_Addr2   (rd_addr2),
    .Rd_Data2   (rd_data2),

    // to EX
    .Of_Payld_o (of_payld),
    .Of_Valid_o (of_valid),
    .Of_Ready_i (of_ready)
  );

  //============================================================
  // EX stage
  //============================================================
  Ex_Stage u_ex (
    .Clk            (Clk),
    .Rst_n          (Rst_n),

    .Of_Payld_i     (of_payld),
    .Of_Valid_i     (of_valid),
    .Of_Ready_o     (of_ready),

    .Ex_Payld_o     (ex_payld),
    .Ex_Valid_o     (ex_valid),
    .Ex_Ready_i     (ex_ready),

    .IsBranchTaken_o(ex_isBranchTaken),
    .BranchPC_o     (ex_branchPC)
  );

  //============================================================
  // MA stage
  //============================================================
  // IMPORTANT: Your Ma_Stage code you pasted expects Ex_Payld_i type = Ma_Wb_t,
  // but EX stage outputs Ex_Ma_t. Fix Ma_Stage port type to Ex_Ma_t.
  // Here we assume Ma_Stage takes Ex_Ma_t (the correct pipeline payload).
  //
  // If your current Ma_Stage still uses Ma_Wb_t on the EX input, it will not compile.
  //
  Ma_Stage u_ma (
    .Clk        (Clk),
    .Rst_n      (Rst_n),

    .Ex_Payld_i (ex_payld),   // <-- should be Ex_Ma_t
    .Ex_Valid_i (ex_valid),
    .Ex_Ready_o (ex_ready),

    .Dmem_Waddr (Dmem_Waddr),
    .Dmem_Wdata (Dmem_Wdata),
    .Dmem_Wen   (Dmem_Wen),

    .Dmem_Raddr (Dmem_Raddr),
    .Dmem_Rdata (Dmem_Rdata),
    .Dmem_Ren   (Dmem_Ren),

    .Ma_Payld_o (ma_payld),
    .Ma_Valid_o (ma_valid),
    .Ma_ready_i (ma_ready)
  );

  //============================================================
  // WB stage (sink: no backpressure)
  //============================================================
  Wb_Stage u_wb (
    .Clk        (Clk),
    .Rst_n      (Rst_n),

    .Ma_Valid_i (ma_valid),
    .Ma_Ready_o (ma_ready),
    .Ma_Payld_i (ma_payld),

    .rf_wr_en   (rf_wr_en),
    .rf_wr_addr (rf_wr_addr),
    .rf_wr_data (rf_wr_data)
  );

  //============================================================
  // Register File (2R1W)
  //============================================================
  // Use your existing regfile module name/ports.
  // This matches the common reg2r1w you were using earlier.
  reg2r1w #(.WIDTH(32), .DEPTH(16)) u_rf (
    .clk      (Clk),
    .rst	  (Rst_n),
    .wr_en    (rf_wr_en),
    .wr_addr  (rf_wr_addr),
    .wr_data  (rf_wr_data),

    .rd_addr1 (rd_addr1),
    .rd_data1 (rd_data1),

    .rd_addr2 (rd_addr2),
    .rd_data2 (rd_data2)
  );

endmodule
