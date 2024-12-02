`include "defines.vh"
module top (
  input i_clk,
  input i_rst_n,
  output [`INS_WIDTH-1:0] virt_out  //virual output for synthesis
);


  //1.rst : ////////////////////////////////////////////////////////
  wire rst_n_sync;
  stdrst u_stdrst (
    .i_clk       (i_clk),
    .i_rst_n     (i_rst_n),
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

  //AXI lite mem intf
  //AW Channel
  wire [`CPU_WIDTH-1:0] ifu_awaddr;
  wire ifu_awvalid;
  wire ifu_awready;
  //W Channel
  wire [`CPU_WIDTH-1:0] ifu_wdata;
  wire [`CPU_WIDTH/8-1:0] ifu_wstrb;
  wire ifu_wvalid;
  wire ifu_wready;
  //B Channel
  wire [1:0] ifu_bresp;
  wire ifu_bvalid;
  wire ifu_bready;
  //AR Channel
  wire [`CPU_WIDTH-1:0] ifu_araddr;
  wire ifu_arvalid;
  wire ifu_arready;
  //R Channel
  wire [`CPU_WIDTH-1:0] ifu_rdata;
  wire [1:0] ifu_rresp;
  wire ifu_rvalid;
  wire ifu_rready;

  //AW Channel
  wire [`CPU_WIDTH-1:0] lsu_awaddr;
  wire lsu_awvalid;
  wire lsu_awready;
  //W Channel
  wire [`CPU_WIDTH-1:0] lsu_wdata;
  wire [`CPU_WIDTH/8-1:0] lsu_wstrb;
  wire lsu_wvalid;
  wire lsu_wready;
  //B Channel
  wire [1:0] lsu_bresp;
  wire lsu_bvalid;
  wire lsu_bready;
  //AR Channel
  wire [`CPU_WIDTH-1:0] lsu_araddr;
  wire lsu_arvalid;
  wire lsu_arready;
  //R Channel
  wire [`CPU_WIDTH-1:0] lsu_rdata;
  wire [1:0] lsu_rresp;
  wire lsu_rvalid;
  wire lsu_rready;

  //AW Channel
  wire [`CPU_WIDTH-1:0] mem_awaddr;
  wire mem_awvalid;
  wire mem_awready;
  //W Channel
  wire [`CPU_WIDTH-1:0] mem_wdata;
  wire [`CPU_WIDTH/8-1:0] mem_wstrb;
  wire mem_wvalid;
  wire mem_wready;
  //B Channel
  wire [1:0] mem_bresp;
  wire mem_bvalid;
  wire mem_bready;
  //AR Channel
  wire [`CPU_WIDTH-1:0] mem_araddr;
  wire mem_arvalid;
  wire mem_arready;
  //R Channel
  wire [`CPU_WIDTH-1:0] mem_rdata;
  wire [1:0] mem_rresp;
  wire mem_rvalid;
  wire mem_rready;


  regfile u_regfile (
    .i_clk   (i_clk),
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
    .i_clk          (i_clk),
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
    .i_clk       (i_clk),
    .i_rst_n     (rst_n_sync),
    .i_pc        (pc),
    .o_instr     (instr),
    .o_post_valid(ifu_valid),
    .i_post_ready(idu_ready),
    .awaddr      (ifu_awaddr),
    .awvalid     (ifu_awvalid),
    .awready     (ifu_awready),
    .wdata       (ifu_wdata),
    .wstrb       (ifu_wstrb),
    .wvalid      (ifu_wvalid),
    .wready      (ifu_wready),
    .bresp       (ifu_bresp),
    .bvalid      (ifu_bvalid),
    .bready      (ifu_bready),
    .araddr      (ifu_araddr),
    .arvalid     (ifu_arvalid),
    .arready     (ifu_arready),
    .rdata       (ifu_rdata),
    .rresp       (ifu_rresp),
    .rvalid      (ifu_rvalid),
    .rready      (ifu_rready)
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
    .i_clk       (i_clk),
    .i_rst_n     (rst_n_sync),
    .i_opt       (lsu_opt),
    .i_addr      (exu_res),
    .i_regst     (rs2),
    .o_regld     (lsu_res),
    .i_pre_valid (exu_valid),
    .o_pre_ready (lsu_ready),
    .o_post_valid(lsu_valid),
    .i_post_ready(wbu_ready),
    .awaddr      (lsu_awaddr),
    .awvalid     (lsu_awvalid),
    .awready     (lsu_awready),
    .wdata       (lsu_wdata),
    .wstrb       (lsu_wstrb),
    .wvalid      (lsu_wvalid),
    .wready      (lsu_wready),
    .bresp       (lsu_bresp),
    .bvalid      (lsu_bvalid),
    .bready      (lsu_bready),
    .araddr      (lsu_araddr),
    .arvalid     (lsu_arvalid),
    .arready     (lsu_arready),
    .rdata       (lsu_rdata),
    .rresp       (lsu_rresp),
    .rvalid      (lsu_rvalid),
    .rready      (lsu_rready)
  );

  wbu u_wbu (
    .i_clk      (i_clk),
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
    .i_clk      (i_clk),
    .i_rst_n    (rst_n_sync),
    .i_brch     (brch),
    .i_jal      (jal),
    .i_jalr     (jalr),
    .i_zero     (zero),
    .i_rs1      (rs1),
    .i_imm      (imm),
    .i_ecall    (ecall),
    .i_mret     (mret),
    .i_mtvec    (mtvec),
    .i_mepc     (mepc),
    .o_pc       (pc),
    .i_lsu_valid(lsu_valid),
    .i_idu_valid(idu_valid)
  );

  iru u_iru (
    .i_clk          (i_clk),
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



  axi_lite_arbiter #(
    .S_COUNT(2)
  ) u_axi_lite_arbiter (
    .i_clk    (i_clk),
    .i_rst_n  (i_rst_n),
    //Slave
    //AW Channel
    .s_awaddr ({ifu_awaddr, lsu_awaddr}),
    .s_awvalid({ifu_awvalid, lsu_awvalid}),
    .s_awready({ifu_awready, lsu_awready}),
    //W Channel
    .s_wdata  ({ifu_wdata, lsu_wdata}),
    .s_wstrb  ({ifu_wstrb, lsu_wstrb}),
    .s_wvalid ({ifu_wvalid, lsu_wvalid}),
    .s_wready ({ifu_wready, lsu_wready}),
    //B Channel
    .s_bresp  ({ifu_bresp, lsu_bresp}),
    .s_bvalid ({ifu_bvalid, lsu_bvalid}),
    .s_bready ({ifu_bready, lsu_bready}),
    //AR Channel
    .s_araddr ({ifu_araddr, lsu_araddr}),
    .s_arvalid({ifu_arvalid, lsu_arvalid}),
    .s_arready({ifu_arready, lsu_arready}),
    //R Channel
    .s_rdata  ({ifu_rdata, lsu_rdata}),
    .s_rresp  ({ifu_rresp, lsu_rresp}),
    .s_rvalid ({ifu_rvalid, lsu_rvalid}),
    .s_rready ({ifu_rready, lsu_rready}),
    //Master
    //AW Channel
    .m_awaddr (mem_awaddr),
    .m_awvalid(mem_awvalid),
    .m_awready(mem_awready),
    //W Channel
    .m_wdata  (mem_wdata),
    .m_wstrb  (mem_wstrb),
    .m_wvalid (mem_wvalid),
    .m_wready (mem_wready),
    //B Channel
    .m_bresp  (mem_bresp),
    .m_bvalid (mem_bvalid),
    .m_bready (mem_bready),
    //AR Channel
    .m_araddr (mem_araddr),
    .m_arvalid(mem_arvalid),
    .m_arready(mem_arready),
    //R Channel
    .m_rdata  (mem_rdata),
    .m_rresp  (mem_rresp),
    .m_rvalid (mem_rvalid),
    .m_rready (mem_rready)
  );

  axi_lite_sram u_axi_lite_sram (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .awaddr (mem_awaddr),
    .awvalid(mem_awvalid),
    .awready(mem_awready),
    .wdata  (mem_wdata),
    .wstrb  (mem_wstrb),
    .wvalid (mem_wvalid),
    .wready (mem_wready),
    .bresp  (mem_bresp),
    .bvalid (mem_bvalid),
    .bready (mem_bready),
    .araddr (mem_araddr),
    .arvalid(mem_arvalid),
    .arready(mem_arready),
    .rdata  (mem_rdata),
    .rresp  (mem_rresp),
    .rvalid (mem_rvalid),
    .rready (mem_rready)
  );


  //3.sim:  ////////////////////////////////////////////////////////
`ifndef SYNTHESIS
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function bit check_finish(input int finish_flag);
  always @(*) begin
    check_rst(rst_n_sync);
    if (check_finish(instr)) begin  //instr == ebreak.
      $display("@%t, \n----------EBREAK: HIT !!%s!! TRAP!!---------------\n", $time,
               a0zero ? "GOOD" : "BAD");
      $finish;
    end
  end
`endif


  assign virt_out = instr;

endmodule
