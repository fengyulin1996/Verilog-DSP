`timescale 1ns / 1ps
/*
有符号乘累加，低电平复位，组合逻辑电路（关键路径长）
最高位（15）符号位，低八位小数，当整数乘法后截取中间[31:16]
R+Ji=(a+bi)(c+di)+e+fi
R=ac-bd+e
J=bc+ad+f
*/
module MAC(
    input wire rstn,
    input wire[15:0] a,
    input wire[15:0] b,
    input wire[15:0] c,
    input wire[15:0] d,
    input wire[15:0] e,
    input wire[15:0] f,
    
    output reg[15:0] R,
    output reg[15:0] J,
    output reg over_m,    //乘法溢出
    output reg over_a     //加法溢出
    );
    wire siga,sigb,sigc,sigd;
    assign siga = a[15];assign sigb = b[15];
    assign sigc = c[15];assign sigd = d[15];
    reg absa,absb,absc,absd;
    reg[31:0] ac,ibd,ad,bc;
    reg[31:0] R_temp,J_temp;
    always @(*) begin
        if(siga==1'b1) absa = ~a+16'h0001;
        else absa = a;
        if(sigb==1'b1) absb = ~b+16'h0001;
        else absb = b;
        if(sigc==1'b1) absc = ~c+16'h0001;
        else absc = c;
        if(sigd==1'b1) absd = ~d+16'h0001;
        else absd = d;    //get abs
        
        if(siga==sigc) ac = {16'h0000,absa}*{16'h0000,absc};
        else ac = ~({16'h0000,absa}*{16'h0000,absc})+32'h0000_0001;
        if(sigb==sigd) ibd = ~({16'h0000,absb}*{16'h0000,absd})+32'h0000_0001;
        else ibd = {16'h0000,absb}*{16'h0000,absd};
        if(sigb==sigc) bc = {16'h0000,absb}*{16'h0000,absc};
        else bc = ~({16'h0000,absb}*{16'h0000,absc})+32'h0000_0001;
        if(siga==sigd) ad = {16'h0000,absa}*{16'h0000,absd};
        else ad = ~({16'h0000,absa}*{16'h0000,absd})+32'h0000_0001;    //get mult
        
        R_temp = ac + ibd + {e[15],e[15],e[15],e[15],e[15],e[15],e[15],e[15],e,8'h00};    //符号拓展
        J_temp = ad + bc  + {f[15],f[15],f[15],f[15],f[15],f[15],f[15],f[15],f,8'h00};
        
        if(rstn == 1'b1) begin    //复位信号决定输出
            R = R_temp[23:8];
            J = J_temp[23:8];    //截位
            if(R_temp[31]==R_temp[30] && R_temp[30]==R_temp[29] && 
            R_temp[29]==R_temp[28] && R_temp[28]==R_temp[27] && 
            R_temp[27]==R_temp[26] && R_temp[26]==R_temp[25] && 
            R_temp[25]==R_temp[24] && R_temp[24]==R_temp[23] && 
            J_temp[31]==J_temp[30] && J_temp[30]==J_temp[29] && 
            J_temp[29]==J_temp[28] && J_temp[28]==J_temp[27] && 
            J_temp[27]==J_temp[26] && J_temp[26]==J_temp[25] && 
            J_temp[25]==J_temp[24] && J_temp[24]==J_temp[23]) over_a = 1'b0;
            else over_a = 1'b1;
        end
        else begin
            R = 16'h0000;
            J = 16'h0000;
            over_m = 1'b0;
            over_a = 1'b0;
        end
    end    //always
endmodule
