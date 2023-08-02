module RegisterFile #(parameter ADDR_WIDTH = 1, DATA_WIDTH = 1) (
        input clk,
        input [DATA_WIDTH-1:0] wdata,
        input [ADDR_WIDTH-1:0] waddr,
        input wen,
        input [ADDR_WIDTH-1:0] raddr1,
        input [ADDR_WIDTH-1:0] raddr2,
        output [DATA_WIDTH-1:0] rdata1,
        output [DATA_WIDTH-1:0] rdata2
    );
    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    always @(posedge clk) begin
        if (wen)
            rf[waddr] <= wdata;
    end

    integer i;

    initial begin
        for(i = 0; i < 2**ADDR_WIDTH; i = i + 1)
            rf[i] = 0;
    end

    assign rdata1 = (raddr1 == 0) ? 0 : rf[raddr1];
    assign rdata2 = (raddr2 == 0) ? 0 : rf[raddr2];
endmodule
