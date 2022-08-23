`timescale 1ns / 1ps

module tb ();
  
  event tb1_start, tb1_done;
  tb_metaball tb1(
    .start(tb1_start),
    .done(tb1_done)
  );

  initial begin
    $display("=== SIMULATION STARTED ===");  
    $timeformat(-9, 0, " ns");
    ->tb1_start;
    wait (tb1_done.triggered);
    $display("=== SIMULATION FINISHED ===");
    $finish;
  end
endmodule
