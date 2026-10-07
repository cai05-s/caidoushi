`timescale 1ns/1ps

// Read-only SD WAV source plus a 4096-stereo-frame asynchronous FIFO.
// Pointer epochs use a four-phase clear/ack handshake. The SD writer stops
// before requesting clear and resumes only after the pixel reader has both
// acknowledged pointer zero and released that acknowledgement. A sector that
// was already accepted is drained by sd_fat32_wav before it restarts.
module night_pcm_stream (
    input wire sd_clk,
    input wire sd_rst_n,
    input wire pixel_clk,
    input wire pixel_rst_n,
    input wire night_active,
    input wire night_drain,
    input wire rescan,
    input wire sd_init_done,
    input wire sd_io_error,
    output wire sd_req,
    output wire [31:0] sd_addr,
    input wire sd_accept,
    input wire [7:0] sd_data,
    input wire sd_valid,
    input wire sd_end,
    output wire pcm_valid,
    output wire signed [15:0] pcm_left,
    output wire signed [15:0] pcm_right,
    input wire pcm_ready,
    output wire priority_sd,
    output wire [7:0] error_sd
);
    // Assertion of either reset clears both sides; no one-sided pointer reset.
    wire fifo_rst_n = sd_rst_n && pixel_rst_n;
    reg [1:0] sd_reset_pipe, pixel_reset_pipe;
    wire sd_local_rst_n = sd_reset_pipe[1];
    wire pixel_local_rst_n = pixel_reset_pipe[1];
    always @(posedge sd_clk or negedge fifo_rst_n) begin
        if (!fifo_rst_n) sd_reset_pipe<=0;
        else sd_reset_pipe<={sd_reset_pipe[0],1'b1};
    end
    always @(posedge pixel_clk or negedge fifo_rst_n) begin
        if (!fifo_rst_n) pixel_reset_pipe<=0;
        else pixel_reset_pipe<={pixel_reset_pipe[0],1'b1};
    end
    localparam [1:0] CLEAR_HIGH=2'd0, CLEAR_LOW=2'd1, RUN=2'd2;
    reg [1:0] clear_state;
    reg clear_request;
    reg clear_ack;
    reg ack_meta, ack_sync;
    reg clear_meta, clear_sync;
    reg night_meta, night_sync, night_d;
    reg drain_meta, drain_sync;
    reg desired_d, init_d, io_error_d, file_error_d;
    reg run_meta, run_sync;
    reg restart_pending, engine_restart;
    reg underrun_pixel, underrun_meta, underrun_sync;

    reg [12:0] write_binary, write_gray;
    reg [12:0] read_binary, read_gray;
    reg [12:0] read_gray_meta, read_gray_sync;
    reg [12:0] write_gray_meta, write_gray_sync;
    reg [31:0] frame_ram [0:4095] /* fehdl force_ram=1, ram_style="bram" */;
    reg [31:0] head_data;
    reg head_valid, playing;

    function [12:0] gray_to_binary;
        input [12:0] value;
        integer bit_index;
        begin
            gray_to_binary[12] = value[12];
            for (bit_index=11; bit_index>=0; bit_index=bit_index-1)
                gray_to_binary[bit_index] = gray_to_binary[bit_index+1] ^ value[bit_index];
        end
    endfunction

    wire engine_valid;
    wire [31:0] engine_data;
    wire engine_ready;
    wire [7:0] engine_error;
    wire desired_run = night_sync || drain_sync;
    wire file_error = engine_error != 0;
    wire new_song = night_sync && !night_d;
    wire clear_event = new_song || rescan ||
        (!desired_run && desired_d) || (!sd_init_done && init_d) ||
        (sd_io_error && !io_error_d) || (file_error && !file_error_d);
    wire engine_enable = clear_state == RUN && desired_run && sd_init_done &&
        !sd_io_error && !restart_pending && !engine_restart && !clear_event;
    wire writer_live = engine_enable && !file_error;
    wire fifo_full = write_gray == {~read_gray_sync[12:11],read_gray_sync[10:0]};
    wire fifo_write = writer_live && engine_valid && !fifo_full;
    wire [12:0] next_write = write_binary + 13'd1;
    wire [12:0] write_used = write_binary - gray_to_binary(read_gray_sync);
    assign engine_ready = writer_live && !fifo_full;
    assign priority_sd = writer_live && (write_used < 13'd2048 || underrun_sync);
    assign error_sd = file_error ? engine_error : underrun_sync ? 8'h44 : 8'h00;

    sd_fat32_wav u_wav (
        .clk(sd_clk), .rst(!sd_local_rst_n), .restart(engine_restart),
        .enable(engine_enable), .sd_init_done(sd_init_done), .sd_io_error(sd_io_error),
        .req(sd_req), .req_addr(sd_addr), .req_accept(sd_accept),
        .rd_data(sd_data), .rd_valid(sd_valid), .rd_end(sd_end),
        .pcm_valid(engine_valid), .pcm_data(engine_data), .pcm_ready(engine_ready),
        .file_ready(), .error_code(engine_error)
    );

    // Only Gray-coded pointers and single-bit control/status cross clocks.
    always @(posedge sd_clk or negedge sd_local_rst_n) begin
        if (!sd_local_rst_n) begin
            night_meta<=0; night_sync<=0; drain_meta<=0; drain_sync<=0;
            ack_meta<=0; ack_sync<=0;
            underrun_meta<=0; underrun_sync<=0;
        end else begin
            night_meta<=night_active; night_sync<=night_meta;
            drain_meta<=night_drain; drain_sync<=drain_meta;
            ack_meta<=clear_ack; ack_sync<=ack_meta;
            underrun_meta<=underrun_pixel; underrun_sync<=underrun_meta;
        end
    end

    always @(posedge sd_clk or negedge sd_local_rst_n) begin
        if (!sd_local_rst_n) begin
            clear_state<=CLEAR_HIGH; clear_request<=1;
            night_d<=0; desired_d<=0; init_d<=0; io_error_d<=0; file_error_d<=0;
            restart_pending<=1; engine_restart<=0;
            write_binary<=0; write_gray<=0;
            read_gray_meta<=0; read_gray_sync<=0;
        end else begin
            night_d<=night_sync; desired_d<=desired_run;
            init_d<=sd_init_done; io_error_d<=sd_io_error; file_error_d<=file_error;
            engine_restart<=0;
            // A retry requested during card initialization must survive until
            // restart can take effect; the engine gives I/O failure priority.
            if (restart_pending && sd_init_done && !sd_io_error) begin
                engine_restart<=1; restart_pending<=0;
            end
            if (new_song || rescan) restart_pending<=1;

            if (clear_event) begin
                clear_state<=CLEAR_HIGH; clear_request<=1;
                write_binary<=0; write_gray<=0;
                read_gray_meta<=0; read_gray_sync<=0;
            end else if (clear_state == CLEAR_HIGH) begin
                write_binary<=0; write_gray<=0;
                read_gray_meta<=0; read_gray_sync<=0;
                if (ack_sync) begin clear_request<=0; clear_state<=CLEAR_LOW; end
            end else if (clear_state == CLEAR_LOW) begin
                write_binary<=0; write_gray<=0;
                read_gray_meta<=0; read_gray_sync<=0;
                if (!ack_sync) clear_state<=RUN;
            end else begin
                read_gray_meta<=read_gray; read_gray_sync<=read_gray_meta;
                if (fifo_write) begin
                    write_binary<=next_write;
                    write_gray<=(next_write >> 1) ^ next_write;
                end
            end
        end
    end

    always @(posedge sd_clk) begin
        if (fifo_write) frame_ram[write_binary[11:0]]<=engine_data;
    end

    always @(posedge pixel_clk or negedge pixel_local_rst_n) begin
        if (!pixel_local_rst_n) begin
            clear_meta<=1; clear_sync<=1;
            run_meta<=0; run_sync<=0;
        end else begin
            clear_meta<=clear_request; clear_sync<=clear_meta;
            run_meta<=writer_live; run_sync<=run_meta;
        end
    end

    wire reader_live = run_sync && !clear_sync;
    wire [12:0] read_used = gray_to_binary(write_gray_sync) - read_binary;
    wire pcm_pop = pcm_valid && pcm_ready;
    wire [12:0] next_read = read_binary + 13'd1;
    wire read_enable = reader_live &&
        ((!head_valid && read_used != 0) || (pcm_pop && read_used > 13'd1));
    wire [11:0] read_address = pcm_pop ? next_read[11:0] : read_binary[11:0];
    assign pcm_valid = reader_live && playing && head_valid;
    assign pcm_left = head_data[15:0];
    assign pcm_right = head_data[31:16];

    // Unreset synchronous read port permits dual-clock block-RAM inference.
    // The read pointer remains on the prefetched head until it is accepted.
    always @(posedge pixel_clk) begin
        if (read_enable) head_data<=frame_ram[read_address];
    end

    always @(posedge pixel_clk or negedge pixel_local_rst_n) begin
        if (!pixel_local_rst_n) begin
            clear_ack<=0; write_gray_meta<=0; write_gray_sync<=0;
            read_binary<=0; read_gray<=0;
            head_valid<=0; playing<=0; underrun_pixel<=0;
        end else begin
            clear_ack<=clear_sync;
            if (!reader_live) begin
                write_gray_meta<=0; write_gray_sync<=0;
                read_binary<=0; read_gray<=0;
                head_valid<=0; playing<=0; underrun_pixel<=0;
            end else begin
                write_gray_meta<=write_gray; write_gray_sync<=write_gray_meta;
                if (read_enable) head_valid<=1;
                else if (pcm_pop) head_valid<=0;

                if (pcm_pop) begin
                    read_binary<=next_read;
                    read_gray<=(next_read >> 1) ^ next_read;
                    if (read_used == 13'd1) begin
                        playing<=0; underrun_pixel<=1;
                    end
                end else if (!playing && head_valid && read_used >= 13'd2048) begin
                    playing<=1; underrun_pixel<=0;
                end
            end
        end
    end
endmodule
