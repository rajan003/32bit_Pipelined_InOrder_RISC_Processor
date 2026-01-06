`include "cpu_pkg.sv"
`include "DivMod.sv"
`include "Shift.sv"
`include "Logical.sv"
`include "move.sv"
module ALU (
  input  aluctrl_t     aluSignal,
  input  logic [31:0]  A,
  input  logic [31:0]  B,
  output logic [31:0]  aluResult,
  output flag_t         flag
);

  localparam int NOPS = 13;

  logic [31:0] res [0:NOPS-1];
  logic [1:0]  flg_bits [0:NOPS-1];
  logic [NOPS-1:0] sel;

  // -------------------------
  // Build one-hot select vector
  // -------------------------
  always@* begin
    sel = '0;
    sel[0]  = aluSignal.isAdd;
    sel[1]  = aluSignal.isSub;
    sel[2]  = aluSignal.isCmp;
    sel[3]  = aluSignal.isOr;
    sel[4]  = aluSignal.isAnd;
    sel[5]  = aluSignal.isNot;
    sel[6]  = aluSignal.isLsl;
    sel[7]  = aluSignal.isLsr;
    sel[8]  = aluSignal.isAsr;
    sel[9]  = aluSignal.isMul;
    sel[10] = aluSignal.isDiv;
    sel[11] = aluSignal.isMod;
    sel[12] = aluSignal.isMov;
  end

  // -------------------------
  // Submodule instantiations
  // -------------------------
  Adder u_add (.A(A), .B(B), .ctrl(2'b00), .result(res[0]), .flag(flg_bits[0]));
  Adder u_sub (.A(A), .B(B), .ctrl(2'b01), .result(res[1]), .flag(flg_bits[1]));
  Adder u_cmp (.A(A), .B(B), .ctrl(2'b10), .result(res[2]), .flag(flg_bits[2]));

  logic_unit u_or  (.A(A), .B(B), .op(2'b01), .result(res[3]), .flag(flg_bits[3]));
  logic_unit u_and (.A(A), .B(B), .op(2'b00), .result(res[4]), .flag(flg_bits[4]));
  logic_unit u_not (.A(A), .B(B), .op(2'b10), .result(res[5]), .flag(flg_bits[5]));

  shifter u_lsl (.A(A), .B(B), .isLsl(1'b1), .isLsr(1'b0), .isAsr(1'b0), .result(res[6]), .flag(flg_bits[6]));
  shifter u_lsr (.A(A), .B(B), .isLsl(1'b0), .isLsr(1'b1), .isAsr(1'b0), .result(res[7]), .flag(flg_bits[7]));
  shifter u_asr (.A(A), .B(B), .isLsl(1'b0), .isLsr(1'b0), .isAsr(1'b1), .result(res[8]), .flag(flg_bits[8]));

  Multiplier u_mul (.A(A), .B(B), .result(res[9]),  .flag(flg_bits[9]));
  divmod     u_div (.dividend(A), .divisor(B), .quotient(res[10]), .remainder(),       .flag(flg_bits[10]));
  divmod     u_mod (.dividend(A), .divisor(B), .quotient(),        .remainder(res[11]), .flag(flg_bits[11]));

  move_unit  u_mov (.A(A), .B(B), .isMov(1'b1), .result(res[12]), .flag(flg_bits[12]));

  // -------------------------
  // Priority selection 
  // -------------------------
  logic hit;
  always@* begin
    aluResult = 32'h0;
    flag.GT   = 1'b0;
    flag.ET   = 1'b0;
    hit = 1'b0;

    for (int i = 0; i < NOPS; i++) begin
      if (sel[i] && !hit) begin
        aluResult = res[i];
        flag.GT   = flg_bits[i][1];
        flag.ET   = flg_bits[i][0];
        hit       = 1'b1;
      end
    end
  end

endmodule
