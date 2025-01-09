`include "defines.vh"
module axi_icache (
  input                     i_clk,
  input                     i_rst_n,
  //fence.i
  input                     fence_i,
  //IFU intf
  //AW Channel
  output                    ifu_awready,
  input                     ifu_awvalid,
  input  [  `CPU_WIDTH-1:0] ifu_awaddr,
  input  [             3:0] ifu_awid,
  input  [             7:0] ifu_awlen,
  input  [             2:0] ifu_awsize,
  input  [             1:0] ifu_awburst,
  //W Channel
  output                    ifu_wready,
  input                     ifu_wvalid,
  input  [  `CPU_WIDTH-1:0] ifu_wdata,
  input  [`CPU_WIDTH/8-1:0] ifu_wstrb,
  input                     ifu_wlast,
  //B Channel
  input                     ifu_bready,
  output                    ifu_bvalid,
  output [             1:0] ifu_bresp,
  output [             3:0] ifu_bid,
  //AR Channel
  output                    ifu_arready,
  input                     ifu_arvalid,
  input  [  `CPU_WIDTH-1:0] ifu_araddr,
  input  [             3:0] ifu_arid,
  input  [             7:0] ifu_arlen,
  input  [             2:0] ifu_arsize,
  input  [             1:0] ifu_arburst,
  //R Channel
  input                     ifu_rready,
  output                    ifu_rvalid,
  output [             1:0] ifu_rresp,
  output [  `CPU_WIDTH-1:0] ifu_rdata,
  output                    ifu_rlast,
  output [             3:0] ifu_rid,
  //Mem intf
  //AW Channel
  input                     icache_awready,
  output                    icache_awvalid,
  output [  `CPU_WIDTH-1:0] icache_awaddr,
  output [             3:0] icache_awid,
  output [             7:0] icache_awlen,
  output [             2:0] icache_awsize,
  output [             1:0] icache_awburst,
  //W Channel
  input                     icache_wready,
  output                    icache_wvalid,
  output [  `CPU_WIDTH-1:0] icache_wdata,
  output [`CPU_WIDTH/8-1:0] icache_wstrb,
  output                    icache_wlast,
  //B Channel
  output                    icache_bready,
  input                     icache_bvalid,
  input  [             1:0] icache_bresp,
  input  [             3:0] icache_bid,
  //AR Channel
  input                     icache_arready,
  output                    icache_arvalid,
  output [  `CPU_WIDTH-1:0] icache_araddr,
  output [             3:0] icache_arid,
  output [             7:0] icache_arlen,
  output [             2:0] icache_arsize,
  output [             1:0] icache_arburst,
  //R Channel
  output                    icache_rready,
  input                     icache_rvalid,
  input  [             1:0] icache_rresp,
  input  [  `CPU_WIDTH-1:0] icache_rdata,
  input                     icache_rlast,
  input  [             3:0] icache_rid
);

  localparam CACHELINE_SIZE = 8;  //byte(s), m = 3
  localparam CACHELINE_NUM = 16;  //n = 4
  localparam CACHELINE_SIZE_WIDTH = $clog2(CACHELINE_SIZE);
  localparam CACHELINE_NUM_WIDTH = $clog2(CACHELINE_NUM);
  localparam TAG_LSB = CACHELINE_SIZE_WIDTH + CACHELINE_NUM_WIDTH;
  localparam INDEX_MSB = TAG_LSB - 1;
  localparam INDEX_LSB = CACHELINE_SIZE_WIDTH;
  localparam OFFSET_MSB = INDEX_LSB - 1;

  typedef enum {
    idle_t,
    check_cache_t,
    mem_araddr_t,
    mem_rdata_t,
    update_array_t,
    instr_fetch_t
  } state_t;

  //cache state
  reg  [                 2:0] state_next;
  wire [                 2:0] state_reg;
  //ifu AR
  reg                         ifu_arready_next;
  wire                        ifu_arready_reg;
  //ifu R
  reg                         ifu_rvalid_next;
  // reg  [      `CPU_WIDTH-1:0] ifu_rdata_next;
  reg                         ifu_rlast_next;
  reg  [                 3:0] ifu_rid_next;
  wire                        ifu_rvalid_reg;
  reg  [      `CPU_WIDTH-1:0] ifu_rdata_reg;
  wire                        ifu_rlast_reg;
  wire [                 3:0] ifu_rid_reg;
  //read control
  reg  [                 3:0] ifu_read_id_next;
  reg  [      `CPU_WIDTH-1:0] ifu_read_addr_next;
  reg  [                 7:0] ifu_read_count_next;
  reg  [                 2:0] ifu_read_size_next;
  reg  [                 1:0] ifu_read_burst_next;
  wire [                 3:0] ifu_read_id_reg;
  wire [      `CPU_WIDTH-1:0] ifu_read_addr_reg;
  wire [                 7:0] ifu_read_count_reg;
  wire [                 2:0] ifu_read_size_reg;
  wire [                 1:0] ifu_read_burst_reg;
  //cache read
  reg                         data_rd_en;
  reg                         valid_rd_en;
  reg                         tag_rd_en;
  //cache write
  reg                         data_wr_en;
  reg                         valid_wr_en;  //set valid bit
  reg                         tag_wr_en;
  reg  [        OFFSET_MSB:0] icache_wr_offset_next;
  wire [        OFFSET_MSB:0] icache_wr_offset_reg;
  // 31    m+n m+n-1   m m-1    0
  // +---------+---------+--------+
  // |   tag   |  index  | offset |
  // +---------+---------+--------+
  reg  [`CPU_WIDTH-1:TAG_LSB] ifu_cache_tag;
  reg  [ INDEX_MSB:INDEX_LSB] ifu_cache_index;
  reg  [        OFFSET_MSB:0] ifu_cache_offset;
  reg  [`CPU_WIDTH-1:TAG_LSB] icache_tag;
  reg                         icache_valid;
  //Mem AR
  reg                         icache_arvalid_next;
  reg  [      `CPU_WIDTH-1:0] icache_araddr_next;
  reg  [                 3:0] icache_arid_next;
  reg  [                 7:0] icache_arlen_next;
  reg  [                 2:0] icache_arsize_next;
  reg  [                 1:0] icache_arburst_next;
  wire                        icache_arvalid_reg;
  wire [      `CPU_WIDTH-1:0] icache_araddr_reg;
  wire [                 3:0] icache_arid_reg;
  wire [                 7:0] icache_arlen_reg;
  wire [                 2:0] icache_arsize_reg;
  wire [                 1:0] icache_arburst_reg;
  //Mem R
  reg                         icache_rready_next;
  wire                        icache_rready_reg;
  //cache data array
  reg  [CACHELINE_SIZE*8-1:0] data_array                   [CACHELINE_NUM-1:0];
  //cache valid bits
  reg  [   CACHELINE_NUM-1:0] data_valid;
  //cache tag array
  reg  [`CPU_WIDTH-1:TAG_LSB] tag_array                    [CACHELINE_NUM-1:0];


  //IFU Write
  assign ifu_awready    = 1'b0;
  assign ifu_wready     = 1'b0;
  assign ifu_bvalid     = 1'b0;
  assign ifu_bresp      = 2'b00;
  assign ifu_bid        = 4'b0;
  //IFU Read
  assign ifu_arready    = ifu_arready_reg;
  assign ifu_rvalid     = ifu_rvalid_reg;
  assign ifu_rresp      = 2'b00;
  assign ifu_rdata      = ifu_rdata_reg;
  assign ifu_rlast      = ifu_rlast_reg;
  assign ifu_rid        = ifu_rid_reg;

  // Write Mem
  assign icache_awvalid = 1'b0;
  assign icache_awaddr  = `CPU_WIDTH'b0;
  assign icache_awid    = 4'b0;
  assign icache_awlen   = 8'b0;
  assign icache_awsize  = 3'b0;
  assign icache_awburst = 2'b0;
  assign icache_wvalid  = 1'b0;
  assign icache_wdata   = `CPU_WIDTH'b0;
  assign icache_wstrb   = {(`CPU_WIDTH / 8) {1'b0}};
  assign icache_wlast   = 1'b0;
  assign icache_bready  = 1'b0;

  //Read Mem
  assign icache_arvalid = icache_arvalid_reg;
  assign icache_araddr  = icache_araddr_reg;
  assign icache_arid    = icache_arid_reg;
  assign icache_arlen   = icache_arlen_reg;
  assign icache_arsize  = icache_arsize_reg;
  assign icache_arburst = icache_arburst_reg;
  //R Channel
  assign icache_rready  = icache_rready_reg;


  always @(*) begin
    state_next = idle_t;

    data_rd_en = 1'b0;
    valid_rd_en = 1'b0;
    tag_rd_en = 1'b0;

    data_wr_en = 1'b0;
    valid_wr_en = 1'b0;
    tag_wr_en = 1'b0;
    icache_wr_offset_next = icache_wr_offset_reg;

    ifu_rid_next = ifu_rid_reg;
    ifu_rlast_next = ifu_rlast_reg;
    ifu_rvalid_next = ifu_rvalid_reg && !ifu_rready;

    ifu_read_id_next = ifu_read_id_reg;
    ifu_read_addr_next = ifu_read_addr_reg;
    ifu_read_count_next = ifu_read_count_reg;
    ifu_read_size_next = ifu_read_size_reg;
    ifu_read_burst_next = ifu_read_burst_reg;

    ifu_arready_next = 1'b0;

    icache_arvalid_next = icache_arvalid_reg && !icache_arready;
    icache_araddr_next = icache_araddr_reg;
    icache_arid_next = icache_arid_reg;
    icache_arlen_next = icache_arlen_reg;
    icache_arsize_next = icache_arsize_reg;
    icache_arburst_next = icache_arburst_reg;

    icache_rready_next = 1'b0;

    case (state_reg)
      idle_t: begin
        ifu_arready_next = 1'b1;
        if (ifu_arvalid && ifu_arready_reg) begin
          ifu_read_id_next = ifu_arid;
          ifu_read_addr_next = ifu_araddr;
          ifu_read_count_next = ifu_arlen;
          ifu_read_size_next = ifu_arsize < $clog2(`CPU_WIDTH / 8) ? ifu_arsize :
            $clog2(`CPU_WIDTH / 8);
          ifu_read_burst_next = ifu_arburst;

          valid_rd_en = 1'b1;
          tag_rd_en = 1'b1;
          {ifu_cache_tag, ifu_cache_index, ifu_cache_offset} = ifu_araddr;


          ifu_arready_next = 1'b0;
          state_next = check_cache_t;
        end else begin
          state_next = idle_t;
        end
      end
      check_cache_t: begin
        if (icache_valid && ifu_cache_tag == icache_tag) begin
          state_next = instr_fetch_t;
        end else begin
          state_next = mem_araddr_t;
        end
      end
      mem_araddr_t: begin
        if (icache_arvalid_reg && icache_arready) begin
          icache_rready_next = 1'b1;
          state_next = mem_rdata_t;
        end else begin
          icache_arvalid_next = 1'b1;
          icache_araddr_next = ifu_read_addr_reg & ~{(OFFSET_MSB + 1) {1'b1}};
          icache_arid_next = ifu_read_id_reg;
          icache_arlen_next = CACHELINE_SIZE / (1 << ifu_read_size_reg) - 1'b1;
          icache_arsize_next = ifu_read_size_reg;
          icache_arburst_next = ifu_read_burst_reg;
          state_next = mem_araddr_t;
        end
      end
      mem_rdata_t: begin
        icache_rready_next = 1'b1;
        if (icache_rvalid && icache_rready_reg) begin
          data_wr_en = 1'b1;
          valid_wr_en = 1'b1;
          tag_wr_en = 1'b1;
          icache_wr_offset_next = icache_wr_offset_reg + (1 << icache_arsize_reg);
          if (icache_rlast) begin
            icache_rready_next = 1'b0;
            state_next = update_array_t;
          end else begin
            state_next = mem_rdata_t;
          end
        end else begin
          state_next = mem_rdata_t;
        end
      end
      update_array_t: begin
        state_next = instr_fetch_t;
      end
      instr_fetch_t: begin
        if (ifu_rready || !ifu_rvalid_reg) begin
          data_rd_en = 1'b1;
          ifu_rvalid_next = 1'b1;
          ifu_rid_next = ifu_read_id_reg;
          ifu_rlast_next = ifu_read_count_reg == 0;
          if (ifu_read_burst_reg != 2'b00) begin
            ifu_read_addr_next = ifu_read_addr_reg + (1 << ifu_read_size_reg);
            {ifu_cache_tag, ifu_cache_index, ifu_cache_offset} = ifu_read_addr_reg;
          end
          ifu_read_count_next = ifu_read_count_reg - 1;
          if (ifu_read_count_reg > 0) begin
            state_next = instr_fetch_t;
          end else begin
            ifu_arready_next = 1'b1;
            state_next = idle_t;
          end
        end else begin
          state_next = instr_fetch_t;
        end
      end
    endcase
  end

  always @(posedge i_clk) begin
    if (data_rd_en) begin
      ifu_rdata_reg <= data_array[ifu_cache_index][ifu_cache_offset*8+:`CPU_WIDTH];
    end
    if (valid_rd_en) begin
      icache_valid <= data_valid[ifu_cache_index];
    end
    if (tag_rd_en) begin
      icache_tag <= tag_array[ifu_cache_index];
    end
    if (data_wr_en) begin
      data_array[ifu_cache_index][icache_wr_offset_reg*8+:`CPU_WIDTH] <= icache_rdata;
    end
    if (valid_wr_en) begin
      data_valid[ifu_cache_index] <= 1'b1;
    end
    if (tag_wr_en) begin
      tag_array[ifu_cache_index] <= ifu_cache_tag;
    end
    if (fence_i) begin
      data_valid <= {CACHELINE_NUM{1'b0}};
    end
  end


  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(idle_t)
  ) u_state_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (state_next),
    .o_dout (state_reg)
  );

  stdreg #(
    .WIDTH    (1 + 1 + 1 + 4),
    .RESET_VAL({(1 + 1 + 1 + 4) {1'b0}})
  ) u_ifu_read_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({ifu_arready_next, ifu_rvalid_next, ifu_rlast_next, ifu_rid_next}),
    .o_dout ({ifu_arready_reg, ifu_rvalid_reg, ifu_rlast_reg, ifu_rid_reg})
  );

  stdreg #(
    .WIDTH    (4 + `CPU_WIDTH + 8 + 3 + 2),
    .RESET_VAL({(4 + `CPU_WIDTH + 8 + 3 + 2) {1'b0}})
  ) u_read_control_reg (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_wen(1'b1),
    .i_din({
      ifu_read_id_next,
      ifu_read_addr_next,
      ifu_read_count_next,
      ifu_read_size_next,
      ifu_read_burst_next
    }),
    .o_dout({
      ifu_read_id_reg, ifu_read_addr_reg, ifu_read_count_reg, ifu_read_size_reg, ifu_read_burst_reg
    })
  );

  stdreg #(
    .WIDTH    (1 + `CPU_WIDTH + 4 + 8 + 3 + 2 + 1),
    .RESET_VAL({(1 + `CPU_WIDTH + 4 + 8 + 3 + 2 + 1) {1'b0}})
  ) u_icache_read_reg (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_wen(1'b1),
    .i_din({
      icache_arvalid_next,
      icache_araddr_next,
      icache_arid_next,
      icache_arlen_next,
      icache_arsize_next,
      icache_arburst_next,
      icache_rready_next
    }),
    .o_dout({
      icache_arvalid_reg,
      icache_araddr_reg,
      icache_arid_reg,
      icache_arlen_reg,
      icache_arsize_reg,
      icache_arburst_reg,
      icache_rready_reg
    })
  );

  stdreg #(
    .WIDTH    (OFFSET_MSB + 1),
    .RESET_VAL({(OFFSET_MSB + 1) {1'b0}})
  ) u_icache_wr_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (icache_wr_offset_next),
    .o_dout (icache_wr_offset_reg)
  );

`ifndef SYNTHESIS
  import "DPI-C" function void cache_AMAT(
    input int hit_rate,
    input int acc_tot,
    input int access_time,
    input int miss_penalty
  );
  reg [31:0] cache_hit_rate;  //times
  reg [31:0] cache_acc_tot;  //times
  reg [31:0] access_time;
  reg cache_acc_en;
  reg [31:0] miss_penalty;
  reg dram_acc_en;
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      cache_acc_en <= 1'b0;
    end else if (ifu_arvalid) begin
      cache_acc_en <= 1'b1;
    end else if (ifu_rvalid_reg && ifu_rready && ifu_rlast) begin
      cache_acc_en <= 1'b0;
    end
  end
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      access_time <= 32'b0;
    end else if (cache_acc_en) begin
      access_time <= access_time + 1'b1;
    end
  end
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      dram_acc_en <= 1'b0;
    end else if (state_reg == check_cache_t) begin
      if (!(icache_valid && ifu_cache_tag == icache_tag)) begin
        dram_acc_en <= 1'b1;
      end
    end else if (state_reg == update_array_t) begin
      dram_acc_en <= 1'b0;
    end
  end
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      miss_penalty <= 32'b0;
    end else if (dram_acc_en) begin
      miss_penalty <= miss_penalty + 1'b1;
    end
  end
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      cache_hit_rate <= 32'b0;
    end else if (state_reg == check_cache_t) begin
      if (icache_valid && ifu_cache_tag == icache_tag) begin
        cache_hit_rate <= cache_hit_rate + 1'b1;
      end
    end
  end
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      cache_acc_tot <= 32'b0;
    end else if (ifu_arvalid && ifu_arready_reg) begin
      cache_acc_tot <= cache_acc_tot + 1'b1;
    end
  end
  always @(*) begin
    cache_AMAT(cache_hit_rate, cache_acc_tot, access_time, miss_penalty);
  end
`endif

endmodule
