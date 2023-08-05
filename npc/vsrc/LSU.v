`include "defines.v"
module LSU(
        input clk,
        input rst,
        input MemWrite,
        input MemRead,
        input [2:0] MemOP,
        input [`XLEN-1:0] MemAddr,
        input [`XLEN-1:0] MemWdata,
        output [`XLEN-1:0] MemRdata
    );

    reg [`XLEN-1:0] rdata;
    wire [`XLEN-1:0] wdata;
    wire [`XLEN-1:0] raddr;
    wire [`XLEN-1:0] waddr;
    wire [3:0] mask;
    wire [3:0] wmask;
    // wire MemWr;
    wire MemRd;

    assign raddr = MemAddr;
    assign MemRd = MemRead;

    MuxKey #(.NR_KEY(5), .KEY_LEN(3), .DATA_LEN(`XLEN)) u_ReadMux (
               .out(MemRdata),
               .key(MemOP),
               .lut({
                        3'b000, {{(`XLEN-8){rdata[7]}}, rdata[7:0]},
                        3'b001, {{(`XLEN-16){rdata[15]}}, rdata[15:0]},
                        3'b010, {{(`XLEN-32){rdata[31]}}, rdata[31:0]},
                        3'b100, {{(`XLEN-8){1'b0}}, rdata[7:0]},
                        3'b101, {{(`XLEN-16){1'b0}}, rdata[15:0]}
                    })
           );

    MuxKey #(.NR_KEY(3), .KEY_LEN(3), .DATA_LEN(4)) u_MaskMux (
               .out(mask),
               .key(MemOP),
               .lut({
                        3'b000, 4'b0001,
                        3'b001, 4'b0011,
                        3'b010, 4'b1111
                    })
           );

    import "DPI-C" function void rtl_pmem_read(input int raddr, output int rdata);
    import "DPI-C" function void rtl_pmem_write(input int waddr, input int wdata, input byte wmask);
    // Using always @(*) and Reg causes a bug!
    // Reg #(.WIDTH(2*`XLEN+4+1), .RESET_VAL(0)) u_WriteReg (
    //         .clk(clk),
    //         .rst(rst),
    //         .din({MemAddr, MemWdata, mask, MemWrite}),
    //         .dout({waddr, wdata, wmask, MemWr}),
    //         .wen(1'b1)
    //     );

    // always @(*) begin
    //     if (MemWr)
    //         rtl_pmem_write(waddr, wdata, wmask);
    // end


    // TODO: FIX BUG and remove timing logic
    always @(negedge clk) begin
        if (MemRd)
            rtl_pmem_read(raddr, rdata);
        else
            rdata = 0;
    end

    // TODO: Remove timing logic
    always @(posedge clk) begin
        if (MemWrite)
            rtl_pmem_write(MemAddr, MemWdata, mask);
    end


endmodule
