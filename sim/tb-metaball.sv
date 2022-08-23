`timescale 1ns / 1ps

module tb_metaball (
  input event start,
  input event done
);
  parameter real rad = 2.5;
  parameter real i_x = 15.5;
  parameter real i_y = 0;
  parameter real iv_y = 8.025;
  logic clk = 0;
  logic rst = 0;
  logic mov_en = 0;
  logic px_stb = 0;
  real p_x = 0;
  real p_y = 0;
  logic vld;
  logic [31:0] out;

  always #10 clk <= ~clk;
  //always #30 mov_en <= ~mov_en;
  
  metaball #(
    .RAD(real_to_fp(rad)),
    .I_X(real_to_fp(i_x)),
    .I_Y(real_to_fp(i_y)),
    .IV_Y(real_to_fp(iv_y))
  ) dut(
    .clk(clk),
    .rst(rst),
    .mov_en(mov_en),
    .px_stb(px_stb),
    .p_x(real_to_fp(p_x)),
    .p_y(real_to_fp(p_y)),
    .vld(vld),
    .out(out)
  );

  function void disp_res(string prop, real expected, int actual);
    int expected_fp;
    string status;
    expected_fp = real_to_fp(expected);
    if (expected_fp == actual) status = "PASS";
    else status = "FAIL";
    $display("%s\t%h\t%h\t%s", prop, expected_fp, actual, status);
  endfunction

  function automatic real fp_to_real(logic[31:0] num);
    real out = 0;
    if (num[31]) num = ~num + 1;
    for (int i = 30; i >= 15; i--) begin
      if (num[i]) out += $pow(2, i - 15);
    end
    for (int i = 14; i >= 0; i--) begin
      if (num[i]) out += 1 / $pow(2, 15 - i);
    end
    return out;
  endfunction

  function automatic logic[31:0] real_to_fp(real num);
    logic[31:0] out = '0;
    logic neg_flag = 0;
    real bit_val = 0;
    if (num < 0) neg_flag = 1;
    num = $sqrt($pow(num, 2));
    for (int i = 30; i >= 15; i--) begin
      bit_val = $pow(2, i - 15);
      if (num >= bit_val) begin
	out[i] = 1'b1;
	num -= bit_val;
      end
    end
    for (int i = 14; i >= 0; i--) begin
      bit_val = 1 / $pow(2, 15 - i);
      if (num >= bit_val) begin
	out[i] = 1'b1;
	num -= bit_val;
      end
    end
    if (neg_flag) out = ~out + 1;
    return out;
  endfunction

  function automatic int fp_mul(int a, b);
    logic [63:0] mul = a * b;
    return mul[48:16];
  endfunction
  
  bit t1_out = 0;

  real dx, dy, dx_sq, dy_sq, dividend, divisor, result;
  initial begin
    wait (start.triggered);
    $display("=== ALGORITHM TEST STARTED ===");
    $display("Property\tExpected\tActual\t\tStatus");
    px_stb = 1;
    // Compute expected algorithm output
    dx = p_x - i_x;
    dy = p_y - i_y;
    dx_sq = $pow(dx, 2);
    dy_sq = $pow(dy, 2);
    dividend = $pow(rad, 2);
    divisor = dx_sq + dy_sq;
    result = dividend / divisor;
    // First wait for a falling validity signal. This is necessary due to the
    // use of an initial block to initialize the `reg_done` signal to high in
    // the qdive module. Because that is executed during simulation runtime,
    // it will trigger the posedge event below before the output has been
    // calculated (simulation time 0)
    @ (negedge vld);
    // Wait for output validity signal indicating completion. Note that `vld`
    // is reset to 0 internally
    @ (posedge vld);
    disp_res("x position", i_x, dut.x);
    disp_res("y position", i_y, dut.y);
    disp_res("delta x\t", dx, dut.dx);
    disp_res("delta y\t", dy, dut.dy);
    disp_res("delta x squared", dx_sq, dut.dx_sq);
    disp_res("delta y squared", dy_sq, dut.dy_sq);
    disp_res("dividend", dividend, dut.dividend);
    disp_res("divisor\t", divisor, dut.divisor);
    disp_res("output\t", result, out);
    $display("=== ALGORITHM TEST FINISHED ===");
    ->done;
  end
endmodule
