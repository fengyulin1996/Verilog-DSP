`timescale 1ns / 1ps
/*
function : control output(when to take input 
�봮������豸�ļ򵥽ӿڣ��ɽ����豸���������Ƿ��������
*/
module fft_output(
    input wire rst,
    input wire req_i,
    input wire ans_i,
    input wire en,
    input wire [15:0] data_i,
    output wire req_o,
    output wire ans_o,
    output reg [15:0] data_o
    );
    assign req_o = req_i;
    assign ans_o = ans_i;
    always @(*) begin
        if(rst == 1'b0) begin
            data_o <= 16'h0000;
        end
        else if(en == 1'b1) begin
            data_o <= data_i;
        end
    end
endmodule
