`include "defines.vh"
module iru (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_pc,
  input                   i_ecall,
  input                   i_mret,
  input  [`CPU_WIDTH-1:0] i_mstatus,
  output                  o_mepc_wen,
  output [`CPU_WIDTH-1:0] o_mepc_wdata,
  output                  o_mcause_wen,
  output [`CPU_WIDTH-1:0] o_mcause_wdata,
  output                  o_mstatus_wen,
  output [`CPU_WIDTH-1:0] o_mstatus_wdata,
  //handshake
  input                   i_idu_valid,
  input                   i_lsu_valid
);

  wire                  mepc_wen;
  wire [`CPU_WIDTH-1:0] mepc_wdata;
  wire                  mcause_wen;
  wire [`CPU_WIDTH-1:0] mcause_wdata;
  wire                  mstatus_wen;
  wire [`CPU_WIDTH-1:0] mstatus_wdata;

  stdreg #(
    .WIDTH    (1 + `CPU_WIDTH),
    .RESET_VAL({(1 + `CPU_WIDTH) {1'b0}})
  ) u_mepc_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_idu_valid),
    .i_din  ({i_ecall, i_pc}),
    .o_dout ({mepc_wen, mepc_wdata})
  );


  stdreg #(
    .WIDTH    (1 + `CPU_WIDTH),
    .RESET_VAL({(1 + `CPU_WIDTH) {1'b0}})
  ) u_mcause_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_idu_valid),
    .i_din  ({i_ecall, i_ecall ? `IRQ_ECALL : `CPU_WIDTH'b0}),
    .o_dout ({mcause_wen, mcause_wdata})
  );

  stdreg #(
    .WIDTH    (1 + `CPU_WIDTH),
    .RESET_VAL({(1 + `CPU_WIDTH) {1'b0}})
  ) u_mstatus_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_idu_valid),
    .i_din  ({i_ecall || i_mret, i_mstatus}),
    .o_dout ({mstatus_wen, mstatus_wdata})
  );



  assign o_mepc_wen = mepc_wen && i_lsu_valid;
  assign o_mepc_wdata = mepc_wdata;
  assign o_mcause_wen = mcause_wen && i_lsu_valid;
  assign o_mcause_wdata = mcause_wdata;
  assign o_mstatus_wen = mstatus_wen && i_lsu_valid;
  assign o_mstatus_wdata = mstatus_wdata;


endmodule
