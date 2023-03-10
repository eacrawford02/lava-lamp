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

  event tb3_start, tb3_done;
  tb_dspl_ctrl tb3(
    .start(tb3_start),
    .done(tb3_done)
  );

  event tb4_start, tb4_done;
  tb_rom tb4(
    .start(tb4_start),
    .done(tb4_done)
  );

  initial begin
    $display("=== SIMULATION STARTED ===");  
    $timeformat(-9, 0, " ns");
    ->tb1_start;
    wait (tb1_done.triggered);
    ->tb2_start;
    wait (tb2_done.triggered);
    ->tb3_start;
    wait (tb3_done.triggered);
    ->tb4_start;
    wait (tb4_done.triggered);
    $display("=== SIMULATION FINISHED ===");
    $finish;
  end
endmodule
