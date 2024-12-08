`include "defines.vh"


module axi_lite_interconnect #(
  parameter S_COUNT = 2,
  parameter M_COUNT = 2,
  parameter M_BASE_ADDR = 0,
  parameter M_ADDR_WIDTH = {M_COUNT{{32'd24}}},
  parameter M_CONNECT_READ = {M_COUNT{{S_COUNT{1'b1}}}},
  parameter M_CONNECT_WRITE = {M_COUNT{{S_COUNT{1'b1}}}}
) (
  input  wire                              i_clk,
  input  wire                              i_rst_n,
  //Slave
  //AW Channel
  input  wire [  S_COUNT * `CPU_WIDTH-1:0] s_awaddr,
  input  wire [               S_COUNT-1:0] s_awvalid,
  output wire [               S_COUNT-1:0] s_awready,
  //W Channel
  input  wire [  S_COUNT * `CPU_WIDTH-1:0] s_wdata,
  input  wire [S_COUNT * `CPU_WIDTH/8-1:0] s_wstrb,
  input  wire [               S_COUNT-1:0] s_wvalid,
  output wire [               S_COUNT-1:0] s_wready,
  //B Channel
  output wire [           S_COUNT * 2-1:0] s_bresp,
  output wire [               S_COUNT-1:0] s_bvalid,
  input  wire [               S_COUNT-1:0] s_bready,
  //AR Channel
  input  wire [  S_COUNT * `CPU_WIDTH-1:0] s_araddr,
  input  wire [               S_COUNT-1:0] s_arvalid,
  output wire [               S_COUNT-1:0] s_arready,
  //R Channel
  output wire [  S_COUNT * `CPU_WIDTH-1:0] s_rdata,
  output wire [           S_COUNT * 2-1:0] s_rresp,
  output wire [               S_COUNT-1:0] s_rvalid,
  input  wire [               S_COUNT-1:0] s_rready,
  //Master
  //AW Channel
  output wire [  M_COUNT * `CPU_WIDTH-1:0] m_awaddr,
  output wire [               M_COUNT-1:0] m_awvalid,
  input  wire [               M_COUNT-1:0] m_awready,
  //W Channel
  output wire [  M_COUNT * `CPU_WIDTH-1:0] m_wdata,
  output wire [M_COUNT * `CPU_WIDTH/8-1:0] m_wstrb,
  output wire [               M_COUNT-1:0] m_wvalid,
  input  wire [               M_COUNT-1:0] m_wready,
  //B Channel
  input  wire [           M_COUNT * 2-1:0] m_bresp,
  input  wire [               M_COUNT-1:0] m_bvalid,
  output wire [               M_COUNT-1:0] m_bready,
  //AR Channel
  output wire [  M_COUNT * `CPU_WIDTH-1:0] m_araddr,
  output wire [               M_COUNT-1:0] m_arvalid,
  input  wire [               M_COUNT-1:0] m_arready,
  //R Channel
  input  wire [  M_COUNT * `CPU_WIDTH-1:0] m_rdata,
  input  wire [           M_COUNT * 2-1:0] m_rresp,
  input  wire [               M_COUNT-1:0] m_rvalid,
  output wire [               M_COUNT-1:0] m_rready
);

  localparam CL_S_COUNT = $clog2(S_COUNT);
  localparam CL_M_COUNT = $clog2(M_COUNT);


  // default address computation
  function [M_COUNT * `CPU_WIDTH-1:0] calcBaseAddrs(input [31:0] dummy);
    integer i;
    reg [`CPU_WIDTH-1:0] base;
    reg [`CPU_WIDTH-1:0] width;
    reg [`CPU_WIDTH-1:0] size;
    reg [`CPU_WIDTH-1:0] mask;
    begin
      calcBaseAddrs = {M_COUNT * `CPU_WIDTH{1'b0}};
      base = 0;
      for (i = 0; i < M_COUNT; i = i + 1) begin
        width = M_ADDR_WIDTH[i*32+:32];
        mask  = {`CPU_WIDTH{1'b1}} >> (`CPU_WIDTH - width);
        size  = mask + 1;
        if (width > 0) begin
          if ((base & mask) != 0) begin
            base = base + size - (base & mask);  // align
          end
          calcBaseAddrs[i*`CPU_WIDTH+:`CPU_WIDTH] = base;
          base = base + size;  // increment
        end
      end
    end
  endfunction

  localparam M_BASE_ADDR_INT = M_BASE_ADDR ? M_BASE_ADDR : calcBaseAddrs(0);

  integer i;

  localparam [2:0] STATE_IDLE = 3'd0;
  localparam [2:0] STATE_DECODE = 3'd1;
  localparam [2:0] STATE_WRITE = 3'd2;
  localparam [2:0] STATE_WRITE_RESP = 3'd3;
  localparam [2:0] STATE_WRITE_DROP = 3'd4;
  localparam [2:0] STATE_READ = 3'd5;
  localparam [2:0] STATE_WAIT_IDLE = 3'd6;

  wire [             2:0] state_reg;
  reg  [             2:0] state_next;
  reg                     match;

  //common signals
  wire [  CL_M_COUNT-1:0] m_select_reg;
  reg  [  CL_M_COUNT-1:0] m_select_next;
  wire [  `CPU_WIDTH-1:0] axil_addr_reg;
  reg  [  `CPU_WIDTH-1:0] axil_addr_next;
  wire                    axil_addr_valid_reg;
  reg                     axil_addr_valid_next;
  wire [  `CPU_WIDTH-1:0] axil_data_reg;
  reg  [  `CPU_WIDTH-1:0] axil_data_next;
  wire [`CPU_WIDTH/8-1:0] axil_wstrb_reg;
  reg  [`CPU_WIDTH/8-1:0] axil_wstrb_next;
  wire [             1:0] axil_resp_reg;
  reg  [             1:0] axil_resp_next;

  wire [     S_COUNT-1:0] s_awready_reg;
  wire [     S_COUNT-1:0] s_wready_reg;
  wire [     S_COUNT-1:0] s_bvalid_reg;
  wire [     S_COUNT-1:0] s_arready_reg;
  wire [     S_COUNT-1:0] s_rvalid_reg;
  reg  [     S_COUNT-1:0] s_awready_next;
  reg  [     S_COUNT-1:0] s_wready_next;
  reg  [     S_COUNT-1:0] s_bvalid_next;
  reg  [     S_COUNT-1:0] s_arready_next;
  reg  [     S_COUNT-1:0] s_rvalid_next;

  wire [     M_COUNT-1:0] m_awvalid_reg;
  wire [     M_COUNT-1:0] m_wvalid_reg;
  wire [     M_COUNT-1:0] m_bready_reg;
  wire [     M_COUNT-1:0] m_arvalid_reg;
  wire [     M_COUNT-1:0] m_rready_reg;
  reg  [     M_COUNT-1:0] m_awvalid_next;
  reg  [     M_COUNT-1:0] m_wvalid_next;
  reg  [     M_COUNT-1:0] m_bready_next;
  reg  [     M_COUNT-1:0] m_arvalid_next;
  reg  [     M_COUNT-1:0] m_rready_next;

  assign s_awready = s_awready_reg;
  assign s_wready  = s_wready_reg;
  assign s_bresp   = {S_COUNT{axil_resp_reg}};
  assign s_bvalid  = s_bvalid_reg;
  assign s_arready = s_arready_reg;
  assign s_rdata   = {S_COUNT{axil_data_reg}};
  assign s_rresp   = {S_COUNT{axil_resp_reg}};
  assign s_rvalid  = s_rvalid_reg;

  assign m_awaddr  = {M_COUNT{axil_addr_reg}};
  assign m_awvalid = m_awvalid_reg;
  assign m_wdata   = {M_COUNT{axil_data_reg}};
  assign m_wstrb   = {M_COUNT{axil_wstrb_reg}};
  assign m_wvalid  = m_wvalid_reg;
  assign m_bready  = m_bready_reg;
  assign m_araddr  = {M_COUNT{axil_addr_reg}};
  assign m_arvalid = m_arvalid_reg;
  assign m_rready  = m_rready_reg;

  // slave side mux
  wire [(CL_S_COUNT > 0 ? CL_S_COUNT-1 : 0):0] s_select;
  wire [                       `CPU_WIDTH-1:0] current_s_araddr;
  wire [                       `CPU_WIDTH-1:0] current_s_awaddr;
  wire                                         current_s_wvalid;
  wire                                         current_s_wready;
  wire [                       `CPU_WIDTH-1:0] current_s_wdata;
  wire [                     `CPU_WIDTH/8-1:0] current_s_wstrb;

  assign current_s_araddr = s_araddr[s_select*`CPU_WIDTH+:`CPU_WIDTH];
  assign current_s_awaddr = s_awaddr[s_select*`CPU_WIDTH+:`CPU_WIDTH];
  assign current_s_wvalid = s_wvalid[s_select];
  assign current_s_wready = s_wready[s_select];
  assign current_s_wdata  = s_wdata[s_select*`CPU_WIDTH+:`CPU_WIDTH];
  assign current_s_wstrb  = s_wstrb[s_select*`CPU_WIDTH/8+:`CPU_WIDTH/8];

  // master side mux
  wire                  current_m_bvalid;
  wire                  current_m_bready;
  wire [           1:0] current_m_bresp;
  wire                  current_m_rvalid;
  wire                  current_m_rready;
  wire [`CPU_WIDTH-1:0] current_m_rdata;
  wire [           1:0] current_m_rresp;

  assign current_m_bvalid = m_bvalid[m_select_reg];
  assign current_m_bready = m_bready[m_select_reg];
  assign current_m_bresp  = m_bresp[m_select_reg*2+:2];
  assign current_m_rvalid = m_rvalid[m_select_reg];
  assign current_m_rready = m_rready[m_select_reg];
  assign current_m_rdata  = m_rdata[m_select_reg*`CPU_WIDTH+:`CPU_WIDTH];
  assign current_m_rresp  = m_rresp[m_select_reg*2+:2];

  // arbiter instance
  wire [S_COUNT*2-1:0] request;
  wire [S_COUNT*2-1:0] acknowledge;
  wire [S_COUNT*2-1:0] grant;
  wire                 grant_valid;
  wire [ CL_S_COUNT:0] grant_encoded;

  wire                 read = grant_encoded[0];
  assign s_select = grant_encoded >> 1;

  arbiter #(
    .PORTS(S_COUNT * 2),
    .ARB_TYPE_ROUND_ROBIN(1),
    .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(1),
    .ARB_LSB_HIGH_PRIORITY(1)
  ) arb_inst (
    .clk(i_clk),
    .rst(!i_rst_n),
    .request(request),
    .acknowledge(acknowledge),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_encoded(grant_encoded)
  );

  genvar n;

  // request generation
  generate
    for (n = 0; n < S_COUNT; n = n + 1) begin
      assign request[2*n]   = s_awvalid[n];
      assign request[2*n+1] = s_arvalid[n];
    end
  endgenerate

  // acknowledge generation
  generate
    for (n = 0; n < S_COUNT; n = n + 1) begin
      assign acknowledge[2*n]   = grant[2*n] && s_bvalid[n] && s_bready[n];
      assign acknowledge[2*n+1] = grant[2*n+1] && s_rvalid[n] && s_rready[n];
    end
  endgenerate


  always @(*) begin
    state_next = STATE_IDLE;

    match = 1'b0;

    m_select_next = m_select_reg;
    axil_addr_next = axil_addr_reg;
    axil_addr_valid_next = axil_addr_valid_reg;
    axil_data_next = axil_data_reg;
    axil_wstrb_next = axil_wstrb_reg;
    axil_resp_next = axil_resp_reg;

    s_awready_next = {(S_COUNT) {1'b0}};
    s_wready_next = {(S_COUNT) {1'b0}};
    s_bvalid_next = s_bvalid_reg & ~s_bready;
    s_arready_next = {(S_COUNT) {1'b0}};
    s_rvalid_next = s_rvalid_reg & ~s_rready;

    m_awvalid_next = m_awvalid_reg & ~m_awready;
    m_wvalid_next = m_wvalid_reg & ~m_wready;
    m_bready_next = {M_COUNT{1'b0}};
    m_arvalid_next = m_arvalid_reg & ~m_arready;
    m_rready_next = {M_COUNT{1'b0}};

    case (state_reg)
      STATE_IDLE: begin
        //wait arbiter
        if (grant_valid) begin
          axil_addr_valid_next = 1'b1;
          if (read) begin
            axil_addr_next = current_s_araddr;
            s_arready_next[s_select] = 1'b1;
          end else begin
            axil_addr_next = current_s_awaddr;
            s_awready_next[s_select] = 1'b1;
          end
          state_next = STATE_DECODE;
        end else begin
          state_next = STATE_IDLE;
        end
      end
      STATE_DECODE: begin
        match = 1'b0;
        for (i = 0; i < M_COUNT; i = i + 1) begin
          if (M_ADDR_WIDTH[i*32 +: 32]  && ((read ? M_CONNECT_READ : M_CONNECT_WRITE) & (1 << (s_select+i*S_COUNT))) && (axil_addr_reg >> M_ADDR_WIDTH[i*32 +: 32]) == (M_BASE_ADDR_INT[i*`CPU_WIDTH +: `CPU_WIDTH] >> M_ADDR_WIDTH[i*32 +: 32])) begin
            m_select_next = i;
            match = 1'b1;
          end
        end
        if (match) begin
          if (read) begin
            m_rready_next[m_select_next] = 1'b1;
            state_next = STATE_READ;
          end else begin
            s_wready_next[s_select] = 1'b1;
            state_next = STATE_WRITE;
          end
        end else begin
          // no match; return decode error
          axil_data_next = `CPU_WIDTH'b0;
          axil_resp_next = 2'b11;
          if (read) begin
            // reading
            s_rvalid_next[s_select] = 1'b1;
            state_next = STATE_WAIT_IDLE;
          end else begin
            // writing
            s_wready_next[s_select] = 1'b1;
            state_next = STATE_WRITE_DROP;
          end
        end
      end
      STATE_WRITE: begin
        s_wready_next[s_select] = 1'b1;

        if (axil_addr_valid_reg) begin
          m_awvalid_next[m_select_reg] = 1'b1;
        end
        axil_addr_valid_next = 1'b0;

        if (current_s_wready && current_s_wvalid) begin
          s_wready_next[s_select] = 1'b0;
          axil_data_next = current_s_wdata;
          axil_wstrb_next = current_s_wstrb;
          m_wvalid_next[m_select_reg] = 1'b1;
          m_bready_next[m_select_reg] = 1'b1;
          state_next = STATE_WRITE_RESP;
        end else begin
          state_next = STATE_WRITE;
        end
      end
      STATE_WRITE_RESP: begin
        m_bready_next[m_select_reg] = 1'b1;
        if (current_m_bready && current_m_bvalid) begin
          m_bready_next[m_select_reg] = 1'b0;
          axil_resp_next = current_m_bresp;
          s_bvalid_next[s_select] = 1'b1;
          state_next = STATE_WAIT_IDLE;
        end else begin
          state_next = STATE_WRITE_RESP;
        end
      end
      STATE_WRITE_DROP: begin
        // write drop state; drop write data
        s_wready_next[s_select] = 1'b1;

        axil_addr_valid_next = 1'b0;

        if (current_s_wready && current_s_wvalid) begin
          s_wready_next[s_select] = 1'b0;
          s_bvalid_next[s_select] = 1'b1;
          state_next = STATE_WAIT_IDLE;
        end else begin
          state_next = STATE_WRITE_DROP;
        end
      end
      STATE_READ: begin
        m_rready_next[m_select_reg] = 1'b1;

        if (axil_addr_valid_reg) begin
          m_arvalid_next[m_select_reg] = 1'b1;
        end

        axil_addr_valid_next = 1'b0;

        if (current_m_rready && current_m_rvalid) begin
          m_rready_next[m_select_reg] = 1'b0;
          axil_data_next = current_m_rdata;
          axil_resp_next = current_m_rresp;
          s_rvalid_next[s_select] = 1'b1;
          state_next = STATE_WAIT_IDLE;
        end else begin
          state_next = STATE_READ;
        end
      end
      STATE_WAIT_IDLE: begin
        // wait for idle state; wait untl grant valid is deasserted

        if (!grant_valid || acknowledge) begin
          state_next = STATE_IDLE;
        end else begin
          state_next = STATE_WAIT_IDLE;
        end
      end
      default: ;
    endcase
  end

  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(STATE_IDLE)
  ) u_state_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (state_next),
    .o_dout (state_reg)
  );

  stdreg #(
    .WIDTH    (S_COUNT * 5),
    .RESET_VAL({(S_COUNT * 5) {1'b0}})
  ) u_slave_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({s_awready_next, s_wready_next, s_bvalid_next, s_arready_next, s_rvalid_next}),
    .o_dout ({s_awready_reg, s_wready_reg, s_bvalid_reg, s_arready_reg, s_rvalid_reg})
  );

  stdreg #(
    .WIDTH    (M_COUNT * 5 + CL_M_COUNT),
    .RESET_VAL({(M_COUNT * 5 + CL_M_COUNT) {1'b0}})
  ) u_master_reg (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_wen(1'b1),
    .i_din({
      m_select_next, m_awvalid_next, m_wvalid_next, m_bready_next, m_arvalid_next, m_rready_next
    }),
    .o_dout({m_select_reg, m_awvalid_reg, m_wvalid_reg, m_bready_reg, m_arvalid_reg, m_rready_reg})
  );

  stdreg #(
    .WIDTH    (`CPU_WIDTH + 1 + `CPU_WIDTH + `CPU_WIDTH / 8 + 2),
    .RESET_VAL({(`CPU_WIDTH + 1 + `CPU_WIDTH + `CPU_WIDTH / 8 + 2) {1'b0}})
  ) u_common_reg (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_wen(1'b1),
    .i_din({axil_addr_next, axil_addr_valid_next, axil_data_next, axil_wstrb_next, axil_resp_next}),
    .o_dout({axil_addr_reg, axil_addr_valid_reg, axil_data_reg, axil_wstrb_reg, axil_resp_reg})
  );



endmodule
