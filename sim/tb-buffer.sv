// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module tb_buffer #(
    parameter DATA_RANGE = 4096,
    parameter RAM_DEPTH = 1024
)(
    input event start,
    input event done
);
  logic clk     = 0,
	en      = 0,
	swap_en = 0,
	w_en    = 0;
  logic [9:0]  addr;
  logic [11:0] din, dout;

  always #10 clk <= ~clk;

  buffer dut(
    .clk(clk),
    .en(en),
    .swap_en(swap_en),
    .w_en(w_en),
    .addr(addr),
    .din(din),
    .dout(dout)
  );

  function automatic void mem_status(string op);
    logic [11:0] a_out = dut.buff_a.bram[addr];
    logic [11:0] b_out = dut.buff_b.bram[addr];
    logic ptr = dut.cur_buff;
    $display("%s\t%h\t%h\t%h\t%h\t%b", op, addr, a_out, b_out, dout, ptr);
  endfunction

  logic [9:0] gen_addr;
  logic [11:0] gen_data;
  string buff, status;
  logic [9:0] word_a, word_b;

  initial begin
    wait (start.triggered);
    $display("=== BUFFER TEST STARTED ===");
    $display("Test\tAddr\tBuff A\tBuff B\tOutput\tBuff Ptr");
    // Assert test data
    gen_addr = $urandom_range(0, RAM_DEPTH-1);
    gen_data = $urandom_range(0, DATA_RANGE-1);
    addr = gen_addr;
    din = gen_data;
    // Test write
    en = 1;
    w_en = 1;
    @ (posedge clk);
    mem_status("Write");
    // Test Swap
    w_en = 0;
    swap_en = 1;
    @ (posedge clk);
    mem_status("Swap");
    // Check output after buffer swap
    swap_en = 0;
    @ (posedge clk);
    mem_status("Hold En");
   $display("=== BUFFER TEST FINISHED ===");
    ->done;
  end
endmodule
