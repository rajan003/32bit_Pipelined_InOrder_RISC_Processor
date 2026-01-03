// Verilog code for Control Unit 
`include "cpu_pkg.sv"
module Control_Unit(
            /// Immediate bit output to Control Unit
                input logic imm, /// immediate indication bit

            /// Opcode to control unit
            input logic [4:0] opcode,
                //input logic clk,
            ///Control Unit
            output ctrl_unit_t Cu_out
    );


always @(*)
begin
 isSt= '0;  
 isLd = '0; 
 isBeq= '0; 
 isBgt= '0; 
 isRet= '0; 
 isImmediate=imm; /// Immediate bit is set if Instruction has immediate set 
 isWb='0; 
 isUBranch='0; 
 isCall ='0;  
 isAdd='0; 
 isSub='0; 
 isCmp='0; 
 isMul='0; 
 isDiv='0; 
 isMod='0; 
 isLsl='0; 
 isLsr='0; 
 isAsr='0; 
 isOr='0; 
 isAnd='0; 
 isNot='0; 
 isMov='0; 
 case(opcode) 
5'b00000:  // ADD (register or Immediate)
         begin
          isAdd=1'b1 ; 
          isWb=1'b1 ;
         end
 5'b00001:  // SUB//Subtract
   begin
          isSub=1'b1 ; 
          isWb=1'b1 ;
   end
 5'b00010:  // Multplication
   begin
          isMul=1'b1 ; 
          isWb=1'b1 ; 
   end
 5'b00011:  // Division
   begin
          isDiv=1'b1 ; 
          isWb=1'b1 ;  
   end
 5'b00100:  // MOD
   begin
          isMod=1'b1 ; 
          isWb=1'b1 ;  
   end
 5'b00101:  // Comparator
   begin
          isCmp=1'b1 ; /// Tellls ALU to compare Only
   end
 5'b00110:  // Logical AND
   begin
          isAnd=1'b1 ; 
          isWb=1'b1 ;  
   end
 5'b00111:  // OR
   begin
          isOr=1'b1 ; 
          isWb=1'b1 ;   
   end
 5'b01000:  // NOT
   begin
          isNot=1'b1 ; 
          isWb=1'b1 ;    
   end
 5'b01001:  // Move
   begin
          isMov=1'b1 ; 
          isWb=1'b1 ;
   end
 5'b01010:  // LSL
   begin
          isLsl=1'b1 ; 
          isWb=1'b1 ;    
   end
 5'b01011:  // LSR
   begin
          isLsr=1'b1 ; 
          isWb=1'b1 ;    
   end
 5'b01100:  // ASR
   begin
          isAsr=1'b1 ; 
          isWb=1'b1 ;    
   end   
 5'b01101:  // NOP 
       begin //
       end 
 5'b01110:  // LD - Load operation 
   begin
          isLd=1'b1 ; 
          isWb=1'b1 ;  
         isAdd= 1'b1;
   end    
  5'b01111:  // ST - Store operation 
   begin
          isSt=1'b1 ; 
         isAdd= 1'b1;
   end   
  5'b10000:  // BEQ - Branch if Equal 
   begin
          isBeq=1'b1 ; 
   end   
 5'b10001:  // BGT-- Branch if Greater
   begin
          isBgt=1'b1 ; 
   end   
 5'b10010:  // b -- Branch offset-- unconditional 
   begin
          isUBranch=1'b1 ; 
   end   
  5'b10011:  // call -- call offset-- unconditional 
   begin
          isUBranch=1'b1 ; 
          isCall = 1'b1;
         isWb = 1'b1;
   end  
   5'b10100:  // ret-- unconditional 
   begin
          isUBranch=1'b1 ; 
          isRet = 1'b1;
   end  
 endcase
      
 end

endmodule
