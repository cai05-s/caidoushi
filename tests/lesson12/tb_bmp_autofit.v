`timescale 1ns/1ps

module tb_bmp_autofit;
    localparam W = 640, H = 480;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    reg load_start = 0, load_abort = 0;
    wire ready, write_req, sd_read, pixel_valid;
    reg write_ack = 0, pixel_ready = 0;
    wire [31:0] sd_address;
    reg [7:0] sd_byte = 0;
    reg sd_valid = 0, sd_end = 0;
    wire [23:0] pixel;
    wire [15:0] image_width, image_height;
    wire info_valid;
    wire [7:0] image_error;
    wire scan_done, scan_found;
    wire [31:0] scan_sector;
    wire [2:0] scan_count;
    wire [3:0] state_code;
    bmp_read dut (
        .clk(clk), .rst(rst), .ready(ready),
        .scan_start(1'b0), .scan_start_sector(32'd0), .scan_max_sector(32'd1000000),
        .scan_target_count(3'd4), .scan_done(scan_done), .scan_found_valid(scan_found),
        .scan_found_sector(scan_sector), .scan_found_total(scan_count),
        .load_start(load_start), .load_abort(load_abort), .load_sector(32'd17),
        .sd_init_done(!rst), .state_code(state_code), .bmp_width(16'd640), .bmp_height(16'd480),
        .write_req(write_req), .write_req_ack(write_ack), .bmp_data_ready(pixel_ready),
        .sd_sec_read(sd_read), .sd_sec_read_addr(sd_address), .sd_sec_read_data(sd_byte),
        .sd_sec_read_data_valid(sd_valid), .sd_sec_read_end(sd_end),
        .bmp_data_wr_en(pixel_valid), .bmp_data(pixel), .image_width(image_width),
        .image_height(image_height), .image_info_valid(info_valid), .image_error(image_error)
    );

    reg [7:0] reference [0:W*H*3-1];
    reg [7:0] sector [0:511];
    reg [4095:0] bmp_path, reference_path, case_name;
    integer input_file, reference_file, got, status, bytes_read;
    integer expected_w, expected_h, expected_error = 0, short_sector = 0, sd_gap = 0;
    integer sd_state = 0, sd_index = 0, sd_wait = 0, sector_reads = 0;
    integer cycles = 0, received = 0, stalled_cycles = 0;
    integer ack_state = 0, ack_wait = 0;
    reg ack_complete = 0, request_seen = 0;
    reg [15:0] random_bits = 16'hd431;
    reg previous_stall = 0;
    reg [23:0] previous_pixel;

    initial begin
        if (!$value$plusargs("bmp=%s", bmp_path)) $fatal(1, "missing bmp");
        if (!$value$plusargs("name=%s", case_name)) case_name = "unnamed";
        status = $value$plusargs("width=%d", expected_w);
        status = $value$plusargs("height=%d", expected_h);
        status = $value$plusargs("error=%d", expected_error);
        status = $value$plusargs("short_sector=%d", short_sector);
        status = $value$plusargs("sd_gap=%d", sd_gap);
        input_file = $fopen(bmp_path, "rb");
        if (!input_file) $fatal(1, "cannot open BMP");
        if (expected_error == 0) begin
            if (!$value$plusargs("reference=%s", reference_path)) $fatal(1, "missing reference");
            reference_file = $fopen(reference_path, "rb");
            if (!reference_file) $fatal(1, "cannot open reference");
            got = $fread(reference, reference_file);
            $fclose(reference_file);
            if (got != W*H*3) $fatal(1, "bad reference length %0d", got);
        end
        repeat (5) @(negedge clk);
        rst = 0;
        repeat (4) @(negedge clk);
        load_start = 1;
        @(negedge clk);
        load_start = 0;
        wait (!ready);
        wait (ready);
        @(negedge clk);
        if (expected_error != 0) begin
            if (image_error != expected_error || info_valid || received != 0 || request_seen)
                $fatal(1, "invalid BMP accepted: error=%h expected=%h valid=%b count=%0d",
                    image_error, expected_error, info_valid, received);
        end else begin
            if (received != W*H || !info_valid || image_error != 0)
                $fatal(1, "incomplete frame: count=%0d valid=%b error=%h", received, info_valid, image_error);
            if (image_width != expected_w || image_height != expected_h)
                $fatal(1, "wrong dimensions %0dx%0d", image_width, image_height);
            if (stalled_cycles == 0) $fatal(1, "backpressure was not exercised");
        end
        $display("PASS %0s pixels=%0d sectors=%0d stalls=%0d cycles=%0d",
            case_name, received, sector_reads, stalled_cycles, cycles);
        $fclose(input_file);
        $finish;
    end

    // 无消费握手的真实 SD 扇区接口：一旦开始，完整送出 512 字节。
    always @(negedge clk) begin
        sd_valid = 0;
        sd_end = 0;
        if (!rst) begin
            case (sd_state)
                0: if (sd_read) begin
                    if (sd_address < 17) $fatal(1, "invalid sector address");
                    status = $fseek(input_file, (sd_address - 17) * 512, 0);
                    if (status != 0) $fatal(1, "seek failed");
                    for (sd_index = 0; sd_index < 512; sd_index = sd_index + 1) sector[sd_index] = 0;
                    bytes_read = $fread(sector, input_file);
                    sd_index = 0;
                    sd_wait = 0;
                    sd_state = 1;
                    sector_reads = sector_reads + 1;
                end
                1: begin
                    if (sd_wait != 0) sd_wait = sd_wait - 1;
                    else begin
                        sd_byte = sector[sd_index];
                        sd_valid = 1;
                        sd_index = sd_index + 1;
                        sd_wait = sd_gap;
                        if (sd_index == (short_sector ? 20 : 512)) sd_state = 2;
                    end
                end
                2: begin sd_end = 1; sd_state = 3; end
                3: if (!sd_read) sd_state = 0;
            endcase
        end
    end

    // 应答期间 FIFO 仍在清空，撤销后额外等待若干拍，再加入随机与长时间停顿。
    always @(negedge clk) begin
        if (!rst) begin
            random_bits = {random_bits[14:0], random_bits[15] ^ random_bits[13] ^ random_bits[12] ^ random_bits[10]};
            case (ack_state)
                0: if (write_req) begin ack_wait = 4; ack_state = 1; end
                1: if (ack_wait != 0) ack_wait = ack_wait - 1;
                   else begin write_ack = 1; ack_state = 2; end
                2: if (!write_req) begin ack_wait = 5; ack_state = 3; end
                3: if (ack_wait != 0) ack_wait = ack_wait - 1;
                   else begin write_ack = 0; ack_wait = 4; ack_state = 4; end
                4: if (ack_wait != 0) ack_wait = ack_wait - 1;
                   else begin ack_complete = 1; ack_state = 5; end
            endcase
            pixel_ready = ack_complete && (random_bits[2:0] != 0) && (cycles % 4096 >= 900);
        end
    end

    always @(posedge clk) begin
        if (!rst) begin
            cycles = cycles + 1;
            if (cycles > 50000000) $fatal(1, "timeout state=%0d pixels=%0d", dut.state, received);
            if (write_req) request_seen = 1;
            if (previous_stall && (!pixel_valid || pixel !== previous_pixel))
                $fatal(1, "valid/data changed while stalled");
            if (pixel_valid && !ack_complete) $fatal(1, "pixel emitted during FIFO reset");
            previous_stall = pixel_valid && !pixel_ready;
            previous_pixel = pixel;
            if (previous_stall) stalled_cycles = stalled_cycles + 1;
            if (pixel_valid && pixel_ready) begin
                if (received >= W*H) $fatal(1, "extra pixel");
                if (pixel !== {reference[received*3], reference[received*3+1], reference[received*3+2]})
                    $fatal(1, "pixel %0d (%0d,%0d): got %h expected %h%h%h",
                        received, received % W, received / W, pixel,
                        reference[received*3], reference[received*3+1], reference[received*3+2]);
                received = received + 1;
            end
        end
    end
endmodule
