///Package Importt/
`include "cpu_pkg.sv"
module Wb_stage (
  			 input logic Start,
           //MA Interface
          //Rb stage interface
	         input Ma_Wb_t Ma_Payld,
	         input logic Ma_Valid,

         // GPR wr interface
              output logic rf_wr_en,
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
	wr_addr_int = Ma_Payld.ctrl.isCall ? ra_addr : Ma_Payld.instr[25:22] ; ///  Ra register addresss or Rd Register from Instruction 
  case({Ma_Payld.ctrl.isCall, Ma_Payld.ctrl.isLd}) 
    2'b00: wr_data_int = Ma_Payld.alu_result;  /// ALU result is saved here 
    2'b01: wr_data_int = Ma_Payld.ld_load ; /// Memory read reesult //Load instruction 
    2'b10: wr_data_int = Ma_Payld.pc + 4 ; ///Next address for PC i.e PC+ 4 Bytes 
      default: wr_data_int = Ma_Payld.alu_result;
  endcase
end 

 /// Register write Observation port to testebench//
  always_comb begin 
	  rf_wr_addr ='0;
	  rf_wr_data = '0;
	  rf_wr_en = '0;
	  if(Ma_valid && Start) begin 
	 	rf_wr_addr = wr_addr_int;
		rf_wr_data = wr_data_int;
		rf_wr_en =  Ma_Payld.ctrl.isWb; /// blocking with start 
	  end 
  end 

endmodule 
