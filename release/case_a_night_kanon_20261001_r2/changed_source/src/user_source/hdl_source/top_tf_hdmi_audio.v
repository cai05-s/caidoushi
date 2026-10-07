`timescale 1ns/1ps

module top(
    input                       clk,
    input                       key1, // A2：轮播暂停/继续
    input                       key2, // B2：应急进入/解除
    input                       key3, // B1：刷新TF目录
    input                       key4, // C1：常态下一张
    input                       sw1, sw2, sw3, sw4,
    output                      buzzer,
    output [3:0]                led,

    output [5:0]                seg_sel,
    output [7:0]                seg_data,

    // HDMI TMDS
    output                      HDMI_CLK_P,
    output                      HDMI_D2_P,
    output                      HDMI_D1_P,
    output                      HDMI_D0_P,

    // HDMI DDC
    output                      HDMI_DDC_SCL,
    inout                       HDMI_DDC_SDA,

    // TF card SPI
    output                      sd_ncs,
    output                      sd_dclk,
    output                      sd_mosi,
    input                       sd_miso
);

parameter MEM_DATA_BITS = 32;
parameter ADDR_BITS     = 21;
parameter BUSRT_BITS    = 10;
parameter [ADDR_BITS-1:0] FRAME_PIXELS = 307200;   // 640*480
parameter [ADDR_BITS-1:0] BUF0_ADDR = 0;
parameter [ADDR_BITS-1:0] BUF1_ADDR = FRAME_PIXELS;
parameter [ADDR_BITS-1:0] BUF2_ADDR = FRAME_PIXELS * 2;
parameter [ADDR_BITS-1:0] BUF3_ADDR = FRAME_PIXELS * 3;
parameter [ADDR_BITS-1:0] BUF4_ADDR = FRAME_PIXELS * 4;

wire Sdr_init_done;
wire Sdr_init_ref_vld;
wire Sdr_busy;

wire sd_card_clk;
wire ext_mem_clk;
wire ext_mem_clk_sft;
wire video_clk;
wire hdmi_5x_clk;

wire hs;
wire vs;
wire de;

wire [23:0] vout_data_raw;
wire [23:0] vout_data;
wire [23:0] vout_data_faded;
wire [23:0] vout_data_adj;
wire        adj_de;
wire [23:0] vout_data_display;
wire [23:0] vout_data_osd;
wire [23:0] vout_data_emergency;
wire        display_valid;
wire        auto_play_status;
wire [15:0] current_image_width_sd;
wire [15:0] current_image_height_sd;
wire        current_image_info_valid_sd;
wire [7:0]  current_image_error_sd;
wire [7:0]  night_error_sd;
// Only the presentation status merges audio errors.  Image scheduling and
// resident-bank validity continue to use the original image error signals.
wire [7:0]  media_error_sd = current_image_error_sd != 0 ? current_image_error_sd : night_error_sd;
wire        sd_init_done, sd_io_error, rescan_accepted_sd;
wire        night_sd_req, night_sd_accept, night_sd_priority;
wire [31:0] night_sd_addr;
wire [7:0]  night_sd_data;
wire        night_sd_valid, night_sd_end;
wire        night_pcm_valid, night_pcm_ready, night_drain;
wire signed [15:0] night_pcm_left, night_pcm_right;
wire        emergency_active_sd;
wire        transition_recover_toggle;
reg [1:0]   display_valid_sync;
reg         display_valid_frame;
reg [2:0]   displayed_buf_sd1, displayed_buf_sd2;
reg [15:0]  image_width_sync1, image_width_sync2;
reg [15:0]  image_height_sync1, image_height_sync2;
reg         image_info_sync1, image_info_sync2;
reg [7:0]   image_error_sync1, image_error_sync2;
reg [15:0]  image_width_frame, image_height_frame;
reg         image_info_frame;
reg [7:0]   image_error_frame;

wire [3:0]  image_state_code;
wire [3:0]  state_code = image_state_code == 4'he ? 4'he :
    (media_error_sd != 0 ? 4'hf : image_state_code);
wire [6:0]  seg_data_0;

wire        video_read_req;
wire        video_read_req_ack;
wire        video_read_en;
wire [31:0] video_read_data;

wire        sd_card_write_en;
wire [31:0] sd_card_write_data;
wire        sd_card_write_req;
wire        sd_card_write_req_ack;
wire        sd_card_write_ready;
wire        frame_write_finish;
reg         frame_write_toggle_mem;

wire [2:0]  write_buf_idx;
wire [2:0]  disp_buf_idx;
reg [2:0]   disp_buf_sync;
reg [2:0]   disp_buf_sync_d;
reg [2:0]   disp_buf_sync_d2;
reg         auto_sync1;
reg         auto_sync2;
reg         osd_sync1;
reg         osd_sync2;
reg [3:0]   state_sync1;
reg [3:0]   state_sync2;
wire        buffer_switch_event;
wire [9:0]  pixel_x;
wire [9:0]  pixel_y;
wire        frame_start;
wire        frame_read_start;
wire        display_commit_toggle_sd;
reg [2:0]  display_commit_sync;
wire        rescan_active_sd;
wire [4:0] bank_ready_sd;
reg [1:0]  rescan_sync;
reg [4:0]  ready_sync1, ready_sync2;
reg        loading_frame;
reg [4:0]  ready_frame;
reg [5:0]  loading_phase;
wire [2:0]  fade_display_buf_idx;
wire [3:0]  fade_display_image_idx;
wire        fade_transition_busy;
wire        fade_display_started;
reg         transition_busy_sd1;
reg         transition_busy_sd2;

wire App_rd_en;
wire [ADDR_BITS-1:0] App_rd_addr;
wire Sdr_rd_en;
wire [MEM_DATA_BITS-1:0] Sdr_rd_dout;
wire App_wr_en;
wire [ADDR_BITS-1:0] App_wr_addr;
wire [MEM_DATA_BITS-1:0] App_wr_din;
wire [3:0] App_wr_dm;

wire hs_0;
wire vs_0;
wire de_0;

wire [9:0]  tmds_ch0_data;
wire [9:0]  tmds_ch1_data;
wire [9:0]  tmds_ch2_data;
wire [9:0]  tmds_clk_data;

// ??????
wire rst_all;
// 配置完成后的寄存器初值由TD配置位实现；不依赖KEY4复位。
reg [15:0] power_count = 16'd0;
wire power_reset = power_count != 16'hffff;
always @(posedge clk) if (power_reset) power_count <= power_count + 1'b1;
wire sys_locked, video_locked;
wire reset_request = power_reset || !sys_locked || !video_locked;
wire sys_reset_n, sd_reset_n, mem_reset_n, video_reset_n, serial_reset_n;
reset_sync u_reset_sys (.clk(clk), .ext_rst_n(!reset_request), .rst_n_sync(sys_reset_n));
reset_sync u_reset_sd (.clk(sd_card_clk), .ext_rst_n(!reset_request), .rst_n_sync(sd_reset_n));
reset_sync u_reset_mem (.clk(ext_mem_clk), .ext_rst_n(!reset_request), .rst_n_sync(mem_reset_n));
reset_sync u_reset_video (.clk(video_clk), .ext_rst_n(!reset_request), .rst_n_sync(video_reset_n));
reset_sync u_reset_serial (.clk(hdmi_5x_clk), .ext_rst_n(!reset_request), .rst_n_sync(serial_reset_n));
assign rst_all = !video_reset_n;
wire [2:0] current_image_index_sd;
wire commit_hard_sd;
wire [3:0] activity_sd;
reg [2:0] image_idx_sync1, image_idx_sync2;
reg commit_hard_sync1, commit_hard_sync2;
reg emergency_video_sync1, emergency_video_sync2, emergency_video_frame;
reg [3:0] switches_sync1, switches_sync2;
reg [3:0] switches_candidate, switches_stable;
reg [3:0] switches_pipe1, switches_pipe2, switches_frame;
reg [20:0] switches_count;
// 整组拨码在像素域连续稳定50ms后接受，避免机械抖动反复换曲。
always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        switches_sync1 <= 0; switches_sync2 <= 0;
        switches_candidate <= 0; switches_stable <= 0; switches_count <= 0;
        switches_pipe1 <= 0; switches_pipe2 <= 0; switches_frame <= 0;
    end else begin
        switches_sync1 <= {sw4,sw3,sw2,sw1}; switches_sync2 <= switches_sync1;
        if (switches_sync2 != switches_candidate) begin
            switches_candidate <= switches_sync2; switches_count <= 0;
        end else if (switches_count < 21'd1249999) begin
            switches_count <= switches_count + 1'b1;
        end else begin
            switches_stable <= switches_candidate;
        end
        // 与亮度目标的两级流水同拍，在帧边界采用同一组设置。
        switches_pipe1 <= switches_stable; switches_pipe2 <= switches_pipe1;
        if (frame_start) switches_frame <= switches_pipe2;
    end
end
reg [1:0] emergency_sys_sync, valid_sys_sync, error_sys_sync;
always @(posedge clk or negedge sys_reset_n) begin
    if (!sys_reset_n) begin emergency_sys_sync <= 0; valid_sys_sync <= 0; error_sys_sync <= 0; end
    else begin
        emergency_sys_sync <= {emergency_sys_sync[0],emergency_active_sd};
        valid_sys_sync <= {valid_sys_sync[0],display_valid};
        error_sys_sync <= {error_sys_sync[0],media_error_sd != 0};
    end
end
assign buzzer = !emergency_sys_sync[1]; // SW1只管背景音乐；SW5仍是蜂鸣器硬件开关
assign led = {error_sys_sync[1], !valid_sys_sync[1], emergency_sys_sync[1], valid_sys_sync[1] && !emergency_sys_sync[1]};
always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        image_idx_sync1 <= 0; image_idx_sync2 <= 0;
        commit_hard_sync1 <= 0; commit_hard_sync2 <= 0;
        emergency_video_sync1 <= 0; emergency_video_sync2 <= 0; emergency_video_frame <= 0;
    end else begin
        image_idx_sync1 <= current_image_index_sd; image_idx_sync2 <= image_idx_sync1;
        commit_hard_sync1 <= commit_hard_sd; commit_hard_sync2 <= commit_hard_sync1;
        emergency_video_sync1 <= emergency_active_sd; emergency_video_sync2 <= emergency_video_sync1;
        if (frame_start) emergency_video_frame <= emergency_video_sync2;
    end
end
// 多位 bank/图号保持到显示确认，以独立 toggle 通知像素域。
assign buffer_switch_event = display_commit_sync[2] ^ display_commit_sync[1];
always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        display_commit_sync <= 0; rescan_sync <= 0;
        ready_sync1 <= 0; ready_sync2 <= 0;
        loading_frame <= 0; ready_frame <= 0; loading_phase <= 0;
    end else begin
        display_commit_sync <= {display_commit_sync[1:0], display_commit_toggle_sd};
        rescan_sync <= {rescan_sync[0], rescan_active_sd};
        ready_sync1 <= bank_ready_sd; ready_sync2 <= ready_sync1;
        if (frame_start) begin
            loading_frame <= rescan_sync[1]; ready_frame <= ready_sync2;
            loading_phase <= loading_phase + 1'b1;
        end
    end
end

// {SW3,SW4}=11/10/01/00 -> 100/70/55/40%；保持原OSD档号B0/B2/B3/B4。
wire [2:0] bright_level = switches_stable[2] ?
    (switches_stable[3] ? 3'd0 : 3'd2) : (switches_stable[3] ? 3'd3 : 3'd4);
wire [2:0] contrast_level = 3'd0;
wire osd_enable_ctrl = 1'b1;

reg [7:0] brightness_val;
reg [7:0] contrast_val;

always @* begin
    case (bright_level)
        3'd0:    brightness_val = 8'd255; // 100% ?????????????????
        3'd1:    brightness_val = 8'd218; // 85% ??????(??????)
        3'd2:    brightness_val = 8'd179; // 70% ??????
        3'd3:    brightness_val = 8'd140; // 55% ??????(?????????)
        default: brightness_val = 8'd255; // Night audio scene stays visible.
    endcase

    case (contrast_level)
        3'd0:    contrast_val = 8'd128; // 100% ????????
        3'd1:    contrast_val = 8'd160; // 125% ???
        3'd2:    contrast_val = 8'd192; // 150% ?????
        3'd3:    contrast_val = 8'd96;  // 75%  ?????
        default: contrast_val = 8'd64;  // 50%  ?????
    endcase
end

// ?????????????????(video_clk)
reg [7:0] brightness_sync1, brightness_sync2;
reg [7:0] contrast_sync1, contrast_sync2;
reg [2:0] bright_lvl_sync1, bright_lvl_sync2;
reg [2:0] contrast_lvl_sync1, contrast_lvl_sync2;

always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        disp_buf_sync       <= 3'd0;
        display_valid_sync  <= 2'b00;
        disp_buf_sync_d     <= 3'd0;
        disp_buf_sync_d2    <= 3'd0;
        auto_sync1          <= 1'b0;
        auto_sync2          <= 1'b0;
        osd_sync1           <= 1'b1;
        osd_sync2           <= 1'b1;
        state_sync1         <= 4'd1;
        state_sync2         <= 4'd1;
        brightness_sync1    <= 8'd255;
        brightness_sync2    <= 8'd255;
        contrast_sync1      <= 8'd128;
        contrast_sync2      <= 8'd128;
        bright_lvl_sync1    <= 3'd0;
        bright_lvl_sync2    <= 3'd0;
        contrast_lvl_sync1  <= 3'd0;
        contrast_lvl_sync2  <= 3'd0;
        image_width_sync1   <= 16'd640;
        image_width_sync2   <= 16'd640;
        image_height_sync1  <= 16'd480;
        image_height_sync2  <= 16'd480;
        image_info_sync1    <= 1'b0;
        image_info_sync2    <= 1'b0;
        image_error_sync1   <= 8'd0;
        image_error_sync2   <= 8'd0;
    end else begin
        disp_buf_sync       <= disp_buf_idx;
        display_valid_sync  <= {display_valid_sync[0], display_valid};
        disp_buf_sync_d     <= disp_buf_sync;
        disp_buf_sync_d2    <= disp_buf_sync_d;
        auto_sync1          <= auto_play_status;
        auto_sync2          <= auto_sync1;
        osd_sync1           <= osd_enable_ctrl;
        osd_sync2           <= osd_sync1;
        state_sync1         <= state_code;
        state_sync2         <= state_sync1;
        brightness_sync1    <= brightness_val;
        brightness_sync2    <= brightness_sync1;
        contrast_sync1      <= contrast_val;
        contrast_sync2      <= contrast_sync1;
        bright_lvl_sync1    <= bright_level;
        bright_lvl_sync2    <= bright_lvl_sync1;
        contrast_lvl_sync1  <= contrast_level;
        contrast_lvl_sync2  <= contrast_lvl_sync1;
        image_width_sync1   <= current_image_width_sd;
        image_width_sync2   <= image_width_sync1;
        image_height_sync1  <= current_image_height_sd;
        image_height_sync2  <= image_height_sync1;
        image_info_sync1    <= current_image_info_valid_sd;
        image_info_sync2    <= image_info_sync1;
        image_error_sync1   <= media_error_sd;
        image_error_sync2   <= image_error_sync1;
    end
end

// ???????????frame_start (vsync????? ???????????????????????????
reg [7:0] brightness_frame;
reg [7:0] contrast_frame;
reg [2:0] bright_lvl_frame;
reg [2:0] contrast_lvl_frame;

always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        brightness_frame   <= 8'd255;
        display_valid_frame <= 1'b0;
        contrast_frame     <= 8'd128;
        bright_lvl_frame   <= 3'd0;
        contrast_lvl_frame <= 3'd0;
        image_width_frame  <= 16'd640;
        image_height_frame <= 16'd480;
        image_info_frame   <= 1'b0;
        image_error_frame  <= 8'd0;
    end else if (frame_start) begin
        if (brightness_frame < brightness_sync2)
            brightness_frame <= (brightness_sync2 - brightness_frame > 4) ? brightness_frame + 4 : brightness_sync2;
        else if (brightness_frame > brightness_sync2)
            brightness_frame <= (brightness_frame - brightness_sync2 > 4) ? brightness_frame - 4 : brightness_sync2;
        display_valid_frame <= display_valid_sync[1] && fade_display_started;
        contrast_frame     <= contrast_sync2;
        bright_lvl_frame   <= bright_lvl_sync2;
        contrast_lvl_frame <= contrast_lvl_sync2;
        image_width_frame  <= image_width_sync2;
        image_height_frame <= image_height_sync2;
        image_info_frame   <= image_info_sync2;
        image_error_frame  <= image_error_sync2;
    end
end

always @(posedge sd_card_clk or negedge sd_reset_n) begin
    if (!sd_reset_n) begin
        transition_busy_sd1 <= 1'b0;
        transition_busy_sd2 <= 1'b0;
        displayed_buf_sd1 <= 3'd0;
        displayed_buf_sd2 <= 3'd0;
    end else begin
        transition_busy_sd1 <= fade_transition_busy;
        transition_busy_sd2 <= transition_busy_sd1;
        displayed_buf_sd1 <= fade_display_buf_idx;
        displayed_buf_sd2 <= displayed_buf_sd1;
    end
end

// ?????? PLL
sys_pll sys_pll_m0(
    .refclk     (clk),
    .clk0_out   (sd_card_clk),
    .clk1_out   (ext_mem_clk),
    .clk2_out   (ext_mem_clk_sft),
    .locked     (sys_locked),
    .reset      (power_count < 16'd256)
);

video_pll video_pll_m0(
    .refclk     (clk),
    .clk0_out   (video_clk),
    .clk1_out   (hdmi_5x_clk),
    .locked     (video_locked),
    .reset      (power_count < 16'd256)
);

// mem_clk ??? write_finish ?????? toggle??? sd_card_clk ????????
always @(posedge ext_mem_clk or negedge mem_reset_n) begin
    if (!mem_reset_n)
        frame_write_toggle_mem <= 1'b0;
    else if (frame_write_finish)
        frame_write_toggle_mem <= ~frame_write_toggle_mem;
end

// ===================== TF ?????????????????? =====================
sd_card_bmp #(
    .CLK_FREQ_HZ       (100_000_000),
    .SCAN_START_SECTOR (32'd0),
    .SCAN_MAX_SECTOR   (32'd131071),
    .SCAN_TARGET_COUNT (3'd5),
    .USE_DEDICATED_EMERGENCY (1),
    .AUTO_PLAY_ON_BOOT (1),
    .CHECK_DISPLAY_ACK (1)
) sd_card_bmp_m0(
    .clk               (sd_card_clk),
    .rst               (!sd_reset_n),
    .key_next          (key4),
    .key_auto          (key1),
    .key_emergency     (key2),
    .key_rescan        (key3),
    .current_image_index (current_image_index_sd),
    .commit_hard       (commit_hard_sd),
    .display_commit_toggle (display_commit_toggle_sd),
    .rescan_active     (rescan_active_sd),
    .bank_ready        (bank_ready_sd),
    .activity_code     (activity_sd),
    .displayed_buf_idx (displayed_buf_sd2),
    .transition_recover_toggle (transition_recover_toggle),
    .transition_busy   (transition_busy_sd2),
    .state_code        (image_state_code),
    .auto_play_status  (auto_play_status),
    .bmp_width         (16'd640),
    .bmp_height        (16'd480),
    .display_valid     (display_valid),
    .current_image_width      (current_image_width_sd),
    .current_image_height     (current_image_height_sd),
    .current_image_info_valid (current_image_info_valid_sd),
    .current_image_error      (current_image_error_sd),
    .emergency_active         (emergency_active_sd),

    .write_finish_toggle(frame_write_toggle_mem),
    .write_buf_idx     (write_buf_idx),
    .disp_buf_idx      (disp_buf_idx),

    .write_req         (sd_card_write_req),
    .write_req_ack     (sd_card_write_req_ack),
    .write_data_ready  (sd_card_write_ready),
    .write_en          (sd_card_write_en),
    .write_data        (sd_card_write_data),
    .audio_sd_req      (night_sd_req),
    .audio_sd_addr     (night_sd_addr),
    .audio_sd_priority (night_sd_priority),
    .audio_sd_accept   (night_sd_accept),
    .audio_sd_data     (night_sd_data),
    .audio_sd_valid    (night_sd_valid),
    .audio_sd_end      (night_sd_end),
    .sd_init_done      (sd_init_done),
    .sd_io_error       (sd_io_error),
    .rescan_accepted   (rescan_accepted_sd),
    .SD_nCS            (sd_ncs),
    .SD_DCLK           (sd_dclk),
    .SD_MOSI           (sd_mosi),
    .SD_MISO           (sd_miso)
);

seg_decoder seg_decoder_m0(
    .bin_data          (state_code),
    .seg_data          (seg_data_0)
);

seg_scan seg_scan_m0(
    .clk               (clk),
    .rst_n             (sys_reset_n),
    .seg_sel           (seg_sel),
    .seg_data          (seg_data),
    .seg_data_0        ({1'b1,7'b1111_111}),
    .seg_data_1        ({1'b1,7'b1111_111}),
    .seg_data_2        ({1'b1,7'b1111_111}),
    .seg_data_3        ({1'b1,7'b1111_111}),
    .seg_data_4        ({1'b1,7'b1111_111}),
    .seg_data_5        ({1'b1,seg_data_0})
);

// ===================== ???????????? =====================
video_timing_data video_timing_data_m0(
    .video_clk         (video_clk),
    .rst               (rst_all),
    .read_req          (video_read_req),
    .frame_read_start  (frame_read_start),
    .read_req_ack      (video_read_req_ack),
    .hs                (hs_0),
    .vs                (vs_0),
    .de                (de_0)
);

video_delay video_delay_m0(
    .video_clk         (video_clk),
    .rst               (rst_all),
    .read_en           (video_read_en),
    .read_data         (video_read_data[31:8]),
    .hs                (hs_0),
    .vs                (vs_0),
    .de                (de_0),
    .hs_r              (hs),
    .vs_r              (vs),
    .de_r              (de),
    .vout_data         (vout_data_raw)
);

// ????????????????????????????????????
assign vout_data = display_valid_frame ? vout_data_raw : 24'd0;

video_xy_tracker u_video_xy_tracker (
    .clk         (video_clk),
    .rst         (rst_all),
    .hs          (hs),
    .vs          (vs),
    .de          (de),
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),
    .frame_start (frame_start)
);

video_fade_overlay #(
    .FADE_FRAMES (16),
    .RECOVERY_ENABLE (1)
) u_video_fade_overlay (
    .force_commit_toggle (transition_recover_toggle),
    .clk               (video_clk),
    .rst               (rst_all),
    .frame_start       (frame_read_start),
    .switch_event      (buffer_switch_event),
    .switch_buf_idx    (disp_buf_sync_d),
    .switch_image_idx  ({1'b0, image_idx_sync2} + 4'd1),
    .switch_hard       (commit_hard_sync2),
    .de                (de),
    .rgb_in            (vout_data),
    .rgb_out           (vout_data_faded),
    .display_buf_idx   (fade_display_buf_idx),
    .display_image_idx (fade_display_image_idx),
    .display_started   (fade_display_started),
    .transition_busy   (fade_transition_busy)
);

// ===================== ??3?????????????????(brightness_contrast_adjust) =====================
brightness_contrast_adjust u_brightness_contrast_adjust (
    .clk        (video_clk),
    .rst_n      (~rst_all),
    .in_de      (de),
    .rgb_in     (vout_data_faded),
    .brightness (brightness_frame),
    .contrast   (contrast_frame),
    .out_de     (adj_de),
    .rgb_out    (vout_data_adj)
);

// ?????????????????rightness_contrast_adjust???????????
reg [9:0] pixel_x_d;
reg [9:0] pixel_y_d;
reg       hs_d, vs_d;
reg [9:0] line_x;
reg [9:0] line_x_d;

always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        pixel_x_d <= 10'd0;
        pixel_y_d <= 10'd0;
        hs_d      <= 1'b0;
        vs_d      <= 1'b0;
        line_x_d  <= 10'd0;
    end else begin
        pixel_x_d <= pixel_x;
        pixel_y_d <= pixel_y;
        hs_d      <= hs;
        vs_d      <= vs;
        line_x_d  <= line_x;
    end
end

// ===================== ??2??????????????????????(thumbnail_layout) =====================

// ?????????????????????
// 图片已在加载到 SDRAM 前自动适配；显示端直接输出标准帧。
// 加载状态条：五个方块对应五个驻留帧；重扫期间轻微压暗旧图。
wire loading_visible = loading_frame && !emergency_video_frame;
wire loading_strip = loading_visible && pixel_y_d >= 10'd450 && pixel_y_d < 10'd466;
wire [23:0] loading_dimmed = {2'b00, vout_data_adj[23:18], 2'b00, vout_data_adj[15:10], 2'b00, vout_data_adj[7:2]};
reg [23:0] loading_rgb;
integer loading_i;
always @* begin
    loading_rgb = loading_visible ? vout_data_adj - loading_dimmed : vout_data_adj;
    for (loading_i = 0; loading_i < 5; loading_i = loading_i + 1) begin
        if (loading_strip && pixel_x_d >= 260 + loading_i * 24 && pixel_x_d < 276 + loading_i * 24)
            loading_rgb = ready_frame[loading_i] ? 24'h30c080 : (loading_phase[4] ? 24'hd0a030 : 24'h605020);
    end
end
assign vout_data_display = loading_rgb;

// OSD ????????????????????????????????????????????C?????????T?????
video_status_osd u_video_status_osd (
    .clk            (video_clk),
    .rst            (rst_all),
    .de             (adj_de),
    .enable         (osd_sync2),
    .pixel_x        (pixel_x_d),
    .pixel_y        (pixel_y_d),
    .image_index    (fade_display_image_idx),
    .auto_enable    (auto_sync2),
    .bright_level   (bright_lvl_frame),
    .contrast_level (contrast_lvl_frame),
    .view_mode      (1'b0),
    .image_width    (image_width_frame),
    .image_height   (image_height_frame),
    .image_info_valid (image_info_frame),
    .image_error    (image_error_frame),
    .rgb_in         (vout_data_display),
    .rgb_out        (vout_data_osd)
);

emergency_osd_overlay u_emergency_osd_overlay (
    .clk              (video_clk),
    .rst              (rst_all),
    .frame_start      (frame_start),
    .emergency_active (emergency_active_sd),
    .in_de            (adj_de),
    .pixel_x          (pixel_x_d),
    .pixel_y          (pixel_y_d),
    .rgb_in           (vout_data_osd),
    .rgb_out          (vout_data_emergency)
);

frame_read_write #(
    .WRITE_V_FLIP     (0), // bmp_read 已统一为自上而下，禁止再次翻转
    .FRAME_WIDTH      (640),
    .FRAME_HEIGHT     (480)
) frame_read_write_m0(
    .mem_clk           (ext_mem_clk),
    .rst               (!mem_reset_n),
    .Sdr_init_done     (Sdr_init_done),
    .Sdr_init_ref_vld  (Sdr_init_ref_vld),
    .Sdr_busy          (Sdr_busy),

    .App_rd_en         (App_rd_en),
    .App_rd_addr       (App_rd_addr),
    .Sdr_rd_en         (Sdr_rd_en),
    .Sdr_rd_dout       (Sdr_rd_dout),

    .read_clk          (video_clk),
    .read_req          (video_read_req),
    .read_req_ack      (video_read_req_ack),
    .read_finish       (),
    .read_addr_0       (BUF0_ADDR),
    .read_addr_1       (BUF1_ADDR),
    .read_addr_2       (BUF2_ADDR),
    .read_addr_3       (BUF3_ADDR),
    .read_addr_4       (BUF4_ADDR),

    .read_addr_index   (fade_display_buf_idx),
    .read_len          (FRAME_PIXELS),
    .read_en           (video_read_en),
    .read_data         (video_read_data),

    .App_wr_en         (App_wr_en),
    .App_wr_addr       (App_wr_addr),
    .App_wr_din        (App_wr_din),
    .App_wr_dm         (App_wr_dm),

    .write_clk         (sd_card_clk),
    .write_req         (sd_card_write_req),
    .write_req_ack     (sd_card_write_req_ack),
    .write_ready       (sd_card_write_ready),
    .write_finish      (frame_write_finish),
    .write_addr_0      (BUF0_ADDR),
    .write_addr_1      (BUF1_ADDR),
    .write_addr_2      (BUF2_ADDR),
    .write_addr_3      (BUF3_ADDR),
    .write_addr_4       (BUF4_ADDR),

    .write_addr_index  (write_buf_idx),
    .write_len         (FRAME_PIXELS),
    .write_en          (sd_card_write_en),
    .write_data        (sd_card_write_data)
);

sdram U3(
    .Clk               (ext_mem_clk),
    .Clk_sft           (ext_mem_clk_sft),
    .Rst               (!mem_reset_n),
    .Sdr_init_done     (Sdr_init_done),
    .Sdr_init_ref_vld  (Sdr_init_ref_vld),
    .Sdr_busy          (Sdr_busy),
    .App_wr_en         (App_wr_en),
    .App_wr_addr       (App_wr_addr),
    .App_wr_dm         (App_wr_dm),
    .App_wr_din        (App_wr_din),
    .App_rd_en         (App_rd_en),
    .App_rd_addr       (App_rd_addr),
    .Sdr_rd_en         (Sdr_rd_en),
    .Sdr_rd_dout       (Sdr_rd_dout)
);

// ?????????????line_x (0~799)
// ????????
reg       de_d_x;
always @(posedge video_clk or posedge rst_all) begin
    if (rst_all) begin
        line_x <= 10'd0;
        de_d_x <= 1'b0;
    end else begin
        de_d_x <= de;
        if (de && !de_d_x)
            line_x <= 10'd0;
        else if (line_x == 10'd799)
            line_x <= 10'd0;
        else
            line_x <= line_x + 10'd1;
    end
end

// ????????????
wire audio_music_enable = switches_frame[0];
wire audio_night_mode = !switches_frame[2] && !switches_frame[3];
wire [1:0] audio_music_profile = {audio_night_mode, switches_frame[1] && !audio_night_mode};
wire [7:0] audio_volume = (!switches_frame[2] && !switches_frame[3]) ? 8'd128 :
    (switches_frame[2] ?
        (switches_frame[3] ? 8'd128 : 8'd96) : 8'd64);
wire pcm_tap_valid;
wire signed [15:0] pcm_tap_left;
wire [23:0] vout_data_wave;
night_pcm_stream u_night_pcm_stream (
    .sd_clk(sd_card_clk), .sd_rst_n(sd_reset_n),
    .pixel_clk(video_clk), .pixel_rst_n(video_reset_n),
    .night_active(audio_night_mode), .night_drain(night_drain),
    .rescan(rescan_accepted_sd), .sd_init_done(sd_init_done), .sd_io_error(sd_io_error),
    .sd_req(night_sd_req), .sd_addr(night_sd_addr), .sd_accept(night_sd_accept),
    .sd_data(night_sd_data), .sd_valid(night_sd_valid), .sd_end(night_sd_end),
    .pcm_valid(night_pcm_valid), .pcm_left(night_pcm_left), .pcm_right(night_pcm_right),
    .pcm_ready(night_pcm_ready), .priority_sd(night_sd_priority), .error_sd(night_error_sd)
);
promax_audio_waveform u_alarm_wave (
    .clk(video_clk), .rst_n(video_reset_n), .enable(emergency_video_frame),
    .vsync(vs_d), .de(adj_de), .pixel_x(pixel_x_d), .pixel_y(pixel_y_d),
    .rgb_in(vout_data_emergency), .pcm_tap_valid(pcm_tap_valid), .pcm_tap_left(pcm_tap_left),
    .rgb_out(vout_data_wave), .waveform_active()
);

// ?????media_hdmi_audio_bridge (HDMI ??????)
media_hdmi_audio_bridge u_media_hdmi_audio_bridge (
    .pixel_clk          (video_clk),
    .pixel_rst_n        (~rst_all),
    .video_hsync        (hs_d),
    .video_vsync        (vs_d),
    .video_de           (adj_de),
    .video_x            (line_x_d),
    .video_rgb          (vout_data_wave),
    .music_profile      (audio_music_profile),
    .music_enable       (audio_music_enable),
    .night_pcm_valid    (night_pcm_valid),
    .night_pcm_left     (night_pcm_left),
    .night_pcm_right    (night_pcm_right),
    .night_pcm_ready    (night_pcm_ready),
    .night_drain        (night_drain),
    .volume             (audio_volume),
    .force_test_tone    (1'b0),
    .emergency_active   (emergency_video_sync2),
    .channel0_symbol    (tmds_ch0_data),
    .channel1_symbol    (tmds_ch1_data),
    .channel2_symbol    (tmds_ch2_data),
    .sequence_error     (),
    .tone_overflow      (),
    .pcm_contract_error (),
    .blip_active        (),
    .pcm_tap_valid      (pcm_tap_valid),
    .pcm_tap_left       (pcm_tap_left)
);

assign tmds_clk_data = 10'b1111100000;

// DDC ????????????
assign HDMI_DDC_SCL = 1'b1;
assign HDMI_DDC_SDA = 1'bz;

// HDMI ?????10:1 SERDES ???
hdmi_phy_wrapper #(
    .DEVICE ( "EG" )
) u_hdmi2phy_wrapper(
    .I_pixel_clk        (video_clk),
    .I_serial_clk       (hdmi_5x_clk),
    .I_rst              (!serial_reset_n),
    .I_tmds_channel_0   (tmds_ch0_data),
    .I_tmds_channel_1   (tmds_ch1_data),
    .I_tmds_channel_2   (tmds_ch2_data),
    .I_tmds_channel_clk (tmds_clk_data),
    .O_tmds_ch0_p       (HDMI_D0_P),
    .O_tmds_ch1_p       (HDMI_D1_P),
    .O_tmds_ch2_p       (HDMI_D2_P),
    .O_tmds_clk_p       (HDMI_CLK_P)
);

endmodule
