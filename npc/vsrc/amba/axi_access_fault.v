// AXI BUS Access Fault Monitor
// Currently Simulation Only
module axi_access_fault (
  input                     i_clk,
  input                     i_rst_n,
  //AW Channel
  input                     awready,
  input                     awvalid,
  input  [  `CPU_WIDTH-1:0] awaddr,
  input  [             3:0] awid,
  input  [             7:0] awlen,
  input  [             2:0] awsize,
  input  [             1:0] awburst,
  //W Channel
  input                     wready,
  input                     wvalid,
  input  [  `CPU_WIDTH-1:0] wdata,
  input  [`CPU_WIDTH/8-1:0] wstrb,
  input                     wlast,
  //B Channel
  input                     bready,
  input                     bvalid,
  input  [             1:0] bresp,
  input  [             3:0] bid,
  //AR Channel
  input                     arready,
  input                     arvalid,
  input  [  `CPU_WIDTH-1:0] araddr,
  input  [             3:0] arid,
  input  [             7:0] arlen,
  input  [             2:0] arsize,
  input  [             1:0] arburst,
  //R Channel
  input                     rready,
  input                     rvalid,
  input  [             1:0] rresp,
  input  [  `CPU_WIDTH-1:0] rdata,
  input                     rlast,
  input  [             3:0] rid,
  //Access Fault Out
  output                    access_fault
);

  wire access_fault_reg;
  reg  access_fault_next;

  assign access_fault = access_fault_reg;

`ifndef SYNTHESIS
  always @(*) begin
    access_fault_next = 1'b0;
    if (bready && bvalid && bresp != 2'b0) begin
      access_fault_next = 1'b1;
      $fatal(0, "AXI Access Fault BRESP=%b, AWADDR=%h", bresp, awaddr);
    end
    if (rready && rvalid && rresp != 2'b0) begin
      access_fault_next = 1'b1;
      $fatal(0, "AXI Access Fault RRESP=%b, ARADDR=%h", rresp, araddr);
    end
  end
`endif

  // stdreg #(
  //   .WIDTH    (1),
  //   .RESET_VAL(1'b0)
  // ) u_reg (
  //   .i_clk  (i_clk),
  //   .i_rst_n(i_rst_n),
  //   .i_wen  (1'b1),
  //   .i_din  (access_fault_next),
  //   .o_dout (access_fault_reg)
  // );

  assign access_fault_reg = access_fault_next;
endmodule
