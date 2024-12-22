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


`ifndef YSYXSOC
  //AW Channel
    wire                                                uart_axi_awready   ;
    wire                                                uart_axi_awvalid   ;
    wire            [`CPU_WIDTH-1:0]                    uart_axi_awaddr    ;
    wire            [3:0]                               uart_axi_awid  ;
    wire            [7:0]                               uart_axi_awlen ;
    wire            [2:0]                               uart_axi_awsize    ;
    wire            [1:0]                               uart_axi_awburst   ;
  //W Channel
    wire                                                uart_axi_wready    ;
    wire                                                uart_axi_wvalid    ;
    wire            [`CPU_WIDTH-1:0]                    uart_axi_wdata ;
    wire            [`CPU_WIDTH/8-1:0]                  uart_axi_wstrb ;
    wire                                                uart_axi_wlast ;
  //B Channel
    wire                                                uart_axi_bready    ;
    wire                                                uart_axi_bvalid    ;
    wire            [1:0]                               uart_axi_bresp ;
    wire            [3:0]                               uart_axi_bid   ;
  //AR Channel
    wire                                                uart_axi_arready   ;
    wire                                                uart_axi_arvalid   ;
    wire            [`CPU_WIDTH-1:0]                    uart_axi_araddr    ;
    wire            [3:0]                               uart_axi_arid  ;
    wire            [7:0]                               uart_axi_arlen ;
    wire            [2:0]                               uart_axi_arsize    ;
    wire            [1:0]                               uart_axi_arburst   ;
  //R Channel
    wire                                                uart_axi_rready    ;
    wire                                                uart_axi_rvalid    ;
    wire            [1:0]                               uart_axi_rresp ;
    wire            [`CPU_WIDTH-1:0]                    uart_axi_rdata ;
    wire                                                uart_axi_rlast ;
    wire            [3:0]                               uart_axi_rid   ;

  //AW Channel
    wire                                                uart_axil_awready  ;
    wire                                                uart_axil_awvalid  ;
    wire            [`CPU_WIDTH-1:0]                    uart_axil_awaddr   ;
  //W Channel
    wire                                                uart_axil_wready   ;
    wire                                                uart_axil_wvalid   ;
    wire            [`CPU_WIDTH-1:0]                    uart_axil_wdata    ;
    wire            [`CPU_WIDTH/8-1:0]                  uart_axil_wstrb    ;
  //B Channel
    wire                                                uart_axil_bready   ;
    wire                                                uart_axil_bvalid   ;
    wire            [1:0]                               uart_axil_bresp    ;
  //AR Channel
    wire                                                uart_axil_arready  ;
    wire                                                uart_axil_arvalid  ;
    wire            [`CPU_WIDTH-1:0]                    uart_axil_araddr   ;
  //R Channel
    wire                                                uart_axil_rready   ;
    wire                                                uart_axil_rvalid   ;
    wire            [1:0]                               uart_axil_rresp    ;
    wire            [`CPU_WIDTH-1:0]                    uart_axil_rdata    ;
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


  axi_interconnect #(
    // Number of AXI inputs (slave interfaces)
    .S_COUNT(`S_COUNT),
    // Number of AXI outputs (master interfaces)
    .M_COUNT(`M_COUNT),
    // Width of data bus in bits
    .DATA_WIDTH(`CPU_WIDTH),
    // Width of address bus in bits
    .ADDR_WIDTH(`CPU_WIDTH),
    // Width of ID signal
    .ID_WIDTH(4),
    // Propagate ID field
    .FORWARD_ID(1),
    // Number of regions per master interface
    .M_REGIONS(`MEM_AXI_REGION),  
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    .M_BASE_ADDR(`AXI_MASTER_BASE_ADDR),
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    .M_ADDR_WIDTH(`AXI_MASTER_ADDR_WIDTH)
  ) u_axi_interconnect (
    .clk(clock),
    .rst(!rst_n_sync),

    .s_axi_awid   ({ifu_axi_awid, lsu_axi_awid}),
    .s_axi_awaddr ({ifu_axi_awaddr, lsu_axi_awaddr}),
    .s_axi_awlen  ({ifu_axi_awlen, lsu_axi_awlen}),
    .s_axi_awsize ({ifu_axi_awsize, lsu_axi_awsize}),
    .s_axi_awburst({ifu_axi_awburst, lsu_axi_awburst}),
    .s_axi_awlock ({1'b0, 1'b0}),
    .s_axi_awcache({4'b0, 4'b0}),
    .s_axi_awprot ({3'b0, 3'b0}),
    .s_axi_awqos  ({4'b0, 4'b0}),
    .s_axi_awuser ({1'b0, 1'b0}),
    .s_axi_awvalid({ifu_axi_awvalid, lsu_axi_awvalid}),
    .s_axi_awready({ifu_axi_awready, lsu_axi_awready}),
    .s_axi_wdata  ({ifu_axi_wdata, lsu_axi_wdata}),
    .s_axi_wstrb  ({ifu_axi_wstrb, lsu_axi_wstrb}),
    .s_axi_wlast  ({ifu_axi_wlast, lsu_axi_wlast}),
    .s_axi_wuser  ({1'b0, 1'b0}),
    .s_axi_wvalid ({ifu_axi_wvalid, lsu_axi_wvalid}),
    .s_axi_wready ({ifu_axi_wready, lsu_axi_wready}),
    .s_axi_bid    ({ifu_axi_bid, lsu_axi_bid}),
    .s_axi_bresp  ({ifu_axi_bresp, lsu_axi_bresp}),
    .s_axi_buser  (),
    .s_axi_bvalid ({ifu_axi_bvalid, lsu_axi_bvalid}),
    .s_axi_bready ({ifu_axi_bready, lsu_axi_bready}),
    .s_axi_arid   ({ifu_axi_arid, lsu_axi_arid}),
    .s_axi_araddr ({ifu_axi_araddr, lsu_axi_araddr}),
    .s_axi_arlen  ({ifu_axi_arlen, lsu_axi_arlen}),
    .s_axi_arsize ({ifu_axi_arsize, lsu_axi_arsize}),
    .s_axi_arburst({ifu_axi_arburst, lsu_axi_arburst}),
    .s_axi_arlock ({1'b0, 1'b0}),
    .s_axi_arcache({4'b0, 4'b0}),
    .s_axi_arprot ({3'b0, 3'b0}),
    .s_axi_arqos  ({4'b0, 4'b0}),
    .s_axi_aruser ({1'b0, 1'b0}),
    .s_axi_arvalid({ifu_axi_arvalid, lsu_axi_arvalid}),
    .s_axi_arready({ifu_axi_arready, lsu_axi_arready}),
    .s_axi_rid    ({ifu_axi_rid, lsu_axi_rid}),
    .s_axi_rdata  ({ifu_axi_rdata, lsu_axi_rdata}),
    .s_axi_rresp  ({ifu_axi_rresp, lsu_axi_rresp}),
    .s_axi_rlast  ({ifu_axi_rlast, lsu_axi_rlast}),
    .s_axi_ruser  (),
    .s_axi_rvalid ({ifu_axi_rvalid, lsu_axi_rvalid}),
    .s_axi_rready ({ifu_axi_rready, lsu_axi_rready}),

`ifdef YSYXSOC
    .m_axi_awid    ({mem_axi_awid, clint_axi_awid}),
    .m_axi_awaddr  ({mem_axi_awaddr, clint_axi_awaddr}),
    .m_axi_awlen   ({mem_axi_awlen, clint_axi_awlen}),
    .m_axi_awsize  ({mem_axi_awsize, clint_axi_awsize}),
    .m_axi_awburst ({mem_axi_awburst, clint_axi_awburst}),
    .m_axi_awlock  (),
    .m_axi_awcache (),
    .m_axi_awprot  (),
    .m_axi_awqos   (),
    .m_axi_awregion(),
    .m_axi_awuser  (),
    .m_axi_awvalid ({mem_axi_awvalid, clint_axi_awvalid}),
    .m_axi_awready ({mem_axi_awready, clint_axi_awready}),
    .m_axi_wdata   ({mem_axi_wdata, clint_axi_wdata}),
    .m_axi_wstrb   ({mem_axi_wstrb, clint_axi_wstrb}),
    .m_axi_wlast   ({mem_axi_wlast, clint_axi_wlast}),
    .m_axi_wuser   (),
    .m_axi_wvalid  ({mem_axi_wvalid, clint_axi_wvalid}),
    .m_axi_wready  ({mem_axi_wready, clint_axi_wready}),
    .m_axi_bid     ({mem_axi_bid, clint_axi_bid}),
    .m_axi_bresp   ({mem_axi_bresp, clint_axi_bresp}),
    .m_axi_buser   (),
    .m_axi_bvalid  ({mem_axi_bvalid, clint_axi_bvalid}),
    .m_axi_bready  ({mem_axi_bready, clint_axi_bready}),
    .m_axi_arid    ({mem_axi_arid, clint_axi_arid}),
    .m_axi_araddr  ({mem_axi_araddr, clint_axi_araddr}),
    .m_axi_arlen   ({mem_axi_arlen, clint_axi_arlen}),
    .m_axi_arsize  ({mem_axi_arsize, clint_axi_arsize}),
    .m_axi_arburst ({mem_axi_arburst, clint_axi_arburst}),
    .m_axi_arlock  (),
    .m_axi_arcache (),
    .m_axi_arprot  (),
    .m_axi_arqos   (),
    .m_axi_arregion(),
    .m_axi_aruser  (),
    .m_axi_arvalid ({mem_axi_arvalid, clint_axi_arvalid}),
    .m_axi_arready ({mem_axi_arready, clint_axi_arready}),
    .m_axi_rid     ({mem_axi_rid, clint_axi_rid}),
    .m_axi_rdata   ({mem_axi_rdata, clint_axi_rdata}),
    .m_axi_rresp   ({mem_axi_rresp, clint_axi_rresp}),
    .m_axi_rlast   ({mem_axi_rlast, clint_axi_rlast}),
    .m_axi_ruser   (),
    .m_axi_rvalid  ({mem_axi_rvalid, clint_axi_rvalid}),
    .m_axi_rready  ({mem_axi_rready, clint_axi_rready})
`else
    .m_axi_awid    ({mem_axi_awid, clint_axi_awid, uart_axi_awid}),
    .m_axi_awaddr  ({mem_axi_awaddr, clint_axi_awaddr, uart_axi_awaddr}),
    .m_axi_awlen   ({mem_axi_awlen, clint_axi_awlen, uart_axi_awlen}),
    .m_axi_awsize  ({mem_axi_awsize, clint_axi_awsize, uart_axi_awsize}),
    .m_axi_awburst ({mem_axi_awburst, clint_axi_awburst, uart_axi_awburst}),
    .m_axi_awlock  (),
    .m_axi_awcache (),
    .m_axi_awprot  (),
    .m_axi_awqos   (),
    .m_axi_awregion(),
    .m_axi_awuser  (),
    .m_axi_awvalid ({mem_axi_awvalid, clint_axi_awvalid, uart_axi_awvalid}),
    .m_axi_awready ({mem_axi_awready, clint_axi_awready, uart_axi_awready}),
    .m_axi_wdata   ({mem_axi_wdata, clint_axi_wdata, uart_axi_wdata}),
    .m_axi_wstrb   ({mem_axi_wstrb, clint_axi_wstrb, uart_axi_wstrb}),
    .m_axi_wlast   ({mem_axi_wlast, clint_axi_wlast, uart_axi_wlast}),
    .m_axi_wuser   (),
    .m_axi_wvalid  ({mem_axi_wvalid, clint_axi_wvalid, uart_axi_wvalid}),
    .m_axi_wready  ({mem_axi_wready, clint_axi_wready, uart_axi_wready}),
    .m_axi_bid     ({mem_axi_bid, clint_axi_bid, uart_axi_bid}),
    .m_axi_bresp   ({mem_axi_bresp, clint_axi_bresp, uart_axi_bresp}),
    .m_axi_buser   (),
    .m_axi_bvalid  ({mem_axi_bvalid, clint_axi_bvalid, uart_axi_bvalid}),
    .m_axi_bready  ({mem_axi_bready, clint_axi_bready, uart_axi_bready}),
    .m_axi_arid    ({mem_axi_arid, clint_axi_arid, uart_axi_arid}),
    .m_axi_araddr  ({mem_axi_araddr, clint_axi_araddr, uart_axi_araddr}),
    .m_axi_arlen   ({mem_axi_arlen, clint_axi_arlen, uart_axi_arlen}),
    .m_axi_arsize  ({mem_axi_arsize, clint_axi_arsize, uart_axi_arsize}),
    .m_axi_arburst ({mem_axi_arburst, clint_axi_arburst, uart_axi_arburst}),
    .m_axi_arlock  (),
    .m_axi_arcache (),
    .m_axi_arprot  (),
    .m_axi_arqos   (),
    .m_axi_arregion(),
    .m_axi_aruser  (),
    .m_axi_arvalid ({mem_axi_arvalid, clint_axi_arvalid, uart_axi_arvalid}),
    .m_axi_arready ({mem_axi_arready, clint_axi_arready, uart_axi_arready}),
    .m_axi_rid     ({mem_axi_rid, clint_axi_rid, uart_axi_rid}),
    .m_axi_rdata   ({mem_axi_rdata, clint_axi_rdata, uart_axi_rdata}),
    .m_axi_rresp   ({mem_axi_rresp, clint_axi_rresp, uart_axi_rresp}),
    .m_axi_rlast   ({mem_axi_rlast, clint_axi_rlast, uart_axi_rlast}),
    .m_axi_ruser   (),
    .m_axi_rvalid  ({mem_axi_rvalid, clint_axi_rvalid, uart_axi_rvalid}),
    .m_axi_rready  ({mem_axi_rready, clint_axi_rready, uart_axi_rready})
  `endif
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
  import "DPI-C" function void axi4_handshake(input bit valid, input bit ready, input bit last, input int pfc_type);
  import "DPI-C" function void exu_finish(input bit valid); //TODO
  import "DPI-C" function void idu_instr_type(input bit valid, input int opcode);
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
    if (check_finish(instr)) begin  //instr =   = ebreak.
      $display("----------EBREAK: HIT [%s] TRAP!!---------------\n", a0zero ? "GOOD" : "BAD");
      $finish;
    end
  end
`endif

endmodule
