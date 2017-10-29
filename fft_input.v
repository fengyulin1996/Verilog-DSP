`timescale 1ns / 1ps
/*
function : control input(when to take input 
�봮�������豸�ļ򵥽ӿڣ��𵽸���������״̬�����Ƿ񴫵����ݽ�������ã�en=1��������
*/
module fft_input(
    input wire rst,
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
        if(rst == 1'b0) begin
            data_o <= 16'h0000;
        end
        else if(en == 1'b1) begin
            data_o <= data_i;
        end
    end
endmodule
