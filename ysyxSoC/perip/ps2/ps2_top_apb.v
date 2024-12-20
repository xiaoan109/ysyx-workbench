module ps2_top_apb (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [ 2:0] in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [ 3:0] in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  input ps2_clk,
  input ps2_data
);

  // ps2_clk为低电平的时候禁止通信
  // 检测低电平到高电平转换，打两拍，跨时钟域避免亚稳态问题
  reg [2:0] ps2_clk_sync;
  always @(posedge clock) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
  end
  wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

  reg [9:0] buffer;   // ps2_data bits
  reg [3:0] counter;  // count ps2_data bits
  reg [7:0] fifo[15:0];     // data fifo
  reg [3:0] w_ptr, r_ptr;  // fifo write and read pointers
  reg empty;
  integer i;

  localparam PS2_STATE_WIDTH = 2;
  reg [PS2_STATE_WIDTH-1:0] ps2_apb_state;
  localparam [PS2_STATE_WIDTH-1:0] PS2_APB_IDLE = 'd0;
  localparam [PS2_STATE_WIDTH-1:0] PS2_APB_READ = 'd1;

  assign in_pready  = (ps2_apb_state == PS2_APB_READ) ? 1'b1 : 1'b0;
  assign in_prdata  = (ps2_apb_state == PS2_APB_READ) ? (empty ? {24'd0, fifo[r_ptr]} : 'd0) : 'd0;
  assign in_pslverr = 1'b0;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ps2_apb_state <= PS2_APB_IDLE;
    end else begin
      case (ps2_apb_state)
        PS2_APB_IDLE: begin
          if (in_psel && !in_pwrite) begin
            ps2_apb_state <= PS2_APB_READ;
          end
        end
        PS2_APB_READ: begin
          ps2_apb_state <= PS2_APB_IDLE;
        end
        default: begin
          ps2_apb_state <= PS2_APB_IDLE;
        end
      endcase
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      counter <= 'd0;
      w_ptr   <= 'd0;
      r_ptr   <= 'd0;
      empty   <= 'd0;
      for (i = 0; i < 8; i++) begin
        fifo[i] <= 'd0;
      end
    end else begin
      if (sampling) begin
        if (counter == 4'd10) begin
          if ((buffer[0] == 0) && (ps2_data) && (^buffer[9:1])) begin
            fifo[w_ptr] <= buffer[8:1];
            w_ptr       <= w_ptr + 1;
            empty       <= 'd1;
          end
          counter <= 'd0;
        end else begin
          buffer[counter] <= ps2_data;
          counter <= counter + 1;
        end
      end

      if (in_penable & in_pready & empty) begin
        r_ptr <= r_ptr + 3'b1;
        if (w_ptr == (r_ptr + 1'b1)) begin
          empty <= 'd0;
        end
      end
    end
  end

endmodule
