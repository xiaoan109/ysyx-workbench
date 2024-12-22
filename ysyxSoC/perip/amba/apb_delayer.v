module apb_delayer(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

  typedef enum [1:0] {idle_t, wait_perip_t, delay_t} state_t;
  reg [1:0] state;
  reg [31:0] counter;
  reg [31:0] prdata_r;
  reg pslverr_r;

  assign out_paddr   = in_paddr;
  assign out_psel    = in_psel && state != delay_t;
  assign out_penable = in_penable;
  assign out_pprot   = in_pprot;
  assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;
  // assign in_pready   = out_pready;
  // assign in_prdata   = out_prdata;
  // assign in_pslverr  = out_pslverr;

  // Fmax: 366MHz, Perip: 100MHz, r = 3.66
  // set s = 32, r*s = 117.12 -> 117
  // wait perip resp: counter 每周期加(r-1)*s=85，直到(r-1)*s*k=85*k
  // wait apb delayer done: counter先/s = 85/32*k, 每周期-1


  always @(posedge clock) begin
    if(reset) begin
      state <= idle_t;
      counter <= 32'b0;
    end else begin
      case(state)
        idle_t: begin
          if(in_psel) begin
            state <= wait_perip_t;
            counter <= counter + 32'd85;
          end
        end
        wait_perip_t: begin
          if(out_pready) begin
            state <= delay_t;
            counter <= (counter + 32'd85) >> 5;
          end else begin
            counter <= counter + 32'd85;
          end
        end
        delay_t: begin
          if(counter == 32'b1) begin
            state <= idle_t;
            counter <= 32'b0;
          end else begin
            counter <= counter - 1'b1;
          end
        end
        default: state <= idle_t;
      endcase
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      prdata_r <= 32'b0;
      pslverr_r <= 1'b0;
    end else if(out_pready) begin
      prdata_r <= out_prdata;
      pslverr_r <= out_pslverr;
    end
  end


  assign in_pready = state == delay_t && counter == 32'b1;
  assign in_prdata   = prdata_r;
  assign in_pslverr  = pslverr_r;


endmodule
