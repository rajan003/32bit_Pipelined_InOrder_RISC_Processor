module shifter #(
  parameter int W = 32
)(
  input  logic [W-1:0] A,
  input  logic [W-1:0] B,

  input  logic         isLsl,
  input  logic         isLsr,
  input  logic         isAsr,

  output logic [W-1:0] result,
  output logic [1:0] flag
);

  logic [4:0] shamt;
  assign shamt = B[4:0];

  always_comb begin
    result = '0;
    if (isLsl)
      result = A << shamt;
    else if (isLsr)
      result = A >> shamt;
    else if (isAsr)
      result = $signed(A) >>> shamt;
  end

  assign flag = '0;
endmodule
