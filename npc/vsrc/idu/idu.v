`include "defines.vh"
module idu (
  input  [    `INS_WIDTH-1:0] i_instr,
  input                       i_rst_n,
  output [    `REG_ADDRW-1:0] o_rdid,         //for reg.
  output [    `REG_ADDRW-1:0] o_rs1id,        //for reg.
  output [    `REG_ADDRW-1:0] o_rs2id,        //for reg.
  output                      o_rdwen,        //for reg.
  output [    `CPU_WIDTH-1:0] o_imm,          //for exu.
  output [`EXU_SEL_WIDTH-1:0] o_exu_src_sel,  //for exu.
  output [`EXU_OPT_WIDTH-1:0] o_exu_opt,      //for exu.
  output [`LSU_OPT_WIDTH-1:0] o_lsu_opt,      //for lsu.
  output                      o_brch,         //for pcu.
  output                      o_jal,          //for pcu.
  output                      o_jalr,         //for pcu.
  // csr
  output                      o_sysins,
  output [    `CSR_ADDRW-1:0] o_csrsid,
  output                      o_csrsren,
  output [`CSR_OPT_WIDTH-1:0] o_excsropt,
  output                      o_excsrsrc,
  output [    `CSR_ADDRW-1:0] o_csrdid,
  output                      o_csrdwen,
  output                      o_ecall,
  output                      o_mret,
  //handshake
  input                       i_pre_valid,
  output                      o_pre_ready,
  output                      o_post_valid,
  input                       i_post_ready
);

  // wire [2:0] func3;
  wire [6:0] opcode;

  // assign func3 = i_instr[14:12];
  assign opcode   = i_instr[6:0];
  assign o_sysins = (opcode == `TYPE_SYS);


  //                    normal decode:  system decode:
  wire [`REG_ADDRW-1:0] nom_rs1id, sys_rs1id;
  wire [`REG_ADDRW-1:0] nom_rs2id;
  wire [`CSR_ADDRW-1:0] sys_csrsid;
  wire                  sys_csrsren;
  wire [`CPU_WIDTH-1:0] nom_imm, sys_imm;
  wire [`EXU_SEL_WIDTH-1:0] nom_exsrc;
  wire [`EXU_OPT_WIDTH-1:0] nom_exopt;
  wire                      sys_excsrsel;
  wire [`CSR_OPT_WIDTH-1:0] sys_excsropt;
  wire [`LSU_OPT_WIDTH-1:0] nom_lsu_opt;
  wire [`REG_ADDRW-1:0] nom_rdid, sys_rdid;
  wire nom_rdwen, sys_rdwen;
  wire [`CSR_ADDRW-1:0] sys_csrdid;
  wire                  sys_csrdwen;
  wire                  nom_jal;
  wire                  nom_jalr;
  wire                  nom_brch;

  idu_normal u_idu_normal (
    .i_instr      (i_instr),
    .i_rst_n      (i_rst_n),      //for sim.
    .o_rdid       (nom_rdid),     //for reg.
    .o_rs1id      (nom_rs1id),    //for reg.
    .o_rs2id      (nom_rs2id),    //for reg.
    .o_rdwen      (nom_rdwen),    //for reg.
    .o_imm        (nom_imm),      //for exu.
    .o_exu_src_sel(nom_exsrc),    //for exu.
    .o_exu_opt    (nom_exopt),    //for exu.
    .o_lsu_opt    (nom_lsu_opt),  //for lsu.
    .o_brch       (nom_brch),     //for pcu.
    .o_jal        (nom_jal),      //for pcu.
    .o_jalr       (nom_jalr)      //for pcu.
  );


  idu_system u_idu_system (
    .i_instr   (i_instr[`INS_WIDTH-1:7]),
    .o_csrsid  (sys_csrsid),
    .o_csrsren (sys_csrsren),
    .o_rs1id   (sys_rs1id),
    .o_imm     (sys_imm),
    .o_excsropt(sys_excsropt),
    .o_excsrsrc(sys_excsrsel),
    .o_rdid    (sys_rdid),
    .o_rdwen   (sys_rdwen),
    .o_csrdid  (sys_csrdid),
    .o_csrdwen (sys_csrdwen)
  );



  assign o_rs1id = o_sysins ? sys_rs1id : nom_rs1id;
  assign o_rs2id = o_sysins ? `REG_ADDRW'b0 : nom_rs2id;
  assign o_csrsid = o_sysins ? sys_csrsid : `CSR_ADDRW'b0;
  assign o_csrsren = o_sysins ? sys_csrsren : 1'b0;
  assign o_imm = o_sysins ? sys_imm : nom_imm;
  assign o_exu_src_sel = o_sysins ? `EXU_SEL_IMM : nom_exsrc;
  assign o_exu_opt = o_sysins ? `EXU_NOP : nom_exopt;
  assign o_excsropt = o_sysins ? sys_excsropt : `CSR_NOP;
  assign o_excsrsrc = o_sysins ? sys_excsrsel : `CSR_SEL_IMM;
  assign o_lsu_opt = o_sysins ? `LSU_NOP : nom_lsu_opt;  // TODO: better way to handle Load & Store
  assign o_rdid = o_sysins ? sys_rdid : nom_rdid;
  assign o_rdwen = o_sysins ? sys_rdwen : nom_rdwen;
  assign o_csrdid = o_sysins ? sys_csrdid : `CSR_ADDRW'b0;
  assign o_csrdwen = o_sysins ? sys_csrdwen : 1'b0;
  assign o_jal = o_sysins ? 1'b0 : nom_jal;
  assign o_jalr = o_sysins ? 1'b0 : nom_jalr;
  assign o_brch = o_sysins ? 1'b0 : nom_brch;


  assign o_ecall = o_sysins && !(|i_instr[31:7]);
  assign o_mret = o_sysins && !(|i_instr[31:30]) && (&i_instr[29:28]) && !(|i_instr[27:22]) && i_instr[21] && !(|i_instr[20:7]);

  assign o_pre_ready = i_post_ready;
  assign o_post_valid = i_pre_valid;


endmodule
