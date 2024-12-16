module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);
  // assign miso = 1'b1;

  reg [7:0] data_reg;
  reg [3:0] data_cnt;
  reg       miso_reg;

  always @(negedge sck or posedge ss) begin
    if (ss) begin
      data_cnt <= 4'b0;
    end else begin
      data_cnt <= data_cnt + 1'b1;
    end
  end

  always @(negedge sck or posedge ss) begin
    if (ss) begin
      data_reg <= 8'b0;
    end else if(!data_cnt[3]) begin
      data_reg[data_cnt[2:0]] <= mosi;
    end
  end

  always @(posedge sck or posedge ss) begin
    if (ss) begin
      miso_reg <= 1'b1;
    end else if(!data_cnt[3]) begin
      miso_reg <= 1'b0;
    end else begin
      miso_reg <= data_reg[7-data_cnt[2:0]];
    end
  end

  assign miso = miso_reg;
endmodule
