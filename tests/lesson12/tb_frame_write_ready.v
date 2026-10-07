`timescale 1ns/1ps

module tb_frame_write_ready;
    reg write_clk = 0, mem_clk = 0, read_clk = 0, rst = 1;
    integer mem_half_period = 25;
    always #5 write_clk = !write_clk;
    always begin #(mem_half_period) mem_clk = !mem_clk; end
    always #20 read_clk = !read_clk;
    reg write_req = 0, write_en = 0;
    reg [31:0] write_data = 0;
    reg [20:0] base_address = 0;
    wire write_ack, write_ready, write_finish;
    wire app_wr_en, app_rd_en;
    wire [20:0] app_wr_address, app_rd_address;
    wire [31:0] app_wr_data, read_data;
    wire [3:0] app_wr_dm;
    wire read_ack, read_finish;
    integer expected_count = 0, expected_base = 0, expected_pattern = 0;
    integer full_cycles = 0, sent, frames = 0;
    frame_read_write #(.WRITE_V_FLIP(0), .FRAME_WIDTH(32), .FRAME_HEIGHT(32)) dut (
        .rst(rst), .mem_clk(mem_clk), .Sdr_init_done(!rst), .Sdr_init_ref_vld(1'b0), .Sdr_busy(1'b0),
        .App_rd_en(app_rd_en), .App_rd_addr(app_rd_address), .Sdr_rd_en(1'b0), .Sdr_rd_dout(32'd0),
        .read_clk(read_clk), .read_req(1'b0), .read_req_ack(read_ack), .read_finish(read_finish),
        .read_addr_0(21'd0), .read_addr_1(21'd0), .read_addr_2(21'd0), .read_addr_3(21'd0),
        .read_addr_index(2'd0), .read_len(21'd1024), .read_en(1'b0), .read_data(read_data),
        .App_wr_en(app_wr_en), .App_wr_addr(app_wr_address), .App_wr_din(app_wr_data), .App_wr_dm(app_wr_dm),
        .write_clk(write_clk), .write_req(write_req), .write_req_ack(write_ack), .write_ready(write_ready),
        .write_finish(write_finish), .write_addr_0(base_address),
        .write_addr_1(21'd0), .write_addr_2(21'd0), .write_addr_3(21'd0),
        .write_addr_index(2'd0), .write_len(21'd1024), .write_en(write_en), .write_data(write_data)
    );

    always @(posedge write_clk) begin
        if (!rst && write_en && !write_ready) full_cycles = full_cycles + 1;
        if (dut.write_fifo_reset && write_ready) $fatal(1, "ready high during clear");
    end
    always @(posedge mem_clk) begin
        if (!rst && app_wr_en) begin
            if (app_wr_address !== expected_base + expected_count)
                $fatal(1, "address count=%0d got=%0d expected=%0d",
                    expected_count, app_wr_address, expected_base + expected_count);
            if (app_wr_data !== expected_pattern + expected_count)
                $fatal(1, "data count=%0d got=%h expected=%h",
                    expected_count, app_wr_data, expected_pattern + expected_count);
            expected_count = expected_count + 1;
        end
    end

    task send_frame;
        input integer frame_base, pattern;
        begin
            @(negedge write_clk);
            expected_count = 0; expected_base = frame_base; expected_pattern = pattern;
            base_address = frame_base;
            write_req = 1;
            wait (write_ack);
            repeat (3) @(negedge write_clk);
            write_req = 0;
            wait (!write_ack && write_ready);
            for (sent = 0; sent < 1024; sent = sent + 1) begin
                @(negedge write_clk);
                write_en = 1;
                write_data = pattern + sent;
                @(posedge write_clk);
                while (!write_ready) @(posedge write_clk);
            end
            @(negedge write_clk);
            write_en = 0;
            wait (write_finish);
            @(negedge mem_clk);
            if (expected_count != 1024) $fatal(1, "wrong final count=%0d", expected_count);
            frames = frames + 1;
            repeat (8) @(negedge write_clk);
        end
    endtask
    initial begin
        #200;
        @(negedge write_clk);
        rst = 0;
        send_frame(307200, 32'h12340000);
        if (full_cycles == 0) $fatal(1, "FIFO full backpressure never exercised");
        mem_half_period = 4;
        send_frame(0, 32'h56780000);
        $display("PASS actual_FIFO frames=%0d words=2048 stalled_write_cycles=%0d", frames, full_cycles);
        $finish;
    end
    initial begin #1000000; $fatal(1, "FIFO test timeout"); end
endmodule
