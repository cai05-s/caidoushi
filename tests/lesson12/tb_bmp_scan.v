`timescale 1ns/1ps

// 检查不同文件长度的扇区跳转、空洞、数量上限及 32 位地址溢出。
module tb_bmp_scan;
    reg clk = 0, rst = 1, scan_start = 0;
    always #5 clk = !clk;
    reg [31:0] first_sector = 17, last_sector = 22;
    reg [2:0] target_count = 4;
    wire ready, done, found, sd_read;
    wire [31:0] found_sector, sd_address;
    wire [2:0] found_total;
    reg [7:0] sd_byte = 0;
    reg sd_valid = 0, sd_end = 0;
    integer sd_state = 0, byte_index = 0, reads = 0, match_count = 0, scenario = 0;
    reg [31:0] active_sector;

    bmp_read dut (
        .clk(clk), .rst(rst), .ready(ready), .scan_start(scan_start),
        .scan_start_sector(first_sector), .scan_max_sector(last_sector),
        .scan_target_count(target_count), .scan_done(done), .scan_found_valid(found),
        .scan_found_sector(found_sector), .scan_found_total(found_total),
        .load_start(1'b0), .load_abort(1'b0), .load_sector(32'd0),
        .sd_init_done(!rst), .bmp_width(16'd640), .bmp_height(16'd480),
        .write_req_ack(1'b0), .bmp_data_ready(1'b0), .sd_sec_read(sd_read),
        .sd_sec_read_addr(sd_address), .sd_sec_read_data(sd_byte),
        .sd_sec_read_data_valid(sd_valid), .sd_sec_read_end(sd_end)
    );

    function [7:0] header_byte;
        input [31:0] sector;
        input integer position;
        reg [31:0] length;
        begin
            length = sector == 17 ? 513 : sector == 19 ? 512 :
                     sector == 21 ? 1024 : sector == 32'hfffffff0 ? 16384 : 0;
            header_byte = 0;
            if (length != 0) begin
                case (position)
                    0: header_byte = 8'h42;
                    1: header_byte = 8'h4d;
                    2, 3, 4, 5: header_byte = length >> ((position - 2) * 8);
                    10: header_byte = 54;
                    14: header_byte = 40;
                    18, 22, 26: header_byte = 1;
                    28: header_byte = 24;
                    default: header_byte = 0;
                endcase
            end
        end
    endfunction

    always @(negedge clk) begin
        sd_valid = 0; sd_end = 0;
        if (rst) sd_state = 0;
        else case (sd_state)
            0: if (sd_read) begin
                if (sd_address < first_sector || sd_address > last_sector)
                    $fatal(1, "out-of-range scan address %h", sd_address);
                if (sd_address == 18 || sd_address == 22)
                    $fatal(1, "did not skip file payload at %0d", sd_address);
                active_sector = sd_address; byte_index = 0;
                reads = reads + 1; sd_state = 1;
            end
            1: begin
                sd_byte = header_byte(active_sector, byte_index); sd_valid = 1;
                byte_index = byte_index + 1;
                if (byte_index == 512) sd_state = 2;
            end
            2: begin sd_end = 1; sd_state = 3; end
            3: if (!sd_read) sd_state = 0;
        endcase
    end

    always @(posedge clk) begin
        if (!rst && found) begin
            if (scenario < 2) begin
                case (match_count)
                    0: if (found_sector != 17) $fatal(1, "first match");
                    1: if (found_sector != 19) $fatal(1, "ceil length/512");
                    2: if (found_sector != 21) $fatal(1, "skip blank sector");
                    default: $fatal(1, "extra match");
                endcase
            end else if (found_sector != 32'hfffffff0) $fatal(1, "overflow match");
            match_count = match_count + 1;
        end
    end

    task check_scan;
        input integer expected_matches, expected_reads;
        begin
            @(negedge clk); #1; rst = 1; scan_start = 0;
            reads = 0; match_count = 0;
            repeat (4) @(negedge clk);
            #1; rst = 0;
            repeat (4) @(negedge clk);
            #1; scan_start = 1;
            @(negedge clk); #1; scan_start = 0;
            wait(done);
            repeat (3) @(negedge clk);
            if (!ready || match_count != expected_matches || found_total != expected_matches || reads != expected_reads)
                $fatal(1, "scenario=%0d matches=%0d count=%0d reads=%0d", scenario, match_count, found_total, reads);
        end
    endtask

    initial begin
        check_scan(3, 4);
        scenario = 1; target_count = 2; check_scan(2, 2);
        scenario = 2; target_count = 4;
        first_sector = 32'hfffffff0; last_sector = 32'hffffffff; check_scan(1, 1);
        scenario = 3; target_count = 0; check_scan(0, 0);
        scenario = 4; target_count = 4; first_sector = 23; last_sector = 22; check_scan(0, 0);
        $display("PASS scan_boundaries scenarios=5");
        $finish;
    end
    initial begin #1000000; $fatal(1, "scan timeout"); end
endmodule
