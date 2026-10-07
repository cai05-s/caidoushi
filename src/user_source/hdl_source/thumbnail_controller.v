`timescale 1ns/1ps

// thumbnail_controller.v —— 第14课：缩略图交互选择控制器
module thumbnail_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        key_right,   // 焦点右移脉冲
    input  wire        key_left,    // 焦点左移脉冲
    input  wire        key_confirm, // 确认选中脉冲
    input  wire        key_mode,    // 模式切换脉冲
    input  wire [3:0]  image_complete,
    input  wire        frame_start, // 场同步帧边界
    output reg         view_mode,   // 0=全屏 1=缩略图
    output reg [1:0]   focus_index,
    output reg [1:0]   active_index,
    output reg         transition_req
);
    reg trans_pend;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            view_mode      <= 1'b0;
            focus_index    <= 2'd0;
            active_index   <= 2'd0;
            transition_req <= 1'b0;
            trans_pend     <= 1'b0;
        end else begin
            transition_req <= 1'b0;

            if (key_mode) begin
                view_mode  <= ~view_mode;
                trans_pend <= 1'b1;
            end

            if (view_mode && key_right) begin
                focus_index <= (focus_index == 2'd3) ? 2'd0 : focus_index + 1'b1;
            end
            if (view_mode && key_left) begin
                focus_index <= (focus_index == 2'd0) ? 2'd3 : focus_index - 1'b1;
            end

            if (view_mode && key_confirm && image_complete[focus_index]) begin
                active_index <= focus_index;
                view_mode    <= 1'b0;
                trans_pend   <= 1'b1;
            end

            if (frame_start && trans_pend) begin
                transition_req <= 1'b1;
                trans_pend     <= 1'b0;
            end
        end
    end

endmodule
