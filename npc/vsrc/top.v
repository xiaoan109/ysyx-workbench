`include "defines.vh"
module top (
  input                   clock,
  input                   reset
  `ifdef YSYXSOC
  ,
  input                   io_master_awready,
  output                  io_master_awvalid,
  output [`CPU_WIDTH-1:0] io_master_awaddr,
  output [           3:0] io_master_awid,
  output [           7:0] io_master_awlen,
  output [           2:0] io_master_awsize,
  output [           1:0] io_master_awburst,
  input                   io_master_wready,
  output                  io_master_wvalid,
  output [`CPU_WIDTH-1:0] io_master_wdata,
  output [           3:0] io_master_wstrb,
  output                  io_master_wlast,
  output                  io_master_bready,
  input                   io_master_bvalid,
  input  [           1:0] io_master_bresp,
  input  [           3:0] io_master_bid,
  input                   io_master_arready,
  output                  io_master_arvalid,
  output [`CPU_WIDTH-1:0] io_master_araddr,
  output [           3:0] io_master_arid,
  output [           7:0] io_master_arlen,
  output [           2:0] io_master_arsize,
  output [           1:0] io_master_arburst,
  output                  io_master_rready,
  input                   io_master_rvalid,
  input  [           1:0] io_master_rresp,
  input  [`CPU_WIDTH-1:0] io_master_rdata,
  input                   io_master_rlast,
  input  [           3:0] io_master_rid
`endif
);

  //1.rst : ////////////////////////////////////////////////////////
  wire rst_n_sync;
  stdrst u_stdrst (
    .i_clk       (clock),
    .i_rst_n     (!reset),
    .o_rst_n_sync(rst_n_sync)
  );

  //2.cpu:  /////////////////////////////////////////////////
  wire [`INS_WIDTH-1:0] instr;  // ifu -> idu.
  wire [`CPU_WIDTH-1:0] pc;  // pcu -> ifu.
  wire [`REG_ADDRW-1:0] rs1id, rs2id;  // idu -> reg.
  wire [`EXU_OPT_WIDTH-1:0] exu_opt;  // idu -> exu.
  wire [`EXU_SEL_WIDTH-1:0] exu_src_sel;  // idu -> exu.
  wire [`LSU_OPT_WIDTH-1:0] lsu_opt;  // idu -> lsu.

  wire [`CPU_WIDTH-1:0] rs1, rs2, imm;  // reg -> exu.

  wire [`CPU_WIDTH-1:0] exu_res;  // exu -> lsu/wbu.
  wire [`CPU_WIDTH-1:0] lsu_res;  // lsu -> wbu.

  wire                  zero;  // exu -> pcu.
  wire brch, jal, jalr;  // idu -> pcu.

  wire [`CPU_WIDTH-1:0] rd;  // wbu -> reg.
  wire [`REG_ADDRW-1:0] idu_rdid;  // idu -> wbu.
  wire [`REG_ADDRW-1:0] wbu_rdid;  //wbu ->reg.
  wire idu_rdwen;  // idu -> wbu.
  wire wbu_rdwen;  //wbu ->reg.

  wire a0zero;  // use for sim, good trap or bad trap. if a0 is zero, a0zero == 1

  wire [`CSR_ADDRW-1:0] csrsid;
  wire csrsren;
  wire [`CSR_OPT_WIDTH-1:0] excsropt;
  wire excsrsrc;
  wire [`CSR_ADDRW-1:0] idu_csrdid;
  wire [`CSR_ADDRW-1:0] wbu_csrdid;
  wire idu_csrdwen;
  wire wbu_csrdwen;
  wire sysins;
  wire mret;
  wire ecall;
  wire fence_i;

  wire [`CPU_WIDTH-1:0] csrs;
  wire [`CPU_WIDTH-1:0] exu_csrd;
  wire [`CPU_WIDTH-1:0] wbu_csrd;

  wire mepc_wen;
  wire [`CPU_WIDTH-1:0] mepc_wdata;
  wire mcause_wen;
  wire [`CPU_WIDTH-1:0] mcause_wdata;
  wire mstatus_wen;
  wire [`CPU_WIDTH-1:0] mstatus_wdata;
  wire [`CPU_WIDTH-1:0] mtvec;
  wire [`CPU_WIDTH-1:0] mstatus;
  wire [`CPU_WIDTH-1:0] mepc;

  //handshake signals
  wire ifu_valid;
  wire idu_ready;
  wire idu_valid;
  wire exu_ready;
  wire exu_valid;
  wire lsu_ready;
  wire lsu_valid;
  wire wbu_ready;

  //AXI intf
  //AW Channel
  wire ifu_axi_awready;
  wire ifu_axi_awvalid;
  wire [`CPU_WIDTH-1:0] ifu_axi_awaddr;
  wire [3:0] ifu_axi_awid;
  wire [7:0] ifu_axi_awlen;
  wire [2:0] ifu_axi_awsize;
  wire [1:0] ifu_axi_awburst;

  //W Channel
  wire ifu_axi_wready;
  wire ifu_axi_wvalid;
  wire [`CPU_WIDTH-1:0] ifu_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] ifu_axi_wstrb;
  wire ifu_axi_wlast;
  //B Channel
  wire ifu_axi_bready;
  wire ifu_axi_bvalid;
  wire [1:0] ifu_axi_bresp;
  wire [3:0] ifu_axi_bid;
  //AR Channel
  wire ifu_axi_arready;
  wire ifu_axi_arvalid;
  wire [`CPU_WIDTH-1:0] ifu_axi_araddr;
  wire [3:0] ifu_axi_arid;
  wire [7:0] ifu_axi_arlen;
  wire [2:0] ifu_axi_arsize;
  wire [1:0] ifu_axi_arburst;
  //R Channel
  wire ifu_axi_rready;
  wire ifu_axi_rvalid;
  wire [1:0] ifu_axi_rresp;
  wire [`CPU_WIDTH-1:0] ifu_axi_rdata;
  wire ifu_axi_rlast;
  wire [3:0] ifu_axi_rid;

  //AW Channel
  wire lsu_axi_awready;
  wire lsu_axi_awvalid;
  wire [`CPU_WIDTH-1:0] lsu_axi_awaddr;
  wire [3:0] lsu_axi_awid;
  wire [7:0] lsu_axi_awlen;
  wire [2:0] lsu_axi_awsize;
  wire [1:0] lsu_axi_awburst;

  //W Channel
  wire lsu_axi_wready;
  wire lsu_axi_wvalid;
  wire [`CPU_WIDTH-1:0] lsu_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] lsu_axi_wstrb;
  wire lsu_axi_wlast;
  //B Channel
  wire lsu_axi_bready;
  wire lsu_axi_bvalid;
  wire [1:0] lsu_axi_bresp;
  wire [3:0] lsu_axi_bid;
  //AR Channel
  wire lsu_axi_arready;
  wire lsu_axi_arvalid;
  wire [`CPU_WIDTH-1:0] lsu_axi_araddr;
  wire [3:0] lsu_axi_arid;
  wire [7:0] lsu_axi_arlen;
  wire [2:0] lsu_axi_arsize;
  wire [1:0] lsu_axi_arburst;
  //R Channel
  wire lsu_axi_rready;
  wire lsu_axi_rvalid;
  wire [1:0] lsu_axi_rresp;
  wire [`CPU_WIDTH-1:0] lsu_axi_rdata;
  wire lsu_axi_rlast;
  wire [3:0] lsu_axi_rid;

  //AW Channel
  wire mem_axi_awready;
  wire mem_axi_awvalid;
  wire [`CPU_WIDTH-1:0] mem_axi_awaddr;
  wire [3:0] mem_axi_awid;
  wire [7:0] mem_axi_awlen;
  wire [2:0] mem_axi_awsize;
  wire [1:0] mem_axi_awburst;
  //W Channel
  wire mem_axi_wready;
  wire mem_axi_wvalid;
  wire [`CPU_WIDTH-1:0] mem_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] mem_axi_wstrb;
  wire mem_axi_wlast;
  //B Channel
  wire mem_axi_bready;
  wire mem_axi_bvalid;
  wire [1:0] mem_axi_bresp;
  wire [3:0] mem_axi_bid;
  //AR Channel
  wire mem_axi_arready;
  wire mem_axi_arvalid;
  wire [`CPU_WIDTH-1:0] mem_axi_araddr;
  wire [3:0] mem_axi_arid;
  wire [7:0] mem_axi_arlen;
  wire [2:0] mem_axi_arsize;
  wire [1:0] mem_axi_arburst;
  //R Channel
  wire mem_axi_rready;
  wire mem_axi_rvalid;
  wire [1:0] mem_axi_rresp;
  wire [`CPU_WIDTH-1:0] mem_axi_rdata;
  wire mem_axi_rlast;
  wire [3:0] mem_axi_rid;


  //AW Channel
  wire clint_axi_awready;
  wire clint_axi_awvalid;
  wire [`CPU_WIDTH-1:0] clint_axi_awaddr;
  wire [3:0] clint_axi_awid;
  wire [7:0] clint_axi_awlen;
  wire [2:0] clint_axi_awsize;
  wire [1:0] clint_axi_awburst;
  //W Channel
  wire clint_axi_wready;
  wire clint_axi_wvalid;
  wire [`CPU_WIDTH-1:0] clint_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] clint_axi_wstrb;
  wire clint_axi_wlast;
  //B Channel
  wire clint_axi_bready;
  wire clint_axi_bvalid;
  wire [1:0] clint_axi_bresp;
  wire [3:0] clint_axi_bid;
  //AR Channel
  wire clint_axi_arready;
  wire clint_axi_arvalid;
  wire [`CPU_WIDTH-1:0] clint_axi_araddr;
  wire [3:0] clint_axi_arid;
  wire [7:0] clint_axi_arlen;
  wire [2:0] clint_axi_arsize;
  wire [1:0] clint_axi_arburst;
  //R Channel
  wire clint_axi_rready;
  wire clint_axi_rvalid;
  wire [1:0] clint_axi_rresp;
  wire [`CPU_WIDTH-1:0] clint_axi_rdata;
  wire clint_axi_rlast;
  wire [3:0] clint_axi_rid;

  //AW Channel
  wire clint_axil_awready;
  wire clint_axil_awvalid;
  wire [`CPU_WIDTH-1:0] clint_axil_awaddr;
  //W Channel
  wire clint_axil_wready;
  wire clint_axil_wvalid;
  wire [`CPU_WIDTH-1:0] clint_axil_wdata;
  wire [`CPU_WIDTH/8-1:0] clint_axil_wstrb;
  //B Channel
  wire clint_axil_bready;
  wire clint_axil_bvalid;
  wire [1:0] clint_axil_bresp;
  //AR Channel
  wire clint_axil_arready;
  wire clint_axil_arvalid;
  wire [`CPU_WIDTH-1:0] clint_axil_araddr;
  //R Channel
  wire clint_axil_rready;
  wire clint_axil_rvalid;
  wire [1:0] clint_axil_rresp;
  wire [`CPU_WIDTH-1:0] clint_axil_rdata;


  //AW Channel
  wire ifu2icache_axi_awready;
  wire ifu2icache_axi_awvalid;
  wire [`CPU_WIDTH-1:0] ifu2icache_axi_awaddr;
  wire [3:0] ifu2icache_axi_awid;
  wire [7:0] ifu2icache_axi_awlen;
  wire [2:0] ifu2icache_axi_awsize;
  wire [1:0] ifu2icache_axi_awburst;
  //W Channel
  wire ifu2icache_axi_wready;
  wire ifu2icache_axi_wvalid;
  wire [`CPU_WIDTH-1:0] ifu2icache_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] ifu2icache_axi_wstrb;
  wire ifu2icache_axi_wlast;
  //B Channel
  wire ifu2icache_axi_bready;
  wire ifu2icache_axi_bvalid;
  wire [1:0] ifu2icache_axi_bresp;
  wire [3:0] ifu2icache_axi_bid;
  //AR Channel
  wire ifu2icache_axi_arready;
  wire ifu2icache_axi_arvalid;
  wire [`CPU_WIDTH-1:0] ifu2icache_axi_araddr;
  wire [3:0] ifu2icache_axi_arid;
  wire [7:0] ifu2icache_axi_arlen;
  wire [2:0] ifu2icache_axi_arsize;
  wire [1:0] ifu2icache_axi_arburst;
  //R Channel
  wire ifu2icache_axi_rready;
  wire ifu2icache_axi_rvalid;
  wire [1:0] ifu2icache_axi_rresp;
  wire [`CPU_WIDTH-1:0] ifu2icache_axi_rdata;
  wire ifu2icache_axi_rlast;
  wire [3:0] ifu2icache_axi_rid;



  //AW Channel
  wire ifu2mem_axi_awready;
  wire ifu2mem_axi_awvalid;
  wire [`CPU_WIDTH-1:0] ifu2mem_axi_awaddr;
  wire [3:0] ifu2mem_axi_awid;
  wire [7:0] ifu2mem_axi_awlen;
  wire [2:0] ifu2mem_axi_awsize;
  wire [1:0] ifu2mem_axi_awburst;
  //W Channel
  wire ifu2mem_axi_wready;
  wire ifu2mem_axi_wvalid;
  wire [`CPU_WIDTH-1:0] ifu2mem_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] ifu2mem_axi_wstrb;
  wire ifu2mem_axi_wlast;
  //B Channel
  wire ifu2mem_axi_bready;
  wire ifu2mem_axi_bvalid;
  wire [1:0] ifu2mem_axi_bresp;
  wire [3:0] ifu2mem_axi_bid;
  //AR Channel
  wire ifu2mem_axi_arready;
  wire ifu2mem_axi_arvalid;
  wire [`CPU_WIDTH-1:0] ifu2mem_axi_araddr;
  wire [3:0] ifu2mem_axi_arid;
  wire [7:0] ifu2mem_axi_arlen;
  wire [2:0] ifu2mem_axi_arsize;
  wire [1:0] ifu2mem_axi_arburst;
  //R Channel
  wire ifu2mem_axi_rready;
  wire ifu2mem_axi_rvalid;
  wire [1:0] ifu2mem_axi_rresp;
  wire [`CPU_WIDTH-1:0] ifu2mem_axi_rdata;
  wire ifu2mem_axi_rlast;
  wire [3:0] ifu2mem_axi_rid;


  //AW Channel
  wire icache_axi_awready;
  wire icache_axi_awvalid;
  wire [`CPU_WIDTH-1:0] icache_axi_awaddr;
  wire [3:0] icache_axi_awid;
  wire [7:0] icache_axi_awlen;
  wire [2:0] icache_axi_awsize;
  wire [1:0] icache_axi_awburst;
  //W Channel
  wire icache_axi_wready;
  wire icache_axi_wvalid;
  wire [`CPU_WIDTH-1:0] icache_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] icache_axi_wstrb;
  wire icache_axi_wlast;
  //B Channel
  wire icache_axi_bready;
  wire icache_axi_bvalid;
  wire [1:0] icache_axi_bresp;
  wire [3:0] icache_axi_bid;
  //AR Channel
  wire icache_axi_arready;
  wire icache_axi_arvalid;
  wire [`CPU_WIDTH-1:0] icache_axi_araddr;
  wire [3:0] icache_axi_arid;
  wire [7:0] icache_axi_arlen;
  wire [2:0] icache_axi_arsize;
  wire [1:0] icache_axi_arburst;
  //R Channel
  wire icache_axi_rready;
  wire icache_axi_rvalid;
  wire [1:0] icache_axi_rresp;
  wire [`CPU_WIDTH-1:0] icache_axi_rdata;
  wire icache_axi_rlast;
  wire [3:0] icache_axi_rid;


`ifndef YSYXSOC
  //AW Channel
  wire                    uart_axi_awready;
  wire                    uart_axi_awvalid;
  wire [  `CPU_WIDTH-1:0] uart_axi_awaddr;
  wire [             3:0] uart_axi_awid;
  wire [             7:0] uart_axi_awlen;
  wire [             2:0] uart_axi_awsize;
  wire [             1:0] uart_axi_awburst;
  //W Channel
  wire                    uart_axi_wready;
  wire                    uart_axi_wvalid;
  wire [  `CPU_WIDTH-1:0] uart_axi_wdata;
  wire [`CPU_WIDTH/8-1:0] uart_axi_wstrb;
  wire                    uart_axi_wlast;
  //B Channel
  wire                    uart_axi_bready;
  wire                    uart_axi_bvalid;
  wire [             1:0] uart_axi_bresp;
  wire [             3:0] uart_axi_bid;
  //AR Channel
  wire                    uart_axi_arready;
  wire                    uart_axi_arvalid;
  wire [  `CPU_WIDTH-1:0] uart_axi_araddr;
  wire [             3:0] uart_axi_arid;
  wire [             7:0] uart_axi_arlen;
  wire [             2:0] uart_axi_arsize;
  wire [             1:0] uart_axi_arburst;
  //R Channel
  wire                    uart_axi_rready;
  wire                    uart_axi_rvalid;
  wire [             1:0] uart_axi_rresp;
  wire [  `CPU_WIDTH-1:0] uart_axi_rdata;
  wire                    uart_axi_rlast;
  wire [             3:0] uart_axi_rid;

  //AW Channel
  wire                    uart_axil_awready;
  wire                    uart_axil_awvalid;
  wire [  `CPU_WIDTH-1:0] uart_axil_awaddr;
  //W Channel
  wire                    uart_axil_wready;
  wire                    uart_axil_wvalid;
  wire [  `CPU_WIDTH-1:0] uart_axil_wdata;
  wire [`CPU_WIDTH/8-1:0] uart_axil_wstrb;
  //B Channel
  wire                    uart_axil_bready;
  wire                    uart_axil_bvalid;
  wire [             1:0] uart_axil_bresp;
  //AR Channel
  wire                    uart_axil_arready;
  wire                    uart_axil_arvalid;
  wire [  `CPU_WIDTH-1:0] uart_axil_araddr;
  //R Channel
  wire                    uart_axil_rready;
  wire                    uart_axil_rvalid;
  wire [             1:0] uart_axil_rresp;
  wire [  `CPU_WIDTH-1:0] uart_axil_rdata;
`endif


  // AXI BUS Access Fault Monitor
  wire ifu_access_fault;
  wire lsu_access_fault;



  regfile u_regfile (
    .i_clk   (clock),
    .i_wen   (wbu_rdwen),
    .i_waddr (wbu_rdid),
    .i_wdata (rd),
    .i_raddr1(rs1id),
    .i_raddr2(rs2id),
    .o_rdata1(rs1),
    .o_rdata2(rs2),
    .s_a0zero(a0zero)
  );

  csrfile u_csrfile (
    .i_clk          (clock),
    .i_rst_n        (rst_n_sync),
    .i_ren          (csrsren),
    .i_raddr        (csrsid),
    .o_rdata        (csrs),
    .i_wen          (wbu_csrdwen),
    .i_waddr        (wbu_csrdid),
    .i_wdata        (wbu_csrd),
    .i_mepc_wen     (mepc_wen),       // ecall
    .i_mepc_wdata   (mepc_wdata),     // ecall
    .i_mcause_wen   (mcause_wen),     // ecall
    .i_mcause_wdata (mcause_wdata),   // ecall
    .i_mstatus_wen  (mstatus_wen),    // ecall
    .i_mstatus_wdata(mstatus_wdata),  // ecall
    .o_mtvec        (mtvec),          // ecall
    .o_mstatus      (mstatus),        // ecall
    .o_mepc         (mepc)            // mret
  );

  ifu u_ifu (
    .i_clk       (clock),
    .i_rst_n     (rst_n_sync),
    .i_pc        (pc),
    .o_instr     (instr),
    .o_post_valid(ifu_valid),
    .i_post_ready(idu_ready),
    .awready     (ifu_axi_awready),
    .awvalid     (ifu_axi_awvalid),
    .awaddr      (ifu_axi_awaddr),
    .awid        (ifu_axi_awid),
    .awlen       (ifu_axi_awlen),
    .awsize      (ifu_axi_awsize),
    .awburst     (ifu_axi_awburst),
    .wready      (ifu_axi_wready),
    .wvalid      (ifu_axi_wvalid),
    .wdata       (ifu_axi_wdata),
    .wstrb       (ifu_axi_wstrb),
    .wlast       (ifu_axi_wlast),
    .bready      (ifu_axi_bready),
    .bvalid      (ifu_axi_bvalid),
    .bresp       (ifu_axi_bresp),
    .bid         (ifu_axi_bid),
    .arready     (ifu_axi_arready),
    .arvalid     (ifu_axi_arvalid),
    .araddr      (ifu_axi_araddr),
    .arid        (ifu_axi_arid),
    .arlen       (ifu_axi_arlen),
    .arsize      (ifu_axi_arsize),
    .arburst     (ifu_axi_arburst),
    .rready      (ifu_axi_rready),
    .rvalid      (ifu_axi_rvalid),
    .rresp       (ifu_axi_rresp),
    .rdata       (ifu_axi_rdata),
    .rlast       (ifu_axi_rlast),
    .rid         (ifu_axi_rid)
  );


  idu u_idu (
    .i_instr      (instr),
    .i_rst_n      (rst_n_sync),
    .o_rdid       (idu_rdid),
    .o_rs1id      (rs1id),
    .o_rs2id      (rs2id),
    .o_rdwen      (idu_rdwen),
    .o_imm        (imm),
    .o_exu_src_sel(exu_src_sel),
    .o_exu_opt    (exu_opt),
    .o_lsu_opt    (lsu_opt),
    .o_brch       (brch),
    .o_jal        (jal),
    .o_jalr       (jalr),
    .o_sysins     (sysins),
    .o_csrsid     (csrsid),
    .o_csrsren    (csrsren),
    .o_excsropt   (excsropt),
    .o_excsrsrc   (excsrsrc),
    .o_csrdid     (idu_csrdid),
    .o_csrdwen    (idu_csrdwen),
    .o_ecall      (ecall),
    .o_mret       (mret),
    .o_fence_i    (fence_i),
    .i_pre_valid  (ifu_valid),
    .o_pre_ready  (idu_ready),
    .o_post_valid (idu_valid),
    .i_post_ready (exu_ready)
  );

  exu u_exu (
    .i_pc        (pc),
    .i_rs1       (rs1),
    .i_rs2       (rs2),
    .i_imm       (imm),
    .i_src_sel   (exu_src_sel),
    .i_opt       (exu_opt),
    .o_exu_res   (exu_res),
    .o_zero      (zero),
    .i_sysins    (sysins),
    .i_csrs      (csrs),
    .i_csr_opt   (excsropt),
    .i_csr_src   (excsrsrc),
    .o_csrd      (exu_csrd),
    .i_pre_valid (idu_valid),
    .o_pre_ready (exu_ready),
    .o_post_valid(exu_valid),
    .i_post_ready(lsu_ready)
  );

  lsu u_lsu (
    .i_clk       (clock),
    .i_rst_n     (rst_n_sync),
    .i_opt       (lsu_opt),
    .i_addr      (exu_res),
    .i_regst     (rs2),
    .o_regld     (lsu_res),
    .i_pre_valid (exu_valid),
    .o_pre_ready (lsu_ready),
    .o_post_valid(lsu_valid),
    .i_post_ready(wbu_ready),
    .awready     (lsu_axi_awready),
    .awvalid     (lsu_axi_awvalid),
    .awaddr      (lsu_axi_awaddr),
    .awid        (lsu_axi_awid),
    .awlen       (lsu_axi_awlen),
    .awsize      (lsu_axi_awsize),
    .awburst     (lsu_axi_awburst),
    .wready      (lsu_axi_wready),
    .wvalid      (lsu_axi_wvalid),
    .wdata       (lsu_axi_wdata),
    .wstrb       (lsu_axi_wstrb),
    .wlast       (lsu_axi_wlast),
    .bready      (lsu_axi_bready),
    .bvalid      (lsu_axi_bvalid),
    .bresp       (lsu_axi_bresp),
    .bid         (lsu_axi_bid),
    .arready     (lsu_axi_arready),
    .arvalid     (lsu_axi_arvalid),
    .araddr      (lsu_axi_araddr),
    .arid        (lsu_axi_arid),
    .arlen       (lsu_axi_arlen),
    .arsize      (lsu_axi_arsize),
    .arburst     (lsu_axi_arburst),
    .rready      (lsu_axi_rready),
    .rvalid      (lsu_axi_rvalid),
    .rresp       (lsu_axi_rresp),
    .rdata       (lsu_axi_rdata),
    .rlast       (lsu_axi_rlast),
    .rid         (lsu_axi_rid)
  );

  wbu u_wbu (
    .i_clk      (clock),
    .i_rst_n    (rst_n_sync),
    .i_exu_res  (exu_res),
    .i_lsu_res  (lsu_res),
    .i_ld_en    (~lsu_opt[0]),
    .i_rdwen    (idu_rdwen),
    .i_rdid     (idu_rdid),
    .i_csrdwen  (idu_csrdwen),
    .i_csrdid   (idu_csrdid),
    .i_csrd     (exu_csrd),
    .o_rdwen    (wbu_rdwen),
    .o_rdid     (wbu_rdid),
    .o_rd       (rd),
    .o_csrdwen  (wbu_csrdwen),
    .o_csrdid   (wbu_csrdid),
    .o_csrd     (wbu_csrd),
    .i_idu_valid(idu_valid),
    .i_lsu_valid(lsu_valid),
    .i_exu_valid(exu_valid),
    .o_wbu_ready(wbu_ready)
  );

  bru u_bru (
    .i_clk             (clock),
    .i_rst_n           (rst_n_sync),
    .i_brch            (brch),
    .i_jal             (jal),
    .i_jalr            (jalr),
    .i_zero            (zero),
    .i_rs1             (rs1),
    .i_imm             (imm),
    .i_ecall           (ecall),
    .i_mret            (mret),
    .i_mtvec           (mtvec),
    .i_mepc            (mepc),
    .i_ifu_access_fault(ifu_access_fault),
    .i_lsu_access_fault(lsu_access_fault),
    .o_pc              (pc),
    .i_lsu_valid       (lsu_valid),
    .i_idu_valid       (idu_valid)
  );

  iru u_iru (
    .i_clk          (clock),
    .i_rst_n        (rst_n_sync),
    .i_pc           (pc),
    .i_ecall        (ecall),
    .i_mret         (mret),
    .i_mstatus      (mstatus),
    .o_mepc_wen     (mepc_wen),
    .o_mepc_wdata   (mepc_wdata),
    .o_mcause_wen   (mcause_wen),
    .o_mcause_wdata (mcause_wdata),
    .o_mstatus_wen  (mstatus_wen),
    .o_mstatus_wdata(mstatus_wdata),
    //handshake
    .i_idu_valid    (idu_valid),
    .i_lsu_valid    (lsu_valid)
  );

  // AXI BUS Access Fault Monitor
  axi_access_fault u_ifu_axi_access_fault (
    .i_clk       (clock),
    .i_rst_n     (rst_n_sync),
    .awready     (ifu_axi_awready),
    .awvalid     (ifu_axi_awvalid),
    .awaddr      (ifu_axi_awaddr),
    .awid        (ifu_axi_awid),
    .awlen       (ifu_axi_awlen),
    .awsize      (ifu_axi_awsize),
    .awburst     (ifu_axi_awburst),
    .wready      (ifu_axi_wready),
    .wvalid      (ifu_axi_wvalid),
    .wdata       (ifu_axi_wdata),
    .wstrb       (ifu_axi_wstrb),
    .wlast       (ifu_axi_wlast),
    .bready      (ifu_axi_bready),
    .bvalid      (ifu_axi_bvalid),
    .bresp       (ifu_axi_bresp),
    .bid         (ifu_axi_bid),
    .arready     (ifu_axi_arready),
    .arvalid     (ifu_axi_arvalid),
    .araddr      (ifu_axi_araddr),
    .arid        (ifu_axi_arid),
    .arlen       (ifu_axi_arlen),
    .arsize      (ifu_axi_arsize),
    .arburst     (ifu_axi_arburst),
    .rready      (ifu_axi_rready),
    .rvalid      (ifu_axi_rvalid),
    .rresp       (ifu_axi_rresp),
    .rdata       (ifu_axi_rdata),
    .rlast       (ifu_axi_rlast),
    .rid         (ifu_axi_rid),
    //Access Fault Out
    .access_fault(ifu_access_fault)
  );

  axi_access_fault u_lsu_axi_access_fault (
    .i_clk       (clock),
    .i_rst_n     (rst_n_sync),
    .awready     (lsu_axi_awready),
    .awvalid     (lsu_axi_awvalid),
    .awaddr      (lsu_axi_awaddr),
    .awid        (lsu_axi_awid),
    .awlen       (lsu_axi_awlen),
    .awsize      (lsu_axi_awsize),
    .awburst     (lsu_axi_awburst),
    .wready      (lsu_axi_wready),
    .wvalid      (lsu_axi_wvalid),
    .wdata       (lsu_axi_wdata),
    .wstrb       (lsu_axi_wstrb),
    .wlast       (lsu_axi_wlast),
    .bready      (lsu_axi_bready),
    .bvalid      (lsu_axi_bvalid),
    .bresp       (lsu_axi_bresp),
    .bid         (lsu_axi_bid),
    .arready     (lsu_axi_arready),
    .arvalid     (lsu_axi_arvalid),
    .araddr      (lsu_axi_araddr),
    .arid        (lsu_axi_arid),
    .arlen       (lsu_axi_arlen),
    .arsize      (lsu_axi_arsize),
    .arburst     (lsu_axi_arburst),
    .rready      (lsu_axi_rready),
    .rvalid      (lsu_axi_rvalid),
    .rresp       (lsu_axi_rresp),
    .rdata       (lsu_axi_rdata),
    .rlast       (lsu_axi_rlast),
    .rid         (lsu_axi_rid),
    //Access Fault Out
    .access_fault(lsu_access_fault)
  );


  wire ifu_slv_select;
`ifdef YSYXSOC
  localparam int unsigned NoIndices = 2;
  localparam int unsigned NoRules = 3;
  typedef logic [`CPU_WIDTH-1:0] addr_t;
  // struct to be used in the addr_decode
  typedef struct packed {
    int unsigned idx;
    addr_t       start_addr;
    addr_t       end_addr;
  } rule_t;
  //memory map 0->flash & sdram, 1->sram
  localparam rule_t [NoRules-1:0] addr_map = '{
    '{idx: 32'd1, start_addr: 32'h30000000, end_addr: 32'h40000000},
    '{idx: 32'd0, start_addr: 32'ha0000000, end_addr: 32'hc0000000},
    '{idx: 32'd1, start_addr: 32'h0f000000, end_addr: 32'h10000000}
  };
  // DUT instantiation
  addr_decode #(
    .NoIndices(NoIndices),  // number indices in rules
    .NoRules  (NoRules),    // total number of rules
    .addr_t   (addr_t),     // address type
    .rule_t   (rule_t)      // has to be overridden, see above!
  ) u_addr_decode (
    .addr_i          (ifu_slv.ar_addr),  // address to decode
    .addr_map_i      (addr_map),         // address map: rule with the highest position wins
    .idx_o           (ifu_slv_select),   // decoded index
    .dec_valid_o     (),                 // decode is valid
    .dec_error_o     (),                 // decode is not valid
    // Default index mapping enable
    .en_default_idx_i(1'b0),             // enable default port mapping
    .default_idx_i   (1'b0)              // default port index
  );
`else
  assign ifu_slv_select = 1'b1;  //no cache, dpi-c pmem
`endif

  AXI_BUS #(
    .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32),
    .AXI_ID_WIDTH  (4),
    .AXI_USER_WIDTH(0)
  ) ifu_slv;

  AXI_BUS #(
    .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32),
    .AXI_ID_WIDTH  (4),
    .AXI_USER_WIDTH(0)
  ) ifu_mst[1:0];  //mst0 -> icache, mst1 -> mem

  assign ifu_axi_awready        = ifu_slv.aw_ready;
  assign ifu_slv.aw_valid       = ifu_axi_awvalid;
  assign ifu_slv.aw_addr        = ifu_axi_awaddr;
  assign ifu_slv.aw_id          = ifu_axi_awid;
  assign ifu_slv.aw_len         = ifu_axi_awlen;
  assign ifu_slv.aw_size        = ifu_axi_awsize;
  assign ifu_slv.aw_burst       = ifu_axi_awburst;
  assign ifu_axi_wready         = ifu_slv.w_ready;
  assign ifu_slv.w_valid        = ifu_axi_wvalid;
  assign ifu_slv.w_data         = ifu_axi_wdata;
  assign ifu_slv.w_strb         = ifu_axi_wstrb;
  assign ifu_slv.w_last         = ifu_axi_wlast;
  assign ifu_slv.b_ready        = ifu_axi_bready;
  assign ifu_axi_bvalid         = ifu_slv.b_valid;
  assign ifu_axi_bresp          = ifu_slv.b_resp;
  assign ifu_axi_bid            = ifu_slv.b_id;
  assign ifu_axi_arready        = ifu_slv.ar_ready;
  assign ifu_slv.ar_valid       = ifu_axi_arvalid;
  assign ifu_slv.ar_addr        = ifu_axi_araddr;
  assign ifu_slv.ar_id          = ifu_axi_arid;
  assign ifu_slv.ar_len         = ifu_axi_arlen;
  assign ifu_slv.ar_size        = ifu_axi_arsize;
  assign ifu_slv.ar_burst       = ifu_axi_arburst;
  assign ifu_slv.r_ready        = ifu_axi_rready;
  assign ifu_axi_rvalid         = ifu_slv.r_valid;
  assign ifu_axi_rresp          = ifu_slv.r_resp;
  assign ifu_axi_rdata          = ifu_slv.r_data;
  assign ifu_axi_rlast          = ifu_slv.r_last;
  assign ifu_axi_rid            = ifu_slv.r_id;

  assign ifu_mst[0].aw_ready    = ifu2icache_axi_awready;
  assign ifu2icache_axi_awvalid = ifu_mst[0].aw_valid;
  assign ifu2icache_axi_awaddr  = ifu_mst[0].aw_addr;
  assign ifu2icache_axi_awid    = ifu_mst[0].aw_id;
  assign ifu2icache_axi_awlen   = ifu_mst[0].aw_len;
  assign ifu2icache_axi_awsize  = ifu_mst[0].aw_size;
  assign ifu2icache_axi_awburst = ifu_mst[0].aw_burst;
  assign ifu_mst[0].w_ready     = ifu2icache_axi_wready;
  assign ifu2icache_axi_wvalid  = ifu_mst[0].w_valid;
  assign ifu2icache_axi_wdata   = ifu_mst[0].w_data;
  assign ifu2icache_axi_wstrb   = ifu_mst[0].w_strb;
  assign ifu2icache_axi_wlast   = ifu_mst[0].w_last;
  assign ifu2icache_axi_bready  = ifu_mst[0].b_ready;
  assign ifu_mst[0].b_valid     = ifu2icache_axi_bvalid;
  assign ifu_mst[0].b_resp      = ifu2icache_axi_bresp;
  assign ifu_mst[0].b_id        = ifu2icache_axi_bid;
  assign ifu_mst[0].ar_ready    = ifu2icache_axi_arready;
  assign ifu2icache_axi_arvalid = ifu_mst[0].ar_valid;
  assign ifu2icache_axi_araddr  = ifu_mst[0].ar_addr;
  assign ifu2icache_axi_arid    = ifu_mst[0].ar_id;
  assign ifu2icache_axi_arlen   = ifu_mst[0].ar_len;
  assign ifu2icache_axi_arsize  = ifu_mst[0].ar_size;
  assign ifu2icache_axi_arburst = ifu_mst[0].ar_burst;
  assign ifu2icache_axi_rready  = ifu_mst[0].r_ready;
  assign ifu_mst[0].r_valid     = ifu2icache_axi_rvalid;
  assign ifu_mst[0].r_resp      = ifu2icache_axi_rresp;
  assign ifu_mst[0].r_data      = ifu2icache_axi_rdata;
  assign ifu_mst[0].r_last      = ifu2icache_axi_rlast;
  assign ifu_mst[0].r_id        = ifu2icache_axi_rid;

  assign ifu_mst[1].aw_ready    = ifu2mem_axi_awready;
  assign ifu2mem_axi_awvalid    = ifu_mst[1].aw_valid;
  assign ifu2mem_axi_awaddr     = ifu_mst[1].aw_addr;
  assign ifu2mem_axi_awid       = ifu_mst[1].aw_id;
  assign ifu2mem_axi_awlen      = ifu_mst[1].aw_len;
  assign ifu2mem_axi_awsize     = ifu_mst[1].aw_size;
  assign ifu2mem_axi_awburst    = ifu_mst[1].aw_burst;
  assign ifu_mst[1].w_ready     = ifu2mem_axi_wready;
  assign ifu2mem_axi_wvalid     = ifu_mst[1].w_valid;
  assign ifu2mem_axi_wdata      = ifu_mst[1].w_data;
  assign ifu2mem_axi_wstrb      = ifu_mst[1].w_strb;
  assign ifu2mem_axi_wlast      = ifu_mst[1].w_last;
  assign ifu2mem_axi_bready     = ifu_mst[1].b_ready;
  assign ifu_mst[1].b_valid     = ifu2mem_axi_bvalid;
  assign ifu_mst[1].b_resp      = ifu2mem_axi_bresp;
  assign ifu_mst[1].b_id        = ifu2mem_axi_bid;
  assign ifu_mst[1].ar_ready    = ifu2mem_axi_arready;
  assign ifu2mem_axi_arvalid    = ifu_mst[1].ar_valid;
  assign ifu2mem_axi_araddr     = ifu_mst[1].ar_addr;
  assign ifu2mem_axi_arid       = ifu_mst[1].ar_id;
  assign ifu2mem_axi_arlen      = ifu_mst[1].ar_len;
  assign ifu2mem_axi_arsize     = ifu_mst[1].ar_size;
  assign ifu2mem_axi_arburst    = ifu_mst[1].ar_burst;
  assign ifu2mem_axi_rready     = ifu_mst[1].r_ready;
  assign ifu_mst[1].r_valid     = ifu2mem_axi_rvalid;
  assign ifu_mst[1].r_resp      = ifu2mem_axi_rresp;
  assign ifu_mst[1].r_data      = ifu2mem_axi_rdata;
  assign ifu_mst[1].r_last      = ifu2mem_axi_rlast;
  assign ifu_mst[1].r_id        = ifu2mem_axi_rid;




  axi_demux_intf #(
    .AXI_ID_WIDTH  (4),   // Synopsys DC requires default value for params
    .ATOP_SUPPORT  (0),
    .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32),
    .AXI_USER_WIDTH(1),
    .NO_MST_PORTS  (2),
    .MAX_TRANS     (8),
    .AXI_LOOK_BITS (3),
    .UNIQUE_IDS    (0),
    .SPILL_AW      (1),
    .SPILL_W       (0),
    .SPILL_B       (0),
    .SPILL_AR      (1),
    .SPILL_R       (0)
  ) u_axi_demux (
    .clk_i          (clock),           // Clock
    .rst_ni         (rst_n_sync),      // Asynchronous reset active low
    .test_i         (1'b0),            // Testmode enable
    .slv_aw_select_i(ifu_slv_select),  // has to be stable, when aw_valid
    .slv_ar_select_i(ifu_slv_select),  // has to be stable, when ar_valid
    .slv            (ifu_slv),         // slave port
    .mst            (ifu_mst)          // master ports
  );

  axi_icache u_axi_icache (
    .i_clk         (clock),
    .i_rst_n       (rst_n_sync),
    .fence_i       (fence_i),
    .ifu_awready   (ifu_axi_awready),
    .ifu_awvalid   (ifu2icache_axi_awvalid),
    .ifu_awaddr    (ifu2icache_axi_awaddr),
    .ifu_awid      (ifu2icache_axi_awid),
    .ifu_awlen     (ifu2icache_axi_awlen),
    .ifu_awsize    (ifu2icache_axi_awsize),
    .ifu_awburst   (ifu2icache_axi_awburst),
    .ifu_wready    (ifu2icache_axi_wready),
    .ifu_wvalid    (ifu2icache_axi_wvalid),
    .ifu_wdata     (ifu2icache_axi_wdata),
    .ifu_wstrb     (ifu2icache_axi_wstrb),
    .ifu_wlast     (ifu2icache_axi_wlast),
    .ifu_bready    (ifu2icache_axi_bready),
    .ifu_bvalid    (ifu2icache_axi_bvalid),
    .ifu_bresp     (ifu2icache_axi_bresp),
    .ifu_bid       (ifu2icache_axi_bid),
    .ifu_arready   (ifu2icache_axi_arready),
    .ifu_arvalid   (ifu2icache_axi_arvalid),
    .ifu_araddr    (ifu2icache_axi_araddr),
    .ifu_arid      (ifu2icache_axi_arid),
    .ifu_arlen     (ifu2icache_axi_arlen),
    .ifu_arsize    (ifu2icache_axi_arsize),
    .ifu_arburst   (ifu2icache_axi_arburst),
    .ifu_rready    (ifu2icache_axi_rready),
    .ifu_rvalid    (ifu2icache_axi_rvalid),
    .ifu_rresp     (ifu2icache_axi_rresp),
    .ifu_rdata     (ifu2icache_axi_rdata),
    .ifu_rlast     (ifu2icache_axi_rlast),
    .ifu_rid       (ifu2icache_axi_rid),
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


`ifdef YSYXSOC
  axi_interconnect_wrap_3x2 #(
    .DATA_WIDTH    (`CPU_WIDTH),
    .ADDR_WIDTH    (`CPU_WIDTH),
    .ID_WIDTH      (4),
    .FORWARD_ID    (1),
    .M_REGIONS     (`MEM_AXI_REGION),
    .M00_BASE_ADDR (`MEM_BASE_ADDR),
    .M00_ADDR_WIDTH(`MEM_ADDR_WIDTH),
    .M01_BASE_ADDR (`CLINT_BASE_ADDR),
    .M01_ADDR_WIDTH(`CLINT_ADDR_WIDTH)
  ) u_axi_interconnect_wrap_3x2 (
    .clk             (clock),
    .rst             (!rst_n_sync),
    .s00_axi_awid    (ifu2mem_axi_awid),
    .s00_axi_awaddr  (ifu2mem_axi_awaddr),
    .s00_axi_awlen   (ifu2mem_axi_awlen),
    .s00_axi_awsize  (ifu2mem_axi_awsize),
    .s00_axi_awburst (ifu2mem_axi_awburst),
    .s00_axi_awlock  (1'b0),
    .s00_axi_awcache (4'b0),
    .s00_axi_awprot  (3'b0),
    .s00_axi_awqos   (4'b0),
    .s00_axi_awuser  (1'b0),
    .s00_axi_awvalid (ifu2mem_axi_awvalid),
    .s00_axi_awready (ifu2mem_axi_awready),
    .s00_axi_wdata   (ifu2mem_axi_wdata),
    .s00_axi_wstrb   (ifu2mem_axi_wstrb),
    .s00_axi_wlast   (ifu2mem_axi_wlast),
    .s00_axi_wuser   (1'b0),
    .s00_axi_wvalid  (ifu2mem_axi_wvalid),
    .s00_axi_wready  (ifu2mem_axi_wready),
    .s00_axi_bid     (ifu2mem_axi_bid),
    .s00_axi_bresp   (ifu2mem_axi_bresp),
    .s00_axi_buser   (),
    .s00_axi_bvalid  (ifu2mem_axi_bvalid),
    .s00_axi_bready  (ifu2mem_axi_bready),
    .s00_axi_arid    (ifu2mem_axi_arid),
    .s00_axi_araddr  (ifu2mem_axi_araddr),
    .s00_axi_arlen   (ifu2mem_axi_arlen),
    .s00_axi_arsize  (ifu2mem_axi_arsize),
    .s00_axi_arburst (ifu2mem_axi_arburst),
    .s00_axi_arlock  (1'b0),
    .s00_axi_arcache (4'b0),
    .s00_axi_arprot  (3'b0),
    .s00_axi_arqos   (4'b0),
    .s00_axi_aruser  (1'b0),
    .s00_axi_arvalid (ifu2mem_axi_arvalid),
    .s00_axi_arready (ifu2mem_axi_arready),
    .s00_axi_rid     (ifu2mem_axi_rid),
    .s00_axi_rdata   (ifu2mem_axi_rdata),
    .s00_axi_rresp   (ifu2mem_axi_rresp),
    .s00_axi_rlast   (ifu2mem_axi_rlast),
    .s00_axi_ruser   (),
    .s00_axi_rvalid  (ifu2mem_axi_rvalid),
    .s00_axi_rready  (ifu2mem_axi_rready),
    .s01_axi_awid    (icache_axi_awid),
    .s01_axi_awaddr  (icache_axi_awaddr),
    .s01_axi_awlen   (icache_axi_awlen),
    .s01_axi_awsize  (icache_axi_awsize),
    .s01_axi_awburst (icache_axi_awburst),
    .s01_axi_awlock  (1'b0),
    .s01_axi_awcache (4'b0),
    .s01_axi_awprot  (3'b0),
    .s01_axi_awqos   (4'b0),
    .s01_axi_awuser  (1'b0),
    .s01_axi_awvalid (icache_axi_awvalid),
    .s01_axi_awready (icache_axi_awready),
    .s01_axi_wdata   (icache_axi_wdata),
    .s01_axi_wstrb   (icache_axi_wstrb),
    .s01_axi_wlast   (icache_axi_wlast),
    .s01_axi_wuser   (1'b0),
    .s01_axi_wvalid  (icache_axi_wvalid),
    .s01_axi_wready  (icache_axi_wready),
    .s01_axi_bid     (icache_axi_bid),
    .s01_axi_bresp   (icache_axi_bresp),
    .s01_axi_buser   (),
    .s01_axi_bvalid  (icache_axi_bvalid),
    .s01_axi_bready  (icache_axi_bready),
    .s01_axi_arid    (icache_axi_arid),
    .s01_axi_araddr  (icache_axi_araddr),
    .s01_axi_arlen   (icache_axi_arlen),
    .s01_axi_arsize  (icache_axi_arsize),
    .s01_axi_arburst (icache_axi_arburst),
    .s01_axi_arlock  (1'b0),
    .s01_axi_arcache (4'b0),
    .s01_axi_arprot  (3'b0),
    .s01_axi_arqos   (4'b0),
    .s01_axi_aruser  (1'b0),
    .s01_axi_arvalid (icache_axi_arvalid),
    .s01_axi_arready (icache_axi_arready),
    .s01_axi_rid     (icache_axi_rid),
    .s01_axi_rdata   (icache_axi_rdata),
    .s01_axi_rresp   (icache_axi_rresp),
    .s01_axi_rlast   (icache_axi_rlast),
    .s01_axi_ruser   (),
    .s01_axi_rvalid  (icache_axi_rvalid),
    .s01_axi_rready  (icache_axi_rready),
    .s02_axi_awid    (lsu_axi_awid),
    .s02_axi_awaddr  (lsu_axi_awaddr),
    .s02_axi_awlen   (lsu_axi_awlen),
    .s02_axi_awsize  (lsu_axi_awsize),
    .s02_axi_awburst (lsu_axi_awburst),
    .s02_axi_awlock  (1'b0),
    .s02_axi_awcache (4'b0),
    .s02_axi_awprot  (3'b0),
    .s02_axi_awqos   (4'b0),
    .s02_axi_awuser  (1'b0),
    .s02_axi_awvalid (lsu_axi_awvalid),
    .s02_axi_awready (lsu_axi_awready),
    .s02_axi_wdata   (lsu_axi_wdata),
    .s02_axi_wstrb   (lsu_axi_wstrb),
    .s02_axi_wlast   (lsu_axi_wlast),
    .s02_axi_wuser   (1'b0),
    .s02_axi_wvalid  (lsu_axi_wvalid),
    .s02_axi_wready  (lsu_axi_wready),
    .s02_axi_bid     (lsu_axi_bid),
    .s02_axi_bresp   (lsu_axi_bresp),
    .s02_axi_buser   (),
    .s02_axi_bvalid  (lsu_axi_bvalid),
    .s02_axi_bready  (lsu_axi_bready),
    .s02_axi_arid    (lsu_axi_arid),
    .s02_axi_araddr  (lsu_axi_araddr),
    .s02_axi_arlen   (lsu_axi_arlen),
    .s02_axi_arsize  (lsu_axi_arsize),
    .s02_axi_arburst (lsu_axi_arburst),
    .s02_axi_arlock  (1'b0),
    .s02_axi_arcache (4'b0),
    .s02_axi_arprot  (3'b0),
    .s02_axi_arqos   (4'b0),
    .s02_axi_aruser  (1'b0),
    .s02_axi_arvalid (lsu_axi_arvalid),
    .s02_axi_arready (lsu_axi_arready),
    .s02_axi_rid     (lsu_axi_rid),
    .s02_axi_rdata   (lsu_axi_rdata),
    .s02_axi_rresp   (lsu_axi_rresp),
    .s02_axi_rlast   (lsu_axi_rlast),
    .s02_axi_ruser   (),
    .s02_axi_rvalid  (lsu_axi_rvalid),
    .s02_axi_rready  (lsu_axi_rready),
    .m00_axi_awid    (mem_axi_awid),
    .m00_axi_awaddr  (mem_axi_awaddr),
    .m00_axi_awlen   (mem_axi_awlen),
    .m00_axi_awsize  (mem_axi_awsize),
    .m00_axi_awburst (mem_axi_awburst),
    .m00_axi_awlock  (),
    .m00_axi_awcache (),
    .m00_axi_awprot  (),
    .m00_axi_awqos   (),
    .m00_axi_awregion(),
    .m00_axi_awuser  (),
    .m00_axi_awvalid (mem_axi_awvalid),
    .m00_axi_awready (mem_axi_awready),
    .m00_axi_wdata   (mem_axi_wdata),
    .m00_axi_wstrb   (mem_axi_wstrb),
    .m00_axi_wlast   (mem_axi_wlast),
    .m00_axi_wuser   (),
    .m00_axi_wvalid  (mem_axi_wvalid),
    .m00_axi_wready  (mem_axi_wready),
    .m00_axi_bid     (mem_axi_bid),
    .m00_axi_bresp   (mem_axi_bresp),
    .m00_axi_buser   (1'b0),
    .m00_axi_bvalid  (mem_axi_bvalid),
    .m00_axi_bready  (mem_axi_bready),
    .m00_axi_arid    (mem_axi_arid),
    .m00_axi_araddr  (mem_axi_araddr),
    .m00_axi_arlen   (mem_axi_arlen),
    .m00_axi_arsize  (mem_axi_arsize),
    .m00_axi_arburst (mem_axi_arburst),
    .m00_axi_arlock  (),
    .m00_axi_arcache (),
    .m00_axi_arprot  (),
    .m00_axi_arqos   (),
    .m00_axi_arregion(),
    .m00_axi_aruser  (),
    .m00_axi_arvalid (mem_axi_arvalid),
    .m00_axi_arready (mem_axi_arready),
    .m00_axi_rid     (mem_axi_rid),
    .m00_axi_rdata   (mem_axi_rdata),
    .m00_axi_rresp   (mem_axi_rresp),
    .m00_axi_rlast   (mem_axi_rlast),
    .m00_axi_ruser   (1'b0),
    .m00_axi_rvalid  (mem_axi_rvalid),
    .m00_axi_rready  (mem_axi_rready),
    .m01_axi_awid    (clint_axi_awid),
    .m01_axi_awaddr  (clint_axi_awaddr),
    .m01_axi_awlen   (clint_axi_awlen),
    .m01_axi_awsize  (clint_axi_awsize),
    .m01_axi_awburst (clint_axi_awburst),
    .m01_axi_awlock  (),
    .m01_axi_awcache (),
    .m01_axi_awprot  (),
    .m01_axi_awqos   (),
    .m01_axi_awregion(),
    .m01_axi_awuser  (),
    .m01_axi_awvalid (clint_axi_awvalid),
    .m01_axi_awready (clint_axi_awready),
    .m01_axi_wdata   (clint_axi_wdata),
    .m01_axi_wstrb   (clint_axi_wstrb),
    .m01_axi_wlast   (clint_axi_wlast),
    .m01_axi_wuser   (),
    .m01_axi_wvalid  (clint_axi_wvalid),
    .m01_axi_wready  (clint_axi_wready),
    .m01_axi_bid     (clint_axi_bid),
    .m01_axi_bresp   (clint_axi_bresp),
    .m01_axi_buser   (1'b0),
    .m01_axi_bvalid  (clint_axi_bvalid),
    .m01_axi_bready  (clint_axi_bready),
    .m01_axi_arid    (clint_axi_arid),
    .m01_axi_araddr  (clint_axi_araddr),
    .m01_axi_arlen   (clint_axi_arlen),
    .m01_axi_arsize  (clint_axi_arsize),
    .m01_axi_arburst (clint_axi_arburst),
    .m01_axi_arlock  (),
    .m01_axi_arcache (),
    .m01_axi_arprot  (),
    .m01_axi_arqos   (),
    .m01_axi_arregion(),
    .m01_axi_aruser  (),
    .m01_axi_arvalid (clint_axi_arvalid),
    .m01_axi_arready (clint_axi_arready),
    .m01_axi_rid     (clint_axi_rid),
    .m01_axi_rdata   (clint_axi_rdata),
    .m01_axi_rresp   (clint_axi_rresp),
    .m01_axi_rlast   (clint_axi_rlast),
    .m01_axi_ruser   (1'b0),
    .m01_axi_rvalid  (clint_axi_rvalid),
    .m01_axi_rready  (clint_axi_rready)
  );
`else
  axi_interconnect_wrap_3x3 #(
    .DATA_WIDTH    (`CPU_WIDTH),
    .ADDR_WIDTH    (`CPU_WIDTH),
    .ID_WIDTH      (4),
    .FORWARD_ID    (1),
    .M_REGIONS     (`MEM_AXI_REGION),
    .M00_BASE_ADDR (`MEM_BASE_ADDR),
    .M00_ADDR_WIDTH(`MEM_ADDR_WIDTH),
    .M01_BASE_ADDR (`CLINT_BASE_ADDR),
    .M01_ADDR_WIDTH(`CLINT_ADDR_WIDTH),
    .M02_BASE_ADDR (`UART_BASE_ADDR),
    .M02_ADDR_WIDTH(`UART_ADDR_WIDTH)
  ) u_axi_interconnect_wrap_3x2 (
    .clk             (clock),
    .rst             (!rst_n_sync),
    .s00_axi_awid    (ifu2mem_axi_awid),
    .s00_axi_awaddr  (ifu2mem_axi_awaddr),
    .s00_axi_awlen   (ifu2mem_axi_awlen),
    .s00_axi_awsize  (ifu2mem_axi_awsize),
    .s00_axi_awburst (ifu2mem_axi_awburst),
    .s00_axi_awlock  (1'b0),
    .s00_axi_awcache (4'b0),
    .s00_axi_awprot  (3'b0),
    .s00_axi_awqos   (4'b0),
    .s00_axi_awuser  (1'b0),
    .s00_axi_awvalid (ifu2mem_axi_awvalid),
    .s00_axi_awready (ifu2mem_axi_awready),
    .s00_axi_wdata   (ifu2mem_axi_wdata),
    .s00_axi_wstrb   (ifu2mem_axi_wstrb),
    .s00_axi_wlast   (ifu2mem_axi_wlast),
    .s00_axi_wuser   (1'b0),
    .s00_axi_wvalid  (ifu2mem_axi_wvalid),
    .s00_axi_wready  (ifu2mem_axi_wready),
    .s00_axi_bid     (ifu2mem_axi_bid),
    .s00_axi_bresp   (ifu2mem_axi_bresp),
    .s00_axi_buser   (),
    .s00_axi_bvalid  (ifu2mem_axi_bvalid),
    .s00_axi_bready  (ifu2mem_axi_bready),
    .s00_axi_arid    (ifu2mem_axi_arid),
    .s00_axi_araddr  (ifu2mem_axi_araddr),
    .s00_axi_arlen   (ifu2mem_axi_arlen),
    .s00_axi_arsize  (ifu2mem_axi_arsize),
    .s00_axi_arburst (ifu2mem_axi_arburst),
    .s00_axi_arlock  (1'b0),
    .s00_axi_arcache (4'b0),
    .s00_axi_arprot  (3'b0),
    .s00_axi_arqos   (4'b0),
    .s00_axi_aruser  (1'b0),
    .s00_axi_arvalid (ifu2mem_axi_arvalid),
    .s00_axi_arready (ifu2mem_axi_arready),
    .s00_axi_rid     (ifu2mem_axi_rid),
    .s00_axi_rdata   (ifu2mem_axi_rdata),
    .s00_axi_rresp   (ifu2mem_axi_rresp),
    .s00_axi_rlast   (ifu2mem_axi_rlast),
    .s00_axi_ruser   (),
    .s00_axi_rvalid  (ifu2mem_axi_rvalid),
    .s00_axi_rready  (ifu2mem_axi_rready),
    .s01_axi_awid    (icache_axi_awid),
    .s01_axi_awaddr  (icache_axi_awaddr),
    .s01_axi_awlen   (icache_axi_awlen),
    .s01_axi_awsize  (icache_axi_awsize),
    .s01_axi_awburst (icache_axi_awburst),
    .s01_axi_awlock  (1'b0),
    .s01_axi_awcache (4'b0),
    .s01_axi_awprot  (3'b0),
    .s01_axi_awqos   (4'b0),
    .s01_axi_awuser  (1'b0),
    .s01_axi_awvalid (icache_axi_awvalid),
    .s01_axi_awready (icache_axi_awready),
    .s01_axi_wdata   (icache_axi_wdata),
    .s01_axi_wstrb   (icache_axi_wstrb),
    .s01_axi_wlast   (icache_axi_wlast),
    .s01_axi_wuser   (1'b0),
    .s01_axi_wvalid  (icache_axi_wvalid),
    .s01_axi_wready  (icache_axi_wready),
    .s01_axi_bid     (icache_axi_bid),
    .s01_axi_bresp   (icache_axi_bresp),
    .s01_axi_buser   (),
    .s01_axi_bvalid  (icache_axi_bvalid),
    .s01_axi_bready  (icache_axi_bready),
    .s01_axi_arid    (icache_axi_arid),
    .s01_axi_araddr  (icache_axi_araddr),
    .s01_axi_arlen   (icache_axi_arlen),
    .s01_axi_arsize  (icache_axi_arsize),
    .s01_axi_arburst (icache_axi_arburst),
    .s01_axi_arlock  (1'b0),
    .s01_axi_arcache (4'b0),
    .s01_axi_arprot  (3'b0),
    .s01_axi_arqos   (4'b0),
    .s01_axi_aruser  (1'b0),
    .s01_axi_arvalid (icache_axi_arvalid),
    .s01_axi_arready (icache_axi_arready),
    .s01_axi_rid     (icache_axi_rid),
    .s01_axi_rdata   (icache_axi_rdata),
    .s01_axi_rresp   (icache_axi_rresp),
    .s01_axi_rlast   (icache_axi_rlast),
    .s01_axi_ruser   (),
    .s01_axi_rvalid  (icache_axi_rvalid),
    .s01_axi_rready  (icache_axi_rready),
    .s02_axi_awid    (lsu_axi_awid),
    .s02_axi_awaddr  (lsu_axi_awaddr),
    .s02_axi_awlen   (lsu_axi_awlen),
    .s02_axi_awsize  (lsu_axi_awsize),
    .s02_axi_awburst (lsu_axi_awburst),
    .s02_axi_awlock  (1'b0),
    .s02_axi_awcache (4'b0),
    .s02_axi_awprot  (3'b0),
    .s02_axi_awqos   (4'b0),
    .s02_axi_awuser  (1'b0),
    .s02_axi_awvalid (lsu_axi_awvalid),
    .s02_axi_awready (lsu_axi_awready),
    .s02_axi_wdata   (lsu_axi_wdata),
    .s02_axi_wstrb   (lsu_axi_wstrb),
    .s02_axi_wlast   (lsu_axi_wlast),
    .s02_axi_wuser   (1'b0),
    .s02_axi_wvalid  (lsu_axi_wvalid),
    .s02_axi_wready  (lsu_axi_wready),
    .s02_axi_bid     (lsu_axi_bid),
    .s02_axi_bresp   (lsu_axi_bresp),
    .s02_axi_buser   (),
    .s02_axi_bvalid  (lsu_axi_bvalid),
    .s02_axi_bready  (lsu_axi_bready),
    .s02_axi_arid    (lsu_axi_arid),
    .s02_axi_araddr  (lsu_axi_araddr),
    .s02_axi_arlen   (lsu_axi_arlen),
    .s02_axi_arsize  (lsu_axi_arsize),
    .s02_axi_arburst (lsu_axi_arburst),
    .s02_axi_arlock  (1'b0),
    .s02_axi_arcache (4'b0),
    .s02_axi_arprot  (3'b0),
    .s02_axi_arqos   (4'b0),
    .s02_axi_aruser  (1'b0),
    .s02_axi_arvalid (lsu_axi_arvalid),
    .s02_axi_arready (lsu_axi_arready),
    .s02_axi_rid     (lsu_axi_rid),
    .s02_axi_rdata   (lsu_axi_rdata),
    .s02_axi_rresp   (lsu_axi_rresp),
    .s02_axi_rlast   (lsu_axi_rlast),
    .s02_axi_ruser   (),
    .s02_axi_rvalid  (lsu_axi_rvalid),
    .s02_axi_rready  (lsu_axi_rready),
    .m00_axi_awid    (mem_axi_awid),
    .m00_axi_awaddr  (mem_axi_awaddr),
    .m00_axi_awlen   (mem_axi_awlen),
    .m00_axi_awsize  (mem_axi_awsize),
    .m00_axi_awburst (mem_axi_awburst),
    .m00_axi_awlock  (),
    .m00_axi_awcache (),
    .m00_axi_awprot  (),
    .m00_axi_awqos   (),
    .m00_axi_awregion(),
    .m00_axi_awuser  (),
    .m00_axi_awvalid (mem_axi_awvalid),
    .m00_axi_awready (mem_axi_awready),
    .m00_axi_wdata   (mem_axi_wdata),
    .m00_axi_wstrb   (mem_axi_wstrb),
    .m00_axi_wlast   (mem_axi_wlast),
    .m00_axi_wuser   (),
    .m00_axi_wvalid  (mem_axi_wvalid),
    .m00_axi_wready  (mem_axi_wready),
    .m00_axi_bid     (mem_axi_bid),
    .m00_axi_bresp   (mem_axi_bresp),
    .m00_axi_buser   (1'b0),
    .m00_axi_bvalid  (mem_axi_bvalid),
    .m00_axi_bready  (mem_axi_bready),
    .m00_axi_arid    (mem_axi_arid),
    .m00_axi_araddr  (mem_axi_araddr),
    .m00_axi_arlen   (mem_axi_arlen),
    .m00_axi_arsize  (mem_axi_arsize),
    .m00_axi_arburst (mem_axi_arburst),
    .m00_axi_arlock  (),
    .m00_axi_arcache (),
    .m00_axi_arprot  (),
    .m00_axi_arqos   (),
    .m00_axi_arregion(),
    .m00_axi_aruser  (),
    .m00_axi_arvalid (mem_axi_arvalid),
    .m00_axi_arready (mem_axi_arready),
    .m00_axi_rid     (mem_axi_rid),
    .m00_axi_rdata   (mem_axi_rdata),
    .m00_axi_rresp   (mem_axi_rresp),
    .m00_axi_rlast   (mem_axi_rlast),
    .m00_axi_ruser   (1'b0),
    .m00_axi_rvalid  (mem_axi_rvalid),
    .m00_axi_rready  (mem_axi_rready),
    .m01_axi_awid    (clint_axi_awid),
    .m01_axi_awaddr  (clint_axi_awaddr),
    .m01_axi_awlen   (clint_axi_awlen),
    .m01_axi_awsize  (clint_axi_awsize),
    .m01_axi_awburst (clint_axi_awburst),
    .m01_axi_awlock  (),
    .m01_axi_awcache (),
    .m01_axi_awprot  (),
    .m01_axi_awqos   (),
    .m01_axi_awregion(),
    .m01_axi_awuser  (),
    .m01_axi_awvalid (clint_axi_awvalid),
    .m01_axi_awready (clint_axi_awready),
    .m01_axi_wdata   (clint_axi_wdata),
    .m01_axi_wstrb   (clint_axi_wstrb),
    .m01_axi_wlast   (clint_axi_wlast),
    .m01_axi_wuser   (),
    .m01_axi_wvalid  (clint_axi_wvalid),
    .m01_axi_wready  (clint_axi_wready),
    .m01_axi_bid     (clint_axi_bid),
    .m01_axi_bresp   (clint_axi_bresp),
    .m01_axi_buser   (1'b0),
    .m01_axi_bvalid  (clint_axi_bvalid),
    .m01_axi_bready  (clint_axi_bready),
    .m01_axi_arid    (clint_axi_arid),
    .m01_axi_araddr  (clint_axi_araddr),
    .m01_axi_arlen   (clint_axi_arlen),
    .m01_axi_arsize  (clint_axi_arsize),
    .m01_axi_arburst (clint_axi_arburst),
    .m01_axi_arlock  (),
    .m01_axi_arcache (),
    .m01_axi_arprot  (),
    .m01_axi_arqos   (),
    .m01_axi_arregion(),
    .m01_axi_aruser  (),
    .m01_axi_arvalid (clint_axi_arvalid),
    .m01_axi_arready (clint_axi_arready),
    .m01_axi_rid     (clint_axi_rid),
    .m01_axi_rdata   (clint_axi_rdata),
    .m01_axi_rresp   (clint_axi_rresp),
    .m01_axi_rlast   (clint_axi_rlast),
    .m01_axi_ruser   (1'b0),
    .m01_axi_rvalid  (clint_axi_rvalid),
    .m01_axi_rready  (clint_axi_rready),
    .m02_axi_awid    (uart_axi_awid),
    .m02_axi_awaddr  (uart_axi_awaddr),
    .m02_axi_awlen   (uart_axi_awlen),
    .m02_axi_awsize  (uart_axi_awsize),
    .m02_axi_awburst (uart_axi_awburst),
    .m02_axi_awlock  (),
    .m02_axi_awcache (),
    .m02_axi_awprot  (),
    .m02_axi_awqos   (),
    .m02_axi_awregion(),
    .m02_axi_awuser  (),
    .m02_axi_awvalid (uart_axi_awvalid),
    .m02_axi_awready (uart_axi_awready),
    .m02_axi_wdata   (uart_axi_wdata),
    .m02_axi_wstrb   (uart_axi_wstrb),
    .m02_axi_wlast   (uart_axi_wlast),
    .m02_axi_wuser   (),
    .m02_axi_wvalid  (uart_axi_wvalid),
    .m02_axi_wready  (uart_axi_wready),
    .m02_axi_bid     (uart_axi_bid),
    .m02_axi_bresp   (uart_axi_bresp),
    .m02_axi_buser   (1'b0),
    .m02_axi_bvalid  (uart_axi_bvalid),
    .m02_axi_bready  (uart_axi_bready),
    .m02_axi_arid    (uart_axi_arid),
    .m02_axi_araddr  (uart_axi_araddr),
    .m02_axi_arlen   (uart_axi_arlen),
    .m02_axi_arsize  (uart_axi_arsize),
    .m02_axi_arburst (uart_axi_arburst),
    .m02_axi_arlock  (),
    .m02_axi_arcache (),
    .m02_axi_arprot  (),
    .m02_axi_arqos   (),
    .m02_axi_arregion(),
    .m02_axi_aruser  (),
    .m02_axi_arvalid (uart_axi_arvalid),
    .m02_axi_arready (uart_axi_arready),
    .m02_axi_rid     (uart_axi_rid),
    .m02_axi_rdata   (uart_axi_rdata),
    .m02_axi_rresp   (uart_axi_rresp),
    .m02_axi_rlast   (uart_axi_rlast),
    .m02_axi_ruser   (1'b0),
    .m02_axi_rvalid  (uart_axi_rvalid),
    .m02_axi_rready  (uart_axi_rready)
  );
`endif

  axi_axil_adapter #(
    // Width of address bus in bits
    .ADDR_WIDTH     (`CPU_WIDTH),
    // Width of input (slave) AXI interface data bus in bits
    .AXI_DATA_WIDTH (`CPU_WIDTH),
    // Width of AXI ID signal
    .AXI_ID_WIDTH   (4),
    // Width of output (master) AXI lite interface data bus in bits
    .AXIL_DATA_WIDTH(`CPU_WIDTH)
  ) u_axi_axil_adapter (
    .clk           (clock),
    .rst           (!rst_n_sync),
    .s_axi_awid    (clint_axi_awid),
    .s_axi_awaddr  (clint_axi_awaddr),
    .s_axi_awlen   (clint_axi_awlen),
    .s_axi_awsize  (clint_axi_awsize),
    .s_axi_awburst (clint_axi_awburst),
    .s_axi_awlock  (1'b0),
    .s_axi_awcache (4'b0),
    .s_axi_awprot  (3'b0),
    .s_axi_awvalid (clint_axi_awvalid),
    .s_axi_awready (clint_axi_awready),
    .s_axi_wdata   (clint_axi_wdata),
    .s_axi_wstrb   (clint_axi_wstrb),
    .s_axi_wlast   (clint_axi_wlast),
    .s_axi_wvalid  (clint_axi_wvalid),
    .s_axi_wready  (clint_axi_wready),
    .s_axi_bid     (clint_axi_bid),
    .s_axi_bresp   (clint_axi_bresp),
    .s_axi_bvalid  (clint_axi_bvalid),
    .s_axi_bready  (clint_axi_bready),
    .s_axi_arid    (clint_axi_arid),
    .s_axi_araddr  (clint_axi_araddr),
    .s_axi_arlen   (clint_axi_arlen),
    .s_axi_arsize  (clint_axi_arsize),
    .s_axi_arburst (clint_axi_arburst),
    .s_axi_arlock  (1'b0),
    .s_axi_arcache (4'b0),
    .s_axi_arprot  (3'b0),
    .s_axi_arvalid (clint_axi_arvalid),
    .s_axi_arready (clint_axi_arready),
    .s_axi_rid     (clint_axi_rid),
    .s_axi_rdata   (clint_axi_rdata),
    .s_axi_rresp   (clint_axi_rresp),
    .s_axi_rlast   (clint_axi_rlast),
    .s_axi_rvalid  (clint_axi_rvalid),
    .s_axi_rready  (clint_axi_rready),
    .m_axil_awaddr (clint_axil_awaddr),
    .m_axil_awprot (),
    .m_axil_awvalid(clint_axil_awvalid),
    .m_axil_awready(clint_axil_awready),
    .m_axil_wdata  (clint_axil_wdata),
    .m_axil_wstrb  (clint_axil_wstrb),
    .m_axil_wvalid (clint_axil_wvalid),
    .m_axil_wready (clint_axil_wready),
    .m_axil_bresp  (clint_axil_bresp),
    .m_axil_bvalid (clint_axil_bvalid),
    .m_axil_bready (clint_axil_bready),
    .m_axil_araddr (clint_axil_araddr),
    .m_axil_arprot (),
    .m_axil_arvalid(clint_axil_arvalid),
    .m_axil_arready(clint_axil_arready),
    .m_axil_rdata  (clint_axil_rdata),
    .m_axil_rresp  (clint_axil_rresp),
    .m_axil_rvalid (clint_axil_rvalid),
    .m_axil_rready (clint_axil_rready)
  );



`ifndef YSYXSOC
  axi_sram #(
    // Width of data bus in bits
    .DATA_WIDTH(`CPU_WIDTH),
    // Width of address bus in bits
    .ADDR_WIDTH(`CPU_WIDTH),
    // Width of ID signal
    .ID_WIDTH(4),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
  ) u_axi_sram (
    .clk          (clock),
    .rst          (!rst_n_sync),
    .s_axi_awid   (mem_axi_awid),
    .s_axi_awaddr (mem_axi_awaddr),
    .s_axi_awlen  (mem_axi_awlen),
    .s_axi_awsize (mem_axi_awsize),
    .s_axi_awburst(mem_axi_awburst),
    .s_axi_awlock (1'b0),
    .s_axi_awcache(4'b0),
    .s_axi_awprot (3'b0),
    .s_axi_awvalid(mem_axi_awvalid),
    .s_axi_awready(mem_axi_awready),
    .s_axi_wdata  (mem_axi_wdata),
    .s_axi_wstrb  (mem_axi_wstrb),
    .s_axi_wlast  (mem_axi_wlast),
    .s_axi_wvalid (mem_axi_wvalid),
    .s_axi_wready (mem_axi_wready),
    .s_axi_bid    (mem_axi_bid),
    .s_axi_bresp  (mem_axi_bresp),
    .s_axi_bvalid (mem_axi_bvalid),
    .s_axi_bready (mem_axi_bready),
    .s_axi_arid   (mem_axi_arid),
    .s_axi_araddr (mem_axi_araddr),
    .s_axi_arlen  (mem_axi_arlen),
    .s_axi_arsize (mem_axi_arsize),
    .s_axi_arburst(mem_axi_arburst),
    .s_axi_arlock (1'b0),
    .s_axi_arcache(4'b0),
    .s_axi_arprot (3'b0),
    .s_axi_arvalid(mem_axi_arvalid),
    .s_axi_arready(mem_axi_arready),
    .s_axi_rid    (mem_axi_rid),
    .s_axi_rdata  (mem_axi_rdata),
    .s_axi_rresp  (mem_axi_rresp),
    .s_axi_rlast  (mem_axi_rlast),
    .s_axi_rvalid (mem_axi_rvalid),
    .s_axi_rready (mem_axi_rready)
  );

  axi_axil_adapter #(
    // Width of address bus in bits
    .ADDR_WIDTH     (`CPU_WIDTH),
    // Width of input (slave) AXI interface data bus in bits
    .AXI_DATA_WIDTH (`CPU_WIDTH),
    // Width of AXI ID signal
    .AXI_ID_WIDTH   (4),
    // Width of output (master) AXI lite interface data bus in bits
    .AXIL_DATA_WIDTH(`CPU_WIDTH)
  ) u0_axi_axil_adapter (
    .clk           (clock),
    .rst           (!rst_n_sync),
    .s_axi_awid    (uart_axi_awid),
    .s_axi_awaddr  (uart_axi_awaddr),
    .s_axi_awlen   (uart_axi_awlen),
    .s_axi_awsize  (uart_axi_awsize),
    .s_axi_awburst (uart_axi_awburst),
    .s_axi_awlock  (1'b0),
    .s_axi_awcache (4'b0),
    .s_axi_awprot  (3'b0),
    .s_axi_awvalid (uart_axi_awvalid),
    .s_axi_awready (uart_axi_awready),
    .s_axi_wdata   (uart_axi_wdata),
    .s_axi_wstrb   (uart_axi_wstrb),
    .s_axi_wlast   (uart_axi_wlast),
    .s_axi_wvalid  (uart_axi_wvalid),
    .s_axi_wready  (uart_axi_wready),
    .s_axi_bid     (uart_axi_bid),
    .s_axi_bresp   (uart_axi_bresp),
    .s_axi_bvalid  (uart_axi_bvalid),
    .s_axi_bready  (uart_axi_bready),
    .s_axi_arid    (uart_axi_arid),
    .s_axi_araddr  (uart_axi_araddr),
    .s_axi_arlen   (uart_axi_arlen),
    .s_axi_arsize  (uart_axi_arsize),
    .s_axi_arburst (uart_axi_arburst),
    .s_axi_arlock  (1'b0),
    .s_axi_arcache (4'b0),
    .s_axi_arprot  (3'b0),
    .s_axi_arvalid (uart_axi_arvalid),
    .s_axi_arready (uart_axi_arready),
    .s_axi_rid     (uart_axi_rid),
    .s_axi_rdata   (uart_axi_rdata),
    .s_axi_rresp   (uart_axi_rresp),
    .s_axi_rlast   (uart_axi_rlast),
    .s_axi_rvalid  (uart_axi_rvalid),
    .s_axi_rready  (uart_axi_rready),
    .m_axil_awaddr (uart_axil_awaddr),
    .m_axil_awprot (),
    .m_axil_awvalid(uart_axil_awvalid),
    .m_axil_awready(uart_axil_awready),
    .m_axil_wdata  (uart_axil_wdata),
    .m_axil_wstrb  (uart_axil_wstrb),
    .m_axil_wvalid (uart_axil_wvalid),
    .m_axil_wready (uart_axil_wready),
    .m_axil_bresp  (uart_axil_bresp),
    .m_axil_bvalid (uart_axil_bvalid),
    .m_axil_bready (uart_axil_bready),
    .m_axil_araddr (uart_axil_araddr),
    .m_axil_arprot (),
    .m_axil_arvalid(uart_axil_arvalid),
    .m_axil_arready(uart_axil_arready),
    .m_axil_rdata  (uart_axil_rdata),
    .m_axil_rresp  (uart_axil_rresp),
    .m_axil_rvalid (uart_axil_rvalid),
    .m_axil_rready (uart_axil_rready)
  );

  axi_lite_uart u_axi_lite_uart (
    .i_clk  (clock),
    .i_rst_n(rst_n_sync),
    .awaddr (uart_axil_awaddr),
    .awvalid(uart_axil_awvalid),
    .awready(uart_axil_awready),
    .wdata  (uart_axil_wdata),
    .wstrb  (uart_axil_wstrb),
    .wvalid (uart_axil_wvalid),
    .wready (uart_axil_wready),
    .bresp  (uart_axil_bresp),
    .bvalid (uart_axil_bvalid),
    .bready (uart_axil_bready),
    .araddr (uart_axil_araddr),
    .arvalid(uart_axil_arvalid),
    .arready(uart_axil_arready),
    .rdata  (uart_axil_rdata),
    .rresp  (uart_axil_rresp),
    .rvalid (uart_axil_rvalid),
    .rready (uart_axil_rready)
  );
`else
  assign mem_axi_awready   = io_master_awready;
  assign io_master_awvalid = mem_axi_awvalid;
  assign io_master_awaddr  = mem_axi_awaddr;
  assign io_master_awid    = mem_axi_awid;
  assign io_master_awlen   = mem_axi_awlen;
  assign io_master_awsize  = mem_axi_awsize;
  assign io_master_awburst = mem_axi_awburst;
  assign mem_axi_wready    = io_master_wready;
  assign io_master_wvalid  = mem_axi_wvalid;
  assign io_master_wdata   = mem_axi_wdata;
  assign io_master_wstrb   = mem_axi_wstrb;
  assign io_master_wlast   = mem_axi_wlast;
  assign io_master_bready  = mem_axi_bready;
  assign mem_axi_bvalid    = io_master_bvalid;
  assign mem_axi_bresp     = io_master_bresp;
  assign mem_axi_bid       = io_master_bid;
  assign mem_axi_arready   = io_master_arready;
  assign io_master_arvalid = mem_axi_arvalid;
  assign io_master_araddr  = mem_axi_araddr;
  assign io_master_arid    = mem_axi_arid;
  assign io_master_arlen   = mem_axi_arlen;
  assign io_master_arsize  = mem_axi_arsize;
  assign io_master_arburst = mem_axi_arburst;
  assign io_master_rready  = mem_axi_rready;
  assign mem_axi_rvalid    = io_master_rvalid;
  assign mem_axi_rresp     = io_master_rresp;
  assign mem_axi_rdata     = io_master_rdata;
  assign mem_axi_rlast     = io_master_rlast;
  assign mem_axi_rid       = io_master_rid;
`endif

  axi_lite_clint u_axi_lite_clint (
    .i_clk  (clock),
    .i_rst_n(rst_n_sync),
    .awaddr (clint_axil_awaddr),
    .awvalid(clint_axil_awvalid),
    .awready(clint_axil_awready),
    .wdata  (clint_axil_wdata),
    .wstrb  (clint_axil_wstrb),
    .wvalid (clint_axil_wvalid),
    .wready (clint_axil_wready),
    .bresp  (clint_axil_bresp),
    .bvalid (clint_axil_bvalid),
    .bready (clint_axil_bready),
    .araddr (clint_axil_araddr),
    .arvalid(clint_axil_arvalid),
    .arready(clint_axil_arready),
    .rdata  (clint_axil_rdata),
    .rresp  (clint_axil_rresp),
    .rvalid (clint_axil_rvalid),
    .rready (clint_axil_rready)
  );


  //3.sim:  ////////////////////////////////////////////////////////
`ifndef SYNTHESIS
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function bit check_finish(input int finish_flag);
  //type 0: ifu AR Channel, 1: ifu R Channel, 2: lsu AW Channel, 3: lsu W Channel, 4: lsu B Channel, 5: lsu AR Channel, 6: lsu R Channel
  import "DPI-C" function void axi4_handshake(
    input bit valid,
    input bit ready,
    input bit last,
    input int pfc_type
  );
  import "DPI-C" function void exu_finish(input bit valid);  //TODO
  import "DPI-C" function void idu_instr_type(
    input bit valid,
    input int opcode
  );
  import "DPI-C" function void inst_start(input bit start);
  always @(*) begin
    check_rst(rst_n_sync);
    axi4_handshake(ifu_axi_arvalid, ifu_axi_arready, 1'b1, 0);
    axi4_handshake(ifu_axi_rvalid, ifu_axi_rready, ifu_axi_rlast, 1);
    axi4_handshake(lsu_axi_awvalid, lsu_axi_awready, 1'b1, 2);
    axi4_handshake(lsu_axi_wvalid, lsu_axi_wready, lsu_axi_wlast, 3);
    axi4_handshake(lsu_axi_bvalid, lsu_axi_bready, 1'b1, 4);
    axi4_handshake(lsu_axi_arvalid, lsu_axi_arready, 1'b1, 5);
    axi4_handshake(lsu_axi_rvalid, lsu_axi_rready, lsu_axi_rlast, 6);
    exu_finish(exu_valid);
    idu_instr_type(idu_valid, instr[6:0]);
    inst_start(wbu_ready);
  end
  always @(*) begin
    if (check_finish(instr)) begin  //instr =   = ebreak.
      $display("----------EBREAK: HIT [%s] TRAP!!---------------\n", a0zero ? "GOOD" : "BAD");
      $finish;
    end
  end
`endif

endmodule
