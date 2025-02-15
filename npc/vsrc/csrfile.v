`include "defines.vh"
module csrfile (
  input i_clk,
  input i_rst_n,

  // from idu, for csrrw/csrrs/csrrc:
  input                   i_ren,
  input  [`CSR_ADDRW-1:0] i_raddr,
  output [`CPU_WIDTH-1:0] o_rdata,

  // from idu & exu, for csrrw/csrrs/csrrc:
  input                  i_wen,
  input [`CSR_ADDRW-1:0] i_waddr,
  input [`CPU_WIDTH-1:0] i_wdata,

  // connect excp/intr:
  input                   i_mepc_wen,       // ecall / iru.
  input  [`CPU_WIDTH-1:0] i_mepc_wdata,     // ecall / iru.
  input                   i_mcause_wen,     // ecall / iru.
  input  [`CPU_WIDTH-1:0] i_mcause_wdata,   // ecall / iru.
  input                   i_mstatus_wen,    // ecall / iru.
  input  [`CPU_WIDTH-1:0] i_mstatus_wdata,  // ecall / iru.
  output [`CPU_WIDTH-1:0] o_mtvec,          // ecall / iru.
  output [`CPU_WIDTH-1:0] o_mstatus,        // ecall / iru.
  output [`CPU_WIDTH-1:0] o_mepc            // mret.
);

  // 1. csr reg file: //////////////////////////////////////////////////////////////////
  wire [`CPU_WIDTH-1:0] mepc;  // Machine exception program counter
  wire [`CPU_WIDTH-1:0] mtvec;  // Machine trap-handler base address
  wire [`CPU_WIDTH-1:0] mcause;  // Machine trap cause
  wire [`CPU_WIDTH-1:0] mstatus;  // Machine status register
  wire [`CPU_WIDTH-1:0] mvendorid;  // Machine vendor id register
  wire [`CPU_WIDTH-1:0] marchid ;  // Machine architecture id register

  // 2. read csr  reg file: ////////////////////////////////////////////////////////////
  wire ren_mepc = i_ren & (i_raddr == `ADDR_MEPC);
  wire ren_mtvec = i_ren & (i_raddr == `ADDR_MTVEC);
  wire ren_mcause = i_ren & (i_raddr == `ADDR_MCAUSE);
  wire ren_mstatus = i_ren & (i_raddr == `ADDR_MSTATUS);
  wire ren_mvendorid = i_ren & (i_raddr == `ADDR_MVENDORID);
  wire ren_marchid = i_ren & (i_raddr == `ADDR_MARCHID);

  assign o_rdata =  ren_mepc      ? mepc      : 
                  ( ren_mtvec     ? mtvec     : 
                  ( ren_mcause    ? mcause    : 
                  ( ren_mstatus   ? mstatus   : 
                  ( ren_mvendorid ? mvendorid : 
                  ( ren_marchid   ? marchid   : `CPU_WIDTH'b0)))));

  assign o_mtvec = mtvec;
  assign o_mepc = mepc;
  assign o_mstatus = mstatus;

  // 3. write csr  reg file: ////////////////////////////////////////////////////////////
  // 3.1 mepc: //////////////////////////////////////////////////////////////////////////
  wire wen_mepc = (i_wen & (i_waddr == `ADDR_MEPC)) | i_mepc_wen;
  wire [`CPU_WIDTH-1:0] wdata_mepc = i_mepc_wen ? i_mepc_wdata : i_wdata;

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mepc (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (wen_mepc),
    .i_din  (wdata_mepc),
    .o_dout (mepc)
  );

  // 3.2 mcause: //////////////////////////////////////////////////////////////////////////
  wire wen_mcause = (i_wen & (i_waddr == `ADDR_MCAUSE)) | i_mcause_wen;
  wire [`CPU_WIDTH-1:0] wdata_mcause = i_mcause_wen ? i_mcause_wdata : i_wdata;

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mcause (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (wen_mcause),
    .i_din  (wdata_mcause),
    .o_dout (mcause)
  );

  // 3.3 mtvec: //////////////////////////////////////////////////////////////////////////
  wire wen_mtvec = (i_wen & (i_waddr == `ADDR_MTVEC));
  wire [`CPU_WIDTH-1:0] wdata_mtvec = i_wdata;

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mtvec (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (wen_mtvec),
    .i_din  (wdata_mtvec),
    .o_dout (mtvec)
  );

  // 3.4 mstatus: //////////////////////////////////////////////////////////////////////////
  wire wen_mstatus = (i_wen & (i_waddr == `ADDR_MSTATUS)) | i_mstatus_wen;
  wire [`CPU_WIDTH-1:0] wdata_mstatus = i_mstatus_wen ? i_mstatus_wdata : i_wdata;

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    // .RESET_VAL(`CPU_WIDTH'h1800)
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mstatus (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (wen_mstatus),
    .i_din  (wdata_mstatus),
    .o_dout (mstatus)
  );

  // 3.5 mvendorid: //////////////////////////////////////////////////////////////////////////

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'h79737978)
  ) reg_mvendorid (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b0),
    .i_din  (`CPU_WIDTH'b0),
    .o_dout (mvendorid)
  );

  // 3.5 marchid: //////////////////////////////////////////////////////////////////////////

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'hbc614e)
  ) reg_marchid (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b0),
    .i_din  (`CPU_WIDTH'b0),
    .o_dout (marchid)
  );

  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
`ifndef SYNTHESIS
  reg [`CPU_WIDTH-1:0] sim_csr[3:0];
  always @(*) begin
    sim_csr[0] = mstatus;
    sim_csr[1] = mtvec;
    sim_csr[2] = mepc;
    sim_csr[3] = mcause;
  end
  import "DPI-C" function void set_csr_ptr(input bit [31:0] a[]);
  initial set_csr_ptr(sim_csr);
`endif

endmodule
