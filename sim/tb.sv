module tb ();
  reg clk = 0;
  reg mov_en = 0;
  always #10 clk <= ~clk;
  always #30 mov_en <= ~mov_en;
  wire vld, out;
  metaball #(.IV_Y(32'h0004_0333)) dut(
    .clk(clk),
    .rst(0),
    .mov_en(mov_en),
    .px_stb(0),
    .p_x(0),
    .p_y(0),
    .vld(vld),
    .out(out)
  );

  initial begin
    $display("=== SIMULATION STARTED ===");
    #1000;
    $display("=== SIMULATION FINISHED ===");
    $finish;
  end
endmodule
