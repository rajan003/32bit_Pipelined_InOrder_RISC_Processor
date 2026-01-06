/// data Path Design for RISC Processor
///Package Importt/
`include "cpu_pkg.sv"
module Ma_Stage (
                input logic Clk,
  				input logic Rst,
  				input logic Start,
  
  			/// Ex-Stage Interface
			  	input Ex_Ma_t Ex_Payld,
  				input logic Ex_Valid,  
  
  			/// Data memory write interface///
 			    output logic [MEM_ADDR_WIDTH-1:0] Dmem_Waddr,   // 4K words -> 12-bit word address
		        output logic [MEM_DATA_WIDTH-1:0] Dmem_Wdata,
			    output logic        Dmem_Wen,

			// Data memory  Read port
 				output logic [MEM_ADDR_WIDTH-1:0] Dmem_Raddr,
 				input logic  [MEM_DATA_WIDTH-1:0] Dmem_Rdata,	
				output logic         Dmem_Ren

			//Rb stage interface
		       output Ma_Wb_t Ma_Payld,
		       output logic Ma_Valid
) ;
  
//-------------------------------------------//
//-----Memory read and Write control---------//
//-------------------------------------------//
// In RISC-V , the only memory access possible is Load and Store.
logic [31:0] mdr, mar, ld_data;
  always @* begin 
     	 mar = '0; /// Address comnes from alu (op1+imm) for both load and store // 8 bits are selected 
     	 mdr = '0; /// This is the destination register content which you want to store 
        //write
      	Dmem_Waddr = '0;   // 4K words -> 12-bit word address
      	Dmem_Wdata = '0;
	    Dmem_Wen = '0;
				  // Read port
      	Dmem_Raddr = '0;
	    ld_data = '0;	
	    Dmem_Ren = '0;
    if(Ex_Valid==1'b1) 
		begin 
	      mar = Ex_Payld.alu_result[7:0]; /// Address comnes from alu (op1+imm) for both load and store // 8 bits are selected 
	      mdr = Ex_Payld.op2  ; /// This is the destination register content which you want to store 
	
	      Dmem_Waddr = mar[MEM_ADDR_WIDTH-1:0];   // 4K words -> 12-bit word address
	      Dmem_Wdata = mdr;
		  Dmem_Wen = Ex_Payld.ctrl.isSt ? 1'b1: 1'b0 ;
	
					  // Read port
	      Dmem_Raddr = mar[MEM_ADDR_WIDTH-1:0];
		  ld_data = Dmem_Rdata;	
		  Dmem_Ren = Ex_Payld.ctrl.isLd;
	      end 
  end 

typedef struct packed {
  logic [31:0] pc;
  logic [31:0] ld_data;
  logic [31:0] aluResult;
	logic [31:0] instr .   ctrl_unit_t ctrl;
} Ma_Rb_t
	
//Pipe payld 
Ma_Wb_t ma_wb_d;

logic   ma_wb_valid;
//logic   stall_mawb;
//logic   flush_mawb;
	
always_comb begin
  ma_wb_d = '0;

  ma_wb_d.pc        = Ex_Payld.pc;
  ma_wb_d.instr     = Ex_Payld.instr;
  ma_wb_d.aluresult = Ex_Payld.aluresult;
  ma_wb_d.ld_data   = ld_data;       // from memory model output
  ma_wb_d.ctrl      = Ex_Payld.ctrl;
end
  

pipe #(.WIDTH(32*4)) u_ma_wb (
	.clk      (Clk),
	.rst_n    (Rst),
	.en       (Start),
	.stall    ('0),     // 0 for now
	.flush    ('0),     // usually 0 (WB rarely flushed)
    .ma_wb_d  (ma_wb_d),
	.ma_wb_q  (Ma_Payld),
	.valid_q  (Ma_Valid)
);

endmodule 
