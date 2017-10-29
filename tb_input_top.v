`timescale 1ns / 1ps
module tb_input_top();
reg clk,rst;
reg req;
reg [15:0] data;    //input

initial begin
    clk = 1'b0;
    rst = 1'b0;    //��λ
    req = 1'b1;    //����������
    data = 16'hffff;    //����1
    #40 rst = 1'b1;    // �����λ
    #200 data = 16'h0000;    //����0
end

always begin
    #5 clk = ~clk;    //10ns ʱ��
end
fft_top fft_top
    (.clk(clk),
     .rst(rst),
     .req_i(req),
     .data_i(data)
     );
endmodule
