/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module Ma_Stage (
          input logic clk,
  				input logic rst,
  				input logic start,
  
  			/// Ex-Stage Interface
			  	input Ex_Ma_t ex_ma_q,
  				input logic ex_ma_valid,  
  
  			/// Data memory write interface///
          output logic [MEM_ADDR_WIDTH-1:0] dmem_waddr,   // 4K words -> 12-bit word address
          output logic [MEM_DATA_WIDTH-1:0] dmem_wdata,
			    output logic        dmem_wen,

				// Read port
           output logic [MEM_ADDR_WIDTH-1:0] dmem_raddr,
 			     input logic  [MEM_DATA_WIDTH-1:0] dmem_rdata,	
			     output logic         dmem_ren
) ;
  
//-------------------------------------------//
//-----Memory read and Write control---------//
//-------------------------------------------//
// In RISC-V , the only memory access possible is Load and Store.
  logic [31:0] mdr, mar, IdResult;
  always @* begin 
      mar = '0; /// Address comnes from alu (op1+imm) for both load and store // 8 bits are selected 
      mdr = '0; /// This is the destination register content which you want to store 
        //write
      dmem_waddr = '0;   // 4K words -> 12-bit word address
      dmem_wdata = '0;
	    dmem_wen = '0;
				  // Read port
      dmem_raddr = '0;
	    IdResult = '0;	
	    dmem_ren = '0;
    if(ex_ma_valid==1'b1)  begin 
      mar = ex_ma_q.alu_result[7:0]; /// Address comnes from alu (op1+imm) for both load and store // 8 bits are selected 
      mdr = ex_ma_q.op2  ; /// This is the destination register content which you want to store 

      dmem_waddr = mar[MEM_ADDR_WIDTH-1:0];   // 4K words -> 12-bit word address
      dmem_wdata = mdr;
	    dmem_wen = ex_ma_q.ctrl.isSt;

				  // Read port
      dmem_raddr = mar[MEM_ADDR_WIDTH-1:0];
	    IdResult = dmem_rdata;	
	    dmem_ren = ex_ma_q.ctrl.isLd;
      end 
  end 

  
  



endmodule 
