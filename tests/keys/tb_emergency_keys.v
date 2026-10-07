`timescale 1ns/1ps
// 对真实控制器施加按键；仅替代 SD/BMP 外设响应，不替代按键和调度逻辑。
module tb_emergency_keys;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, key_next = 1, key_auto = 1;
    reg sd_initialized = 0, scanned = 0, found = 0;
    reg [31:0] found_sector = 0;
    reg reader_ready = 1, write_toggle = 0;
    reg hold_load = 0, hold_transition = 0;
    reg [7:0] reader_error = 0;
    integer load_left = 0, fade_left = 0, load_count = 0;
    integer last_loaded = -1;
    reg [1:0] previous_buffer = 0;
    wire transition_busy = hold_transition || (fade_left != 0);
    wire emergency, autoplay, display_valid;
    wire [1:0] display_buffer;
    wire [7:0] image_error;

    sd_card_bmp #(.CLK_FREQ_HZ(1000), .LONG_PRESS_MS(1000),
        .AUTO_PLAY_MS(100000), .LOAD_STALL_MS(10000),
        .CHECK_PIXEL_COUNT(0), .MAX_LOAD_RETRIES(0)) dut (
        .clk(clk), .rst(rst), .key_next(key_next), .key_auto(key_auto),
        .key_emergency(1'b1), .displayed_buf_idx(2'd0), .transition_recover_toggle(),
        .transition_busy(transition_busy), .bmp_width(16'd640), .bmp_height(16'd480),
        .display_valid(display_valid), .state_code(), .write_finish_toggle(write_toggle),
        .write_buf_idx(), .disp_buf_idx(display_buffer), .auto_play_status(autoplay),
        .current_image_width(), .current_image_height(), .current_image_info_valid(),
        .current_image_error(image_error), .emergency_active(emergency),
        .write_req(), .write_req_ack(1'b0), .write_data_ready(1'b1),
        .write_en(), .write_data(), .SD_nCS(), .SD_DCLK(), .SD_MOSI(), .SD_MISO(1'b1)
    );

    // 模拟源文件完成、SDRAM 写完和正常转场；按键逻辑始终运行真实 RTL。
    always @(negedge clk) begin
        if (rst) begin
            reader_ready = 1;
            write_toggle = 0;
            load_left = 0;
            fade_left = 0;
            load_count = 0;
            last_loaded = -1;
            previous_buffer = 0;
        end else begin
            if (dut.load_abort) begin
                load_left = 0;
                reader_ready = 1;
            end else if (dut.load_start_pulse) begin
                if (load_left != 0) $fatal(1, "overlapping load requests");
                reader_ready = 0;
                load_left = 20;
                load_count = load_count + 1;
                last_loaded = dut.load_idx;
            end else if (load_left != 0 && !hold_load) begin
                load_left = load_left - 1;
                if (load_left == 0) begin
                    reader_ready = 1;
                    write_toggle = ~write_toggle;
                end
            end
            if (fade_left != 0) fade_left = fade_left - 1;
            if (display_buffer != previous_buffer) begin
                previous_buffer = display_buffer;
                fade_left = 30;
            end
        end
    end

    task ticks;
        input integer count;
        repeat (count) begin @(posedge clk); #1; end
    endtask

    task scan_card;
        input integer images;
        integer i;
        begin
            rst = 1; key_auto = 1; key_next = 1;
            hold_load = 0; hold_transition = 0; reader_error = 0;
            sd_initialized = 0; scanned = 0; found = 0;
            ticks(5);
            rst = 0; sd_initialized = 1;
            ticks(5);
            for (i = 0; i < images; i = i + 1) begin
                found_sector = 100 + 100 * i;
                found = 1; ticks(1);
                found = 0; ticks(1);
            end
            scanned = 1;
        end
    endtask

    task boot;
        input integer images;
        begin
            scan_card(images);
            ticks(150);
            if (images != 0 && !display_valid) $fatal(1, "initial image missing");
        end
    endtask

    task short_auto;
        begin key_auto = 0; ticks(100); key_auto = 1; ticks(70); end
    endtask

    task long_auto;
        begin key_auto = 0; ticks(1500); key_auto = 1; ticks(70); end
    endtask

    task next_image;
        begin key_next = 0; ticks(100); key_next = 1; ticks(100); end
    endtask

    integer saved_count;
    integer n;
    initial begin
        force dut.sd_init_done = sd_initialized;
        force dut.sd_io_error = 1'b0;
        force dut.bmp_ready = reader_ready;
        force dut.scan_done = scanned;
        force dut.scan_found_valid = found;
        force dut.scan_found_sector = found_sector;
        force dut.bmp_image_error = reader_error;
        force dut.bmp_image_width = 16'd640;
        force dut.bmp_image_height = 16'd480;
        force dut.bmp_image_info_valid = 1'b1;
        force dut.sd_sec_read_data_valid = 1'b0;
        force dut.sd_sec_read_end = 1'b0;
        force dut.bmp_data_wr_en = 1'b0;

        boot(4);
        repeat (4) begin key_auto = 0; ticks(5); key_auto = 1; ticks(5); end
        ticks(60);
        if (autoplay || emergency) $fatal(1, "bounce triggered an action");
        key_auto = 0; ticks(100);
        if (autoplay) $fatal(1, "short action fired before release");
        key_auto = 1; ticks(70);
        if (!autoplay || emergency) $fatal(1, "short release must only enable autoplay");
        $display("PASS debounce and short/long separation");

        next_image();
        if (dut.img_idx != 1) $fatal(1, "normal next image failed");
        long_auto();
        if (!emergency || autoplay || last_loaded != 3) $fatal(1, "emergency entry failed");
        saved_count = load_count;
        next_image(); ticks(1500);
        if (!emergency || autoplay || load_count != saved_count)
            $fatal(1, "ordinary navigation escaped emergency mode");
        short_auto(); ticks(150);
        if (emergency || !autoplay || dut.img_idx != 1)
            $fatal(1, "short exit must restore normal image and autoplay");
        $display("PASS emergency entry, normal navigation suppression, short exit and restore");

        key_auto = 0; ticks(4000);
        saved_count = load_count;
        if (!emergency || autoplay) $fatal(1, "long hold failed");
        ticks(2000);
        if (!emergency || load_count != saved_count) $fatal(1, "hold repeated emergency action");
        key_auto = 1; ticks(70);
        if (!emergency || autoplay) $fatal(1, "long release acted as short press");
        long_auto(); ticks(150);
        if (emergency || !autoplay || dut.img_idx != 1) $fatal(1, "long exit failed");
        $display("PASS held key triggers once, release is consumed, long exit works");

        boot(4);
        hold_transition = 1;
        next_image();
        long_auto();
        short_auto();
        if (emergency || dut.emergency_req_pending) $fatal(1, "stale emergency request after exit");
        hold_transition = 0; ticks(200);
        if (last_loaded != 0 || dut.img_idx != 0 || dut.next_req_pending)
            $fatal(1, "pending normal request overwrote resume");
        $display("PASS queued navigation and emergency cancel while transition busy");

        boot(4); next_image(); hold_load = 1;
        long_auto();
        if (!dut.load_busy || last_loaded != 3) $fatal(1, "expected in-flight emergency load");
        short_auto();
        if (emergency) $fatal(1, "cannot exit during load");
        long_auto();
        if (!emergency || dut.normal_resume_pending)
            $fatal(1, "quick reentry retained stale resume or lost normal image");
        hold_load = 0; ticks(300);
        short_auto(); ticks(200);
        if (emergency || dut.img_idx != 1) $fatal(1, "in-flight reentry/exit did not recover");
        $display("PASS exit/reenter during load preserves original normal image");

        boot(4); next_image(); long_auto();
        hold_load = 1; short_auto();
        if (last_loaded != 1 || dut.normal_resume_pending || !dut.load_busy || dut.img_idx != 3)
            $fatal(1, "expected restore load in flight while emergency image is displayed");
        long_auto(); hold_load = 0; ticks(300);
        short_auto(); ticks(200);
        if (emergency || dut.img_idx != 1)
            $fatal(1, "reentry during restore load replaced normal snapshot with emergency image");
        $display("PASS reentry after restore request is consumed preserves normal snapshot");

        boot(4); next_image(); long_auto(); reader_error = 8'h31;
        short_auto(); ticks(100);
        if (emergency || dut.load_busy || image_error != 8'h31)
            $fatal(1, "expected failed restore load");
        reader_error = 0; next_image();
        if (dut.img_idx != 0) $fatal(1, "normal navigation did not recover after failed restore");
        long_auto(); short_auto(); ticks(200);
        if (emergency || dut.img_idx != 0)
            $fatal(1, "failed restore left stale snapshot after successful normal navigation");
        $display("PASS successful normal navigation after failed restore refreshes snapshot");

        boot(4); hold_load = 1; long_auto(); ticks(10500);
        if (!emergency || dut.load_busy || image_error != 8'h38)
            $fatal(1, "stalled emergency load did not time out");
        hold_load = 0; short_auto(); ticks(200);
        if (emergency || image_error != 0 || dut.img_idx != 0)
            $fatal(1, "stalled load prevented normal recovery");
        $display("PASS emergency load timeout and short-press recovery");

        scan_card(4); hold_load = 1; ticks(100); long_auto();
        if (display_valid || !emergency) $fatal(1, "expected emergency during initial load");
        reader_error = 8'h31; hold_load = 0;
        wait (dut.load_abort); #1; reader_error = 0;
        ticks(150);
        if (!display_valid || !emergency || dut.img_idx != 3)
            $fatal(1, "bad initial poster blocked valid emergency poster");
        short_auto(); ticks(150);
        if (emergency || dut.img_idx != 0) $fatal(1, "cannot restore after initial poster failure");
        $display("PASS valid emergency poster can bypass failed initial normal poster");

        for (n = 1; n <= 3; n = n + 1) begin
            boot(n); long_auto();
            if (!emergency || image_error != 8'h3d) $fatal(1, "missing poster must report 3d");
            short_auto(); ticks(150);
            if (emergency || image_error != 0 || !display_valid)
                $fatal(1, "missing emergency poster blocked exit");
        end
        $display("PASS 1/2/3-image configurations remain responsive without emergency poster");

        boot(0); short_auto(); long_auto();
        if (emergency || autoplay || load_count != 0) $fatal(1, "no-image case scheduled a load");
        $display("PASS empty card ignores playback and emergency requests");

        boot(4); reader_error = 8'h31;
        long_auto();
        if (!emergency || dut.load_busy || image_error != 8'h31) $fatal(1, "bad emergency BMP stuck loader");
        reader_error = 0; short_auto(); ticks(150);
        if (emergency || image_error != 0 || dut.img_idx != 0) $fatal(1, "bad BMP prevented recovery");
        $display("PASS invalid emergency BMP recovery");

        boot(4);
        // 定向碰撞：同一拍所有请求到达时，应急必须具有唯一优先级。
        @(negedge clk); #1;
        dut.emergency_mode = 1;
        dut.emergency_req_pending = 1;
        dut.next_req_pending = 1;
        dut.auto_play_en = 1;
        dut.auto_cnt = 99999;
        ticks(2);
        if (last_loaded != 3) $fatal(1, "normal load overwrote emergency arbitration");
        $display("PASS simultaneous emergency/next/autoplay arbitration");
        $display("ALL KEY TESTS PASS");
        $finish;
    end
    initial begin #2000000; $fatal(1, "test watchdog expired"); end
endmodule
