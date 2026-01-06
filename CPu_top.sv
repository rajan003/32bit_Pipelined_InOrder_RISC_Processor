// CPU Top (memory interfaces exported to top)
 //-- Package Import------//
`include "cpu_pkg.sv"
`include "DataPath.sv"
`include "CtrlUnit.sv"
`include "REG2R1W.sv"
`include "Adder.sv"
`include "Multiplier.sv"
`include "ALU.sv"
module CPU_Top (
  input  logic clk,
  input logic rst,
  input logic start,

  // -------------------------
  // Instruction memory (read-only)
  // -------------------------
  output logic                      imem_en,
  output logic [INST_ADDR_WIDTH-1:0] imem_addr,
  input  logic [INST_DATA_WIDTH-1:0] imem_data,

  // -------------------------
  // Data memory (true 2-port)
  // -------------------------
  // Write port
  output logic [MEM_ADDR_WIDTH-1:0]               dmem_waddr,
  output logic [MEM_DATA_WIDTH-1:0]               dmem_wdata,
  output logic                      dmem_wen,

  // Read port
  output logic [MEM_ADDR_WIDTH-1:0]               dmem_raddr,
  input  logic [MEM_DATA_WIDTH-1:0]               dmem_rdata,
  output logic                      dmem_ren,

  // -------------------------
  // Register-file write monitor (TB visibility)
  // -------------------------
  output logic [3:0]                rf_wr_addr,
  output logic [31:0]               rf_wr_data,
  output logic                      rf_wr_en
);
  
//==========IF Stage=================//
  `include "cpu_pkg.sv"
module If_stage (
                input logic clk,
  				input logic rst,

          ///Instruction SRAM wr Interface/// For loading SRAM 
               output logic imem_en ,
 			   output logic [INST_ADDR_WIDTH -1:0] imem_addr,
 			   input logic [INST_DATA_WIDTH-1:0] imem_data,
         /// EX Stage Interface
				input logic Ex_isBranchTaken,
	            input logic [31:0] Ex_BranchPC,
	
		 ///OF Stage Interface
				//IF Stage Output
			    output logic If_id_valid,
				input If_Of_t If_Payld,

) ;

  //===================OF Stage==================//
  //Package Importt/
`include "cpu_pkg.sv"
module Of_Stage (
                input logic clk,
  				input logic rst,
			//IF Stage Output
				input If_Of_t If_Payld,
				input logic If_valid,
  

            /// Immediate bit output to Control Unit
                output logic Cu_imm, /// immediate indication bi
                output logic [4:0] Cu_opcode  //Opcode
                input ctrl_unit_t Cu_out

			// GPR Reg Interface 
			  //// Read Ports-0//////
				output logic [3:0] rd_addr1,
				input logic [31:0] rd_data1,
			  ///Read Port-1///
				output logic [3:0] rd_addr2,
				input logic [31:0] rd_data2
			// Ex Stage 
				output Of_Ex_t of_ex_q,
  				output logic of_ex_valid
		);

  //===================EX Stage====================//
  module Ex_Stage (
                input logic clk,
  				input logic rst,
  
  				input logic start,
  		  //Of Stage Output
			  	output Of_Ex_t Of_Ex_q,
  				output logic Of_Ex_Valid

       //Ex Stage Output
			  	output Ex_Ma_t ex_ma_q,
  				output logic ex_ma_valid,  

	   ///Branch Control To IF Stage
	            output logic isBranchTaken,
	            output logic [31:0] BranchPC
) ;

    ///==================MA Stage==================//
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

			//Rb stage interface
		    output Ma_Wb_t Ma_Wb_q,
		   output logic Ma_Wb_vld
) ;
      ///=====================WB Stage===///////////////
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
    ////================================///



endmodule
