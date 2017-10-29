`timescale 1ns / 1ps
/*
�����ļ�
״̬����д����Թ̶���ͨ����clk�����ظı�a�Ӷ�����״̬ת�ƣ�
over�ı仯��Ҫ��alu�и������������Ŀ�����ݴ�������Ƚ��е���
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
reg [15:0] fft_data_i[0:31];    //��д32��fft
reg [4:0] fft_datai_count;    //������λ����
reg [4:0] fft_datao_count;
wire [4:0] vice_fft_count;
reg [1:0] current_state,next_state;
reg [3:0] over;    //״̬ת����־λ
reg en_input,en_output;
wire [15:0] data_input_c,data_output_c;
reg [15:0] data_output;
reg req_input,req_output;
reg ans_input,ans_output;
wire req_input_c,ans_input_c,ans_o_c,req_output_c,ans_output_c,req_o_c;    //�˿���������,wire-->reg
assign req_input_c = req_input;
assign ans_input_c = ans_input;
assign ans_o_c = ans_o;
assign req_output_c = req_output;
assign ans_output_c = ans_output;
assign req_o_c = req_o;
parameter S0 = 2'b00;    //ͣ�� һλ����
parameter S1 = 2'b01;    //����
parameter S2 = 2'b11;    //����
parameter S3 = 2'b10;    //���
//��λ����
assign vice_fft_count = {fft_datai_count[0],fft_datai_count[1],fft_datai_count[2],fft_datai_count[3],fft_datai_count[4]};    //��λ����

always @(posedge clk) begin    //״̬ת��
    if(rst == 1'b0) current_state <= S0;
    else current_state <= next_state;
end
always @(*) begin    //����߼�����̬����������ź�
    if(rst == 1'b0) begin 
        current_state <= S0;
        next_state <= S0;    //start from S0
        fft_datai_count <= 10'b00000_00000;
        fft_datao_count <= 10'b00000_00000;
    end
    else
        case(current_state)
            S0:begin
               next_state = (req_i==1)?S1:S0;    //����������
               ans_input = 0;    //����������
               req_output = 0;    //���������
               en_input=0;    //fft_in������
               en_output=0;    //fft_out������
               over = 4'b0000;
               end
            S1:begin
               next_state = (over[1] == 1)?S2:S1;
               ans_input = 1;    //��������
               req_output = 0;    //���������
               en_input=1;    //fft_in����
               en_output=0;    //fft_out������
               end
            S2:begin
               next_state = (over[2]==1)?S3:S2;
               ans_input = 0;    //����������
               req_output = 0;    //���������
               en_input=0;    //fft_in������
               en_output=0;    //fft_out������
               end
            S3:begin
               next_state = (over[3]==1)?S0:S3;
               ans_input = 0;    //����������
               req_output = 1;    //�������
               en_input=0;    //fft_in������
               en_output=1;    //fft_out����
               end
        endcase
end
always @(posedge clk) begin    //S0���̣���λ��״̬
    if(current_state == S0) begin
        ans_input <= 0;
        req_output <= 0;
        
        
    end
    else if(current_state == S1) begin    //S1:����+��λ����
        fft_datai_count <= fft_datai_count + 5'b00001;
        fft_data_i[vice_fft_count] <= data_input_c;
        if(fft_datai_count == 5'b11111) over[1] <= 1'b1;
    end
    else if(current_state == S2) begin    //S2���������㣬�ڿ�ʼ�׶��Ǹ��տ���
        
    end
    else if(current_state == S3) begin    //S3���������������ľ�����λ����Ľ��
        fft_datao_count <= fft_datao_count + 5'b00001;
        data_output <= fft_data_i[fft_datao_count];
    end
end

fft_input fft_input
         (.rst(rst),
          .req_i(req_i),    //.�˿�������������
          .data_i(data_i),
          .ans_o(ans_o_c),
          .data_o(data_input_c),
          .en(en_input),
          .req_o(req_input_c),
          .ans_i(ans_input_c)
          );
fft_output fft_output
           (.rst(rst),
            .req_i(req_output_c),    //.�˿�������������
            .data_i(data_output_c),
            .ans_o(ans_output_c),
            .data_o(data_o),
            .en(en_output),
            .req_o(req_output_c),
            .ans_i(ans_output_c)
            );
endmodule
