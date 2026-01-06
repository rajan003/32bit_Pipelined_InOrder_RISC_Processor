`include "cpu_pkg.sv"
//------------------------------------------------------------------------------
// Pipe module
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Generic pipeline register for ANY packed type T
//------------------------------------------------------------------------------
module pipe #(
  parameter WIDTH =32)   // override with your struct type
)(
  input  logic clk,
  input  logic rst_n,   // active-low
  input  logic en,      // global enable/start
  input  logic stall,   // hold
  input  logic flush,   // bubble
  input  logic [WIDTH-1:0]  d,
  output logic [WIDTH-1:0]  q,
  output logic valid_q
);



  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q       <= '0;
      valid_q <= 1'b0;
    end
    else if (!en) begin
      q       <= '0;
      valid_q <= 1'b0;
    end
    else if (flush) begin
      q       <= '0;
      valid_q <= 1'b0;
    end
    else if (!stall) begin
      q       <= d;
      valid_q <= 1'b1;
    end
    // else: hold q/valid_q automatically
  end

endmodule
