`timescale 1ns / 1ps
//旋转因子16位有符号定点数
//xx==>timing
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
    output wire[15:0] data_oR,
    output wire[15:0] data_oJ
    );
    parameter W80_R=16'b0111_1111_1111_1111;    //1                                      
    parameter W80_J=16'b0000_0000_0000_0000;                                      
    parameter W81_R=16'b0101_1010_1000_0010;    //sqrt(2)/2                                  
    parameter W81_J=16'b1010_0101_0111_1110;    //-sqrt(2)/2                                  
    parameter W82_R=16'b0000_0000_0000_0000;
    parameter W82_J=16'b1000_0000_0000_0001;    //-j                                                                          
    parameter W83_R=16'b1010_0101_0111_1110;    //-sqrt(2)/2                                  
    parameter W83_J=16'b1010_0101_0111_1110;    //-sqrt(2)/2                                  
    parameter W84_R=16'b1000_0000_0000_0001;    //-1
    parameter W84_J=16'b0000_0000_0000_0000;                                      
    parameter W85_R=16'b1010_0101_0111_1110;    //-sqrt(2)/2                                  
    parameter W85_J=16'b0101_1010_1000_0010;    //sqrt(2)/2                                  
    parameter W86_R=16'b0000_0000_0000_0000;
    parameter W86_J=16'b0111_1111_1111_1111;    //1                                                                          
    parameter W87_R=16'b0101_1010_1000_0010;    //sqrt(2)/2                                  
    parameter W87_J=16'b0101_1010_1000_0010;    //sqrt(2)/2
reg [15:0] fft_data_i[0:7];    //先写8点fft
reg [15:0] fft_data_temp1R[0:7];
reg [15:0] fft_data_temp1J[0:7];
reg [15:0] fft_data_temp2R[0:7];
reg [15:0] fft_data_temp2J[0:7];
reg [15:0] fft_data_oR[0:7];
reg [15:0] fft_data_oJ[0:7];
reg [2:0] fft_datai_count;    //方便码位倒序
reg [2:0] fft_datao_count;
wire [2:0] vice_fft_count;
reg [1:0] current_state,next_state;
reg [3:0] over;    //状态转换标志位
reg en_input,en_output;
wire [15:0] data_input_c,data_output_c;
reg [15:0] data_outputR,data_outputJ;
reg req_input,req_output;
reg ans_input,ans_output;
wire req_input_c,ans_input_c,ans_o_c,req_output_c,ans_output_c,req_o_c;    //端口例化连线,wire-->reg
wire [15:0] test;
reg [2:0] diexingji;    //第几级蝶形运算1,2,3
reg [2:0] position;    //从上到下第几个数（简单点，别用状态机了）0:7
reg[15:0] data1R_in, data1J_in, data2R_in, data2J_in, dataR_out, dataJ_out;    //复数乘法器连线
wire[15:0] dataR_out_connect,dataJ_out_connect;
//assign dataR_out_connect = dataR_out;
//assign dataJ_out_connect = dataJ_out;
assign req_input_c = req_input;
assign ans_input_c = ans_input;
assign ans_o_c = ans_o;
assign req_output_c = req_output;
assign ans_output_c = ans_output;
assign req_o_c = req_o;
parameter S0 = 2'b00;    //停机
parameter S1 = 2'b01;    //输入
parameter S2 = 2'b10;    //处理
parameter S3 = 2'b11;    //输出
//码位倒序
assign vice_fft_count = {fft_datai_count[0],fft_datai_count[1],fft_datai_count[2]};    //码位倒序
assign test = 16'b0000_0000_0000_0000;
always @(posedge clk) begin    //状态转换
    if(rst == 1'b0) current_state <= S0;
    else current_state <= next_state;
end
always @(*) begin    //组合逻辑：次态，输出控制信号
    dataR_out <= dataR_out_connect;
    dataJ_out <= dataJ_out_connect;
    if(rst == 1'b0) begin 
        current_state <= S0;
        next_state <= S0;    //start from S0
        fft_datai_count <= 3'b000;
        fft_datao_count <= 3'b000;
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
        diexingji = 3'b000;
        position = 3'b000;
        /*
        fft_data_temp1R[0] <= 16'h0000;
        fft_data_temp1R[1] <= 16'h0000;
        fft_data_temp1R[2] <= 16'h0000;
        fft_data_temp1R[3] <= 16'h0000;
        fft_data_temp1R[4] <= 16'h0000;
        fft_data_temp1R[5] <= 16'h0000;
        fft_data_temp1R[6] <= 16'h0000;
        fft_data_temp1R[7] <= 16'h0000;
        
        fft_data_temp1J[0] <= 16'h0000;
        fft_data_temp1J[1] <= 16'h0000;
        fft_data_temp1J[2] <= 16'h0000;
        fft_data_temp1J[3] <= 16'h0000;
        fft_data_temp1J[4] <= 16'h0000;
        fft_data_temp1J[5] <= 16'h0000;
        fft_data_temp1J[6] <= 16'h0000;
        fft_data_temp1J[7] <= 16'h0000;
        
        fft_data_temp2R[0] <= 16'h0000;
        fft_data_temp2R[1] <= 16'h0000;
        fft_data_temp2R[2] <= 16'h0000;
        fft_data_temp2R[3] <= 16'h0000;
        fft_data_temp2R[4] <= 16'h0000;
        fft_data_temp2R[5] <= 16'h0000;
        fft_data_temp2R[6] <= 16'h0000;
        fft_data_temp2R[7] <= 16'h0000;
        
        fft_data_temp2J[0] <= 16'h0000;
        fft_data_temp2J[1] <= 16'h0000;
        fft_data_temp2J[2] <= 16'h0000;
        fft_data_temp2J[3] <= 16'h0000;
        fft_data_temp2J[4] <= 16'h0000;
        fft_data_temp2J[5] <= 16'h0000;
        fft_data_temp2J[6] <= 16'h0000;
        fft_data_temp2J[7] <= 16'h0000;
        */
    end
    else if(current_state == S1) begin    //S1:输入+码位倒序
        over[2] <= 1'b0;
        fft_datai_count <= fft_datai_count + 3'b001;
        fft_data_i[vice_fft_count] <= data_input_c;
        if(fft_datai_count == 3'b110) begin
        over[1] <= 1'b1;
        diexingji <= 2'b0;    //为下面的状态做初始化
        position  <= 3'b000;
        end
    end
    else if(current_state == S2) begin    //S2：蝶形运算，在开始阶段是个空壳子
        case(diexingji)
            2'b00:begin    //刚进入S2，输入第一个乘法
                  diexingji <= 2'b01;
                  position  <= 3'b000;
                  data1R_in <= fft_data_i[4];
                  data1J_in <= 16'h0000;
                  data2R_in <= W80_R;
                  data2J_in <= W80_J;
                  end
            2'b01:begin
                  case(position)
                      3'b000:
                      begin
                          fft_data_temp1R[0] <= dataR_out_connect + fft_data_i[0];    //当前数运算结果
                          fft_data_temp1J[0] <= dataJ_out_connect;
                          position  <= 3'b001;
                          data1R_in <= fft_data_i[4];    //下一次乘法
                          data1J_in <= 16'h0000;
                          data2R_in <= W84_R;
                          data2J_in <= W84_J;
                      end
                      3'b001:
                      begin
                        fft_data_temp1R[1] <= dataR_out + fft_data_i[0];    //当前数运算结果
                        fft_data_temp1J[1] <= dataJ_out;
                        position  <= 3'b010;
                        data1R_in <= fft_data_i[6];     //下一次乘法
                        data1J_in <= 16'h0000;
                        data2R_in <= W80_R;
                        data2J_in <= W80_J;
                      end
                      3'b010:
                      begin
                          fft_data_temp1R[2] <= dataR_out + fft_data_i[2];    //当前数运算结果
                          fft_data_temp1J[2] <= dataJ_out;
                          position  <= 3'b011;
                          data1R_in <= fft_data_i[6];    //下一次乘法
                          data1J_in <= 16'h0000;
                          data2R_in <= W84_R;
                          data2J_in <= W84_J;
                      end
                      3'b011:
                      begin
                        fft_data_temp1R[3] <= dataR_out + fft_data_i[2];    //当前数运算结果
                        fft_data_temp1J[3] <= dataJ_out;
                        position  <= 3'b100;
                        data1R_in <= fft_data_i[5];    //下一次乘法
                        data1J_in <= 16'h0000;
                        data2R_in <= W80_R;
                        data2J_in <= W80_J;
                      end
                      3'b100:
                      begin
                          fft_data_temp1R[position] <= dataR_out + fft_data_i[1];    //当前数运算结果
                          fft_data_temp1J[position] <= dataJ_out;
                          position  <= 3'b101;
                          data1R_in <= fft_data_i[5];    //下一次乘法
                          data1J_in <= 16'h0000;
                          data2R_in <= W84_R;
                          data2J_in <= W84_J;
                      end
                      3'b101:
                      begin
                        fft_data_temp1R[position] <= dataR_out + fft_data_i[1];    //当前数运算结果
                        fft_data_temp1J[position] <= dataJ_out;
                        position  <= 3'b110;
                        data1R_in <= fft_data_i[7];    //下一次乘法
                        data1J_in <= 16'h0000;
                        data2R_in <= W80_R;
                        data2J_in <= W80_J;
                      end
                      3'b110:
                      begin
                          fft_data_temp1R[position] <= dataR_out + fft_data_i[3];    //当前数运算结果
                          fft_data_temp1J[position] <= dataJ_out;
                          position  <= 3'b111;
                          data1R_in <= fft_data_i[7];    //下一次乘法
                          data1J_in <= 16'h0000;
                          data2R_in <= W84_R;
                          data2J_in <= W84_J;
                      end
                      3'b111:
                      begin
                        fft_data_temp1R[position] <= dataR_out + fft_data_i[3];    //当前数运算结果
                        fft_data_temp1J[position] <= dataJ_out;
                        position  <= 3'b000;
                        diexingji <= 2'b10;
                        data1R_in <= fft_data_temp1R[2];    //下一次乘法
                        data1J_in <= fft_data_temp1J[2];
                        data2R_in <= W80_R;
                        data2J_in <= W80_J;
                      end
                  endcase
                  end
            2'b10:begin
                  case(position)
                  3'b000:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[0] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[0] + dataJ_out;
                      position <= 3'b001;
                      data1R_in <= fft_data_temp1R[3];    //下一次乘法
                      data1J_in <= fft_data_temp1J[3];
                      data2R_in <= W82_R;
                      data2J_in <= W82_J;
                  end
                  3'b001:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[1] + dataR_out;
                      fft_data_temp2J[position] <= fft_data_temp1J[1] + dataJ_out;
                      position <= 3'b010;
                      data1R_in <= fft_data_temp1R[2];    //下一次乘法
                      data1J_in <= fft_data_temp1J[2];
                      data2R_in <= W84_R;
                      data2J_in <= W84_J;
                  end                  
                  3'b010:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[0] + dataR_out;
                      fft_data_temp2J[position] <= fft_data_temp1J[0] + dataJ_out;
                      position <= 3'b011;
                      data1R_in <= fft_data_temp1R[3];    //下一次乘法
                      data1J_in <= fft_data_temp1J[3];
                      data2R_in <= W86_R;
                      data2J_in <= W86_J;
                  end                                    
                  3'b011:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[1] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[1] + dataJ_out;
                      position <= 3'b100;
                      data1R_in <= fft_data_temp1R[6];    //下一次乘法
                      data1J_in <= fft_data_temp1J[6];
                      data2R_in <= W80_R;
                      data2J_in <= W80_J;
                  end
                  3'b100:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[4] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[4] + dataJ_out;
                      position <= 3'b101;
                      data1R_in <= fft_data_temp1R[7];    //下一次乘法
                      data1J_in <= fft_data_temp1J[7];
                      data2R_in <= W82_R;
                      data2J_in <= W82_J;
                  end
                  3'b101:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[5] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[5] + dataJ_out;
                      position <= 3'b110;
                      data1R_in <= fft_data_temp1R[6];    //下一次乘法
                      data1J_in <= fft_data_temp1J[6];
                      data2R_in <= W84_R;
                      data2J_in <= W84_J;
                  end
                  3'b110:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[4] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[4] + dataJ_out;
                      position <= 3'b111;
                      data1R_in <= fft_data_temp1R[7];    //下一次乘法
                      data1J_in <= fft_data_temp1J[7];
                      data2R_in <= W86_R;
                      data2J_in <= W86_J;
                  end
                  3'b111:begin
                      fft_data_temp2R[position] <= fft_data_temp1R[5] + dataR_out;//同址运算
                      fft_data_temp2J[position] <= fft_data_temp1J[5] + dataJ_out;
                      position <= 3'b000;
                      diexingji <= 2'b11;
                      data1R_in <= fft_data_temp1R[7];    //下一次乘法
                      data1J_in <= fft_data_temp1J[7];
                      data2R_in <= W80_R;
                      data2J_in <= W80_J;
                  end
                  endcase
                  end
            2'b11:begin
                  case(position)
                  3'b000:begin
                      fft_data_oR[position] <= fft_data_temp2R[0] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[0] + dataJ_out;
                      position <= 3'b001;
                      data1R_in <= fft_data_temp2R[5];    //下一次乘法
                      data1J_in <= fft_data_temp2J[5];
                      data2R_in <= W81_R;
                      data2J_in <= W81_J;
                  end
                  3'b001:begin
                      fft_data_oR[position] <= fft_data_temp2R[1] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[1] + dataJ_out;
                      position <= 3'b010;
                      data1R_in <= fft_data_temp2R[6];    //下一次乘法
                      data1J_in <= fft_data_temp2J[6];
                      data2R_in <= W82_R;
                      data2J_in <= W82_J;
                  end
                  3'b010:begin
                      fft_data_oR[position] <= fft_data_temp2R[2] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[2] + dataJ_out;
                      position <= 3'b011;
                      data1R_in <= fft_data_temp2R[7];    //下一次乘法
                      data1J_in <= fft_data_temp2J[7];
                      data2R_in <= W83_R;
                      data2J_in <= W83_J;
                  end
                  3'b011:begin
                      fft_data_oR[position] <= fft_data_temp2R[3] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[3] + dataJ_out;
                      position <= 3'b100;
                      data1R_in <= fft_data_temp2R[4];    //下一次乘法
                      data1J_in <= fft_data_temp2J[4];
                      data2R_in <= W84_R;
                      data2J_in <= W84_J;
                  end
                  3'b100:begin
                      fft_data_oR[position] <= fft_data_temp2R[0] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[0] + dataJ_out;
                      position <= 3'b101;
                      data1R_in <= fft_data_temp2R[5];    //下一次乘法
                      data1J_in <= fft_data_temp2J[5];
                      data2R_in <= W85_R;
                      data2J_in <= W85_J;
                  end
                  3'b101:begin
                      fft_data_oR[position] <= fft_data_temp2R[1] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[1] + dataJ_out;
                      position <= 3'b110;
                      data1R_in <= fft_data_temp2R[6];    //下一次乘法
                      data1J_in <= fft_data_temp2J[6];
                      data2R_in <= W86_R;
                      data2J_in <= W86_J;
                  end
                  3'b110:begin
                      fft_data_oR[position] <= fft_data_temp2R[2] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[2] + dataJ_out;
                      position <= 3'b111;
                      data1R_in <= fft_data_temp2R[7];    //下一次乘法
                      data1J_in <= fft_data_temp2J[7];
                      data2R_in <= W87_R;
                      data2J_in <= W87_J;
                  end
                  3'b111:begin
                      fft_data_oR[position] <= fft_data_temp2R[3] + dataR_out;//同址运算
                      fft_data_oJ[position] <= fft_data_temp2J[3] + dataJ_out;
                      position <= 3'b000;
                      data1R_in <= fft_data_temp2R[0];    //下一次乘法
                      data1J_in <= fft_data_temp2J[0];
                      data2R_in <= W80_R;
                      data2J_in <= W80_J;
                      over[2] <= 1'b1;
                  end
                  endcase
            end
        endcase
    end
    else if(current_state == S3) begin    //S3：输出，现在输出的就是码位倒序的结果
        fft_datao_count <= fft_datao_count + 3'b001;
        data_outputR <= fft_data_oR[fft_datao_count];
        data_outputJ <= fft_data_oJ[fft_datao_count];
    end
end
mult_cplx mult_cplx    //复数乘法器的输入输出接到reg上
    (.clk(clk),
     .rstn(rst),
     .data1R_in(data1R_in),
     .data1J_in(data1J_in),
     .data2R_in(data2R_in),
     .data2J_in(data2J_in),
     .dataR_out(dataR_out_connect),
     .dataJ_out(dataJ_out_connect)
    );
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
            .data_iR(data_outputR),
            .data_iJ(data_outputJ),
            .ans_o(ans_output_c),
            .data_oR(data_oR),
            .data_oJ(data_oJ),
            .en(en_output),
            .req_o(req_output_c),
            .ans_i(ans_output_c)
            );
endmodule
