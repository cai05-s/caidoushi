`timescale 1ns/1ps

// bilinear_8q8.v —— 双线性插值选做骨架 (第12课扩展)
// 输入：4个相邻像素 p00/p10/p01/p11（左上/右上/左下/右下）
//       wx = (x的小数部分)<<8, wy = (y的小数部分)<<8  (0~255)
// 思路：先按行加权，再按列加权，每步乘16位再取高8位
module bilinear_8q8 (
    input  wire [7:0]  p00_r, p10_r, p01_r, p11_r,
    input  wire [7:0]  p00_g, p10_g, p01_g, p11_g,
    input  wire [7:0]  p00_b, p10_b, p01_b, p11_b,
    input  wire [7:0]  wx,
    input  wire [7:0]  wy,
    output wire [7:0]  out_r,
    output wire [7:0]  out_g,
    output wire [7:0]  out_b
);
    // 综合安全要点：8'd256会溢出截断为0，必须显式声明为9位 9'd256
    wire [8:0]  inv_wx       = 9'd256 - {1'b0, wx};
    wire [8:0]  inv_wy       = 9'd256 - {1'b0, wy};

    // R通道：先水平加权，再垂直加权
    wire [15:0] row_top_r    = p00_r * inv_wx + p10_r * wx;
    wire [15:0] row_bottom_r = p01_r * inv_wx + p11_r * wx;
    wire [15:0] out_r_full   = row_top_r[15:8] * inv_wy + row_bottom_r[15:8] * wy;
    assign out_r             = out_r_full[15:8];

    // G通道
    wire [15:0] row_top_g    = p00_g * inv_wx + p10_g * wx;
    wire [15:0] row_bottom_g = p01_g * inv_wx + p11_g * wx;
    wire [15:0] out_g_full   = row_top_g[15:8] * inv_wy + row_bottom_g[15:8] * wy;
    assign out_g             = out_g_full[15:8];

    // B通道
    wire [15:0] row_top_b    = p00_b * inv_wx + p10_b * wx;
    wire [15:0] row_bottom_b = p01_b * inv_wx + p11_b * wx;
    wire [15:0] out_b_full   = row_top_b[15:8] * inv_wy + row_bottom_b[15:8] * wy;
    assign out_b             = out_b_full[15:8];

endmodule
