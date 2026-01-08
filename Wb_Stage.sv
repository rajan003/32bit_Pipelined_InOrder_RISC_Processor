`include "cpu_pkg.sv"

module Wb_Stage (
  input  logic    Clk,
  input  logic    Rst_n,

  // MA->WB interface (vld/rdy/payload)
  input  logic    Ma_Valid_i,
  output logic    Ma_Ready_o,
  input  Ma_Wb_t  Ma_Payld_i,

  // Register file write port
  output logic        rf_wr_en,
  output logic [3:0]  rf_wr_addr,
  output logic [31:0] rf_wr_data
);

  // WB is a sink: always ready (no backpressure from RF write)
  //TO-DO/// This need to be improved for REG write Delay
  assign Ma_Ready_o = 1'b1;

  // Decode writeback fields (combinational)
  logic [3:0]  ra_addr;
  logic [3:0]  wr_addr_int;
  logic [31:0] wr_data_int;

  always_comb begin
    ra_addr    = 4'hF;         // RA fixed reg (r15)
    wr_addr_int = Ma_Payld_i.ctrl.isCall ? ra_addr : Ma_Payld_i.instr[25:22];

    // Select WB data
    unique case ({Ma_Payld_i.ctrl.isCall, Ma_Payld_i.ctrl.isLd})
      2'b00: wr_data_int = Ma_Payld_i.aluresult;
      2'b01: wr_data_int = Ma_Payld_i.ld_data;
      2'b10: wr_data_int = Ma_Payld_i.pc + 32'd4;
      default: wr_data_int = Ma_Payld_i.aluresult;
    endcase
  end

  // Fire RF write only on handshake
  wire wb_fire = Ma_Valid_i && Ma_Ready_o;

  always_ff @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
      rf_wr_en   <= 1'b0;
      rf_wr_addr <= '0;
      rf_wr_data <= '0;
    end else begin
      rf_wr_en   <= wb_fire && Ma_Payld_i.ctrl.isWb;
      rf_wr_addr <= wr_addr_int;
      rf_wr_data <= wr_data_int;
    end
  end

endmodule
