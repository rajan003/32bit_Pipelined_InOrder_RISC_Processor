module hazard_lock(
                  input If_Of_t  Of_payld,
                  input Of_Ex_t Ex_Payld,
                  input Ex_Ma_t Ma_Payld,
                  input Ma_Rb_t Wb_Payld,

                  output logic Hzd_Stall )


  ////Identifying the Opcode fetch Payload ///If-Of stage pipelone output
  logic [5:0] A_Opcode;
  logic A_src1 ;
  logic A_src2 ;
  logic Ex_src;
  logic Ma_src;
  logic Wb_src;
  logic src1_cnflt;
  logic src2_cnflt;
  
  always_comb begin 
    A_Opcode = Of_Payld.instr[31:27];
    A_src1 = (A_Opcode =5'b01001) ? Of_Payld.instr[31:27] : Of_Payld.instr[31:27] ;
    A_src2 = (A_Opcode =5'b01001) ? Of_Payld.instr[31:27] : Of_Payld.instr[31:27] ;

    Ex_Src = (A_Opcode =5'b01001) ? Ex_Payld.instr[31:27] : Ex_Payld.instr[31:27] ;
    Ma_src = (A_Opcode =5'b01001) ? Ma_Payld.instr[31:27] : Ma_Payld.instr[31:27] ;
    Wb_src = (A_Opcode =5'b01001) ? Wb_Payld.instr[31:27 : Wb_Payld.instr[31:27] ;

    Abranch = (A_Opcode == nop) | (A_Opcode == b) | (A_Opcode == beq) | (A_Opcode == bgt) | (A_Opcode == call) ;
    Exbranch = (Ex_Opcode == nop) | (Ex_Opcode == b) | (Ex_Opcode == beq) | (Ex_Opcode == bgt) | (Ex_Opcode == call) ;
    Mabranch = (Ma_Opcode == nop) | (Ma_Opcode == b) | (Ma_Opcode == beq) | (Ma_Opcode == bgt) | (Ma_Opcode == call) ;
    Wbbranch = (Wb_Opcode == nop) | (Wb_Opcode == b) | (Wb_Opcode == beq) | (Wb_Opcode == bgt) | (Wb_Opcode == call) ;

    src1_cnflt = (A_Src1 == Ex_src  &&  Exbranch) | (A_Src1 == Ma_src && Mabranch) | (A_Src1 == Wb_src && Wbbranch) ;
    src2_cnflt = (A_Src2 == Ex_src  &&  Exbranch) | (A_Src2 == Ma_src && Mabranch) | (A_Src2 == Wb_src && Wbbranch) ;
  end 



                                                   assign Hzd_Stall = Abranch | src_cnflt1 | src_cnflt2;                                        

  endmodule

