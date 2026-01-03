`include "cpu_pkg.sv"
//------------------------------------------------------------------------------
// Pipe module
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Generic pipeline register for ANY packed type T
//------------------------------------------------------------------------------
module pipe_reg #(
  parameter type T = logic [31:0]   // override with your struct type
)(
  input  logic clk,
  input  logic rst_n,   // active-low
  input  logic en,      // global enable/start
  input  logic stall,   // hold
  input  logic flush,   // bubble
  input  T     d,
  output T     q,
  output logic valid_q
);

  function automatic T bubble();
    T t;
    t = '0;      // works for packed structs/vectors
    return t;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q       <= bubble();
      valid_q <= 1'b0;
    end
    else if (!en) begin
      q       <= bubble();
      valid_q <= 1'b0;
    end
    else if (flush) begin
      q       <= bubble();
      valid_q <= 1'b0;
    end
    else if (!stall) begin
      q       <= d;
      valid_q <= 1'b1;
    end
    // else: hold q/valid_q automatically
  end

endmodule
