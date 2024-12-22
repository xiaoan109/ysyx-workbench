module delay_counter #(
  parameter CNT_MAX_WIDTH = 8
) (
  input i_clk,
  input i_rst_n,
  input i_ena,  // 1clk pulse
  input [CNT_MAX_WIDTH-1:0] i_bound,
  output o_done
);

  reg [CNT_MAX_WIDTH-1:0] cnt_next;
  wire [CNT_MAX_WIDTH-1:0] cnt_reg;
  reg cnt_run_next;
  wire cnt_run_reg;
  wire [CNT_MAX_WIDTH-1:0] cnt_bound;
  wire cnt_start;

  assign cnt_start = i_ena && |i_bound;  //max count not equal to zero


  stdreg #(
    .WIDTH(CNT_MAX_WIDTH),
    .RESET_VAL({(CNT_MAX_WIDTH) {1'b0}})
  ) u_cnt_bound_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (cnt_start),
    .i_din  (i_bound),
    .o_dout (cnt_bound)
  );

  always @(*) begin
    cnt_run_next = cnt_run_reg;
    if (cnt_start) begin
      cnt_run_next = 1'b1;
    end else if (cnt_reg == cnt_bound - 1) begin
      cnt_run_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH(1),
    .RESET_VAL(1'b0)
  ) u_cnt_run_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (cnt_run_next),
    .o_dout (cnt_run_reg)
  );

  always @(*) begin
    cnt_next = cnt_reg;
    if (cnt_run_reg) begin
      if (cnt_reg == cnt_bound - 1) begin
        cnt_next = {(CNT_MAX_WIDTH) {1'b0}};
      end else begin
        cnt_next = cnt_next + 1'b1;
      end
    end
  end

  stdreg #(
    .WIDTH(CNT_MAX_WIDTH),
    .RESET_VAL({(CNT_MAX_WIDTH) {1'b0}})
  ) u_cnt_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (cnt_next),
    .o_dout (cnt_reg)
  );


  assign o_done = cnt_run_reg && cnt_reg == cnt_bound - 1;

endmodule
