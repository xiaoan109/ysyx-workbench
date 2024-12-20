module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);
`define RCMD 8'hEB
`define WCMD 8'h38
`define QPICMD 8'h35


// assign dio = 4'bz;
wire [3:0] dout_en;
wire [3:0] dout;
wire [3:0] din;
assign din = dio;

genvar i;
generate
  for(i=0; i<4; i=i+1)begin
    assign dio[i] = dout_en[i] ? dout[i] : 1'bz;
  end
endgenerate

reg QPI_MODE = 0;

reg[7:0] cmd;
reg[23:0] addr;
reg[31:0] data;
reg[31:0] rdata;
reg[7:0] counter;
reg [2:0] state;
typedef enum [2:0] { cmd_t, addr_t, data_t, delay_t, err_t } state_t;

always @(posedge ce_n) begin
  if(cmd == `QPICMD)begin
    QPI_MODE = 1;
  end
end

always @(posedge sck or posedge ce_n) begin
  if(ce_n)begin
    counter <= 'd0;
    state   <= cmd_t;
  end
  else begin
    case(state)
      cmd_t:begin
        if(QPI_MODE)begin
          counter <= (counter < 8'd1 ) ? counter + 8'd1 : 8'd0;
          state <= (counter == 8'd1 ) ? addr_t : state;
        end
        else begin
          counter <= (counter < 8'd7 ) ? counter + 8'd1 : 8'd0;
          state <= (counter == 8'd7 ) ? addr_t : state;
        end
      end
      addr_t:begin
        counter <= (counter < 8'd5) ? counter + 8'd1 : 8'd0;
        state  <= (counter == 8'd5) ? (cmd == `RCMD ? delay_t : (cmd == `WCMD ? data_t : err_t) ):state;
      end
      data_t:begin
        counter <= counter + 8'd1;
        state <= state;
      end
      delay_t:begin
        counter <= (counter < 8'd6) ? counter + 8'd1 : 8'd0;
        state  <= (counter == 8'd6) ? data_t  : state;
      end
      default: begin
        state <= state;
        $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh`, only support `EBh,38H` read command\n", cmd);
        $fatal;
      end
    endcase
  end
end

always@(posedge sck or posedge ce_n) begin
  if (ce_n)               cmd <= 8'd0;
  else if (state == cmd_t)begin
    if(QPI_MODE)begin
      cmd <= { cmd[3:0], din[3:0] };
    end
    else begin
      cmd <= { cmd[6:0], din[0] };
    end
  end 
end

always@(posedge sck or posedge ce_n) begin
  if (ce_n) addr <= 24'd0;
  else if (state == addr_t && counter < 8'd6)
    addr <= { addr[19:0], din[3:0] };
end

wire [31:0] data_bswap = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
always@(posedge sck or posedge ce_n) begin
  if (ce_n) data <= 32'd0;
  else if (state == data_t && cmd == `RCMD) begin
    data <= { {counter == 8'd0 ? data_bswap : data}[27:0], 4'b0000 };
  end
  else if (state == data_t && cmd == `WCMD) begin
    data <= {data[27:0], din[3:0]};
  end
end
assign dout = {(state == data_t &&counter == 8'd0) ? data_bswap : data}[31:28];

assign dout_en = (state == data_t | state == delay_t)&& cmd == `RCMD ? 4'b1111 : 4'd0;


import "DPI-C" function void psram_read(input int addr, output int data);
import "DPI-C" function void psram_write(input int addr, input int data,input int mask);

wire [31:0] wdata = {data[7:0], data[15:8], data[23:16], data[31:24]};

always @(posedge sck)begin
  if((state == delay_t) && (counter == 8'd0) && (cmd == `RCMD))begin
    psram_read({8'd0,addr},rdata);
  end
end
always@(posedge ce_n) begin
  if(cmd == `WCMD)begin
    psram_write({8'd0,addr},wdata,{24'd0,counter});
  end
end
endmodule