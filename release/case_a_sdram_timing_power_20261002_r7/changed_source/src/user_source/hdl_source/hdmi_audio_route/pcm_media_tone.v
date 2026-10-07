`timescale 1ns/1ps

// Day image-linked synthesis and night stereo PCM share the existing gain envelope.
// Only future FIFO entries change on controls; a stalled HDMI head stays stable.
module pcm_media_tone #(
    parameter integer CLOCK_HZ = 25000000,
    parameter integer SAMPLE_HZ = 48000,
    parameter integer NOTE_SAMPLES = 12000, // Day notes are 250 ms.
    parameter integer FADE_SAMPLES = 4800   // 所有音量档均约100ms
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [1:0]         music_profile, // [1] night; [0] reserved
    input  wire [1:0]         image_melody_id,
    input  wire               image_change_pulse,
    input  wire               music_enable,
    input  wire [7:0]         volume,
    input  wire               emergency_active,
    input  wire               night_pcm_valid,
    output wire               night_pcm_ready,
    input  wire signed [15:0] night_pcm_left,
    input  wire signed [15:0] night_pcm_right,
    output wire               night_drain,
    output wire               sample_valid,
    input  wire               sample_ready,
    output wire signed [15:0] sample_left,
    output wire signed [15:0] sample_right,
    output reg                overflow,
    output wire               blip_active
);
    reg [24:0] rate_accumulator;
    reg [19:0] music_phase, alarm_phase;
    reg [1:0] active_profile;
    reg [1:0] image_melody_q;
    reg [12:0] blip_countdown;
    reg cue_pending;
    reg [2:0] note_index;
    reg [14:0] note_sample_count, alarm_count;
    reg alarm_high, emergency_d;

    reg [7:0] music_gain, ramp_target, ramp_span;
    reg [12:0] ramp_count, ramp_error;
    reg ramp_active, ramp_up;

    reg [31:0] fifo [0:7];
    reg [2:0] write_pointer, read_pointer;
    reg [3:0] fifo_count;
    // Keep the 25 MHz control clock, but stop the audio datapath's sample
    // accumulator and synthesis updates while the output is fully idle.
    // A pending profile change, emergency tone, night drain, or queued FIFO
    // word keeps the path active so wake-up remains lossless.
    wire tone_active = music_enable || emergency_active || active_profile[1] ||
                       music_profile[1] || (fifo_count != 0);
    wire sample_pop = sample_valid && sample_ready;
    wire sample_tick = rate_accumulator >= CLOCK_HZ - SAMPLE_HZ;
    wire sample_tick_active = sample_tick && tone_active;
    wire sample_push = sample_tick_active && (fifo_count != 8 || sample_pop);
    assign sample_valid = fifo_count != 0;
    assign sample_left = fifo[read_pointer][15:0];
    assign sample_right = fifo[read_pointer][31:16];
    assign blip_active = blip_countdown != 0 && !active_profile[1] &&
                         !music_profile[1] && !emergency_active;
    // Keep the old stream running until its fade-out has reached zero.
    assign night_drain = active_profile[1];
    // Consume real time even under mute/alarm or an overfull HDMI output FIFO.
    assign night_pcm_ready = sample_tick_active && active_profile[1];

    // Image 1: C-major; image 2: A-minor; image 3: pentatonic;
    // image 4: low/high swing. The image ID is intentionally independent of SW2.
    function [19:0] melody_inc;
        input [1:0] melody;
        input [2:0] note;
        begin
            case ({melody, note})
                5'b00_000: melody_inc = 20'd11426;
                5'b00_001: melody_inc = 20'd14396;
                5'b00_010: melody_inc = 20'd17127;
                5'b00_011: melody_inc = 20'd22860;
                5'b00_100: melody_inc = 20'd17127;
                5'b00_101: melody_inc = 20'd14396;
                5'b01_000: melody_inc = 20'd9634;
                5'b01_001: melody_inc = 20'd11426;
                5'b01_010: melody_inc = 20'd14396;
                5'b01_011: melody_inc = 20'd19269;
                5'b01_100: melody_inc = 20'd14396;
                5'b01_101: melody_inc = 20'd11426;
                5'b10_000: melody_inc = 20'd11426;
                5'b10_001: melody_inc = 20'd12833;
                5'b10_010: melody_inc = 20'd14396;
                5'b10_011: melody_inc = 20'd17127;
                5'b10_100: melody_inc = 20'd19269;
                5'b10_101: melody_inc = 20'd22860;
                5'b11_000: melody_inc = 20'd11426;
                5'b11_001: melody_inc = 20'd8566;
                5'b11_010: melody_inc = 20'd14396;
                5'b11_011: melody_inc = 20'd11426;
                5'b11_100: melody_inc = 20'd8566;
                5'b11_101: melody_inc = 20'd14396;
                default: melody_inc = 20'd11426;
            endcase
        end
    endfunction

    function signed [15:0] sine_sample;
        input [3:0] index;
        begin
            case (index)
                4'd0: sine_sample = 16'sd0;
                4'd1: sine_sample = 16'sd4592;
                4'd2: sine_sample = 16'sd8485;
                4'd3: sine_sample = 16'sd11087;
                4'd4: sine_sample = 16'sd12000;
                4'd5: sine_sample = 16'sd11087;
                4'd6: sine_sample = 16'sd8485;
                4'd7: sine_sample = 16'sd4592;
                4'd8: sine_sample = 16'sd0;
                4'd9: sine_sample = -16'sd4592;
                4'd10: sine_sample = -16'sd8485;
                4'd11: sine_sample = -16'sd11087;
                4'd12: sine_sample = -16'sd12000;
                4'd13: sine_sample = -16'sd11087;
                4'd14: sine_sample = -16'sd8485;
                default: sine_sample = -16'sd4592;
            endcase
        end
    endfunction

    wire [1:0] requested_profile = music_profile[1] ? 2'b10 : 2'b00;
    wire profile_change = requested_profile != active_profile;
    wire night_starved = active_profile[1] && !night_pcm_valid;
    wire [7:0] wanted_gain = (emergency_active || profile_change || !music_enable || night_starved) ? 8'd0 : volume;
    wire [13:0] ramp_sum = {1'b0, ramp_error} + {6'd0, ramp_span};
    wire [19:0] day_note_inc = melody_inc(image_melody_q, note_index);
    wire [19:0] music_inc = day_note_inc;
    wire [19:0] selected_music_inc = (!active_profile[1] && blip_countdown != 0) ? 20'd32768 : music_inc;
    wire [14:0] note_last = NOTE_SAMPLES - 1;
    wire [19:0] alarm_inc = alarm_high ? 20'd34953 : 20'd17476; // 1600/800Hz
    wire [19:0] selected_phase = emergency_active ? alarm_phase : music_phase;
    // 应急解除的第一拍先归零，避免SW1关闭时漏出100ms背景音乐。
    wire [7:0] selected_gain = emergency_active ? 8'd128 : emergency_d ? 8'd0 : music_gain;
    wire signed [15:0] synth_sample = sine_sample(selected_phase[19:16]);
    wire signed [15:0] raw_left = emergency_active ? synth_sample :
        active_profile[1] ? (night_pcm_valid ? night_pcm_left : 16'sd0) : synth_sample;
    wire signed [15:0] raw_right = emergency_active ? synth_sample :
        active_profile[1] ? (night_pcm_valid ? night_pcm_right : 16'sd0) : synth_sample;
    wire signed [24:0] scaled_left = raw_left * $signed({1'b0, selected_gain});
    wire signed [24:0] scaled_right = raw_right * $signed({1'b0, selected_gain});
    // Full-scale signed PCM times gain<=255 stays in range after divide by256.
    wire signed [15:0] scaled_sample_left = scaled_left >>> 8;
    wire signed [15:0] scaled_sample_right = scaled_right >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rate_accumulator <= 0;
            music_phase <= 0; alarm_phase <= 0; active_profile <= 0;
            image_melody_q <= 0; blip_countdown <= 0; cue_pending <= 0;
            note_index <= 0; note_sample_count <= 0;
            alarm_count <= 0; alarm_high <= 0; emergency_d <= 0;
            music_gain <= 0; ramp_target <= 0; ramp_span <= 0;
            ramp_count <= 0; ramp_error <= 0; ramp_active <= 0; ramp_up <= 0;
            write_pointer <= 0; read_pointer <= 0; fifo_count <= 0; overflow <= 0;
        end else begin
            if (tone_active) begin
                if (sample_tick)
                    rate_accumulator <= rate_accumulator + SAMPLE_HZ - CLOCK_HZ;
                else
                    rate_accumulator <= rate_accumulator + SAMPLE_HZ;
            end

            // Preserve the one-cycle frame event until a future FIFO sample
            // can accept it. The live ID always names the latest display.
            if (music_profile[1] || active_profile[1] || emergency_active) begin
                cue_pending <= 0;
                blip_countdown <= 0;
            end else if (image_change_pulse) cue_pending <= 1;
            else if (sample_push && cue_pending) cue_pending <= 0;

            if (sample_push) begin
                // 只改变新入队样本；valid&&!ready时队头数据保持不动。
                fifo[write_pointer] <= {scaled_sample_right, scaled_sample_left};
                write_pointer <= write_pointer + 1'b1;
                emergency_d <= emergency_active;

                // 背景节奏在静音/告警期间仍走时。新曲只在零增益时接管。
                if (profile_change && music_gain == 0) begin
                    active_profile <= requested_profile;
                    music_phase <= 0; note_index <= 0; note_sample_count <= 0;
                    image_melody_q <= image_melody_id;
                    blip_countdown <= 0;
                end else if (!active_profile[1] && !music_profile[1] &&
                             !emergency_active && cue_pending) begin
                    image_melody_q <= image_melody_id;
                    music_phase <= 0; note_index <= 0; note_sample_count <= 0;
                    blip_countdown <= 13'd4800;
                end else if (!active_profile[1] && !music_profile[1] &&
                             !emergency_active && image_melody_q != image_melody_id) begin
                    // Initial display, or return from the emergency page:
                    // adopt the displayed melody without inventing a cue.
                    image_melody_q <= image_melody_id;
                    music_phase <= 0; note_index <= 0; note_sample_count <= 0;
                end else begin
                    music_phase <= music_phase + selected_music_inc;
                    if (blip_countdown != 0 && !active_profile[1] &&
                        !music_profile[1] && !emergency_active) begin
                        blip_countdown <= blip_countdown - 1'b1;
                        if (blip_countdown == 1) music_phase <= 0;
                    end else if (note_sample_count >= note_last) begin
                        note_sample_count <= 0;
                        note_index <= (note_index == 5) ? 3'd0 : note_index + 1'b1;
                    end else note_sample_count <= note_sample_count + 1'b1;
                end

                if (!emergency_active) begin
                    alarm_phase <= 0; alarm_count <= 0; alarm_high <= 0;
                end else begin
                    alarm_phase <= alarm_phase + alarm_inc;
                    if (alarm_count == 23999) begin
                        alarm_count <= 0; alarm_high <= !alarm_high;
                    end else alarm_count <= alarm_count + 1'b1;
                end

                // 误差累加把任意gain差值均匀分配到4800个样本，低档也渐变100ms。
                if ((emergency_d && !emergency_active) || night_starved) begin
                    music_gain <= 0; ramp_target <= 0; ramp_span <= 0;
                    ramp_active <= 0; ramp_count <= 0; ramp_error <= 0;
                end else if (wanted_gain != ramp_target) begin
                    ramp_target <= wanted_gain;
                    ramp_span <= (wanted_gain > music_gain) ? wanted_gain - music_gain : music_gain - wanted_gain;
                    ramp_up <= wanted_gain > music_gain;
                    ramp_active <= wanted_gain != music_gain;
                    ramp_count <= 0; ramp_error <= 0;
                end else if (ramp_active) begin
                    if (ramp_count == FADE_SAMPLES - 1) begin
                        music_gain <= ramp_target; ramp_active <= 0;
                        ramp_count <= 0; ramp_error <= 0;
                    end else begin
                        ramp_count <= ramp_count + 1'b1;
                        if (ramp_sum >= FADE_SAMPLES) begin
                            ramp_error <= ramp_sum - FADE_SAMPLES;
                            music_gain <= ramp_up ? music_gain + 1'b1 : music_gain - 1'b1;
                        end else ramp_error <= ramp_sum[12:0];
                    end
                end
            end else if (sample_tick) begin
                overflow <= 1;
            end

            if (sample_pop) read_pointer <= read_pointer + 1'b1;
            case ({sample_push, sample_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end
endmodule
