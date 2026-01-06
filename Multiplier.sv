///Package Importt/
`include "cpu_pkg.sv"

module Multiplier #(parameter WIDTH=32)
  (
    input logic [WIDTH-1:0] A,
    input logic [WIDTH-1:0] B,

    output logic [(2*WIDTH)-1:0] result,
    output logic [1:0] flag );



  //// DUlll implementation 
  assign result = A * B ; /// This works when not all width are occupied // result,a,b are same width which is conceptually wrong
  assign flag = 2'b00 ;

  /// Impl-2// Fast / high-Fmax: partial products + Dadda (or Wallace) CSA tree + final CPA, optionally pipelined
  

endmodule 
