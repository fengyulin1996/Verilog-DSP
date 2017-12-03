`timescale 1ns / 1ps
/*
function : control output(when to take input 
与串行输出设备的简单接口，由接收设备决定主机是否向外输出
*/
module fft_output(
    input wire rstn,
    input wire req_i,
    input wire ans_i,
    input wire en,
    input wire [15:0] data_iR,
    input wire [15:0] data_iJ,
    output reg req_o,
    output reg ans_o,
    output reg [15:0] data_oR,
    output reg [15:0] data_oJ
    );
    always @(*) begin
        req_o = req_i;
        ans_o = ans_i;
        if(rstn == 1'b0) begin
            data_oR <= 16'h0000;
            data_oJ <= 16'h0000;
        end
        else if(en == 1'b1) begin
            data_oR <= data_iR;
            data_oJ <= data_iJ;
        end
    end
endmodule
