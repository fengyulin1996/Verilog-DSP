`timescale 1ns / 1ps
module tb_input_top6();
reg clk,rst;
reg req;
reg [15:0] data;    //input

initial begin
    clk = 1'b0;
    rst = 1'b0;    //复位
    req = 1'b1;    //打开输入请求
    data = 16'h7fff;    //输入1
    #40 rst = 1'b1;    // 解除复位
    #40 data = 16'h0000;    //输入0
end

always begin
    #5 clk = ~clk;    //10ns 时钟
end
fft_top fft_top
    (.clk(clk),
     .rst(rst),
     .req_i(req),
     .data_i(data)
     );
endmodule
