`timescale 1ns/1ps

// 背景音乐独立于图片：{夜间,A/B}选择旋律，静音仍发送连续PCM。
module pcm_media_tone #(
    parameter integer CLOCK_HZ = 25000000,
    parameter integer SAMPLE_HZ = 48000,
    parameter integer NOTE_SAMPLES = 12000, // 白天250ms，夜间500ms
    parameter integer FADE_SAMPLES = 4800   // 所有音量档均约100ms
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [1:0]         music_profile, // [1]夜间，[0]B曲
    input  wire               music_enable,
    input  wire [7:0]         volume,
    input  wire               emergency_active,
    output wire               sample_valid,
    input  wire               sample_ready,
    output wire signed [15:0] sample_left,
    output wire signed [15:0] sample_right,
    output reg                overflow,
    output wire               blip_active   // 兼容旧接口；切图提示音已取消
);
    reg [24:0] rate_accumulator;
    reg [19:0] music_phase, alarm_phase;
    reg [1:0] active_profile;
    reg [2:0] note_index;
    reg [14:0] note_sample_count, alarm_count;
    reg alarm_high, emergency_d;

    reg [7:0] music_gain, ramp_target, ramp_span;
    reg [12:0] ramp_count, ramp_error;
    reg ramp_active, ramp_up;

    reg signed [15:0] fifo [0:7];
    reg [2:0] write_pointer, read_pointer;
    reg [3:0] fifo_count;
    wire sample_pop = sample_valid && sample_ready;
    wire sample_tick = rate_accumulator >= CLOCK_HZ - SAMPLE_HZ;
    wire sample_push = sample_tick && (fifo_count != 8 || sample_pop);
    assign sample_valid = fifo_count != 0;
    assign sample_left = fifo[read_pointer];
    assign sample_right = fifo[read_pointer];
    assign blip_active = 1'b0;

    // A：C大调 C5 E5 G5 C6 G5 E5；B：五声音阶 C5 D5 E5 G5 A5 C6。
    function [19:0] melody_inc;
        input song_b;
        input [2:0] note;
        begin
            case ({song_b, note})
                4'b0_000: melody_inc = 20'd11426;
                4'b0_001: melody_inc = 20'd14396;
                4'b0_010: melody_inc = 20'd17127;
                4'b0_011: melody_inc = 20'd22860;
                4'b0_100: melody_inc = 20'd17127;
                4'b0_101: melody_inc = 20'd14396;
                4'b1_000: melody_inc = 20'd11426;
                4'b1_001: melody_inc = 20'd12833;
                4'b1_010: melody_inc = 20'd14396;
                4'b1_011: melody_inc = 20'd17127;
                4'b1_100: melody_inc = 20'd19269;
                4'b1_101: melody_inc = 20'd22860;
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

    wire profile_change = music_profile != active_profile;
    wire [7:0] wanted_gain = (emergency_active || profile_change || !music_enable) ? 8'd0 : volume;
    wire [13:0] ramp_sum = {1'b0, ramp_error} + {6'd0, ramp_span};
    wire [19:0] day_note_inc = melody_inc(active_profile[0], note_index);
    wire [19:0] music_inc = active_profile[1] ? (day_note_inc >> 1) : day_note_inc;
    wire [14:0] note_last = active_profile[1] ? (2 * NOTE_SAMPLES - 1) : (NOTE_SAMPLES - 1);
    wire [19:0] alarm_inc = alarm_high ? 20'd34953 : 20'd17476; // 1600/800Hz
    wire [19:0] selected_phase = emergency_active ? alarm_phase : music_phase;
    // 应急解除的第一拍先归零，避免SW1关闭时漏出100ms背景音乐。
    wire [7:0] selected_gain = emergency_active ? 8'd128 : emergency_d ? 8'd0 : music_gain;
    wire signed [15:0] raw_sample = sine_sample(selected_phase[19:16]);
    wire signed [24:0] scaled = raw_sample * $signed({1'b0, selected_gain});
    // 正弦峰值12000，gain<=255，因此移位后始终在16位范围内。
    wire signed [15:0] scaled_sample = scaled >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rate_accumulator <= 0;
            music_phase <= 0; alarm_phase <= 0; active_profile <= 0;
            note_index <= 0; note_sample_count <= 0;
            alarm_count <= 0; alarm_high <= 0; emergency_d <= 0;
            music_gain <= 0; ramp_target <= 0; ramp_span <= 0;
            ramp_count <= 0; ramp_error <= 0; ramp_active <= 0; ramp_up <= 0;
            write_pointer <= 0; read_pointer <= 0; fifo_count <= 0; overflow <= 0;
        end else begin
            if (sample_tick)
                rate_accumulator <= rate_accumulator + SAMPLE_HZ - CLOCK_HZ;
            else
                rate_accumulator <= rate_accumulator + SAMPLE_HZ;

            if (sample_push) begin
                // 只改变新入队样本；valid&&!ready时队头数据保持不动。
                fifo[write_pointer] <= scaled_sample;
                write_pointer <= write_pointer + 1'b1;
                emergency_d <= emergency_active;

                // 背景节奏在静音/告警期间仍走时。新曲只在零增益时接管。
                if (profile_change && music_gain == 0) begin
                    active_profile <= music_profile;
                    music_phase <= 0; note_index <= 0; note_sample_count <= 0;
                end else begin
                    music_phase <= music_phase + music_inc;
                    if (note_sample_count >= note_last) begin
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
                if (emergency_d && !emergency_active) begin
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
