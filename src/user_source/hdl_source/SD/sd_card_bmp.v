`timescale 1ns/1ps
// 五个常驻帧：0..3常态，4应急。预加载和显示仲裁独立，切图不读TF。
module sd_card_bmp #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer EXTERNAL_CONTROLS = 0,
    parameter [31:0] SCAN_START_SECTOR = 0,
    parameter [31:0] SCAN_MAX_SECTOR = 131071,
    parameter [2:0] SCAN_TARGET_COUNT = 5,
    parameter integer LONG_PRESS_MS = 1000,
    parameter integer AUTO_PLAY_MS = 3000,
    parameter integer LOAD_STALL_MS = 1000,
    parameter integer USE_DEDICATED_EMERGENCY = 0,
    parameter integer AUTO_PLAY_ON_BOOT = 0,
    parameter integer MAX_LOAD_RETRIES = 1,
    parameter integer CHECK_PIXEL_COUNT = 1,
    parameter integer FRAME_PIXELS = 307200,
    parameter integer CHECK_DISPLAY_ACK = 0,
    parameter integer TRANSITION_TIMEOUT_MS = 2000,
    parameter integer SD_IO_TIMEOUT_MS = 500,
    parameter integer SD_INIT_TIMEOUT_MS = 5000
)(
    input wire clk, rst, key_next, key_auto, key_emergency, key_rescan,
    input wire ctl_ready,ctl_menu,ctl_auto,
    input wire [1:0] ctl_period,
    input wire ctl_next_press,ctl_rescan_press,ctl_emergency_press,
    input wire sensor_emergency,
    input wire transition_busy,
    input wire [2:0] displayed_buf_idx,
    input wire [2:0] reader_bank_idx,
    input wire reader_bank_valid,
    input wire write_path_idle,
    output wire write_abort,
    output reg transition_recover_toggle,
    input wire [15:0] bmp_width, bmp_height,
    output reg display_valid,
    output reg [3:0] state_code,
    input wire write_finish_toggle,
    output reg [2:0] write_buf_idx, disp_buf_idx,
    output wire auto_play_status,
    output reg [15:0] current_image_width, current_image_height,
    output reg current_image_info_valid,
    output reg [7:0] current_image_error,
    output wire emergency_active,
    output wire [2:0] current_image_index,
    output reg commit_hard,
    output reg display_commit_toggle,
    output wire rescan_active,
    output wire refresh_ui_active,
    output wire [4:0] bank_ready,
    output wire [3:0] activity_code,
    output wire write_req,
    input wire write_req_ack, write_data_ready,
    output wire write_en,
    output wire [31:0] write_data,
    input wire audio_sd_req,
    input wire [31:0] audio_sd_addr,
    input wire audio_sd_priority,
    output wire audio_sd_accept,
    output wire [7:0] audio_sd_data,
    output wire audio_sd_valid, audio_sd_end,
    output wire sd_init_done, sd_io_error,
    output reg rescan_accepted,
    output wire SD_nCS, SD_DCLK, SD_MOSI,
    input wire SD_MISO
);
    localparam integer LONG_CYCLES = (CLK_FREQ_HZ / 1000) * LONG_PRESS_MS;
    localparam integer LOAD_CYCLES = (CLK_FREQ_HZ / 1000) * LOAD_STALL_MS;
    localparam integer AUTO_CYCLES = (CLK_FREQ_HZ / 1000) * AUTO_PLAY_MS;
    localparam integer TRANSITION_CYCLES = (CLK_FREQ_HZ / 1000) * TRANSITION_TIMEOUT_MS;
    wire raw_next_press,raw_auto_press,raw_emergency_press,raw_rescan_press;
    wire key_next_press=EXTERNAL_CONTROLS?ctl_next_press:raw_next_press;
    wire key_auto_press=EXTERNAL_CONTROLS?1'b0:raw_auto_press;
    wire key_emergency_press=EXTERNAL_CONTROLS?ctl_emergency_press:raw_emergency_press;
    wire key_rescan_press=EXTERNAL_CONTROLS?ctl_rescan_press:raw_rescan_press;
    wire key_auto_stable;
    reg ctl_ready_q,ctl_menu_q,ctl_auto_q;
    reg [1:0] ctl_period_q;
    reg [31:0] dwell_limit;
    reg auto_tick_q;
    wire control_changed=EXTERNAL_CONTROLS &&
        ({ctl_ready,ctl_menu,ctl_auto,ctl_period}!={ctl_ready_q,ctl_menu_q,ctl_auto_q,ctl_period_q});
    wire normal_controls_allowed=!EXTERNAL_CONTROLS || (ctl_ready && !ctl_menu && !control_changed);
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ctl_ready_q<=0;ctl_menu_q<=0;ctl_auto_q<=0;ctl_period_q<=0;
            dwell_limit<=AUTO_CYCLES-1;auto_tick_q<=0;
        end else begin
            ctl_ready_q<=ctl_ready;ctl_menu_q<=ctl_menu;ctl_auto_q<=ctl_auto;ctl_period_q<=ctl_period;
            if(EXTERNAL_CONTROLS) begin
                case(ctl_period)
                    0:dwell_limit<=CLK_FREQ_HZ*2-1;1:dwell_limit<=CLK_FREQ_HZ*3-1;
                    2:dwell_limit<=CLK_FREQ_HZ*5-1;3:dwell_limit<=CLK_FREQ_HZ*10-1;
                endcase
            end
            auto_tick_q<=auto_cnt>=dwell_limit;
        end
    end
    reg key_auto_stable_d, long_press_marked;
    reg [31:0] long_press_cnt;
    wire key_auto_short = key_auto_stable && !key_auto_stable_d && !long_press_marked;
    wire key_auto_long = !key_auto_stable && !long_press_marked && (long_press_cnt >= LONG_CYCLES - 1);
    wire bmp_ready, bmp_scan_done;
    reg scan_done, scan_kicked, preload_scheduled;
    wire scan_found_valid;
    wire [31:0] scan_found_sector;
    wire [2:0] scan_found_total;
    wire [3:0] state_code_i;
    wire bmp_data_wr_en, bmp_image_info_valid;
    wire [23:0] bmp_data;
    wire [15:0] bmp_image_width, bmp_image_height;
    wire [7:0] bmp_image_error;
    wire sd_sec_read, sd_sec_read_data_valid, sd_sec_read_end;
    wire [31:0] sd_sec_read_addr;
    wire [7:0] sd_sec_read_data;
    wire core_sec_read, core_sec_valid, core_sec_end;
    wire [31:0] core_sec_addr;
    wire [7:0] core_sec_data;
    reg scan_start_pulse, load_start_pulse;
    reg [1:0] scan_start_guard;
    wire [31:0] load_sector;
    reg [31:0] img_sector0, img_sector1, img_sector2, img_sector3, img_sector4;
    reg [2:0] img_found_count, img_idx, load_idx;
    reg auto_play_en, emergency_mode, emergency_source_sensor, emergency_req_pending, normal_resume_pending;
    reg next_req_pending, load_busy, load_abort;
    reg [2:0] normal_image_idx;
    reg rescan_pending, cache_active, normal_auto_play_en;
    reg boot_preload;
    reg transition_wait, transition_busy_seen;
    reg [31:0] auto_cnt, load_timeout_cnt, transition_count, pixel_count;
    reg source_done_seen, write_done_seen;
    reg [2:0] wrfin_tgl_sync;
    reg [4:0] failed_images, bank_valid, cache_pending;
    reg [15:0] bank_width [0:4];
    reg [15:0] bank_height [0:4];
    reg [4:0] bank_info_valid;
    reg retry_pending;
    reg [7:0] retry_count;
    integer bank_i;

    wire emergency_event = sensor_emergency || (USE_DEDICATED_EMERGENCY ? key_emergency_press : key_auto_long);
    wire emergency_enter = !emergency_mode && emergency_event;
    wire emergency_exit = emergency_mode &&
        (emergency_source_sensor ? !sensor_emergency :
        (USE_DEDICATED_EMERGENCY ? key_emergency_press : (key_auto_short || key_auto_long)));
    wire auto_event = USE_DEDICATED_EMERGENCY ? key_auto_press : key_auto_short;
    wire auto_tick = EXTERNAL_CONTROLS?auto_tick_q:(auto_cnt >= AUTO_CYCLES - 1);
    wire write_finish_pulse = wrfin_tgl_sync[2] ^ wrfin_tgl_sync[1];
    wire [4:0] image_mask = (img_found_count >= 5) ? 5'b11111 : ((5'b00001 << img_found_count) - 1'b1);
    wire [4:0] protected_bank =
        (display_valid ? (5'b00001 << disp_buf_idx) : 5'd0) |
        (reader_bank_valid ? (5'b00001 << reader_bank_idx) : 5'd0);
    assign write_abort = load_abort;
    wire [3:0] normal_ready = bank_valid[3:0] & image_mask[3:0] & ~cache_pending[3:0];
    wire [4:0] load_candidates = cache_pending & ~protected_bank;
    wire can_commit = !transition_wait && !transition_busy;
    wire can_load = scan_done && preload_scheduled && sd_init_done && bmp_ready &&
        !load_busy && !load_abort && !load_start_pulse && can_commit && write_path_idle;
    wire transfer_complete = source_done_seen && write_done_seen;
    wire pixel_count_bad = CHECK_PIXEL_COUNT && source_done_seen && (pixel_count != FRAME_PIXELS);
    wire stalled = load_timeout_cnt >= LOAD_CYCLES - 1;
    wire load_failed = load_busy && !load_start_pulse &&
        ((!sd_init_done) || sd_io_error || (bmp_ready && bmp_image_error != 0) ||
         pixel_count_bad || (stalled && !(sd_sec_read_data_valid || sd_sec_read_end || write_en || write_finish_pulse)));
    wire [7:0] load_error_code = (!sd_init_done || sd_io_error || stalled) ? 8'h38 :
        ((bmp_ready && bmp_image_error != 0) ? bmp_image_error : 8'h3a);
    assign auto_play_status = auto_play_en;
    assign emergency_active = emergency_mode;
    assign current_image_index = img_idx;
    assign rescan_active = rescan_pending || cache_active;
    // Boot still fills all five banks, but only later user refreshes show the
    // progress squares and dimming. Do not change cache scheduling to hide UI.
    assign refresh_ui_active = rescan_active && !boot_preload;
    always @(posedge clk or posedge rst) begin
        if (rst) boot_preload <= 1'b1;
        else if (!cache_active) boot_preload <= 1'b0;
    end
    assign bank_ready = bank_valid;
    assign activity_code = !sd_init_done ? 0 : (!scan_done ? 2 : (load_busy ? 3 : 4));
    assign write_en = bmp_data_wr_en && write_data_ready;
    assign write_data = {bmp_data, 8'd0};

    key_press_debounce #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .DEBOUNCE_MS(50)) u_key_next
        (.clk(clk), .rst(rst), .button_in(key_next), .press_pulse(raw_next_press), .button_stable_out());
    key_press_debounce #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .DEBOUNCE_MS(50)) u_key_auto
        (.clk(clk), .rst(rst), .button_in(key_auto), .press_pulse(raw_auto_press), .button_stable_out(key_auto_stable));
    key_press_debounce #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .DEBOUNCE_MS(50)) u_key_emergency
        (.clk(clk), .rst(rst), .button_in(key_emergency), .press_pulse(raw_emergency_press), .button_stable_out());
    key_press_debounce #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .DEBOUNCE_MS(50)) u_key_rescan
        (.clk(clk), .rst(rst), .button_in(key_rescan), .press_pulse(raw_rescan_press), .button_stable_out());

    function [31:0] sector_lut;
        input [2:0] idx;
        case (idx)
            0: sector_lut = img_sector0;
            1: sector_lut = img_sector1;
            2: sector_lut = img_sector2;
            3: sector_lut = img_sector3;
            4: sector_lut = img_sector4;
            default: sector_lut = img_sector0;
        endcase
    endfunction
    // load_idx 已寄存；bmp_read 只在 load_start 拍采样，此时 img_sector* 不变。
    // 不把 choose_load 优先链串到 32 位扇区选择器上。
    assign load_sector = sector_lut(load_idx);
    function [2:0] choose_image;
        input [1:0] start_idx;
        input [3:0] eligible;
        integer i;
        reg chosen;
        reg [1:0] candidate;
        begin
            choose_image = {1'b0, start_idx}; chosen = 0;
            for (i = 0; i < 4; i = i + 1) begin
                candidate = start_idx + i;
                if (!chosen && eligible[candidate]) begin
                    choose_image = {1'b0, candidate}; chosen = 1;
                end
            end
        end
    endfunction
    function [2:0] choose_load;
        input [4:0] eligible;
        begin
            // 首张正常图先出画面，随后优先准备应急页。
            if (emergency_mode && eligible[4]) choose_load = 4;
            else if (!display_valid && eligible[0]) choose_load = 0;
            else if (eligible[4]) choose_load = 4;
            else choose_load = choose_image(0, eligible[3:0]);
        end
    endfunction
    task start_image;
        input [2:0] idx;
        input fresh_attempt;
        begin
            load_idx <= idx;
            write_buf_idx <= idx; bank_valid[idx] <= 0;
            load_start_pulse <= 1; load_busy <= 1;
            source_done_seen <= 0; write_done_seen <= 0;
            pixel_count <= 0; load_timeout_cnt <= 0;
            if (fresh_attempt) retry_count <= 0;
        end
    endtask
    task commit_image;
        input [2:0] idx;
        input hard_cut;
        begin
            // 只修改显示邮箱，不触发BMP或SD读；邮箱保持到像素域确认。
            disp_buf_idx <= idx; img_idx <= idx; display_valid <= 1;
            commit_hard <= hard_cut;
            display_commit_toggle <= ~display_commit_toggle;
            transition_wait <= 1; transition_busy_seen <= 0; transition_count <= 0;
            auto_cnt <= 0;
        end
    endtask

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_auto_stable_d <= 1; long_press_marked <= 0; long_press_cnt <= 0;
            scan_start_pulse <= 0; load_start_pulse <= 0; scan_kicked <= 0; scan_done <= 0;
            scan_start_guard <= 0; preload_scheduled <= 0; img_found_count <= 0;
            img_sector0 <= 0; img_sector1 <= 0; img_sector2 <= 0; img_sector3 <= 0; img_sector4 <= 0;
            rescan_pending <= 0; cache_active <= 1; commit_hard <= 0; display_commit_toggle <= 0;
            rescan_accepted <= 0;
            img_idx <= 0; load_idx <= 0;
            write_buf_idx <= 0; disp_buf_idx <= 0;
            auto_play_en <= AUTO_PLAY_ON_BOOT != 0; auto_cnt <= 0;
            emergency_mode <= 0; emergency_source_sensor <= 0;
            emergency_req_pending <= 0; normal_resume_pending <= 0;
            normal_image_idx <= 0; normal_auto_play_en <= 0;
            next_req_pending <= 0; load_busy <= 0; load_abort <= 0;
            failed_images <= 0; bank_valid <= 0; cache_pending <= 0; bank_info_valid <= 0;
            retry_pending <= 0; retry_count <= 0;
            transition_wait <= 0; transition_busy_seen <= 0; transition_count <= 0;
            transition_recover_toggle <= 0;
            load_timeout_cnt <= 0; pixel_count <= 0;
            source_done_seen <= 0; write_done_seen <= 0; wrfin_tgl_sync <= 0;
            display_valid <= 0; state_code <= 1;
            current_image_width <= 640; current_image_height <= 480;
            current_image_info_valid <= 0; current_image_error <= 0;
            for (bank_i = 0; bank_i < 5; bank_i = bank_i + 1) begin
                bank_width[bank_i] <= 640; bank_height[bank_i] <= 480;
            end
        end else begin
            scan_start_pulse <= 0; load_start_pulse <= 0; load_abort <= 0;
            rescan_accepted <= 0;
            if (scan_start_guard != 0) scan_start_guard <= scan_start_guard - 1'b1;
            wrfin_tgl_sync <= {wrfin_tgl_sync[1:0], write_finish_toggle};
            // 尺寸属于慢速OSD元数据：由已寄存的显示bank选择，
            // 不把整条仲裁优先链串到32位宽的尺寸选择器上。
            if (display_valid) begin
                current_image_width <= bank_width[disp_buf_idx];
                current_image_height <= bank_height[disp_buf_idx];
                current_image_info_valid <= bank_info_valid[disp_buf_idx];
            end
            // BMP头验证后尺寸已经稳定，趁加载期间写入无效bank的元数据。
            // bank_valid仍仅由完整像素和SDRAM完成握手置位。
            if (load_busy && !load_start_pulse && bmp_image_info_valid) begin
                bank_width[load_idx] <= bmp_image_width;
                bank_height[load_idx] <= bmp_image_height;
                bank_info_valid[load_idx] <= 1;
            end
            key_auto_stable_d <= key_auto_stable;
            if (key_auto_stable) begin long_press_cnt <= 0; long_press_marked <= 0; end
            else if (long_press_cnt < LONG_CYCLES - 1) long_press_cnt <= long_press_cnt + 1'b1;
            else long_press_marked <= 1;

            if (sd_io_error) begin
                current_image_error <= 8'h38;
                if (!scan_done) begin scan_kicked <= 0; img_found_count <= 0; end
            end
            if (scan_found_valid && !scan_done) begin
                case (img_found_count)
                    0: img_sector0 <= scan_found_sector;
                    1: img_sector1 <= scan_found_sector;
                    2: img_sector2 <= scan_found_sector;
                    3: img_sector3 <= scan_found_sector;
                    4: img_sector4 <= scan_found_sector;
                    default: ;
                endcase
                if (img_found_count < 5) img_found_count <= img_found_count + 1'b1;
            end
            if (bmp_scan_done && scan_kicked && !scan_done && scan_start_guard == 0 && !scan_start_pulse) begin
                scan_done <= 1;
                if (bmp_image_error != 0) current_image_error <= bmp_image_error;
                else if (img_found_count == 0 && !scan_found_valid) current_image_error <= 8'h3e;
            end
            if (!scan_kicked && !scan_done && sd_init_done && bmp_ready && !load_abort) begin
                scan_start_pulse <= 1; scan_kicked <= 1; img_found_count <= 0; scan_start_guard <= 2;
            end
            if (scan_done && !preload_scheduled) begin
                // 扫描结束后一拍生成mask，包含最后一个发现事件。
                preload_scheduled <= 1; cache_pending <= image_mask;
            end

            if (transition_wait) begin
                if (transition_busy) transition_busy_seen <= 1;
                if (!transition_busy && transition_busy_seen &&
                    (!CHECK_DISPLAY_ACK || (displayed_buf_idx == disp_buf_idx &&
                        reader_bank_valid && reader_bank_idx == disp_buf_idx))) begin
                    transition_wait <= 0; transition_busy_seen <= 0; transition_count <= 0;
                    if (current_image_error == 8'h3f) current_image_error <= 0;
                end else if (transition_count >= TRANSITION_CYCLES - 1) begin
                    transition_count <= 0; current_image_error <= 8'h3f;
                    transition_recover_toggle <= ~transition_recover_toggle;
                end else transition_count <= transition_count + 1'b1;
            end else transition_count <= 0;

            if (load_busy && !load_start_pulse && bmp_ready) source_done_seen <= 1;
            if (load_busy && write_en && pixel_count <= FRAME_PIXELS) pixel_count <= pixel_count + 1'b1;
            if (load_busy && write_finish_pulse && (!CHECK_PIXEL_COUNT || pixel_count == FRAME_PIXELS)) write_done_seen <= 1;
            if (load_failed) begin
                load_busy <= 0; load_abort <= 1; load_timeout_cnt <= 0;
                source_done_seen <= 0; write_done_seen <= 0; current_image_error <= load_error_code;
                if (retry_count < MAX_LOAD_RETRIES) begin
                    retry_pending <= 1; retry_count <= retry_count + 1'b1;
                end else begin
                    retry_pending <= 0; failed_images[load_idx] <= 1; cache_pending[load_idx] <= 0;
                end
            end else if (load_busy && transfer_complete) begin
                load_busy <= 0; load_timeout_cnt <= 0; source_done_seen <= 0; write_done_seen <= 0;
                bank_valid[load_idx] <= 1; cache_pending[load_idx] <= 0; failed_images[load_idx] <= 0;
            end else if (load_busy) begin
                if (sd_sec_read_data_valid || sd_sec_read_end || write_en || write_finish_pulse) load_timeout_cnt <= 0;
                else load_timeout_cnt <= load_timeout_cnt + 1'b1;
            end else load_timeout_cnt <= 0;

            // 普通播放时钟与TF状态无关：缓存就绪后拔卡仍能轮播。
            if (auto_play_en && normal_controls_allowed && !emergency_mode && !normal_resume_pending && !cache_active &&
                !rescan_pending && !emergency_event && !auto_event && display_valid && can_commit && normal_ready != 0) begin
                if (auto_tick) auto_cnt <= 0;
                else auto_cnt <= auto_cnt + 1'b1;
            end else auto_cnt <= 0;

            // 显示优先于后台写入；同一拍绝不同时开始写和选择该bank。
            if (emergency_enter || emergency_exit) begin end
            else if (emergency_req_pending && bank_valid[4]) begin
                // 已缓存的应急页可以打断尚未结束的普通淡入淡出。
                commit_image(4, 1); emergency_req_pending <= 0;
            end else if (emergency_req_pending && scan_done && preload_scheduled && !cache_pending[4] && !load_busy) begin
                emergency_req_pending <= 0; current_image_error <= 8'h3d;
            end else if (can_commit && !emergency_mode && normal_resume_pending &&
                normal_image_idx < 4 && bank_valid[normal_image_idx] && !cache_pending[normal_image_idx]) begin
                commit_image(normal_image_idx, 0); normal_resume_pending <= 0;
            end else if (can_commit && !emergency_mode && normal_ready != 0 &&
                ((!display_valid || img_idx == 4) ||
                 (normal_resume_pending && (!cache_pending[normal_image_idx] || !image_mask[normal_image_idx])) ||
                 (cache_active && (cache_pending[disp_buf_idx] || !image_mask[disp_buf_idx])))) begin
                commit_image(choose_image(0, normal_ready), !display_valid);
                normal_resume_pending <= 0;
            end else if (can_commit && !emergency_mode && !normal_resume_pending && normal_ready != 0 &&
                !rescan_pending && !key_rescan_press && normal_controls_allowed && (next_req_pending || (auto_play_en && auto_tick && !auto_event && (!EXTERNAL_CONTROLS || ctl_auto)))) begin
                next_req_pending <= 0;
                if (choose_image(img_idx[1:0] + 2'd1, normal_ready) != img_idx)
                    commit_image(choose_image(img_idx[1:0] + 2'd1, normal_ready), 0);
            end else if (can_load && !rescan_pending && !key_rescan_press) begin
                if (retry_pending && !protected_bank[load_idx]) begin
                    retry_pending <= 0; start_image(load_idx, 0);
                end else if (load_candidates != 0) begin
                    start_image(choose_load(load_candidates), 1);
                end
            end

            if (cache_active && scan_done && preload_scheduled && !load_busy && !load_start_pulse &&
                !load_abort && !retry_pending && can_commit && !emergency_event) begin
                if (cache_pending == 0) begin
                    cache_active <= 0;
                    if (img_found_count == 5 && failed_images == 0) current_image_error <= 0;
                end else if (load_candidates == 0 && !emergency_mode && normal_ready == 0) begin
                    // 只剩当前旧帧且所有替代图均缺失/失败，禁止原地刷新。
                    cache_active <= 0; cache_pending <= 0;
                    normal_resume_pending <= 0; current_image_error <= 8'h3c;
                end
            end
            if (normal_resume_pending && !emergency_mode && scan_done && preload_scheduled &&
                normal_ready == 0 && cache_pending[3:0] == 0 && !load_busy && !emergency_event) begin
                // 无常态页可恢复也必须释放按键仲裁，保留最后一张完整画面。
                normal_resume_pending <= 0; current_image_error <= 8'h3e;
            end
            if (key_next_press && !emergency_mode && !normal_resume_pending) begin
                next_req_pending <= 1;
                if (scan_done && img_found_count == 0 && !cache_active) rescan_pending <= 1;
            end
            if (auto_event && !emergency_mode && !normal_resume_pending) auto_play_en <= ~auto_play_en;
            if (emergency_enter) begin
                emergency_mode <= 1; emergency_source_sensor <= sensor_emergency;
                emergency_req_pending <= 1; normal_resume_pending <= 0;
                next_req_pending <= 0;
                // 快速重新进入应急时，保留原常态恢复点。
                if (!normal_resume_pending && img_idx < 4) begin
                    normal_image_idx <= img_idx; normal_auto_play_en <= auto_play_en;
                end
                auto_play_en <= 0;
            end else if (emergency_exit) begin
                emergency_mode <= 0; emergency_source_sensor <= 0;
                emergency_req_pending <= 0; normal_resume_pending <= display_valid;
                auto_play_en <= normal_auto_play_en; next_req_pending <= 0;
                current_image_error <= 0;
            end
            // 重复KEY3合并；应急期间不启动重扫，不撤销完整帧。
            if (key_rescan_press && !emergency_mode && !cache_active && !rescan_pending) rescan_pending <= 1;
            if (rescan_pending && !emergency_mode && !emergency_enter && !load_busy && can_commit &&
                bmp_ready && !load_start_pulse && !load_abort) begin
                rescan_accepted <= 1;
                rescan_pending <= 0; cache_active <= 1; scan_done <= 0; scan_kicked <= 0; preload_scheduled <= 0;
                img_found_count <= 0; failed_images <= 0; cache_pending <= 0;
                bank_valid <= bank_valid & protected_bank;
                retry_pending <= 0; next_req_pending <= 0; normal_resume_pending <= 0; current_image_error <= 0;
            end
            if (sd_io_error && (cache_active || rescan_pending)) begin
                // 无卡/掉卡时结束本轮刷新，撤掉等待提示；缓存帧继续可用。
                // TF协议仍自行重初始化，用户可用KEY3发起下一次扫描。
                cache_active <= 0; cache_pending <= 0; retry_pending <= 0;
                rescan_pending <= 0; current_image_error <= 8'h38;
                if (!scan_done) begin
                    scan_done <= 1; preload_scheduled <= 1; img_found_count <= 0;
                end
            end
            if(EXTERNAL_CONTROLS && ctl_ready && !emergency_mode && !emergency_enter)
                auto_play_en<=ctl_auto;
            state_code <= emergency_mode ? 4'he : (current_image_error != 0 ? 4'hf : {1'b0, img_idx} + 4'd1);
        end
    end

    bmp_read bmp_read_m0(
        .clk(clk), .rst(rst), .ready(bmp_ready), .scan_start(scan_start_pulse),
        .scan_start_sector(SCAN_START_SECTOR), .scan_max_sector(SCAN_MAX_SECTOR),
        .scan_target_count(SCAN_TARGET_COUNT), .scan_done(bmp_scan_done),
        .scan_found_valid(scan_found_valid), .scan_found_sector(scan_found_sector), .scan_found_total(scan_found_total),
        .load_start(load_start_pulse), .load_abort(load_abort), .load_sector(load_sector),
        .sd_init_done(sd_init_done), .state_code(state_code_i), .bmp_width(bmp_width), .bmp_height(bmp_height),
        .write_req(write_req), .write_req_ack(write_req_ack), .bmp_data_ready(write_data_ready),
        .sd_sec_read(sd_sec_read), .sd_sec_read_addr(sd_sec_read_addr), .sd_sec_read_data(sd_sec_read_data),
        .sd_sec_read_data_valid(sd_sec_read_data_valid), .sd_sec_read_end(sd_sec_read_end),
        .bmp_data_wr_en(bmp_data_wr_en), .bmp_data(bmp_data), .image_width(bmp_image_width),
        .image_height(bmp_image_height), .image_info_valid(bmp_image_info_valid), .image_error(bmp_image_error)
    );
    sd_sector_arbiter u_sector_arbiter (
        .clk(clk), .rst(rst), .sd_init_done(sd_init_done), .sd_io_error(sd_io_error),
        .bmp_req(sd_sec_read), .bmp_addr(sd_sec_read_addr), .bmp_data(sd_sec_read_data),
        .bmp_valid(sd_sec_read_data_valid), .bmp_end(sd_sec_read_end),
        .audio_req(audio_sd_req), .audio_addr(audio_sd_addr), .audio_priority(audio_sd_priority),
        .audio_accept(audio_sd_accept), .audio_data(audio_sd_data),
        .audio_valid(audio_sd_valid), .audio_end(audio_sd_end),
        .core_req(core_sec_read), .core_addr(core_sec_addr), .core_data(core_sec_data),
        .core_valid(core_sec_valid), .core_end(core_sec_end)
    );
    sd_card_top #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .IO_TIMEOUT_MS(SD_IO_TIMEOUT_MS),
        .INIT_TIMEOUT_MS(SD_INIT_TIMEOUT_MS)) sd_card_top_m0(
        .clk(clk), .rst(rst), .SD_nCS(SD_nCS), .SD_DCLK(SD_DCLK), .SD_MOSI(SD_MOSI), .SD_MISO(SD_MISO),
        .sd_init_done(sd_init_done), .io_error(sd_io_error), .sd_sec_read(core_sec_read), .sd_sec_read_addr(core_sec_addr),
        .sd_sec_read_data(core_sec_data), .sd_sec_read_data_valid(core_sec_valid), .sd_sec_read_end(core_sec_end),
        .sd_sec_write(1'b0), .sd_sec_write_addr(32'd0), .sd_sec_write_data(8'd0),
        .sd_sec_write_data_req(), .sd_sec_write_end()
    );
endmodule

module key_press_debounce #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire clk,
    input  wire rst,
    input  wire button_in,         // 默认：松开=1，按下=0
    output reg  press_pulse,
    output reg  button_stable_out  // 新增：消抖后的稳定状态输出
);

localparam integer DEBOUNCE_CYCLES = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

reg button_sync0;
reg button_sync1;
reg button_stable;
reg [31:0] cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        button_sync0      <= 1'b1;
        button_sync1      <= 1'b1;
        button_stable     <= 1'b1;
        button_stable_out <= 1'b1;
        cnt               <= 32'd0;
        press_pulse       <= 1'b0;
    end else begin
        button_sync0 <= button_in;
        button_sync1 <= button_sync0;
        press_pulse  <= 1'b0;

        if (button_sync1 == button_stable) begin
            cnt <= 32'd0;
        end else begin
            if (cnt >= DEBOUNCE_CYCLES - 1) begin
                if (button_stable && !button_sync1)
                    press_pulse <= 1'b1;
                button_stable     <= button_sync1;
                button_stable_out <= button_sync1;  // 同步输出稳定电平
                cnt               <= 32'd0;
            end else begin
                cnt <= cnt + 32'd1;
            end
        end
    end
end

endmodule
