`include "M.v"

module main();

    reg S, R, clk, rst, b;
    wire rst2;
    wire out, ready;
    wire pos, neg;
    wire Q, Q1;
    
    reg [3:0] dataCnt;
    reg [23:0] data [5:0];
    
    reg [5:0] clk64;
    
    wire [23:0] pixel;
    wire [4:0] address;
    wire transmitter_clk;
    wire out_clk;
    
    assign pixel = data[address];
    
    spiclkgen clk_gen(.clk(clk), .rst(rst), .clk_dvd(transmitter_clk), .shifted(out_clk), .mreset(rst2));    

    linespitransmitter lt(.clk(transmitter_clk), .rst(rst2), .pixel_count(4), .pixel({8'hFF, pixel}), .address(address), .out(out), .done(ready));
    
    always begin
        #10 clk <= ~clk;
    end
    
    always @(posedge ready) begin
        dataCnt <= dataCnt + 1;
    end
    
    always @(posedge clk) begin
        clk64 <= clk64 + 1;
    end
    
    initial begin
        data[0] <= 24'hAAAAAA;
        data[1] <= 24'hCCCCCC;
        data[2] <= 24'hAAAAAA;
        data[3] <= 24'h111111;
        data[4] <= 24'h222222;
        data[5] <= 24'h333333;
        $dumpfile("log.vcd");
        $dumpvars;
        dataCnt <= 0;
        clk64<= 0;
        b <= 1;
        clk <= 0;
        rst <= 1;
        #300 rst <= 0; clk64 <= 0;
        #1300 b <= 0;
        #200000 $finish;
    end
   
endmodule
