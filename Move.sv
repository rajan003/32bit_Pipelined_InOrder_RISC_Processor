module move_unit #(
  parameter int W = 32
)(
  input  logic [W-1:0] A,     // usually ignored
  input  logic [W-1:0] B,     // value to move
  input  logic         isMov,
  output logic [W-1:0] result,
  output logic [1:0] flag
);

  always_comb begin
    result = '0;
    if (isMov)
      result = B;
  end

endmodule
