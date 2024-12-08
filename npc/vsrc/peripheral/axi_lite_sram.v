`include "defines.vh"
module axi_lite_sram (
  input  wire                    i_clk,
  input  wire                    i_rst_n,
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

  reg                   mem_wen;
  reg                   mem_ren;

  wire                  awready_reg;
  reg                   awready_next;
  wire                  wready_reg;
  reg                   wready_next;
  wire                  bvalid_reg;
  reg                   bvalid_next;
  wire                  arready_reg;
  reg                   arready_next;
  wire                  rvalid_reg;
  reg                   rvalid_next;
  wire [`CPU_WIDTH-1:0] rdata_reg;
  wire [`CPU_WIDTH-1:0] rdata_next;

  wire [           7:0] lfsr_delay;  // assert > 0
  wire                  cnt_done;
  reg                   bvalid_wait_next;
  wire                  bvalid_wait_reg;
  reg                   rvalid_wait_next;
  wire                  rvalid_wait_reg;

  assign awready = awready_reg;
  assign wready  = wready_reg;
  assign bvalid  = bvalid_reg;
  assign bresp   = 2'b00;  // Always OK
  assign arready = arready_reg;
  assign rvalid  = rvalid_reg;
  assign rresp   = 2'b00;  // Always OK
  assign rdata   = rdata_reg;


  //AW/W/B Channel
  always @(*) begin
    mem_wen = 1'b0;
    awready_next = 1'b0;
    wready_next = 1'b0;
    bvalid_next = bvalid_reg && !bready;
    bvalid_wait_next = bvalid_wait_reg;
    if (awvalid && wvalid && (!awready && !wready) && (!bvalid || bready)) begin
      mem_wen = 1'b1;
      awready_next = 1'b1;
      wready_next = 1'b1;
      if (lfsr_delay == 8'b1) begin
        bvalid_next = 1'b1;
      end else begin
        bvalid_wait_next = 1'b1;
      end
    end
    if (bvalid_wait_reg && cnt_done) begin
      bvalid_next = 1'b1;
      bvalid_wait_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH    (4),
    .RESET_VAL(4'b0)
  ) u_AW_W_B_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({awready_next, wready_next, bvalid_next, bvalid_wait_next}),
    .o_dout ({awready_reg, wready_reg, bvalid_reg, bvalid_wait_reg})
  );

  //AR/R Channel
  always @(*) begin
    mem_ren = 1'b0;
    arready_next = 1'b0;
    rvalid_next = rvalid_reg && !rready;
    rvalid_wait_next = rvalid_wait_reg;
    if (arvalid && !arready && (!rvalid || rready)) begin
      mem_ren = 1'b1;
      arready_next = 1'b1;
      if (lfsr_delay == 8'b1) begin
        rvalid_next = 1'b1;
      end else begin
        rvalid_wait_next = 1'b1;
      end
    end
    if (rvalid_wait_reg && cnt_done) begin
      rvalid_next = 1'b1;
      rvalid_wait_next = 1'b0;
    end
  end


  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(3'b0)
  ) u_AR_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({arready_next, rvalid_next, rvalid_wait_next}),
    .o_dout ({arready_reg, rvalid_reg, rvalid_wait_reg})
  );


  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (mem_ren),
    .i_din  (rdata_next),
    .o_dout (rdata_reg)
  );



`ifdef LFSR
  lfsr_8bit #(
    .SEED (8'b0),
    .WIDTH(8)
  ) u_lfsr_8bit (
    .clk_i        (i_clk),
    .rst_ni       (i_rst_n),
    .en_i         (mem_wen || mem_ren),  // 1'b1
    .refill_way_oh(lfsr_delay)
  );
`else
  assign lfsr_delay = `SRAM_DELAY;
`endif

  delay_counter u_delay_counter (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_ena  (mem_wen || mem_ren),  // 1clk pulse
    .i_bound(lfsr_delay - 1'b1),   //minus 1 is the real delay
    .o_done (cnt_done)
  );



  `ifndef SYNTHESIS
    import "DPI-C" function void pmem_write(
      input int       waddr,
      input int       wdata,
      input bit [3:0] wmask,
      input bit       wen
    );
    always @(*) begin
      pmem_write(awaddr, wdata, wstrb, mem_wen);
    end
    import "DPI-C" function void pmem_read(
      input  int raddr,
      output int rdata,
      input  bit ren
    );
    always @(*) begin
      pmem_read(araddr, rdata_next, mem_ren);
    end
  `else
  wire [`CPU_WIDTH-1:0] rdata_int;

  RegisterFile #(
    .ADDR_WIDTH(8),
    .DATA_WIDTH(32)
  ) u_RegisterFile (
    .clk(i_clk),
    .wdata(wdata),
    .waddr(awaddr[9:2] + 8'b1),
    .wen(mem_wen),
    .raddr1(araddr[9:2] + 8'b1),
    .raddr2(8'b0),
    .rdata1(rdata_int),
    .rdata2()
  );
  genvar i;
  generate
    for (i = 0; i < `CPU_WIDTH / 8; i = i + 1) begin : byte_revert
      assign rdata_next[i*8+:8] = rdata_int[(`CPU_WIDTH/8-i-1)*8+:8];
    end
  endgenerate

  initial begin
    $readmemh(`MEM_INIT_FILE, u_RegisterFile.rf);
  end
  // integer fd;
  // reg file_is_open;
  // reg [7:0] byte0;
  // reg [7:0] byte1;
  // reg [7:0] byte2;
  // reg [7:0] byte3;
  // integer file_size;
  // integer i;
  // initial begin
  //   fd = $fopen(`MEM_INIT_FILE, "rb");
  //   if (fd == 0) begin
  //     $display("%m @%0t: Could not open file '%s'", $time, `MEM_INIT_FILE);
  //     $stop;
  //   end else begin
  //     $display("%m @%0t: Opened %s for reading", $time, `MEM_INIT_FILE);
  //     file_is_open = 1'b1;
  //   end

  //   $fseek(fd, 0, 2);  // move cur to end.
  //   file_size = $ftell(fd);
  //   $display("File size=%d", file_size);
  //   $fseek(fd, 0, 0);  // move cur to begin.
  //   if (file_is_open) begin
  //     for (i = 0; i < (file_size >> 2); i = i + 1) begin
  //       byte0 = $fgetc(fd);
  //       byte1 = $fgetc(fd);
  //       byte2 = $fgetc(fd);
  //       byte3 = $fgetc(fd);
  //       // $display("word=%h %h %h %h", byte3, byte2, byte1, byte0);
  //       u_RegisterFile.rf[i+1] = {byte3, byte2, byte1, byte0};
  //     end
  //   end
  // end
  `endif

endmodule
