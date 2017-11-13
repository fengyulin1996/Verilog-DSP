`timescale 1ns / 1ps
/*
有符号复数乘法器
*/
module mult_cplx(
    input wire clk,
    input wire rstn,
    input wire[15:0] data1R_in,
    input wire[15:0] data1J_in,
    input wire[15:0] data2R_in,
    input wire[15:0] data2J_in,
    output reg[15:0] dataR_out,
    output reg[15:0] dataJ_out
    );
    wire siga,sigb,sigc,sigd,sigr,sigj;
    assign siga = data1R_in[15];
    assign sigb = data1J_in[15];
    assign sigc = data2R_in[15];
    assign sigd = data2J_in[15];    //get符号
    assign sigr = dataR_out[15];
    assign sigj = dataJ_out[15];
    reg[15:0] tempa,tempb,tempc,tempd;    //绝对值
    reg[30:0] ac,ibd,ad,bc;    //乘积项
    always @(*)begin
        if(siga == 1'b1) tempa <= ~(data1R_in) + 16'h0001;
        else tempa <= data1R_in;
        if(sigb == 1'b1) tempb <= ~(data1J_in) + 16'h0001;
        else tempb <= data1J_in;
        if(sigc == 1'b1) tempc <= ~(data2R_in) + 16'h0001;
        else tempc <= data2R_in;
        if(sigd == 1'b1) tempd <= ~(data2J_in) + 16'h0001;
        else tempd <= data2J_in;    //get绝对值
        
        if(siga == sigc) ac <= {16'h0000,tempa[14:0]} * {16'h0000,tempc[14:0]};    //31位
        else ac <= ~({16'h0000,tempa[14:0]} * {16'h0000,tempc[14:0]}) + 31'h0000_0001;
        if(sigb == sigd) ibd <= ~({16'h0000,tempb[14:0]} * {16'h0000,tempd[14:0]}) + 31'h0000_0001;
        else ibd <= {16'h0000,tempb[14:0]} * {16'h0000,tempd[14:0]};
        if(siga == sigd) ad <= {16'h0000,tempa[14:0]} * {16'h0000,tempd[14:0]};
        else ad <= ~({16'h0000,tempa[14:0]} * {16'h0000,tempd[14:0]}) + 31'h0000_0001;
        if(sigb == sigc) bc <= {16'h0000,tempb[14:0]} * {16'h0000,tempc[14:0]};
        else bc <= ~({16'h0000,tempb[14:0]} * {16'h0000,tempc[14:0]}) + 31'h0000_0001;    //get乘积项(有符号）
    end
    always @(*) begin
        if(rstn == 1'b0) begin
            dataR_out <= 16'b0000;
            dataJ_out <= 16'b0000;
        end
        else begin
            dataR_out <= ac[30:15] + ibd[30:15];    //31位有符号数据加法会有溢出！
            dataJ_out <= ad[30:15] + bc[30:15];
        end
    end
endmodule
