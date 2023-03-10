`timescale 1ns / 1ps

module rom(
  input               clk,
  input               en,
  input        [10:0] addr,
  output logic [11:0] dout
);
  (*rom_style = "block" *) logic [11:0] data [2047:0];

  initial begin
    $readmemh("colour.data", data);
  end

  always_ff @ (posedge clk) begin
    if (en) dout <= data[addr];
  end
endmodule
