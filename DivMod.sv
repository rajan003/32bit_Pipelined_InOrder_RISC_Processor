module divmod #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] dividend,
  input  logic [WIDTH-1:0] divisor,
  output logic [WIDTH-1:0] quotient,
  output logic [WIDTH-1:0] remainder,
  output logic [1:0] flag
//  output logic         div_by_zero
);

  logic [WIDTH:0]   rem;
  logic [WIDTH-1:0] quot;
  logic div_by_zero;
  
  always@* begin
    div_by_zero = (divisor == '0)? 1'b1: 1'b0 ;

    // default outputs
    quotient  = '0;
    remainder = '0;

    if (div_by_zero) begin
      // define safe behavior on divide-by-zero
      quotient  = '0;
      remainder = dividend;
    end else begin
      rem  = '0;
      quot = '0;

      // Long division: MSB -> LSB
      for (int i = WIDTH-1; i >= 0; i--) begin
        rem = {rem[WIDTH-1:0], dividend[i]};   // shift left + bring next bit

        if (rem >= {1'b0, divisor}) begin
          rem      = rem - {1'b0, divisor};
          quot[i]  = 1'b1;
        end else begin
          quot[i]  = 1'b0;
        end
      end

      quotient  = quot;
      remainder = rem[WIDTH-1:0];
    end
  end
  assign flag = '0; /// Flag are meaningless //

endmodule
