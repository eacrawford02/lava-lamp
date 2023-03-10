// Copyright (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module tb_rom #(
    parameter RAM_DEPTH = 2048
)(
    input event start,
    input event done
);
  logic clk = 0,
	en  = 0;
  logic [10:0] addr = 0;
  logic [11:0] dout;

  rom dut(
    .clk(clk),
    .en(en),
    .addr(addr),
    .dout(dout)
  );

  always #5 clk <= ~clk;

  int fd, err_cnt;
  string line;

  initial begin
    wait (start.triggered);
    $display("=== ROM TEST STARTED ===");
    fd = $fopen("colour.data", "r");
    if (!fd) $display("Error opening file");
    err_cnt = 0;
    en = 1;
    @ (posedge clk);
    for (int i = 0; i < RAM_DEPTH; i++) begin
      $fgets(line, fd);
      if (line.atohex() != dout) begin
	err_cnt++;
	$display("Error: ROM does not match data file at index %4d",
		 "(%3h vs. %3h)", i, dout, line.atohex());
      end
      addr = addr + 1;
      @ (posedge clk);
    end
    $display("Encountered %0d errors", err_cnt);
    $fclose(fd);
    $display("=== ROM TEST FINISHED ===");
    ->done;
  end
endmodule
