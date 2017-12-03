`timescale 1ns / 1ps
/*
function : control input(when to take input
与串行输入设备的简单接口，起到根据主机的状态决定是否传递数据进入的作用，en=1允许输入
端口连接时输入可以用reg，输出必须用wire
*/
module fft_input(
    input wire rstn,
    input wire req_i,
    input wire ans_i,
    input wire en,
    input wire [15:0] data_i,
    output reg req_o,
    output reg ans_o,
    output reg [15:0] data_o
    );
    
    always @(*) begin
        req_o = req_i;
        ans_o = ans_i;
        if(rstn == 1'b0) begin
            data_o <= 16'h0000;
        end
        else if(en == 1'b1) begin
            data_o <= data_i;
        end
    end
endmodule
