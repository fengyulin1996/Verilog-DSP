`timescale 1ns / 1ps
/*
顶层文件
状态机的写法相对固定，通过在clk上升沿改变a从而控制状态转移，
over的变化需要在alu中根据输入输出数目，数据处理情况等进行调整
*/
module fft_top(
    input wire clk,
    input wire rst,
    
    input wire req_i,    //fft_in
    output reg ans_o,
    input wire[15:0] data_i,
    
    input wire ans_i,    //from fft_out
    output reg req_o,
    output wire[15:0] data_o
    );
reg [15:0] fft_data_i[0:31];    //先写32点fft
reg [4:0] fft_datai_count;    //方便码位倒序
reg [4:0] fft_datao_count;
wire [4:0] vice_fft_count;
reg [1:0] current_state,next_state;
reg [3:0] over;    //状态转换标志位
reg en_input,en_output;
wire [15:0] data_input_c,data_output_c;
reg [15:0] data_output;
reg req_input,req_output;
reg ans_input,ans_output;
wire req_input_c,ans_input_c,ans_o_c,req_output_c,ans_output_c,req_o_c;    //端口例化连线,wire-->reg
assign req_input_c = req_input;
assign ans_input_c = ans_input;
assign ans_o_c = ans_o;
assign req_output_c = req_output;
assign ans_output_c = ans_output;
assign req_o_c = req_o;
parameter S0 = 2'b00;    //停机 一位热码
parameter S1 = 2'b01;    //输入
parameter S2 = 2'b11;    //处理
parameter S3 = 2'b10;    //输出
//码位倒序
assign vice_fft_count = {fft_datai_count[0],fft_datai_count[1],fft_datai_count[2],fft_datai_count[3],fft_datai_count[4]};    //码位倒序

always @(posedge clk) begin    //状态转换
    if(rst == 1'b0) current_state <= S0;
    else current_state <= next_state;
end
always @(*) begin    //组合逻辑：次态，输出控制信号
    if(rst == 1'b0) begin 
        current_state <= S0;
        next_state <= S0;    //start from S0
        fft_datai_count <= 10'b00000_00000;
        fft_datao_count <= 10'b00000_00000;
    end
    else
        case(current_state)
            S0:begin
               next_state = (req_i==1)?S1:S0;    //有输入请求
               ans_input = 0;    //不允许输入
               req_output = 0;    //不请求输出
               en_input=0;    //fft_in不工作
               en_output=0;    //fft_out不工作
               over = 4'b0000;
               end
            S1:begin
               next_state = (over[1] == 1)?S2:S1;
               ans_input = 1;    //允许输入
               req_output = 0;    //不请求输出
               en_input=1;    //fft_in工作
               en_output=0;    //fft_out不工作
               end
            S2:begin
               next_state = (over[2]==1)?S3:S2;
               ans_input = 0;    //不允许输入
               req_output = 0;    //不请求输出
               en_input=0;    //fft_in不工作
               en_output=0;    //fft_out不工作
               end
            S3:begin
               next_state = (over[3]==1)?S0:S3;
               ans_input = 0;    //不允许输入
               req_output = 1;    //请求输出
               en_input=0;    //fft_in不工作
               en_output=1;    //fft_out工作
               end
        endcase
end
always @(posedge clk) begin    //S0进程，复位后状态
    if(current_state == S0) begin
        ans_input <= 0;
        req_output <= 0;
        
        
    end
    else if(current_state == S1) begin    //S1:输入+码位倒序
        fft_datai_count <= fft_datai_count + 5'b00001;
        fft_data_i[vice_fft_count] <= data_input_c;
        if(fft_datai_count == 5'b11111) over[1] <= 1'b1;
    end
    else if(current_state == S2) begin    //S2：蝶形运算，在开始阶段是个空壳子
        
    end
    else if(current_state == S3) begin    //S3：输出，现在输出的就是码位倒序的结果
        fft_datao_count <= fft_datao_count + 5'b00001;
        data_output <= fft_data_i[fft_datao_count];
    end
end

fft_input fft_input
         (.rst(rst),
          .req_i(req_i),    //.端口名（线网名）
          .data_i(data_i),
          .ans_o(ans_o_c),
          .data_o(data_input_c),
          .en(en_input),
          .req_o(req_input_c),
          .ans_i(ans_input_c)
          );
fft_output fft_output
           (.rst(rst),
            .req_i(req_output_c),    //.端口名（线网名）
            .data_i(data_output_c),
            .ans_o(ans_output_c),
            .data_o(data_o),
            .en(en_output),
            .req_o(req_output_c),
            .ans_i(ans_output_c)
            );
endmodule
