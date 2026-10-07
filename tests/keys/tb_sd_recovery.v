`timescale 1ns/1ps
// SPI卡模型仅驱动MISO。真实BMP、SD命令、扇区和SPI模块全部参与。
module tb_sd_recovery;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, load_start = 0, load_abort = 0, ack = 0;
    wire ready, write_req, pixel_valid;
    wire [23:0] pixel;
    wire ncs, sck, mosi, initialized, io_error;
    reg miso = 1, card_present = 0, omit_token = 0;
    wire read_req, data_valid, read_end;
    wire [31:0] read_addr;
    wire [7:0] data_byte, image_error;
    integer pixel_count = 0, errors = 0;
    sd_card_top #(.SPI_LOW_SPEED_DIV(0), .CLK_FREQ_HZ(1000000),
        .IO_TIMEOUT_MS(5), .INIT_TIMEOUT_MS(50), .RESET_HOLD_MS(1)) dut (
        .clk(clk), .rst(rst), .SD_nCS(ncs), .SD_DCLK(sck), .SD_MOSI(mosi), .SD_MISO(miso),
        .sd_init_done(initialized), .sd_sec_read(read_req), .sd_sec_read_addr(read_addr),
        .sd_sec_read_data(data_byte), .sd_sec_read_data_valid(data_valid), .sd_sec_read_end(read_end),
        .sd_sec_write(1'b0), .sd_sec_write_addr(32'd0), .sd_sec_write_data(8'd0),
        .sd_sec_write_data_req(), .sd_sec_write_end(), .io_error(io_error));
    bmp_read #(.FRAME_WIDTH(4), .FRAME_HEIGHT(2), .MAX_DIM(16)) bmp (
        .clk(clk), .rst(rst), .ready(ready), .scan_start(1'b0), .scan_start_sector(32'd0),
        .scan_max_sector(32'd0), .scan_target_count(3'd0), .scan_done(), .scan_found_valid(),
        .scan_found_sector(), .scan_found_total(), .load_start(load_start), .load_abort(load_abort),
        .load_sector(32'd0), .sd_init_done(initialized), .state_code(),
        .bmp_width(16'd4), .bmp_height(16'd2), .write_req(write_req), .write_req_ack(ack),
        .bmp_data_ready(!ack), .sd_sec_read(read_req), .sd_sec_read_addr(read_addr),
        .sd_sec_read_data(data_byte), .sd_sec_read_data_valid(data_valid), .sd_sec_read_end(read_end),
        .bmp_data_wr_en(pixel_valid), .bmp_data(pixel), .image_width(), .image_height(),
        .image_info_valid(), .image_error(image_error));

    always @(posedge clk) begin
        ack <= write_req;
        if (io_error) errors = errors + 1;
        if (!rst && pixel_valid && !ack) begin
            if (pixel !== 24'h123456) $fatal(1, "stale or damaged pixel: %h", pixel);
            pixel_count = pixel_count + 1;
        end
    end

    reg [7:0] queue [0:1023];
    integer head = 0, tail = 0, rx_bits = 0, tx_bits = 0, cmd_count = 0;
    reg [7:0] rx_byte = 0, tx_byte = 8'hff, command = 0;
    integer j;
    function [7:0] bmp_byte;
        input integer offset;
        begin
            case (offset)
                0: bmp_byte = 8'h42;
                1: bmp_byte = 8'h4d;
                2: bmp_byte = 78;
                10: bmp_byte = 54;
                14: bmp_byte = 40;
                18: bmp_byte = 4;
                22: bmp_byte = 8'hfe;
                23,24,25: bmp_byte = 8'hff;
                26: bmp_byte = 1;
                28: bmp_byte = 24;
                default: if (offset >= 54 && offset < 78) begin
                    case ((offset - 54) % 3)
                        0: bmp_byte = 8'h56;
                        1: bmp_byte = 8'h34;
                        default: bmp_byte = 8'h12;
                    endcase
                end else bmp_byte = 0;
            endcase
        end
    endfunction
    task enqueue;
        input [7:0] value;
        begin queue[tail] = value; tail = tail + 1; end
    endtask
    task receive_byte;
        input [7:0] value;
        begin
            if (cmd_count == 0) begin
                if (value[7:6] == 2'b01) begin command = value & 8'h3f; cmd_count = 1; end
            end else if (cmd_count == 5) begin
                cmd_count = 0;
                case (command)
                    0,55: enqueue(8'h01);
                    8: begin enqueue(8'h01); enqueue(0); enqueue(0); enqueue(1); enqueue(8'haa); end
                    17: begin
                        enqueue(0);
                        if (!omit_token) begin
                            enqueue(8'hff); enqueue(8'hff); enqueue(8'hfe);
                            for (j = 0; j < 512; j = j + 1) enqueue(bmp_byte(j));
                            enqueue(0); enqueue(0);
                        end
                    end
                    default: enqueue(0);
                endcase
            end else cmd_count = cmd_count + 1;
        end
    endtask
    always @(posedge ncs) begin
        head = 0; tail = 0; rx_bits = 0; tx_bits = 0; cmd_count = 0; miso = 1;
    end
    always @(negedge sck) begin
        if (!ncs && card_present) begin
            if (tx_bits == 0) begin
                if (head < tail) begin tx_byte = queue[head]; head = head + 1; end
                else tx_byte = 8'hff;
            end
            miso = tx_byte[7-tx_bits];
            tx_bits = (tx_bits + 1) % 8;
        end else miso = 1;
    end
    always @(posedge sck) begin
        if (!ncs && card_present) begin
            rx_byte = {rx_byte[6:0], mosi};
            if (rx_bits == 7) begin rx_bits = 0; receive_byte(rx_byte); end
            else rx_bits = rx_bits + 1;
        end
    end
    task ticks;
        input integer count;
        repeat (count) begin @(posedge clk); #1; end
    endtask
    task launch;
        begin wait (ready); ticks(10); load_start = 1; ticks(1); load_start = 0; end
    endtask
    initial begin
        ticks(5); rst = 0;
        wait (io_error); ticks(2);
        if (initialized || !ncs) $fatal(1, "no-card initialization did not reset SPI");
        $display("PASS absent card has bounded initialization and deselected SPI");
        card_present = 1; omit_token = 1;
        launch();
        wait (dut.sd_card_cmd_m0.state == 6); ticks(100);
        load_abort = 1; ticks(1); load_abort = 0; ticks(3);
        if (bmp.state != 18) $fatal(1, "test did not reach real BMP drain state");
        wait (io_error); ticks(2);
        if (initialized || !ncs || bmp.state != 0) $fatal(1, "missing token left BMP/SD/SPI stuck");
        $display("PASS missing token resets real SD chain and releases BMP drain");
        omit_token = 0;
        launch(); wait (!ready); wait (ready); ticks(5);
        if (pixel_count != 8 || image_error != 0) $fatal(1, "reinitialized card failed complete BMP load");
        $display("PASS real SPI reinitialization and eight fresh pixels after missing token");
        launch(); wait (data_valid); ticks(10);
        // 注入SPI执行单元不再前进，检验数据中途无进展也能重启。
        force dut.spi_master_m0.state = 3'd0;
        wait (io_error); release dut.spi_master_m0.state; ticks(2);
        if (initialized || !ncs || bmp.state != 0) $fatal(1, "mid-sector stall not recovered");
        launch(); wait (!ready); wait (ready); ticks(5);
        if (pixel_count != 16 || image_error != 0 || errors != 3)
            $fatal(1, "bad recovery count/pixels: errors=%0d pixels=%0d", errors, pixel_count);
        $display("PASS mid-sector SPI stall recovery without stale pixels");
        $finish;
    end
    initial begin #10000000; $fatal(1, "SD recovery watchdog"); end
endmodule
