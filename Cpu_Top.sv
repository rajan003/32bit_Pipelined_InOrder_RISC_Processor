`timescale 1ns/1ps
`include "cpu_pkg.sv"

// Stages
`include "If_stage.sv"
`include "Of_stage.sv"
`include "Ex_stage.sv"
`include "Ma_stage.sv"
`include "Wb_stage.sv"

// Blocks
`include "CtrlUnit.sv"
`include "REG2R1W.sv"

module cpu_top (
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  // -------------------------
  // Instruction memory (read-only)
  // -------------------------
  output logic                      imem_en,
  output logic [INST_ADDR_WIDTH-1:0] imem_addr,
  input  logic [INST_DATA_WIDTH-1:0] imem_data,

  // -------------------------
  // Data memory (true 2-port)
  // -------------------------
  output logic [MEM_ADDR_WIDTH-1:0] dmem_waddr,
  output logic [MEM_DATA_WIDTH-1:0] dmem_wdata,
  output logic                      dmem_wen,

  output logic [MEM_ADDR_WIDTH-1:0] dmem_raddr,
  input  logic [MEM_DATA_WIDTH-1:0] dmem_rdata,
  output logic                      dmem_ren
);

  // ============================================================
  // IF -> OF
  // ============================================================
  If_Of_t if_payld;
  logic   if_valid;

  // ============================================================
  // OF -> EX
  // ============================================================
  Of_Ex_t of_payld;
  logic   of_valid;

  // ============================================================
  // EX -> MA
  // ============================================================
  Ex_Ma_t ex_payld;
  logic   ex_valid;

  // ============================================================
  // MA -> WB
  // ============================================================
  Ma_Wb_t ma_payld;
  logic   ma_valid;

  // ============================================================
  // Branch feedback (EX -> IF)
  // ============================================================
  logic        ex_isBranchTaken;
  logic [31:0] ex_branchPC;

  // ============================================================
  // Control Unit wires (OF -> CU -> OF)
  // ============================================================
  logic       cu_imm;
  logic [4:0] cu_opcode;
  ctrl_unit_t cu_out;

  // ============================================================
  // Register file wires (OF reads, WB writes)
  // ============================================================
  logic [3:0] rf_rd_addr1, rf_rd_addr2;
  logic [31:0] rf_rd_data1, rf_rd_data2;

  logic        rf_wr_en;
  logic [3:0]  rf_wr_addr;
  logic [31:0] rf_wr_data;

  // ============================================================
  // IF stage
  // ============================================================
  If_stage u_if (
    .Clk              (clk),
    .Rst_n            (rst_n),
    .Start            (start),

    .Imem_En          (imem_en),
    .Imem_Addr        (imem_addr),
    .Imem_Data        (imem_data),

    .Ex_IsBranchTaken (ex_isBranchTaken),
    .Ex_BranchPC      (ex_branchPC),

    .If_Valid         (if_valid),
    .If_Payld         (if_payld)     // <-- MUST be output in IF module
  );

  // ============================================================
  // OF stage
  // ============================================================
  Of_Stage u_of (
    .Clk      (clk),
    .Rst      (rst_n),   // assuming active-low reset input naming is messy in your code
    .Start    (start),

    .If_Payld (if_payld),
    .If_Valid (if_valid),

    .Cu_Imm   (cu_imm),
    .Cu_Opcode(cu_opcode),
    .Cu_Out   (cu_out),

    .Rd_Addr1 (rf_rd_addr1),
    .Rd_Data1 (rf_rd_data1),
    .Rd_Addr2 (rf_rd_addr2),
    .Rd_Data2 (rf_rd_data2),

    .Of_Payld (of_payld),
    .Of_Valid (of_valid)
  );

  // ============================================================
  // Control Unit (combinational)
  // ============================================================
  Control_Unit u_cu (
    .imm        (cu_imm),
    .opcode     (cu_opcode),

    // pack these into ctrl_unit_t inside CU, or assign them into cu_out here
    // If your CU already outputs ctrl_unit_t, connect directly.
    // If not, you'll need a small "assign cu_out.xxx = isAdd/isLd/..." wrapper.
    .cu_out     (cu_out)
  );

  // ============================================================
  // Register file (2R1W)
  // ============================================================
  reg2r1w #(.WIDTH(32), .DEPTH(16)) u_rf (
    .clk      (clk),

    // WB writeback
    .wr_en    (rf_wr_en),
    .wr_addr  (rf_wr_addr),
    .wr_data  (rf_wr_data),

    // OF reads
    .rd_addr1 (rf_rd_addr1),
    .rd_data1 (rf_rd_data1),
    .rd_addr2 (rf_rd_addr2),
    .rd_data2 (rf_rd_data2)
  );

  // ============================================================
  // EX stage
  // ============================================================
  Ex_Stage u_ex (
    .Clk            (clk),
    .Rst            (rst_n),
    .Start          (start),

    .Of_Payld       (of_payld),
    .Of_Valid       (of_valid),

    .Ex_Payld       (ex_payld),
    .Ex_Valid       (ex_valid),

    .IsBranchTaken  (ex_isBranchTaken),
    .BranchPC       (ex_branchPC)
  );

  // ============================================================
  // MA stage (drives DMEM)
  // ============================================================
  Ma_Stage u_ma (
    .Clk       (clk),
    .Rst       (rst_n),
    .Start     (start),

    .Ex_Payld  (ex_payld),
    .Ex_Valid  (ex_valid),

    .Dmem_Waddr(dmem_waddr),
    .Dmem_Wdata(dmem_wdata),
    .Dmem_Wen  (dmem_wen),

    .Dmem_Raddr(dmem_raddr),
    .Dmem_Rdata(dmem_rdata),
    .Dmem_Ren  (dmem_ren),

    .Ma_Payld  (ma_payld),
    .Ma_Valid  (ma_valid)
  );

  // ============================================================
  // WB stage (drives RF write)
  // ============================================================
  Wb_stage u_wb (
    .Start     (start),

    .Ma_Payld  (ma_payld),
    .Ma_Valid  (ma_valid),

    .rf_wr_en  (rf_wr_en),
    .rf_wr_addr(rf_wr_addr),
    .rf_wr_data(rf_wr_data)
  );

endmodule
