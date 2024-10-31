`include "defines.vh"
module exu (
  input      [    `CPU_WIDTH-1:0] i_pc,
  input      [    `CPU_WIDTH-1:0] i_rs1,
  input      [    `CPU_WIDTH-1:0] i_rs2,
  input      [    `CPU_WIDTH-1:0] i_imm,
  input      [`EXU_SEL_WIDTH-1:0] i_src_sel,
  input      [`EXU_OPT_WIDTH-1:0] i_opt,
  input                           i_sysins,
  input      [    `CPU_WIDTH-1:0] i_csrs,
  input      [`CSR_OPT_WIDTH-1:0] i_csr_opt,
  input                           i_csr_src,
  output reg [    `CPU_WIDTH-1:0] o_exu_res,
  output                          o_zero,
  output     [    `CPU_WIDTH-1:0] o_csrd,
  //handshake
  input                           i_pre_valid,
  output                          o_pre_ready,
  output                          o_post_valid,
  input                           i_post_ready
);

  wire [`CPU_WIDTH-1:0] sys_rs1, sys_csr, sys_csrres, sys_rdres;

  assign sys_rs1 = (i_csr_src == `CSR_SEL_IMM) ? i_imm : i_rs1;
  assign sys_csr = i_csrs;

  // cal sys_rdres :
  MuxKeyWithDefault #(1 << `CSR_OPT_WIDTH, `CSR_OPT_WIDTH, `CPU_WIDTH) mux_sys_rdres (
    sys_rdres,
    i_csr_opt,
    `CPU_WIDTH'b0,
    {`CSR_NOP, `CPU_WIDTH'b0, `CSR_RW, sys_csr, `CSR_RS, sys_csr, `CSR_RC, sys_csr}
  );

  // cal sys_csrres :
  MuxKeyWithDefault #(1 << `CSR_OPT_WIDTH, `CSR_OPT_WIDTH, `CPU_WIDTH) mux_sys_csrres (
    sys_csrres,
    i_csr_opt,
    `CPU_WIDTH'b0,
    {
      `CSR_NOP,
      `CPU_WIDTH'b0,
      `CSR_RW,
      sys_rs1,
      `CSR_RS,
      sys_csr | sys_rs1,
      `CSR_RC,
      sys_csr & ~sys_rs1
    }
  );

  wire [`CPU_WIDTH-1:0] src1, src2;

  MuxKeyWithDefault #(1 << `EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src1 (
    src1,
    i_src_sel,
    `CPU_WIDTH'b0,
    {`EXU_SEL_REG, i_rs1, `EXU_SEL_IMM, i_rs1, `EXU_SEL_PC4, i_pc, `EXU_SEL_PCI, i_pc}
  );

  MuxKeyWithDefault #(1 << `EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src2 (
    src2,
    i_src_sel,
    `CPU_WIDTH'b0,
    {`EXU_SEL_REG, i_rs2, `EXU_SEL_IMM, i_imm, `EXU_SEL_PC4, `CPU_WIDTH'h4, `EXU_SEL_PCI, i_imm}
  );

  // 请记住：硬件中不区分有符号和无符号，全部按照补码进行运算！
  // 所以 src1 - src2 得到是补码！ 如果src1和src2是有符号数，通过输出最高位就可以判断正负！
  // 如果src1和src2是无符号数，那么就在最高位补0，拓展为有符号数再减法，通过最高位判断正负！
  reg  [`EXU_OPT_WIDTH-1:0] alu_opt;
  wire [    `CPU_WIDTH-1:0] alu_res;
  wire                      sububit;  // use for sltu,bltu,bgeu
  wire                      less;
  assign less = src2=={1'b1, {(`CPU_WIDTH-1){1'b0}}} ? 0 : src1=={1'b1, {(`CPU_WIDTH-1){1'b0}}} ? 1 : ~src1[`CPU_WIDTH-1]&src2[`CPU_WIDTH-1] ? 0 : src1[`CPU_WIDTH-1]&~src2[`CPU_WIDTH-1] ? 1 : alu_res[`CPU_WIDTH-1];
  reg [`CPU_WIDTH-1:0] int_res;

  always @(*) begin
    case (i_opt)
      `EXU_SLT: begin
        alu_opt                 = `ALU_SUB;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = less;
      end
      `EXU_SLTU: begin
        alu_opt                 = `ALU_SUBU;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = sububit;
      end
      `EXU_BEQ: begin
        alu_opt                 = `ALU_SUB;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = ~(|alu_res);
      end
      `EXU_BNE: begin
        alu_opt                 = `ALU_SUB;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = (|alu_res);
      end
      `EXU_BLT: begin
        alu_opt                 = `ALU_SUB;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = less;
      end
      `EXU_BGE: begin
        alu_opt                 = `ALU_SUB;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = ~less;
      end
      `EXU_BLTU: begin
        alu_opt                 = `ALU_SUBU;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = sububit;
      end
      `EXU_BGEU: begin
        alu_opt                 = `ALU_SUBU;
        int_res[`CPU_WIDTH-1:1] = 0;
        int_res[0]              = ~sububit;
      end
      default: begin
        alu_opt = i_opt;
        int_res = alu_res;
      end
    endcase
  end

  alu u_alu (
    .i_src1   (src1),
    .i_src2   (src2),
    .i_opt    (alu_opt),
    .o_alu_res(alu_res),
    .o_sububit(sububit)
  );

  assign o_zero = ~(|int_res);

  assign o_exu_res = i_sysins ? sys_rdres : int_res;
  assign o_csrd = sys_csrres;


  assign o_pre_ready = i_post_ready;
  assign o_post_valid = i_pre_valid;

endmodule
