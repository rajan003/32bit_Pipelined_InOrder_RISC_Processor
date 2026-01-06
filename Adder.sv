///designinmg a ALU control unit//
///This ctroller sends Sigtnal to ALU unit to do some operation..\
///Package Importt/
`include "cpu_pkg.sv"
module Adder #(parameter WIDTH=32 ) (
  input logic [WIDTH-1:0] A,
  input logic [WIDTH-1:0] B,

  input logic [1:0] ctrl, /// Control tp the type of operation 00: ADD, 01: SUB, 10:CMP 11:RES
  
  output logic [WIDTH-1:0] result,
  output logic [1:0] flag);


  logic [WIDTH-1:0] B_not ;
  logic [WIDTH :0] SUM ; /// ! extra bit for Carry bit 
  
  always@(*) begin 
      B_not  = (ctrl==2'b00) ? B : ~B;/// For Addition B_not = B , for Subtractio/Comparison B_not = B ^ WIDTH{1'b1} i.e Invert of B
      SUM = {1'b0, A} + {1'b0, B_not} + (ctrl==2'b00 ? 1'b0 : 1'b1) ; /// SUM = A+ B , SUb= A + 2's(B) = A + ~B + 1 
      result = SUM[WIDTH-1:0] ; /// Result is still N bit width 
      ////Equal to zero///
      flag[0] = (result=='0) ; /// After Subtraction the result is 0 , i.e. they are equal
      flag[1] = SUM[WIDTH] &  (result != '0) ; /// if A > b than we have a carry 
  end

endmodule
      
      
      
