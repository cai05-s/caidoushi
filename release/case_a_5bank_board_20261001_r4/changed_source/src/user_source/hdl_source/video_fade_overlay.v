module video_fade_overlay #(
    parameter integer FADE_FRAMES = 16,
    parameter integer RECOVERY_ENABLE = 0
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        frame_start,
    input  wire        switch_event,
    input wire switch_hard,
    input  wire        force_commit_toggle,
    input  wire [2:0]  switch_buf_idx,
    input  wire [3:0]  switch_image_idx,
    input  wire        de,
    input  wire [23:0] rgb_in,
    output reg  [23:0] rgb_out,
    output reg  [2:0]  display_buf_idx,
    output reg  [3:0]  display_image_idx,
    output reg         display_started,
    output wire        transition_busy
);

localparam integer STEP = (256 / FADE_FRAMES) == 0 ? 1 : (256 / FADE_FRAMES);
localparam [1:0] S_IDLE = 2'd0, S_OUT = 2'd1, S_IN = 2'd2;
reg [1:0] state;
reg [7:0] alpha;
reg [7:0] r_mix;
reg [7:0] g_mix;
reg [7:0] b_mix;
reg [15:0] r_prod;
reg [15:0] g_prod;
reg [15:0] b_prod;
reg [2:0] pending_buf_idx;
reg [3:0] pending_image_idx;
reg [1:0] recovery_sync;
reg recovery_seen, recovery_pending;
reg hard_pending;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        recovery_sync <= 0; recovery_seen <= 0; recovery_pending <= 0;
    end else if (RECOVERY_ENABLE) begin
        recovery_sync <= {recovery_sync[0], force_commit_toggle};
        if (recovery_sync[1] != recovery_seen) begin
            recovery_seen <= recovery_sync[1]; recovery_pending <= 1;
        end
        if (frame_start && recovery_pending) recovery_pending <= 0;
    end
end

assign transition_busy = (state != S_IDLE) || recovery_pending;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= S_IDLE;
        alpha <= 8'd255;
        display_buf_idx <= 3'd0;
        display_image_idx <= 4'd1;
        display_started <= 0;
        pending_buf_idx <= 3'd0;
        pending_image_idx <= 4'd1; hard_pending <= 0;
    end else begin
        if (RECOVERY_ENABLE && frame_start && recovery_pending) begin
            // frame_start接读帧起点，bank与read_req同拍更新。
            // S_IN至少保护一帧，保证读端已接受新地址才释放旧bank。
            state <= S_IN;
            alpha <= 8'd255;
            display_buf_idx <= switch_buf_idx;
            display_image_idx <= switch_image_idx;
            display_started <= 1;
        end else if (switch_event && (state == S_IDLE || switch_hard)) begin
            state <= S_OUT;
            // 抢占时保持本帧亮度；硬切亮度与bank在下一读帧边界一起更新。
            if (state == S_IDLE) alpha <= 8'd255;
            pending_buf_idx <= switch_buf_idx;
            pending_image_idx <= switch_image_idx;
            hard_pending <= switch_hard;
        end else if (frame_start) begin
            case (state)
                S_OUT: begin
                    if (hard_pending || alpha <= STEP) begin
                        alpha <= hard_pending ? 8'd255 : 8'd0;
                        display_buf_idx   <= pending_buf_idx;
                        display_image_idx <= pending_image_idx;
                        display_started <= 1;
                        state <= S_IN;
                    end else begin
                        alpha <= alpha - STEP;
                    end
                end
                S_IN:  if (alpha >= 8'd255 - STEP) begin alpha <= 8'd255; state <= S_IDLE; end else alpha <= alpha + STEP;
                default: ;
            endcase
        end
    end
end

always @* begin
    if (state == S_IDLE || alpha == 8'd255) begin
        r_prod = 16'd0;
        g_prod = 16'd0;
        b_prod = 16'd0;
        r_mix  = rgb_in[23:16];
        g_mix  = rgb_in[15:8];
        b_mix  = rgb_in[7:0];
        rgb_out = de ? rgb_in : 24'd0;
    end else begin
        r_prod = {8'd0, rgb_in[23:16]} * {8'd0, alpha};
        g_prod = {8'd0, rgb_in[15:8]}  * {8'd0, alpha};
        b_prod = {8'd0, rgb_in[7:0]}   * {8'd0, alpha};
        r_mix = r_prod[15:8];
        g_mix = g_prod[15:8];
        b_mix = b_prod[15:8];
        rgb_out = de ? {r_mix, g_mix, b_mix} : 24'd0;
    end
end

endmodule
