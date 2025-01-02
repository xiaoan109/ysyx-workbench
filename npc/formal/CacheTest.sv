`include "defines.vh"

module CacheTest (
  input                     clock,
  input                     reset,
  //IFU intf
  //AW Channel
  output                    ifu_axi_awready,
  input                     ifu_axi_awvalid,
  input  [  `CPU_WIDTH-1:0] ifu_axi_awaddr,
  input  [             3:0] ifu_axi_awid,
  input  [             7:0] ifu_axi_awlen,
  input  [             2:0] ifu_axi_awsize,
  input  [             1:0] ifu_axi_awburst,
  //W Channel
  output                    ifu_axi_wready,
  input                     ifu_axi_wvalid,
  input  [  `CPU_WIDTH-1:0] ifu_axi_wdata,
  input  [`CPU_WIDTH/8-1:0] ifu_axi_wstrb,
  input                     ifu_axi_wlast,
  //B Channel
  input                     ifu_axi_bready,
  output                    ifu_axi_bvalid,
  output [             1:0] ifu_axi_bresp,
  output [             3:0] ifu_axi_bid,
  //AR Channel
  output                    ifu_axi_arready,
  input                     ifu_axi_arvalid,
  input  [  `CPU_WIDTH-1:0] ifu_axi_araddr,
  input  [             3:0] ifu_axi_arid,
  input  [             7:0] ifu_axi_arlen,
  input  [             2:0] ifu_axi_arsize,
  input  [             1:0] ifu_axi_arburst,
  //R Channel
  input                     ifu_axi_rready,
  output                    ifu_axi_rvalid,
  output [             1:0] ifu_axi_rresp,
  output [  `CPU_WIDTH-1:0] ifu_axi_rdata,
  output                    ifu_axi_rlast,
  output [             3:0] ifu_axi_rid,
  //random delay in axi transaction
  input                     block
);

  // localparam MEMSIZE = 128;  //byte
  typedef enum {
    idle_t,
    wait_icache_t,
    check_t
  } state_t;

  //AW Channel
  wire                    icache_axi_awready;
  wire                    icache_axi_awvalid;
  wire [  `CPU_WIDTH-1:0] icache_axi_awaddr;
  wire [             3:0] icache_axi_awid;
  wire [             7:0] icache_axi_awlen;
  wire [             2:0] icache_axi_awsize;
  wire [             1:0] icache_axi_awburst;
  //W Channel
  wire                    icache_axi_wready;
  wire                    icache_axi_wvalid;
  wire [  `CPU_WIDTH-1:0] icache_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] icache_axi_wstrb;
  wire                    icache_axi_wlast;
  //B Channel
  wire                    icache_axi_bready;
  wire                    icache_axi_bvalid;
  wire [             1:0] icache_axi_bresp;
  wire [             3:0] icache_axi_bid;
  //AR Channel
  wire                    icache_axi_arready;
  wire                    icache_axi_arvalid;
  wire [  `CPU_WIDTH-1:0] icache_axi_araddr;
  wire [             3:0] icache_axi_arid;
  wire [             7:0] icache_axi_arlen;
  wire [             2:0] icache_axi_arsize;
  wire [             1:0] icache_axi_arburst;
  //R Channel
  wire                    icache_axi_rready;
  wire                    icache_axi_rvalid;
  wire [             1:0] icache_axi_rresp;
  wire [  `CPU_WIDTH-1:0] icache_axi_rdata;
  wire                    icache_axi_rlast;
  wire [             3:0] icache_axi_rid;

  // wire [  `CPU_WIDTH-1:0] mem                [MEMSIZE/4-1:0];

  axi_icache u_axi_icache (
    .i_clk         (clock),
    .i_rst_n       (!reset),
    .ifu_awready   (ifu_axi_awready),
    .ifu_awvalid   (ifu_axi_awvalid),
    .ifu_awaddr    (ifu_axi_awaddr),
    .ifu_awid      (ifu_axi_awid),
    .ifu_awlen     (ifu_axi_awlen),
    .ifu_awsize    (ifu_axi_awsize),
    .ifu_awburst   (ifu_axi_awburst),
    .ifu_wready    (ifu_axi_wready),
    .ifu_wvalid    (ifu_axi_wvalid),
    .ifu_wdata     (ifu_axi_wdata),
    .ifu_wstrb     (ifu_axi_wstrb),
    .ifu_wlast     (ifu_axi_wlast),
    .ifu_bready    (ifu_axi_bready),
    .ifu_bvalid    (ifu_axi_bvalid),
    .ifu_bresp     (ifu_axi_bresp),
    .ifu_bid       (ifu_axi_bid),
    .ifu_arready   (ifu_axi_arready),
    .ifu_arvalid   (ifu_axi_arvalid),
    .ifu_araddr    (ifu_axi_araddr),
    .ifu_arid      (ifu_axi_arid),
    .ifu_arlen     (ifu_axi_arlen),
    .ifu_arsize    (ifu_axi_arsize),
    .ifu_arburst   (ifu_axi_arburst),
    .ifu_rready    (ifu_axi_rready),
    .ifu_rvalid    (ifu_axi_rvalid),
    .ifu_rresp     (ifu_axi_rresp),
    .ifu_rdata     (ifu_axi_rdata),
    .ifu_rlast     (ifu_axi_rlast),
    .ifu_rid       (ifu_axi_rid),
    .icache_awready(icache_axi_awready),
    .icache_awvalid(icache_axi_awvalid),
    .icache_awaddr (icache_axi_awaddr),
    .icache_awid   (icache_axi_awid),
    .icache_awlen  (icache_axi_awlen),
    .icache_awsize (icache_axi_awsize),
    .icache_awburst(icache_axi_awburst),
    .icache_wready (icache_axi_wready),
    .icache_wvalid (icache_axi_wvalid),
    .icache_wdata  (icache_axi_wdata),
    .icache_wstrb  (icache_axi_wstrb),
    .icache_wlast  (icache_axi_wlast),
    .icache_bready (icache_axi_bready),
    .icache_bvalid (icache_axi_bvalid),
    .icache_bresp  (icache_axi_bresp),
    .icache_bid    (icache_axi_bid),
    .icache_arready(icache_axi_arready),
    .icache_arvalid(icache_axi_arvalid),
    .icache_araddr (icache_axi_araddr),
    .icache_arid   (icache_axi_arid),
    .icache_arlen  (icache_axi_arlen),
    .icache_arsize (icache_axi_arsize),
    .icache_arburst(icache_axi_arburst),
    .icache_rready (icache_axi_rready),
    .icache_rvalid (icache_axi_rvalid),
    .icache_rresp  (icache_axi_rresp),
    .icache_rdata  (icache_axi_rdata),
    .icache_rlast  (icache_axi_rlast),
    .icache_rid    (icache_axi_rid)
  );

  axi_ram #(
    // Width of data bus in bits
    .DATA_WIDTH     (`CPU_WIDTH),
    // Width of address bus in bits
    .ADDR_WIDTH     (8),           // `CPU_WIDTH -> 8
    // Width of ID signal
    .ID_WIDTH       (4),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
  ) u_axi_ram (
    .clk          (clock),
    .rst          (reset),
    .s_axi_awid   (icache_axi_awid),
    .s_axi_awaddr (icache_axi_awaddr),
    .s_axi_awlen  (icache_axi_awlen),
    .s_axi_awsize (icache_axi_awsize),
    .s_axi_awburst(icache_axi_awburst),
    .s_axi_awlock (1'b0),
    .s_axi_awcache(4'b0),
    .s_axi_awprot (3'b0),
    .s_axi_awvalid(icache_axi_awvalid),
    .s_axi_awready(icache_axi_awready),
    .s_axi_wdata  (icache_axi_wdata),
    .s_axi_wstrb  (icache_axi_wstrb),
    .s_axi_wlast  (icache_axi_wlast),
    .s_axi_wvalid (icache_axi_wvalid),
    .s_axi_wready (icache_axi_wready),
    .s_axi_bid    (icache_axi_bid),
    .s_axi_bresp  (icache_axi_bresp),
    .s_axi_bvalid (icache_axi_bvalid),
    .s_axi_bready (icache_axi_bready),
    .s_axi_arid   (icache_axi_arid),
    .s_axi_araddr (icache_axi_araddr),
    .s_axi_arlen  (icache_axi_arlen),
    .s_axi_arsize (icache_axi_arsize),
    .s_axi_arburst(icache_axi_arburst),
    .s_axi_arlock (1'b0),
    .s_axi_arcache(4'b0),
    .s_axi_arprot (3'b0),
    .s_axi_arvalid(icache_axi_arvalid),
    .s_axi_arready(icache_axi_arready),
    .s_axi_rid    (icache_axi_rid),
    .s_axi_rdata  (icache_axi_rdata),
    .s_axi_rresp  (icache_axi_rresp),
    .s_axi_rlast  (icache_axi_rlast),
    .s_axi_rvalid (icache_axi_rvalid),
    .s_axi_rready (icache_axi_rready)
  );


  reg [`CPU_WIDTH-1:0] mem[(2**6)-1:0];
  integer i, j;

  initial begin
    // two nested loops for smaller number of iterations per loop
    // workaround for synthesizer complaints about large loop counts
    for (i = 0; i < 2 ** 6; i = i + 2 ** (6 / 2)) begin
      for (j = i; j < i + 2 ** (6 / 2); j = j + 1) begin
        mem[j] = j;
      end
    end
  end

  reg init = 0;
  always @(posedge clock) begin
    assume (reset == !init);
    if (init) begin
      if (icache_axi_rvalid && icache_axi_rready && icache_axi_rlast && icache_axi_arlen == 8'b0) begin
        r_assert : assert (icache_axi_rdata == mem[icache_axi_araddr>>2]);
      end
    end
    init <= 1;
  end

endmodule
