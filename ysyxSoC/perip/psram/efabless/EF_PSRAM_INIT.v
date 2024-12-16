`timescale              1ns/1ps
`default_nettype        none

// Using EBH Command
module PSRAM_INIT (
    // External Interface to Quad I/O
    input   wire            clk,
    input   wire            rst_n,
    input                   start,
    output  wire            done,   
    output  reg             sck,
    output  reg             ce_n,
    output  wire [3:0]      dout,
    output  wire            douten
);

wire[7:0]   CMD_35H = 8'h35;
    
reg [7:0]   counter;
always @ (posedge clk or negedge rst_n)
    if(!rst_n)
        sck <= 1'b0;
    else if(~ce_n)
        sck <= ~ sck;
    else 
        sck <= 1'b0;

always @ (posedge clk or negedge rst_n)
    if(!rst_n)
        ce_n <= 1'b1;
    else if(start)
        ce_n <= 1'b0;
    else
        ce_n <= 1'b1;

always @ (posedge clk or negedge rst_n)
    if(!rst_n)
        counter <= 8'b0;
    else if(sck & ~done)
        counter <= counter + 1'b1;
    else if(ce_n)
        counter <= 8'b0;

assign dout   =  (counter < 8)   ?   {3'b0, CMD_35H[7 - counter]}: 4'h0;
assign douten =  1'b1;
assign done   = (counter == 8);

endmodule