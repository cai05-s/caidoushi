`timescale 1ns/1ps


// promax_audio_waveform.v —— 第11课：音频波形与峰值条可视化模块
module promax_audio_waveform #(
    parameter integer WAVE_X       = 64,
    parameter integer WAVE_Y       = 400,
    parameter integer WAVE_WIDTH   = 512,
    parameter integer WAVE_HEIGHT  = 64,
    parameter integer DECIMATE     = 12,
    parameter integer SAMPLE_COUNT = 32
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire        vsync,
    input  wire        de,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [23:0] rgb_in,
    input  wire        pcm_tap_valid,
    input  wire [15:0] pcm_tap_left,
    output wire [23:0] rgb_out,
    output wire        waveform_active
);
    localparam integer CENTER_Y       = WAVE_Y + (WAVE_HEIGHT / 2);
    localparam integer SAMPLE_SPACING = WAVE_WIDTH / SAMPLE_COUNT; // 512 / 32 = 16

    // 显示只使用高8位有符号值除以4的结果；提前保留向零取整的6位商。
    wire signed [5:0] capture_quarter = pcm_tap_left[15:10] +
        ((pcm_tap_left[15] && (|pcm_tap_left[9:8])) ? 6'd1 : 6'd0);
    (* ram_style = "dram" *) reg [5:0] sample_bank0 [0:SAMPLE_COUNT-1];
    (* ram_style = "dram" *) reg [5:0] sample_bank1 [0:SAMPLE_COUNT-1];
    reg       write_bank;
    reg       display_bank;
    reg       display_valid;
    reg [5:0] capture_count;
    reg [7:0] decimate_count;
    reg [7:0] peak_bank0;
    reg [7:0] peak_bank1;
    reg [7:0] display_peak;

    reg [9:0] line_y;
    reg       de_q;
    reg       vs_q;

    wire [7:0] sample_abs = pcm_tap_left[15] ?
                            (~pcm_tap_left[15:8] + 1'b1) : pcm_tap_left[15:8];

    wire frame_start = vs_q && !vsync;

    // Unreset distributed RAM keeps the asynchronous display read unchanged.
    // display_valid masks RAM until a complete bank has been captured; the
    // write bank is always opposite the displayed bank, including after swap.
    always @(posedge clk) begin
        if (rst_n && !frame_start && pcm_tap_valid &&
            capture_count < SAMPLE_COUNT && decimate_count == 8'd0) begin
            if (write_bank)
                sample_bank1[capture_count] <= capture_quarter;
            else
                sample_bank0[capture_count] <= capture_quarter;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_y         <= 10'd0;
            de_q           <= 1'b0;
            vs_q           <= 1'b1;
            write_bank     <= 1'b0;
            display_bank   <= 1'b1;
            display_valid  <= 1'b0;
            capture_count  <= 6'd0;
            decimate_count <= 8'd0;
            peak_bank0     <= 8'd0;
            peak_bank1     <= 8'd0;
            display_peak   <= 8'd0;
        end else begin
            de_q   <= de;
            vs_q   <= vsync;
            line_y <= pixel_y;

            if (frame_start) begin
                if (capture_count == SAMPLE_COUNT) begin
                    display_bank  <= write_bank;
                    display_valid <= 1'b1;
                    display_peak  <= write_bank ? peak_bank1 : peak_bank0;
                    write_bank    <= ~write_bank;
                end
                capture_count  <= 6'd0;
                decimate_count <= 8'd0;
                if (write_bank) peak_bank0 <= 8'd0;
                else            peak_bank1 <= 8'd0;
            end else if (pcm_tap_valid && capture_count < SAMPLE_COUNT) begin
                if (decimate_count == 8'd0) begin
                    capture_count  <= capture_count + 1'b1;
                    decimate_count <= DECIMATE - 1;
                    if (write_bank) begin
                        if (sample_abs > peak_bank1) peak_bank1 <= sample_abs;
                    end else begin
                        if (sample_abs > peak_bank0) peak_bank0 <= sample_abs;
                    end
                end else begin
                    decimate_count <= decimate_count - 1'b1;
                end
            end
        end
    end

    // 显示侧逻辑
    integer sample_index;
    reg signed [5:0] selected_sample;
    integer sample_value;
    integer sample_y;
    reg [7:0] peak_height;
    reg wave_pixel;
    reg axis_pixel;
    reg peak_pixel;

    always @* begin
        sample_index    = 0;
        selected_sample = 6'sd0;
        sample_value    = 0;
        sample_y        = CENTER_Y;
        peak_height     = display_peak >> 2;
        wave_pixel      = 1'b0;
        axis_pixel      = 1'b0;
        peak_pixel      = 1'b0;

        if (enable && de && pixel_x >= WAVE_X &&
            pixel_x < (WAVE_X + WAVE_WIDTH) &&
            pixel_y >= WAVE_Y && pixel_y < (WAVE_Y + WAVE_HEIGHT)) begin
            axis_pixel = (pixel_y == CENTER_Y);
            sample_index = (pixel_x - WAVE_X) / SAMPLE_SPACING;
            if (display_valid && sample_index >= 0 && sample_index < SAMPLE_COUNT) begin
                selected_sample = display_bank ?
                                  sample_bank1[sample_index] : sample_bank0[sample_index];
                sample_value = (selected_sample);
                sample_y = CENTER_Y - sample_value;
                wave_pixel = (pixel_y >= sample_y - 1 && pixel_y <= sample_y + 1);
            end
        end

        // 峰值条判断：波形右侧 8~16 像素处
        if (enable && de && pixel_x >= (WAVE_X + WAVE_WIDTH + 8) &&
            pixel_x < (WAVE_X + WAVE_WIDTH + 16) &&
            pixel_y >= (WAVE_Y + WAVE_HEIGHT - peak_height) &&
            pixel_y < (WAVE_Y + WAVE_HEIGHT)) begin
            peak_pixel = 1'b1;
        end
    end

    assign waveform_active = wave_pixel || axis_pixel || peak_pixel;
    assign rgb_out = wave_pixel ? 24'h20ff90 :
                     peak_pixel ? 24'hffb020 :
                     axis_pixel ? 24'h406060 : rgb_in;

endmodule
