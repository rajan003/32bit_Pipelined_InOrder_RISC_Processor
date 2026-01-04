///Package Importt/
`include "cpu_pkg.sv"
module Wb_stage (
                input logic clk,
  				      input logic rst,
  				      input logic start,
           //MA Interface
        			//Rb stage interface
	        	   input Ma_Wb_t Ma_Wb_q,
	        	   input logic Ma_Wb_vld

           /// GPR wr interface
              output logic rd_wr_en,
              output [3:0] rf_wr_addr;
              output [31:0] rf_wr_data

) ;
  

//---------------------------------------------------------//
//--------------- Decode: Register read and write----------//
//---------------------------------------------------------//
/// Write interface controls and data//
  logic [3:0] wr_addr_int;
  logic [31:0] wr_data_int;
always@* begin 
  ra_addr = 4'b1111; /// Fixed to 15th location for RA
	wr_addr_int = Ma_Wb_q.ctrl.isCall ? ra_addr : Ma_Wb_q.instr[25:22] ; ///  Ra register addresss or Rd Register from Instruction 
  case({Ma_Wb_q.ctrl.isCall, Ma_Wb_q.ctrl.isLd}) 
    2'b00: wr_data_int = Ma_Wb_q.alu_result;  /// ALU result is saved here 
    2'b01: wr_data_int = Ma_Wb_q.Ld_load ; /// Memory read reesult //Load instruction 
    2'b10: wr_data_int = Ma_Wb_q.pc + 4 ; ///Next address for PC i.e PC+ 4 Bytes 
      default: wr_data_int = Ma_Wb_q.alu_result;
  endcase
end 

 /// Register write Observation port to testebench//
  always_comb begin 
	 rf_wr_addr = wr_addr_int;
	 rf_wr_data = wr_data_int;
	 rf_wr_en =  Cu_isWb; /// blocking with start 
  end 

endmodule 
