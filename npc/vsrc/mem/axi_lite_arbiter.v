`include "defines.vh"

// verilator lint_off WIDTHTRUNC
module axi_lite_arbiter #(
  parameter S_COUNT = 2
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
  output wire [            `CPU_WIDTH-1:0] m_awaddr,
  output wire                              m_awvalid,
  input  wire                              m_awready,
  //W Channel
  output wire [            `CPU_WIDTH-1:0] m_wdata,
  output wire [          `CPU_WIDTH/8-1:0] m_wstrb,
  output wire                              m_wvalid,
  input  wire                              m_wready,
  //B Channel
  input  wire [                       1:0] m_bresp,
  input  wire                              m_bvalid,
  output wire                              m_bready,
  //AR Channel
  output wire [            `CPU_WIDTH-1:0] m_araddr,
  output wire                              m_arvalid,
  input  wire                              m_arready,
  //R Channel
  input  wire [            `CPU_WIDTH-1:0] m_rdata,
  input  wire [                       1:0] m_rresp,
  input  wire                              m_rvalid,
  output wire                              m_rready
);

  localparam CL_S_COUNT = $clog2(S_COUNT);

  localparam [2:0] STATE_IDLE = 3'd0;
  localparam [2:0] STATE_DECODE = 3'd1;
  localparam [2:0] STATE_WRITE = 3'd2;
  localparam [2:0] STATE_WRITE_RESP = 3'd3;
  localparam [2:0] STATE_WRITE_DROP = 3'd4;
  localparam [2:0] STATE_READ = 3'd5;
  localparam [2:0] STATE_WAIT_IDLE = 3'd6;

  wire [             2:0] state_reg;
  reg  [             2:0] state_next;
  reg                     match;  //目前2to1的arbiter必定match

  //common signals
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

  wire                    m_awvalid_reg;
  wire                    m_wvalid_reg;
  wire                    m_bready_reg;
  wire                    m_arvalid_reg;
  wire                    m_rready_reg;

  reg                     m_awvalid_next;
  reg                     m_wvalid_next;
  reg                     m_bready_next;
  reg                     m_arvalid_next;
  reg                     m_rready_next;

  assign s_awready = s_awready_reg;
  assign s_wready  = s_wready_reg;
  assign s_bresp   = {S_COUNT{axil_resp_reg}};
  assign s_bvalid  = s_bvalid_reg;
  assign s_arready = s_arready_reg;
  assign s_rdata   = {S_COUNT{axil_data_reg}};
  assign s_rresp   = {S_COUNT{axil_resp_reg}};
  assign s_rvalid  = s_rvalid_reg;

  assign m_awaddr  = axil_addr_reg;
  assign m_awvalid = m_awvalid_reg;
  assign m_wdata   = axil_data_reg;
  assign m_wstrb   = axil_wstrb_reg;
  assign m_wvalid  = m_wvalid_reg;
  assign m_bready  = m_bready_reg;
  assign m_araddr  = axil_addr_reg;
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
    .rst_n(i_rst_n),
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
    m_bready_next = 1'b0;
    m_arvalid_next = m_arvalid_reg & ~m_arready;
    m_rready_next = 1'b0;

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
          state_next = STATE_DECODE;  //保留这个后续可以改为Xbar          
        end else begin
          state_next = STATE_IDLE;
        end
      end
      STATE_DECODE: begin  //目前不会decode error
        match = 1'b1;

        if (match) begin
          if (read) begin
            m_rready_next = 1'b1;
            state_next = STATE_READ;
          end else begin
            m_bready_next = 1'b1;
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
          m_awvalid_next = 1'b1;
        end
        axil_addr_valid_next = 1'b0;

        if (current_s_wready && current_s_wvalid) begin
          s_wready_next[s_select] = 1'b0;
          axil_data_next = current_s_wdata;
          axil_wstrb_next = current_s_wstrb;
          m_wvalid_next = 1'b1;
          m_bready_next = 1'b1;
          state_next = STATE_WRITE_RESP;
        end else begin
          state_next = STATE_WRITE;
        end
      end
      STATE_WRITE_RESP: begin
        m_bready_next = 1'b1;
        if (m_bready && m_bvalid) begin
          m_bready_next = 1'b0;
          axil_resp_next = m_bresp;
          s_bvalid_next[s_select] = 1'b1;
          state_next = STATE_WAIT_IDLE;
        end else begin
          state_next = STATE_WRITE_RESP;
        end
      end
      STATE_WRITE_DROP: begin  //目前不会进入此状态
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
        m_rready_next = 1'b1;

        if (axil_addr_valid_reg) begin
          m_arvalid_next = 1'b1;
        end

        axil_addr_valid_next = 1'b0;

        if (m_rready && m_rvalid) begin
          m_rready_next = 1'b0;
          axil_data_next = m_rdata;
          axil_resp_next = m_rresp;
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
    .WIDTH    (5),
    .RESET_VAL(5'b0)
  ) u_master_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({m_awvalid_next, m_wvalid_next, m_bready_next, m_arvalid_next, m_rready_next}),
    .o_dout ({m_awvalid_reg, m_wvalid_reg, m_bready_reg, m_arvalid_reg, m_rready_reg})
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
// verilator lint_on WIDTHTRUNC
