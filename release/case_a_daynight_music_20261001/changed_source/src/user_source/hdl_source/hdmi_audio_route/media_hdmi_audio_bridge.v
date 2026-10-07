`timescale 1ns/1ps

// Player-owned boundary between the registered video bundle and the verified
// Route B HDMI packet/symbol chain. The EG4 DDR PHY remains in the board Top so
// this bridge can be exercised in ordinary RTL simulation without vendor pads.
// 拨码选择背景曲目与音量，图片切换不重启音乐；应急声音独立优先。
module media_hdmi_audio_bridge (
    input  wire        pixel_clk,
    input  wire        pixel_rst_n,
    input  wire        video_hsync,
    input  wire        video_vsync,
    input  wire        video_de,
    input  wire [9:0]  video_x,
    input  wire [23:0] video_rgb,
    input  wire [1:0]  music_profile,
    input  wire        music_enable,
    input  wire [7:0]  volume,
    input  wire        force_test_tone,
    input wire emergency_active,
    output wire [9:0]  channel0_symbol,
    output wire [9:0]  channel1_symbol,
    output wire [9:0]  channel2_symbol,
    output wire        sequence_error,
    output wire        tone_overflow,
    output wire        pcm_contract_error,
    output wire        blip_active,
    output wire        pcm_tap_valid,
    output wire signed [15:0] pcm_tap_left
);
    wire wav_valid;
    wire wav_ready;
    wire signed [15:0] wav_left;
    wire signed [15:0] wav_right;
    wire arp_valid;
    wire arp_ready;
    wire signed [15:0] arp_left;
    wire signed [15:0] arp_right;
    wire source_valid;
    wire source_ready;
    wire signed [15:0] source_left;
    wire signed [15:0] source_right;
    wire sample_valid;
    wire sample_ready;
    wire signed [15:0] sample_left;
    wire signed [15:0] sample_right;

    reg video_hsync_q;
    reg video_vsync_q;
    reg video_de_q;
    reg [9:0] video_x_q;
    reg [23:0] video_rgb_q;
    always @(posedge pixel_clk or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            video_hsync_q <= 1'b1;
            video_vsync_q <= 1'b1;
            video_de_q <= 1'b0;
            video_x_q <= 10'd0;
            video_rgb_q <= 24'h000000;
        end else begin
            video_hsync_q <= video_hsync;
            video_vsync_q <= video_vsync;
            video_de_q <= video_de;
            video_x_q <= video_x;
            video_rgb_q <= video_de ? video_rgb : 24'h000000;
        end
    end

    pcm_test_tone #(.SAMPLE_DIV(521)) u_test_tone (
        .clk(pixel_clk), .rst_n(pixel_rst_n), .enable(force_test_tone),
        .sample_valid(wav_valid), .sample_ready(wav_ready),
        .sample_left(wav_left), .sample_right(wav_right),
        .rom_index(), .sample_accepted()
    );

    pcm_media_tone u_tone (
        .clk(pixel_clk), .rst_n(pixel_rst_n),
        .music_profile(music_profile), .music_enable(music_enable),
        .volume(volume), .emergency_active(emergency_active),
        .sample_valid(arp_valid), .sample_ready(arp_ready),
        .sample_left(arp_left), .sample_right(arp_right),
        .overflow(tone_overflow), .blip_active(blip_active)
    );

    audio_source_mux u_source_mux (
        .wav_valid(wav_valid), .wav_ready(wav_ready),
        .wav_left(wav_left), .wav_right(wav_right),
        .wav_active(force_test_tone),
        .arp_valid(arp_valid), .arp_ready(arp_ready),
        .arp_left(arp_left), .arp_right(arp_right),
        .force_arpeggio(emergency_active),
        .out_valid(source_valid), .out_ready(source_ready),
        .out_left(source_left), .out_right(source_right)
    );

    m06_pcm_contract_adapter u_m06_pcm_contract (
        .clk(pixel_clk), .rst_n(pixel_rst_n),
        .source_valid(source_valid), .source_ready(source_ready),
        .source_left(source_left), .source_right(source_right),
        .pcm_valid(sample_valid), .pcm_ready(sample_ready),
        .pcm_left(sample_left), .pcm_right(sample_right),
        .contract_error(pcm_contract_error)
    );

    hdmi_audio_symbol_core u_symbol_core (
        .pixel_clk(pixel_clk), .rst_n(pixel_rst_n),
        .video_hsync(video_hsync_q), .video_vsync(video_vsync_q),
        .video_de(video_de_q), .video_x(video_x_q), .video_rgb(video_rgb_q),
        .sample_valid(sample_valid), .sample_ready(sample_ready),
        .sample_left(sample_left), .sample_right(sample_right),
        .channel0_symbol(channel0_symbol),
        .channel1_symbol(channel1_symbol),
        .channel2_symbol(channel2_symbol),
        .sequence_error(sequence_error)
    );

    assign pcm_tap_valid = sample_valid && sample_ready;
    assign pcm_tap_left = sample_left;
endmodule
