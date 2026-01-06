module logic_unit #(
  parameter int W = 32
)(
  input  logic [W-1:0]   A,
  input  logic [W-1:0]   B,
  input  logic_op_t      op,
  output logic [W-1:0]   result,
  output logic [1:0] flag
);

  always_comb begin
    case (op)
      ALU_AND: result = A & B;
      ALU_OR : result = A | B;
      ALU_NOT: result = ~A;
      default: result = '0;
    endcase
  end
assign flag = '0;
endmodule
