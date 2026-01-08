// Verilog/SystemVerilog code for Control Unit
`include "cpu_pkg.sv"

module Control_Unit (
  input  logic      imm,     // immediate indicator bit (from instr[26])
  input  logic [4:0] opcode,  // instr[31:27]
  output ctrl_unit_t Cu_out
);

  always_comb begin
    // Default everything to 0
    Cu_out = '0;
    // Always reflect immediate bit
    Cu_out.isImmediate = imm;
    case (opcode)
      5'b00000: begin // ADD
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isAdd  = 1'b1;
      end
      5'b00001: begin // SUB
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isSub  = 1'b1;
      end
      5'b00010: begin // MUL
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isMul  = 1'b1;
      end
      5'b00011: begin // DIV
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isDiv  = 1'b1;
      end
      5'b00100: begin // MOD
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isMod  = 1'b1;
      end
      5'b00101: begin // CMP
        // no WB; just update flags in ALU
        Cu_out.alu_ctrl.isCmp  = 1'b1;
      end
      5'b00110: begin // AND
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isAnd  = 1'b1;
      end
      5'b00111: begin // OR
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isOr   = 1'b1;
      end
      5'b01000: begin // NOT
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isNot  = 1'b1;
      end
      5'b01001: begin // MOV
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isMov  = 1'b1;
      end
      5'b01010: begin // LSL
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isLsl  = 1'b1;
      end
      5'b01011: begin // LSR
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isLsr  = 1'b1;
      end
      5'b01100: begin // ASR
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isAsr  = 1'b1;
      end
      5'b01101: begin // NOP
        // all zeros
      end
      5'b01110: begin // LD
        Cu_out.isLd            = 1'b1;
        Cu_out.isWb            = 1'b1;
        Cu_out.alu_ctrl.isAdd  = 1'b1; // address calc (base + offset/imm)
      end
      5'b01111: begin // ST
        Cu_out.isSt            = 1'b1;
        Cu_out.alu_ctrl.isAdd  = 1'b1; // address calc
      end
      5'b10000: begin // BEQ
        Cu_out.isBeq           = 1'b1;
      end
      5'b10001: begin // BGT
        Cu_out.isBgt           = 1'b1;
      end
      5'b10010: begin // B (unconditional)
        Cu_out.isUBranch       = 1'b1;
      end
      5'b10011: begin // CALL
        Cu_out.isUBranch       = 1'b1;
        Cu_out.isCall          = 1'b1;
        Cu_out.isWb            = 1'b1; // write RA in WB stage
      end
      5'b10100: begin // RET
        Cu_out.isUBranch       = 1'b1;
        Cu_out.isRet           = 1'b1;
      end

      default: begin
        // keep as NOP
      end
    endcase
  end

endmodule
