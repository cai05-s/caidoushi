`timescale 1ns/1ps
// Two read-only clients share one complete SD sector transaction.  BMP holds
// req until end; WAV holds req until accept.  Neither may steal an active read.
module sd_sector_arbiter (
    input wire clk, rst,
    input wire sd_init_done, sd_io_error,
    input wire bmp_req,
    input wire [31:0] bmp_addr,
    output wire [7:0] bmp_data,
    output wire bmp_valid, bmp_end,
    input wire audio_req,
    input wire [31:0] audio_addr,
    input wire audio_priority,
    output reg audio_accept,
    output wire [7:0] audio_data,
    output wire audio_valid, audio_end,
    output wire core_req,
    output reg [31:0] core_addr,
    input wire [7:0] core_data,
    input wire core_valid, core_end
);
    reg active, owner_audio;
    reg bmp_armed, audio_armed, last_audio;
    wire usable = sd_init_done && !sd_io_error;
    wire bmp_waiting = bmp_req && bmp_armed;
    wire audio_waiting = audio_req && audio_armed;
    wire choose_audio = audio_waiting &&
        (audio_priority || !bmp_waiting || !last_audio);

    // The controller has no request-ready signal.  It is idle after init or a
    // completed read.  Keep req/address until end, then leave a full low cycle
    // while its S_READ_END state returns to S_WAIT_READ_WRITE.
    assign core_req = active && usable;
    assign bmp_data = core_data;
    assign audio_data = core_data;
    assign bmp_valid = active && !owner_audio && usable && core_valid;
    assign audio_valid = active && owner_audio && usable && core_valid;
    assign bmp_end = active && !owner_audio && usable && core_end;
    assign audio_end = active && owner_audio && usable && core_end;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active <= 0; owner_audio <= 0; core_addr <= 0;
            bmp_armed <= 1; audio_armed <= 1; last_audio <= 0;
            audio_accept <= 0;
        end else begin
            audio_accept <= 0;
            if (!bmp_req) bmp_armed <= 1;
            if (!audio_req) audio_armed <= 1;
            if (!usable) begin
                // sd_card_top resets the complete SPI/command/sector chain on
                // error.  Quarantine its response and require a fresh request
                // after both clients have observed initialization loss.
                active <= 0;
                bmp_armed <= !bmp_req;
                audio_armed <= !audio_req;
            end else if (active) begin
                if (core_end) active <= 0;
            end else if (choose_audio) begin
                active <= 1; owner_audio <= 1; core_addr <= audio_addr;
                audio_armed <= 0; audio_accept <= 1; last_audio <= 1;
            end else if (bmp_waiting) begin
                active <= 1; owner_audio <= 0; core_addr <= bmp_addr;
                bmp_armed <= 0; last_audio <= 0;
            end
        end
    end
endmodule
