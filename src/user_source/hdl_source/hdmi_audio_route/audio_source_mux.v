`timescale 1ns/1ps

// Valid/ready router for interchangeable PCM sources.
module audio_source_mux (
    input  wire               wav_valid,
    output wire               wav_ready,
    input  wire signed [15:0] wav_left,
    input  wire signed [15:0] wav_right,
    input  wire               wav_active,
    input  wire               arp_valid,
    output wire               arp_ready,
    input  wire signed [15:0] arp_left,
    input  wire signed [15:0] arp_right,
    input  wire               force_arpeggio,
    output wire               out_valid,
    input  wire               out_ready,
    output wire signed [15:0] out_left,
    output wire signed [15:0] out_right
);
    wire use_wav = wav_active && !force_arpeggio;
    assign out_valid = use_wav ? wav_valid : arp_valid;
    assign out_left  = use_wav ? wav_left : arp_left;
    assign out_right = use_wav ? wav_right : arp_right;
    assign wav_ready = use_wav ? out_ready : 1'b0;
    assign arp_ready = use_wav ? 1'b0 : out_ready;
endmodule
