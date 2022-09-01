// Copyright (C) 2022  Ewen Crawford
`timescale 1ns / 1ps

module tb ();
  
  event tb1_start, tb1_done;
  tb_metaball tb1(
    .start(tb1_start),
    .done(tb1_done)
  );

  event tb2_start, tb2_done;
  tb_buffer tb2(
    .start(tb2_start),
    .done(tb2_done)
  );

  initial begin
    $display("=== SIMULATION STARTED ===");  
    $timeformat(-9, 0, " ns");
    ->tb1_start;
    wait (tb1_done.triggered);
    ->tb2_start;
    wait (tb2_done.triggered);
    $display("=== SIMULATION FINISHED ===");
    $finish;
  end
endmodule
