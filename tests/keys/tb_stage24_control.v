`timescale 1ns/1ps
module tb_stage24_control;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, key1 = 1, key2 = 1, key3 = 1;
    reg initialized = 0, scanned = 0, found = 0, io_error = 0;
    reg [31:0] found_sector = 0;
    reg reader_ready = 1, pixel_valid = 0, write_toggle = 0;
    reg [7:0] reader_error = 0;
    reg [3:0] bad_images = 0, short_images = 0;
    reg hold_load = 0, omit_write_finish = 0, drop_switch = 0, stop_frames = 0;
    integer remaining = -1, loads = 0, counts [0:3];
    integer frame_count = 0, recoveries = 0;
    reg [1:0] previous_buffer = 0;
    reg [1:0] read_latched_buffer = 0;
    reg last_recovery = 0;
    wire [1:0] buffer, write_buffer, actual_buffer;
    wire emergency, autoplay, valid, fade_busy, recovery;
    wire [7:0] error_code;
    wire frame_start = !stop_frames && (frame_count == 0);
    wire switch_event = !drop_switch && (previous_buffer != buffer);
    sd_card_bmp #(.CLK_FREQ_HZ(1000), .USE_DEDICATED_EMERGENCY(1),
        .AUTO_PLAY_ON_BOOT(1), .AUTO_PLAY_MS(100000), .LOAD_STALL_MS(200),
        .MAX_LOAD_RETRIES(1), .CHECK_PIXEL_COUNT(1), .FRAME_PIXELS(16),
        .CHECK_DISPLAY_ACK(1), .TRANSITION_TIMEOUT_MS(200)) dut (
        .clk(clk), .rst(rst), .key_next(key1), .key_auto(key2), .key_emergency(key3),
        .transition_busy(fade_busy), .displayed_buf_idx(actual_buffer), .transition_recover_toggle(recovery),
        .bmp_width(16'd640), .bmp_height(16'd480), .display_valid(valid), .state_code(),
        .write_finish_toggle(write_toggle), .write_buf_idx(write_buffer), .disp_buf_idx(buffer),
        .auto_play_status(autoplay), .current_image_width(), .current_image_height(),
        .current_image_info_valid(), .current_image_error(error_code), .emergency_active(emergency),
        .write_req(), .write_req_ack(1'b0), .write_data_ready(1'b1), .write_en(), .write_data(),
        .SD_nCS(), .SD_DCLK(), .SD_MOSI(), .SD_MISO(1'b1));
    video_fade_overlay #(.FADE_FRAMES(2), .RECOVERY_ENABLE(1)) fade (
        .clk(clk), .rst(rst), .frame_start(frame_start), .switch_event(switch_event),
        .force_commit_toggle(recovery), .switch_buf_idx(buffer), .switch_image_idx({2'b00,dut.img_idx}+4'd1),
        .de(1'b1), .rgb_in(24'h123456), .rgb_out(), .display_buf_idx(actual_buffer),
        .display_image_idx(), .transition_busy(fade_busy));
    integer i;
    always @(posedge clk) begin
        if (rst) begin previous_buffer <= 0; frame_count <= 0; read_latched_buffer <= 0; end
        else begin
            previous_buffer <= buffer;
            frame_count <= (frame_count == 19) ? 0 : frame_count + 1;
            // 模拟视频读请求早于frame_start两个节拍锁存缓冲号。
            if (!stop_frames && frame_count == 18) read_latched_buffer <= actual_buffer;
        end
    end
    always @(negedge clk) begin
        if (rst) begin
            reader_ready = 1; pixel_valid = 0; write_toggle = 0;
            remaining = -1; loads = 0; reader_error = 0;
            recoveries = 0; last_recovery = 0;
            for (i = 0; i < 4; i = i + 1) counts[i] = 0;
        end else begin
            if (last_recovery != recovery) begin recoveries = recoveries + 1; last_recovery = recovery; end
            if (dut.load_abort) begin remaining = -1; reader_ready = 1; pixel_valid = 0; end
            else if (dut.load_start_pulse) begin
                if (valid && write_buffer == read_latched_buffer) $fatal(1, "writing the currently read buffer");
                loads = loads + 1; counts[dut.load_idx] = counts[dut.load_idx] + 1;
                reader_ready = 0; pixel_valid = 0;
                reader_error = bad_images[dut.load_idx] ? 8'h31 : 0;
                remaining = bad_images[dut.load_idx] ? 0 : (short_images[dut.load_idx] ? 8 : 16);
            end else if (remaining >= 0 && !hold_load) begin
                if (remaining > 0) begin pixel_valid = 1; remaining = remaining - 1; end
                else begin
                    pixel_valid = 0; reader_ready = 1; remaining = -1;
                    if (!omit_write_finish && reader_error == 0) write_toggle = ~write_toggle;
                end
            end
        end
    end
    task ticks;
        input integer count;
        repeat(count) begin @(posedge clk); #1; end
    endtask
    task reset_all;
        begin
            rst = 1; key1 = 1; key2 = 1; key3 = 1;
            initialized = 0; scanned = 0; found = 0; io_error = 0;
            hold_load = 0; omit_write_finish = 0; drop_switch = 0; stop_frames = 0;
            ticks(5); rst = 0;
        end
    endtask
    task catalogue;
        input integer images;
        integer k;
        begin
            initialized = 1; ticks(5);
            for (k = 0; k < images; k = k + 1) begin
                found_sector = k * 100; found = 1; ticks(1); found = 0; ticks(1);
            end
            scanned = 1; ticks(500);
        end
    endtask
    task press3;
        begin key3 = 0; ticks(60); key3 = 1; ticks(60); end
    endtask
    task press2;
        begin key2 = 0; ticks(60); key2 = 1; ticks(60); end
    endtask
    task press1;
        begin key1 = 0; ticks(60); key1 = 1; ticks(200); end
    endtask
    integer before_loads, k;
    initial begin
        force dut.sd_init_done = initialized;
        force dut.sd_io_error = io_error;
        force dut.bmp_ready = reader_ready;
        force dut.bmp_scan_done = scanned;
        force dut.scan_found_valid = found;
        force dut.scan_found_sector = found_sector;
        force dut.bmp_image_error = reader_error;
        force dut.bmp_image_width = 16'd640;
        force dut.bmp_image_height = 16'd480;
        force dut.bmp_image_info_valid = 1'b1;
        force dut.bmp_data_wr_en = pixel_valid;
        force dut.sd_sec_read_data_valid = 1'b0;
        force dut.sd_sec_read_end = 1'b0;
        reset_all();
        press3();
        if (!emergency) $fatal(1, "KEY3 blocked by absent SD card");
        press2();
        if (autoplay) $fatal(1, "KEY2 affected emergency playback");
        key3 = 0; ticks(4000);
        if (emergency) $fatal(1, "KEY3 did not exit / repeated while held");
        key3 = 1; ticks(60);
        if (emergency || !autoplay) $fatal(1, "held KEY3 release toggled again");
        $display("PASS dedicated KEY3 enters/exits without a card; held key acts once");
        catalogue(4);
        if (!valid || !autoplay || dut.img_idx != 0) $fatal(1, "boot did not load normal poster/autoplay");
        press2(); if (autoplay) $fatal(1, "KEY2 did not pause");
        press1(); if (dut.img_idx != 1) $fatal(1, "KEY1 did not navigate");
        press3(); ticks(150);
        if (!emergency || dut.img_idx != 3) $fatal(1, "KEY3 did not load emergency poster");
        press3(); ticks(150);
        if (emergency || autoplay || dut.img_idx != 1) $fatal(1, "did not restore poster/pause setting");
        $display("PASS KEY1/KEY2/KEY3 separation, startup autoplay, paused state restore");

        before_loads = loads;
        for (k = 0; k < 100; k = k + 1) press3();
        ticks(300);
        if (emergency || dut.img_idx != 1 || dut.load_busy) $fatal(1, "100-key stress did not settle");
        $display("PASS 100 emergency toggles settle to original normal poster");

        bad_images = 4'b0001; reset_all(); catalogue(4);
        if (!valid || dut.img_idx != 1 || counts[0] != 2) $fatal(1, "bad first poster was not retried once/skipped");
        $display("PASS first bad poster retries once and skips to second");
        bad_images = 4'hf; reset_all(); catalogue(4); ticks(1000);
        if (valid || loads != 8) $fatal(1, "all-bad catalogue retries forever or committed incomplete frame");
        before_loads = loads; ticks(1000);
        if (loads != before_loads) $fatal(1, "all-bad request storm");
        bad_images = 0; press1(); ticks(300);
        if (!valid || dut.img_idx != 0) $fatal(1, "KEY1 did not retry repaired media");
        $display("PASS all-bad images stop after bounded attempts; KEY1 retries repaired media");

        reset_all(); catalogue(0);
        if (!dut.scan_done || error_code != 8'h3e) $fatal(1, "empty catalogue not reported");
        key1 = 0;
        wait (dut.scan_start_pulse); ticks(1);
        // 模拟真实BMP：收到start的时钟沿之后才撤销上次保持为1的done。
        scanned = 0; ticks(2);
        if (dut.scan_done) $fatal(1, "rescan accepted stale completion");
        key1 = 1;
        found_sector = 100; found = 1; ticks(1); found = 0; ticks(1);
        scanned = 1; ticks(400);
        if (!valid || dut.img_found_count != 1) $fatal(1, "rescan ignored newly found poster");
        $display("PASS KEY1 rescan rejects stale scan_done and accepts newly inserted media");

        reset_all(); initialized = 1; ticks(5);
        found = 1; ticks(1); found = 0; ticks(2);
        press3(); press3();
        if (dut.normal_resume_pending) $fatal(1, "partial catalogue queued nonexistent normal restore");
        initialized = 0; io_error = 1; ticks(1); io_error = 0; ticks(10);
        catalogue(0);
        if (dut.normal_resume_pending || dut.normal_restore_active)
            $fatal(1, "empty rescan retained restore lock");
        key1 = 0; wait (dut.scan_start_pulse); key1 = 1;
        $display("PASS failed partial scan followed by empty catalogue does not lock KEY1");

        short_images = 1; reset_all(); catalogue(4);
        if (!valid || dut.img_idx != 1 || counts[0] != 2) $fatal(1, "short frame was committed");
        short_images = 0;
        $display("PASS incomplete pixel stream rejected before frame commit");

        reset_all(); catalogue(4); press2(); hold_load = 1;
        key1 = 0; ticks(60); key1 = 1; ticks(60);
        initialized = 0; io_error = 1; ticks(1); io_error = 0; scanned = 0; ticks(20);
        if (!valid || buffer != 0 || !dut.scan_done) $fatal(1, "SD recovery erased last good picture/catalogue");
        press3(); if (!emergency) $fatal(1, "KEY3 blocked during SD recovery");
        press3(); if (emergency) $fatal(1, "exit blocked during SD recovery");
        hold_load = 0; initialized = 1; ticks(400);
        if (dut.load_busy || !valid || dut.img_idx != 0) $fatal(1, "SD reinitialization did not resume");
        $display("PASS SD reinitialization preserves frame/catalogue and emergency controls");

        reset_all(); catalogue(4); press2(); drop_switch = 1;
        key1 = 0; ticks(60); key1 = 1; ticks(60);
        key1 = 0; ticks(60); key1 = 1; ticks(600);
        if (recoveries == 0 || actual_buffer != buffer || dut.transition_wait)
            $fatal(1, "lost transition not recovered with real frame-boundary acknowledgement");
        drop_switch = 0;
        $display("PASS lost transition request recovers without writing displayed buffer");
        stop_frames = 1; press1(); ticks(600);
        if (!dut.transition_wait || error_code != 8'h3f) $fatal(1, "stopped video did not hold buffer reuse");
        before_loads = loads; press3(); press3(); ticks(300);
        if (emergency || loads != before_loads) $fatal(1, "video failure blocked exit or allowed unsafe write");
        stop_frames = 0; ticks(600);
        if (dut.transition_wait || actual_buffer != buffer) $fatal(1, "video return did not complete recovery");
        $display("PASS stopped video preserves buffers; controls work and recovery follows frame return");
        $display("ALL STAGE24 CONTROL TESTS PASS");
        $finish;
    end
    initial begin #3000000; $fatal(1, "control watchdog"); end
endmodule
