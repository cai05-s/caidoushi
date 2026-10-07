`timescale 1ns/1ps

// =========================================================================
// 亮度与对比度实时调节模块 (Brightness & Contrast Adjust Pipeline)
// 适配安路 FPGA，1 时钟周期流水线
// 特性：
// 1. 最高亮度档(255)且标准对比度(128)时，硬件直通 bypass，原汁原味零精度损失
// 2. 带四舍五入舍入补偿(+128)，杜绝向下截断引起的暗部发黑与偏色
// 3. 亮度系数按 (channel*brightness+128)>>8 缩放；标准对比度路径
//    保留该结果，避免带符号中心化错误把暗部全部截成黑色。
// =========================================================================

module brightness_contrast_adjust (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_de,
    input  wire [23:0] rgb_in,
    input  wire [7:0]  brightness,   // 亮度系数 (255=100%, 154约60%, 102=40%)
    input  wire [7:0]  contrast,     // 对比度系数 (128=100%, 160=125%, 192=150%, 96=75%, 64=50%)
    output reg         out_de,
    output reg  [23:0] rgb_out
);

    wire is_bypass = (brightness == 8'd255) && (contrast == 8'd128);

    // ---- R 通道 ----
    wire [16:0] mul_r = rgb_in[23:16] * brightness + 8'd128;
    wire [7:0]  bright_r = (brightness == 8'd255) ? rgb_in[23:16] : mul_r[15:8];
    wire signed [8:0]  ctr_r = ({1'b0, bright_r}) - 9'sd128;
    wire signed [17:0] contrast_ext = $signed({10'd0, contrast});
    wire signed [17:0] ctr_r_product = ctr_r * contrast_ext;
    wire signed [18:0] sc_r = ctr_r_product + 19'sd64;
    wire signed [10:0] sum_r = (sc_r >>> 7) + 11'sd128;
    wire [7:0] final_r = (contrast == 8'd128) ? bright_r :
                         (sum_r < 11'sd0)   ? 8'd0   :
                         (sum_r > 11'sd255) ? 8'd255 : sum_r[7:0];

    // ---- G 通道 ----
    wire [16:0] mul_g = rgb_in[15:8] * brightness + 8'd128;
    wire [7:0]  bright_g = (brightness == 8'd255) ? rgb_in[15:8] : mul_g[15:8];
    wire signed [8:0]  ctr_g = ({1'b0, bright_g}) - 9'sd128;
    wire signed [17:0] ctr_g_product = ctr_g * contrast_ext;
    wire signed [18:0] sc_g = ctr_g_product + 19'sd64;
    wire signed [10:0] sum_g = (sc_g >>> 7) + 11'sd128;
    wire [7:0] final_g = (contrast == 8'd128) ? bright_g :
                         (sum_g < 11'sd0)   ? 8'd0   :
                         (sum_g > 11'sd255) ? 8'd255 : sum_g[7:0];

    // ---- B 通道 ----
    wire [16:0] mul_b = rgb_in[7:0] * brightness + 8'd128;
    wire [7:0]  bright_b = (brightness == 8'd255) ? rgb_in[7:0] : mul_b[15:8];
    wire signed [8:0]  ctr_b = ({1'b0, bright_b}) - 9'sd128;
    wire signed [17:0] ctr_b_product = ctr_b * contrast_ext;
    wire signed [18:0] sc_b = ctr_b_product + 19'sd64;
    wire signed [10:0] sum_b = (sc_b >>> 7) + 11'sd128;
    wire [7:0] final_b = (contrast == 8'd128) ? bright_b :
                         (sum_b < 11'sd0)   ? 8'd0   :
                         (sum_b > 11'sd255) ? 8'd255 : sum_b[7:0];

    // 打一拍流水线寄存器与 DE 对齐
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_de  <= 1'b0;
            rgb_out <= 24'h000000;
        end else begin
            out_de  <= in_de;
            rgb_out <= {final_r, final_g, final_b};
        end
    end

endmodule
