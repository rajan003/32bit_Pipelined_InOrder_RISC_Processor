`timescale 1ns/1ps
`include "cpu_pkg.sv"

module Ma_Stage (
  input  logic Clk,
  input  logic Rst_n,           // active-low reset

  // -----------------------------
  // EX -> MA handshake
  // -----------------------------
  input  Ma_Wb_t Ex_Payld_i,     // (your naming) EX/MEM payload into MA
  input  logic   Ex_Valid_i,
  output logic   Ex_Ready_o,

  // -----------------------------
  // DMEM interface
  // -----------------------------
  output logic [MEM_ADDR_WIDTH-1:0] Dmem_Waddr,
  output logic [MEM_DATA_WIDTH-1:0] Dmem_Wdata,
  output logic                      Dmem_Wen,

  output logic [MEM_ADDR_WIDTH-1:0] Dmem_Raddr,
  input  logic [MEM_DATA_WIDTH-1:0] Dmem_Rdata,
  output logic                      Dmem_Ren,

  // -----------------------------
  // MA -> WB handshake
  // -----------------------------
  output Ma_Wb_t Ma_Payld_o,
  output logic   Ma_Valid_o,
  input  logic   Ma_ready_i
);

  // ------------------------------------------------------------
  // Internal pipeline to WB (1-entry) using your ready/valid pipe
  // ------------------------------------------------------------
  Ma_Wb_t ma_wb_d;
  logic   ma_wb_valid_d;
  logic   ma_pipe_ready;     // ready from pipe back to MA (ready_d)

  // ------------------------------------------------------------
  // Load handling state
  //   ld_wait_q    : we issued a load read last cycle, data comes this cycle
  //   ld_pending_q : we have load data captured and must send it to WB pipe
  // ------------------------------------------------------------
  logic   ld_wait_q;
  logic   ld_pending_q;

  Ma_Wb_t ex_hold_q;         // holds metadata for the load
  logic [MEM_DATA_WIDTH-1:0] ld_data_q; // captured load data

  // ------------------------------------------------------------
  // Convenience decode for current EX packet
  // ------------------------------------------------------------
  logic ex_is_ld, ex_is_st;
  assign ex_is_ld = Ex_Payld_i.ctrl.isLd;
  assign ex_is_st = Ex_Payld_i.ctrl.isSt;

  // ------------------------------------------------------------
  // MA busy if a load is waiting for response OR response pending to send
  // ------------------------------------------------------------
  logic ma_busy;
  assign ma_busy = ld_wait_q | ld_pending_q;

  // ------------------------------------------------------------
  // EX acceptance rule:
  //   - Only accept EX when MA is not busy (no load in flight)
  //   - And the MA->WB pipe can accept a non-load (or accept a load request
  //     only when pipe is ready so response can be pushed next cycle)
  // ------------------------------------------------------------
  logic accept_ex;
  always_comb begin
    accept_ex = 1'b0;

    if (!ma_busy) begin /// Their is no data in Load Pipe 
      if (Ex_Valid_i) begin
        // For both load and non-load, require pipe to be ready
        // (because load response will push into the same pipe next cycle,
        // and MA is blocked during the load so pipe occupancy won't change)
        if (ma_pipe_ready) begin
          accept_ex = 1'b1;
        end
      end
    end
  end

  // EX backpressure
  assign Ex_Ready_o = (!ma_busy) && ma_pipe_ready;

  // ------------------------------------------------------------
  // DMEM command generation (ONLY when accept_ex)
  // ------------------------------------------------------------
  always_comb begin
    // defaults
    Dmem_Waddr = '0;
    Dmem_Wdata = '0;
    Dmem_Wen   = 1'b0;

    Dmem_Raddr = '0;
    Dmem_Ren   = 1'b0;

    if (accept_ex) begin  /// Common for both Mem read and write 
      logic [MEM_ADDR_WIDTH-1:0] addr;
      addr = Ex_Payld_i.aluresult[MEM_ADDR_WIDTH-1:0];

      if (ex_is_st) begin /// Store Instruction
        Dmem_Waddr = addr;
        Dmem_Wdata = Ex_Payld_i.op2;
        Dmem_Wen   = 1'b1;
      end

      if (ex_is_ld) begin  //// Load instruction 
        Dmem_Raddr = addr;
        Dmem_Ren   = 1'b1;     // issue read ONLY on accept
      end
    end
  end

  // ------------------------------------------------------------
  // Load state machine + capture
  // ------------------------------------------------------------
  always_ff @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
      ld_wait_q    <= 1'b0;
      ld_pending_q <= 1'b0;
      ex_hold_q    <= '0;
      ld_data_q    <= '0;
    end else begin
      // default: clear ld_wait_q after one cycle
      // ld_wait_q means "expecting data this cycle"
      if (ld_wait_q) begin
        // data is valid this cycle (sync-read latency = 1 cycle)
        ld_data_q    <= Dmem_Rdata;
        ld_pending_q <= 1'b1;     // now we must send to WB
        ld_wait_q    <= 1'b0;
      end

      // Accepting a new EX packet
      if (accept_ex && ex_is_ld) begin
        // hold metadata for the load, data comes next cycle
        ex_hold_q <= Ex_Payld_i;
        ld_wait_q <= 1'b1;
      end

      // If we successfully push the completed load into the WB pipe, clear pending
      if (ld_pending_q && ma_pipe_ready && ma_wb_valid_d) begin
        ld_pending_q <= 1'b0;
      end
    end
  end

  // ------------------------------------------------------------
  // Build payload to WB pipe (priority: load-complete > non-load)
  // ------------------------------------------------------------
  always_comb begin
    ma_wb_d       = '0;
    ma_wb_valid_d = 1'b0;

    // Priority 1: completed load waiting to go to WB
    if (ld_pending_q) begin
      ma_wb_valid_d      = 1'b1;
      ma_wb_d.pc         = ex_hold_q.pc;
      ma_wb_d.instr      = ex_hold_q.instr;
      ma_wb_d.aluresult  = ex_hold_q.aluresult;
      ma_wb_d.op2        = ex_hold_q.op2;
      ma_wb_d.ld_data    = ld_data_q;
      ma_wb_d.ctrl       = ex_hold_q.ctrl;
    end

    // Priority 2: non-load EX instruction passes through same cycle
    else if (accept_ex && !ex_is_ld) begin
      ma_wb_valid_d      = 1'b1;
      ma_wb_d.pc         = Ex_Payld_i.pc;
      ma_wb_d.instr      = Ex_Payld_i.instr;
      ma_wb_d.aluresult  = Ex_Payld_i.aluresult;
      ma_wb_d.op2        = Ex_Payld_i.op2;
      ma_wb_d.ld_data    = '0;
      ma_wb_d.ctrl       = Ex_Payld_i.ctrl;
    end
  end

  // ------------------------------------------------------------
  // Flush hook (future branch flush, exceptions, etc.)
  // ------------------------------------------------------------
  logic flush_ma;
  assign flush_ma = 1'b0;

  // ------------------------------------------------------------
  // MA -> WB pipe register (ready/valid)
  // ------------------------------------------------------------
  pipe #(.T(Ma_Wb_t)) u_ma_wb_pipe (
    .clk     (Clk),
    .rst_n   (Rst_n),

    // source (MA)
    .valid_d (ma_wb_valid_d),
    .data_d  (ma_wb_d),
    .ready_d (ma_pipe_ready),

    // dest (WB)
    .valid_q (Ma_Valid_o),
    .data_q  (Ma_Payld_o),
    .ready_q (Ma_ready_i),

    .flush   (flush_ma)
  );

endmodule
