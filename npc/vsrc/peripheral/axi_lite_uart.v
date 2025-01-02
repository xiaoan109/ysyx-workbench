`include "defines.vh"
module axi_lite_uart (
  input                          i_clk,
  input                          i_rst_n,
  //AW Channel
  input  wire [  `CPU_WIDTH-1:0] awaddr,
  input  wire                    awvalid,
  output wire                    awready,
  //W Channel
  input  wire [  `CPU_WIDTH-1:0] wdata,
  input  wire [`CPU_WIDTH/8-1:0] wstrb,
  input  wire                    wvalid,
  output wire                    wready,
  //B Channel
  output wire [             1:0] bresp,
  output wire                    bvalid,
  input  wire                    bready,
  //AR Channel
  input  wire [  `CPU_WIDTH-1:0] araddr,
  input  wire                    arvalid,
  output wire                    arready,
  //R Channel
  output wire [  `CPU_WIDTH-1:0] rdata,
  output wire [             1:0] rresp,
  output wire                    rvalid,
  input  wire                    rready
);


  reg                      reg_wen;
  reg                      reg_ren;

  wire                     awready_reg;
  reg                      awready_next;
  wire                     wready_reg;
  reg                      wready_next;
  wire                     bvalid_reg;
  reg                      bvalid_next;
  wire                     arready_reg;
  reg                      arready_next;
  wire                     rvalid_reg;
  reg                      rvalid_next;
  wire    [`CPU_WIDTH-1:0] rdata_reg;
  reg     [`CPU_WIDTH-1:0] rdata_next;


  wire    [`CPU_WIDTH-1:0] uart_data_reg;  //addr: 0x0
  reg     [`CPU_WIDTH-1:0] uart_data_next;

  integer                  byte_index;

  wire                     sim_disp_en;

  assign awready = awready_reg;
  assign wready  = wready_reg;
  assign bvalid  = bvalid_reg;
  assign bresp   = 2'b00;  // Always OK
  assign arready = arready_reg;
  assign rvalid  = rvalid_reg;
  assign rresp   = 2'b00;  // Always OK
  assign rdata   = rdata_reg;

  import "DPI-C" function void difftest_skip();

  //AW/W/B Channel
  always @(*) begin
    reg_wen = 1'b0;
    awready_next = 1'b0;
    wready_next = 1'b0;
    bvalid_next = bvalid_reg && !bready;
    if (awvalid && wvalid && (!awready && !wready) && (!bvalid || bready)) begin
`ifndef SYNTHESIS
      difftest_skip();
`endif
      reg_wen = 1'b1;
      awready_next = 1'b1;
      wready_next = 1'b1;
      bvalid_next = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(3'b0)
  ) u_AW_W_B_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({awready_next, wready_next, bvalid_next}),
    .o_dout ({awready_reg, wready_reg, bvalid_reg})
  );

  //AR/R Channel
  always @(*) begin
    reg_ren = 1'b0;
    arready_next = 1'b0;
    rvalid_next = rvalid_reg && !rready;
    if (arvalid && !arready && (!rvalid || rready)) begin
`ifndef SYNTHESIS
      difftest_skip();
`endif
      reg_ren = 1'b1;
      arready_next = 1'b1;
      rvalid_next = 1'b1;
    end
  end


  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_AR_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({arready_next, rvalid_next}),
    .o_dout ({arready_reg, rvalid_reg})
  );



  always @(*) begin
    case (araddr[11:2])  //0xa000_0000 ~ 0xa000_0fff
      10'h0:   rdata_next = uart_data_reg;
      default: rdata_next = `CPU_WIDTH'b0;
    endcase
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (reg_ren),
    .i_din  (rdata_next),
    .o_dout (rdata_reg)
  );


  always @(*) begin
    uart_data_next = uart_data_reg;
    if (reg_wen) begin
      case (awaddr[11:2])  //0xa000_0000 ~ 0xa000_0fff
        10'h0:
        for (byte_index = 0; byte_index <= (`CPU_WIDTH / 8) - 1; byte_index = byte_index + 1)
        if (wstrb[byte_index] == 1'b1) begin
          // Respective byte enables are asserted as per write strobes 
          // Slave register 0
          uart_data_next[(byte_index*8)+:8] = wdata[(byte_index*8)+:8];
        end
        default: ;
      endcase
    end
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_uart_data_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (reg_wen),
    .i_din  (uart_data_next),
    .o_dout (uart_data_reg)
  );

  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_sim_out_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (reg_wen),
    .o_dout (sim_disp_en)
  );
  

  always @(sim_disp_en) begin
    // $write("%m @%t UART TX: %c", $time, uart_data_reg[7:0]);
    if (sim_disp_en) begin
      $write("%c", uart_data_reg[7:0]);
    end
  end


  // import "DPI-C" function void pmem_write(
  //   input int       waddr,
  //   input int       wdata,
  //   input bit [3:0] wmask,
  //   input bit       wen
  // );
  // always @(*) begin
  //   pmem_write(awaddr, wdata, wstrb, reg_wen);
  // end

endmodule
