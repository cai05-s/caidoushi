`timescale 1ns/1ps

// 按真实 BMP 尺寸等比例适配，输出自上而下的固定画布。
// bmp_data_wr_en 是 valid：保持数据到 bmp_data_ready，FIFO 取 valid && ready。
// 沿用连续物理扇区文件约定；本模块不解释 FAT 簇链。
module bmp_read #(
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer MAX_DIM = 4096
) (
    input wire clk, input wire rst, output wire ready,
    input wire scan_start,
    input wire [31:0] scan_start_sector, scan_max_sector,
    input wire [2:0] scan_target_count,
    output reg scan_done, scan_found_valid,
    output reg [31:0] scan_found_sector,
    output reg [2:0] scan_found_total,
    input wire load_start, load_abort,
    input wire [31:0] load_sector,
    input wire sd_init_done,
    output reg [3:0] state_code,
    // 保留原接口；输出画布由 FRAME_WIDTH/FRAME_HEIGHT 决定。
    input wire [15:0] bmp_width, bmp_height,
    output reg write_req,
    input wire write_req_ack, bmp_data_ready,
    output reg sd_sec_read,
    output reg [31:0] sd_sec_read_addr,
    input wire [7:0] sd_sec_read_data,
    input wire sd_sec_read_data_valid, sd_sec_read_end,
    output reg bmp_data_wr_en,
    output reg [23:0] bmp_data,
    output reg [15:0] image_width, image_height,
    output reg image_info_valid,
    output reg [7:0] image_error
);
    localparam [4:0] ST_IDLE = 0, ST_SECTOR = 1, ST_SCAN_CHECK = 2,
        ST_HEADER_CHECK = 3, ST_GEOMETRY = 4, ST_DIV_WAIT = 5,
        ST_STEP_X = 6, ST_STEP_Y = 7, ST_ACK_HIGH = 8, ST_ACK_LOW = 9,
        ST_ROW = 10, ST_ROW_OFFSET = 11, ST_FETCH = 12,
        ST_BYTE_WAIT = 13, ST_BYTE_DATA = 14, ST_PIXEL = 15,
        ST_PIXEL_DATA = 16, ST_SEND = 17, ST_DRAIN = 18, ST_ROW_ADD = 19, ST_SAMPLE = 20;
    localparam [7:0] ERR_NONE = 8'h00, ERR_SIGNATURE = 8'h31,
        ERR_DIMENSIONS = 8'h32, ERR_PLANES = 8'h33, ERR_BPP = 8'h34,
        ERR_COMPRESSION = 8'h35, ERR_OFFSET = 8'h36,
        ERR_LENGTH = 8'h37, ERR_IO = 8'h38, ERR_DIB = 8'h39;
    localparam integer LINE_ADDR_BITS = (FRAME_WIDTH > 1) ? $clog2(FRAME_WIDTH) : 1;

    reg [4:0] state, sector_return_state;
    reg [9:0] sector_count;
    reg capture_header, sector_cached;
    reg [31:0] cached_sector, scan_sector, file_first_sector;
    reg [7:0] signature_0, signature_1;
    reg [31:0] file_len, pixel_offset, dib_size, width_raw, height_raw, compression;
    reg [15:0] planes, bit_count;
    reg [31:0] height_abs, header_stride, header_pixel_bytes;
    reg [32:0] required_file_bytes;
    reg [32:0] dib_end;
    reg [32:0] file_sector_count, next_scan_match;
    wire sector_complete = (sector_count == 10'd512) ||
        (sector_count == 10'd511 && sd_sec_read_data_valid);
    reg [7:0] header_error;
    reg [7:0] header_error_q;

    reg top_down, width_limited;
    reg [15:0] row_stride;
    reg [31:0] row_byte_offset, fetch_pos;
    reg [15:0] fit_width, fit_height, x_offset, y_offset;
    reg [15:0] out_x, out_y, source_x, source_y, file_row;
    reg [15:0] x_step, y_step, x_remainder, y_remainder, x_error, y_error;
    wire [16:0] x_error_sum = {1'b0, x_error} + {1'b0, x_remainder};
    wire [16:0] y_error_sum = {1'b0, y_error} + {1'b0, y_remainder};
    reg [16:0] image_x_end, image_y_end;
    wire row_in_image = out_y >= y_offset && out_y < image_y_end;
    wire pixel_in_image = row_in_image && out_x >= x_offset && out_x < image_x_end;

    reg line_valid;
    reg [15:0] cached_row, capture_x;
    reg [LINE_ADDR_BITS-1:0] sample_x;
    wire [15:0] next_sample_source = source_x + x_step +
                                      ((x_error_sum >= {1'b0, fit_width}) ? 16'd1 : 16'd0);
    reg [1:0] channel;
    reg [7:0] blue_hold, green_hold;
    reg [8:0] sector_read_address;
    reg [7:0] sector_read_data;
    reg [23:0] line_read_data;
    // 同步读写，不清零存储阵列，允许 TD 推断为片上块 RAM。
    reg [7:0] sector_memory [0:511] /* fehdl force_ram=1, ram_style="bram" */;
    // Cache the fitted output samples, including repeated enlargement samples.
    reg [23:0] line_memory [0:FRAME_WIDTH-1] /* fehdl force_ram=1, ram_style="bram" */;

    reg [1:0] ack_sync;
    reg div_start;
    reg [1:0] div_operation;
    reg [31:0] div_numerator, div_denominator;
    wire div_done;
    wire [31:0] div_quotient, div_remainder;
    reg [31:0] aspect_w, aspect_h;
    wire [31:0] wanted_sector = file_first_sector + (fetch_pos >> 9);

    assign ready = state == ST_IDLE && sd_init_done && !load_abort;

    // 宽高等字段最迟在字节 33 完成，判头在 512 字节扇区结束之后。
    // 连续流水计算在判头前已稳定，拆开乘法、加法和范围比较的长路径。
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            height_abs <= 0; header_stride <= 0;
            header_pixel_bytes <= 0; required_file_bytes <= 0;
            file_sector_count <= 0; next_scan_match <= 0;
            dib_end <= 0; header_error_q <= ERR_NONE;
            image_x_end <= FRAME_WIDTH; image_y_end <= FRAME_HEIGHT;
            aspect_w <= 0; aspect_h <= 0;
        end else begin
            height_abs <= height_raw[31] ? (~height_raw + 32'd1) : height_raw;
            header_stride <= (({16'd0, width_raw[15:0]} << 1) +
                              {16'd0, width_raw[15:0]} + 32'd3) & 32'hfffffffc;
            header_pixel_bytes <= header_stride[15:0] * height_abs[15:0];
            required_file_bytes <= {1'b0, pixel_offset} + {1'b0, header_pixel_bytes};
            // 文件长度在头部第 5 字节完成；扇区收完前两级流水已稳定。
            // 拆开向上取整、地址累加与扫描边界比较，缩短 SD 侧组合路径。
            file_sector_count <= ({1'b0, file_len} + 33'd511) >> 9;
            next_scan_match <= {1'b0, scan_sector} + file_sector_count;
            // 头字段在前54字节完成，检查在512字节扇区结束后进行；
            // 几何参数在除法阶段稳定，像素阶段不再串联边界加法。
            dib_end <= {1'b0, dib_size} + 33'd14;
            header_error_q <= header_error;
            image_x_end <= {1'b0, x_offset} + {1'b0, fit_width};
            image_y_end <= {1'b0, y_offset} + {1'b0, fit_height};
            aspect_w <= width_raw[15:0] * FRAME_HEIGHT;
            aspect_h <= height_abs[15:0] * FRAME_WIDTH;
        end
    end

    // 先检查完整头字段，再使用受范围约束的 16 位尺寸参与运算。
    always @* begin
        header_error = ERR_NONE;
        if (signature_0 != 8'h42 || signature_1 != 8'h4d)
            header_error = ERR_SIGNATURE;
        else if (width_raw == 0 || width_raw > MAX_DIM || height_abs == 0 || height_abs > MAX_DIM)
            header_error = ERR_DIMENSIONS;
        else if (planes != 16'd1) header_error = ERR_PLANES;
        else if (bit_count != 16'd24) header_error = ERR_BPP;
        else if (compression != 0) header_error = ERR_COMPRESSION;
        else if (dib_size < 32'd40 || dib_end > {1'b0, pixel_offset}) header_error = ERR_DIB;
        else if (pixel_offset < 32'd54 || pixel_offset >= file_len) header_error = ERR_OFFSET;
        else if (required_file_bytes > {1'b0, file_len}) header_error = ERR_LENGTH;
    end

    always @* begin
        case (state)
            ST_IDLE: state_code = 4'd1;
            ST_SECTOR, ST_SCAN_CHECK, ST_HEADER_CHECK: state_code = 4'd2;
            ST_GEOMETRY, ST_DIV_WAIT, ST_STEP_X, ST_STEP_Y, ST_ACK_HIGH, ST_ACK_LOW: state_code = 4'd3;
            default: state_code = 4'd4;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) ack_sync <= 2'b00;
        else ack_sync <= {ack_sync[0], write_req_ack};
    end

    bmp_fit_divider u_fit_divider (
        .clk(clk), .rst(rst || load_abort || !sd_init_done), .start(div_start),
        .numerator(div_numerator), .denominator(div_denominator),
        .done(div_done), .quotient(div_quotient), .remainder(div_remainder)
    );

    always @(posedge clk) begin
        if (state == ST_SECTOR && sd_sec_read_data_valid && sector_count < 10'd512)
            sector_memory[sector_count[8:0]] <= sd_sec_read_data;
        if (state == ST_BYTE_WAIT)
            sector_read_data <= sector_memory[sector_read_address];
        if (state == ST_SAMPLE)
            line_memory[sample_x] <= {sector_read_data, green_hold, blue_hold};
        if (state == ST_PIXEL && pixel_in_image)
            line_read_data <= line_memory[source_x[LINE_ADDR_BITS-1:0]];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signature_0 <= 0; signature_1 <= 0; file_len <= 0; pixel_offset <= 0;
            dib_size <= 0; width_raw <= 0; height_raw <= 0;
            planes <= 0; bit_count <= 0; compression <= 0;
        end else if (state == ST_SECTOR && capture_header && sd_sec_read_data_valid) begin
            case (sector_count)
                0: signature_0 <= sd_sec_read_data;
                1: signature_1 <= sd_sec_read_data;
                2: file_len[7:0] <= sd_sec_read_data;
                3: file_len[15:8] <= sd_sec_read_data;
                4: file_len[23:16] <= sd_sec_read_data;
                5: file_len[31:24] <= sd_sec_read_data;
                10: pixel_offset[7:0] <= sd_sec_read_data;
                11: pixel_offset[15:8] <= sd_sec_read_data;
                12: pixel_offset[23:16] <= sd_sec_read_data;
                13: pixel_offset[31:24] <= sd_sec_read_data;
                14: dib_size[7:0] <= sd_sec_read_data;
                15: dib_size[15:8] <= sd_sec_read_data;
                16: dib_size[23:16] <= sd_sec_read_data;
                17: dib_size[31:24] <= sd_sec_read_data;
                18: width_raw[7:0] <= sd_sec_read_data;
                19: width_raw[15:8] <= sd_sec_read_data;
                20: width_raw[23:16] <= sd_sec_read_data;
                21: width_raw[31:24] <= sd_sec_read_data;
                22: height_raw[7:0] <= sd_sec_read_data;
                23: height_raw[15:8] <= sd_sec_read_data;
                24: height_raw[23:16] <= sd_sec_read_data;
                25: height_raw[31:24] <= sd_sec_read_data;
                26: planes[7:0] <= sd_sec_read_data;
                27: planes[15:8] <= sd_sec_read_data;
                28: bit_count[7:0] <= sd_sec_read_data;
                29: bit_count[15:8] <= sd_sec_read_data;
                30: compression[7:0] <= sd_sec_read_data;
                31: compression[15:8] <= sd_sec_read_data;
                32: compression[23:16] <= sd_sec_read_data;
                33: compression[31:24] <= sd_sec_read_data;
                default: ;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE; sector_return_state <= ST_IDLE; sector_count <= 0;
            capture_header <= 0; sector_cached <= 0; cached_sector <= 0;
            scan_sector <= 0; file_first_sector <= 0;
            scan_done <= 0; scan_found_valid <= 0; scan_found_sector <= 0; scan_found_total <= 0;
            sd_sec_read <= 0; sd_sec_read_addr <= 0; write_req <= 0;
            bmp_data_wr_en <= 0; bmp_data <= 0;
            image_width <= 0; image_height <= 0; image_info_valid <= 0; image_error <= ERR_NONE;
            top_down <= 0; width_limited <= 0; row_stride <= 0; row_byte_offset <= 0; fetch_pos <= 0;
            fit_width <= FRAME_WIDTH; fit_height <= FRAME_HEIGHT; x_offset <= 0; y_offset <= 0;
            out_x <= 0; out_y <= 0; source_x <= 0; source_y <= 0; file_row <= 0;
            x_step <= 0; y_step <= 0; x_remainder <= 0; y_remainder <= 0; x_error <= 0; y_error <= 0;
            line_valid <= 0; cached_row <= 0; capture_x <= 0; sample_x <= 0; channel <= 0;
            blue_hold <= 0; green_hold <= 0; sector_read_address <= 0;
            div_start <= 0; div_operation <= 0; div_numerator <= 0; div_denominator <= 1;
        end else begin
            scan_found_valid <= 0;
            div_start <= 0;
            if (!sd_init_done) begin
                state <= ST_IDLE; sd_sec_read <= 0; write_req <= 0; bmp_data_wr_en <= 0;
                scan_done <= 0; scan_found_total <= 0; image_info_valid <= 0;
                sector_cached <= 0; line_valid <= 0;
            end else if (load_abort) begin
                // 已发出的 SD 事务须收尾，避免残余字节污染下一张图的文件头。
                state <= ((state == ST_SECTOR || state == ST_DRAIN) && !sd_sec_read_end) ? ST_DRAIN : ST_IDLE;
                sd_sec_read <= 0; write_req <= 0; bmp_data_wr_en <= 0;
                image_info_valid <= 0; sector_cached <= 0; line_valid <= 0;
            end else case (state)
                ST_IDLE: begin
                    sd_sec_read <= 0; write_req <= 0; bmp_data_wr_en <= 0;
                    if (scan_start) begin
                        scan_found_total <= 0; scan_done <= 0;
                        if (scan_target_count == 0 || scan_start_sector > scan_max_sector)
                            scan_done <= 1;
                        else begin
                            scan_sector <= scan_start_sector; sd_sec_read_addr <= scan_start_sector;
                            sector_count <= 0; capture_header <= 1; sector_cached <= 0;
                            sector_return_state <= ST_SCAN_CHECK; sd_sec_read <= 1; state <= ST_SECTOR;
                        end
                    end else if (load_start) begin
                        file_first_sector <= load_sector; sd_sec_read_addr <= load_sector;
                        sector_count <= 0; capture_header <= 1; sector_cached <= 0; line_valid <= 0;
                        image_info_valid <= 0; image_error <= ERR_NONE;
                        sector_return_state <= ST_HEADER_CHECK; sd_sec_read <= 1; state <= ST_SECTOR;
                    end
                end
                ST_SECTOR: begin
                    if (sd_sec_read_data_valid && sector_count < 10'd512)
                        sector_count <= sector_count + 1'b1;
                    if (sd_sec_read_end) begin
                        sd_sec_read <= 0;
                        cached_sector <= sd_sec_read_addr; sector_cached <= sector_complete;
                        if (sector_complete) state <= sector_return_state;
                        else begin
                            state <= ST_IDLE; image_info_valid <= 0; image_error <= ERR_IO;
                            if (sector_return_state == ST_SCAN_CHECK) scan_done <= 1;
                        end
                    end
                end
                ST_SCAN_CHECK: begin
                    if (header_error_q == ERR_NONE) begin
                        scan_found_valid <= 1; scan_found_sector <= scan_sector;
                        scan_found_total <= scan_found_total + 1'b1;
                        if (scan_found_total + 1'b1 >= scan_target_count || next_scan_match > {1'b0, scan_max_sector}) begin
                            scan_done <= 1; state <= ST_IDLE;
                        end else begin
                            scan_sector <= next_scan_match[31:0]; sd_sec_read_addr <= next_scan_match[31:0];
                            sector_count <= 0; sd_sec_read <= 1; state <= ST_SECTOR;
                        end
                    end else if (scan_sector >= scan_max_sector) begin
                        scan_done <= 1; state <= ST_IDLE;
                    end else begin
                        scan_sector <= scan_sector + 1'b1; sd_sec_read_addr <= scan_sector + 1'b1;
                        sector_count <= 0; sd_sec_read <= 1; state <= ST_SECTOR;
                    end
                end
                ST_HEADER_CHECK: begin
                    capture_header <= 0;
                    image_error <= header_error_q;
                    if (header_error_q != ERR_NONE) state <= ST_IDLE;
                    else begin
                        image_width <= width_raw[15:0]; image_height <= height_abs[15:0];
                        image_info_valid <= 1; top_down <= height_raw[31]; row_stride <= header_stride[15:0];
                        state <= ST_GEOMETRY;
                    end
                end
                ST_GEOMETRY: begin
                    width_limited <= aspect_w >= aspect_h;
                    fit_width <= FRAME_WIDTH; fit_height <= FRAME_HEIGHT;
                    div_numerator <= (aspect_w >= aspect_h) ? aspect_h : aspect_w;
                    div_denominator <= (aspect_w >= aspect_h) ? {16'd0, image_width} : {16'd0, image_height};
                    div_operation <= 0; div_start <= 1; state <= ST_DIV_WAIT;
                end
                ST_DIV_WAIT: if (div_done) begin
                    case (div_operation)
                        0: begin
                            if (width_limited) fit_height <= (div_quotient == 0) ? 16'd1 : div_quotient[15:0];
                            else fit_width <= (div_quotient == 0) ? 16'd1 : div_quotient[15:0];
                            state <= ST_STEP_X;
                        end
                        1: begin
                            x_step <= div_quotient[15:0]; x_remainder <= div_remainder[15:0];
                            state <= ST_STEP_Y;
                        end
                        default: begin
                            y_step <= div_quotient[15:0]; y_remainder <= div_remainder[15:0];
                            x_offset <= (FRAME_WIDTH - fit_width) >> 1;
                            y_offset <= (FRAME_HEIGHT - fit_height) >> 1;
                            out_x <= 0; out_y <= 0; source_x <= 0; source_y <= 0; x_error <= 0; y_error <= 0;
                            write_req <= 1; state <= ST_ACK_HIGH;
                        end
                    endcase
                end
                ST_STEP_X: begin
                    div_numerator <= {16'd0, image_width}; div_denominator <= {16'd0, fit_width};
                    div_operation <= 1; div_start <= 1; state <= ST_DIV_WAIT;
                end
                ST_STEP_Y: begin
                    div_numerator <= {16'd0, image_height}; div_denominator <= {16'd0, fit_height};
                    div_operation <= 2; div_start <= 1; state <= ST_DIV_WAIT;
                end
                ST_ACK_HIGH: if (ack_sync[1]) begin write_req <= 0; state <= ST_ACK_LOW; end
                ST_ACK_LOW: if (!ack_sync[1] && bmp_data_ready) state <= ST_ROW;
                ST_ROW: begin
                    source_x <= 0; x_error <= 0;
                    if (!row_in_image || (line_valid && cached_row == source_y)) state <= ST_PIXEL;
                    else begin
                        file_row <= top_down ? source_y : (image_height - 16'd1 - source_y);
                        line_valid <= 0; state <= ST_ROW_OFFSET;
                    end
                end
                ST_ROW_OFFSET: begin
                    row_byte_offset <= file_row * row_stride;
                    state <= ST_ROW_ADD;
                end
                ST_ROW_ADD: begin
                    fetch_pos <= pixel_offset + row_byte_offset;
                    capture_x <= 0; sample_x <= 0; channel <= 0; state <= ST_FETCH;
                end
                ST_FETCH: begin
                    if (!sector_cached || cached_sector != wanted_sector) begin
                        sd_sec_read_addr <= wanted_sector; sector_count <= 0; capture_header <= 0;
                        sector_return_state <= ST_FETCH; sd_sec_read <= 1; state <= ST_SECTOR;
                    end else begin
                        sector_read_address <= fetch_pos[8:0]; state <= ST_BYTE_WAIT;
                    end
                end
                ST_BYTE_WAIT: state <= ST_BYTE_DATA;
                ST_BYTE_DATA: begin
                    fetch_pos <= fetch_pos + 1'b1;
                    state <= ST_FETCH;
                    case (channel)
                        0: begin blue_hold <= sector_read_data; channel <= 1; end
                        1: begin green_hold <= sector_read_data; channel <= 2; end
                        default: begin
                            channel <= 0;
                            if (capture_x == source_x) begin
                                state <= ST_SAMPLE;
                            end else if (capture_x == image_width - 1'b1) begin
                                line_valid <= 1; cached_row <= source_y; state <= ST_PIXEL;
                                source_x <= 0; x_error <= 0;
                            end else capture_x <= capture_x + 1'b1;
                        end
                    endcase
                end
                ST_SAMPLE: begin
                    // sector_read_data and the B/G holds stay unchanged here.
                    // Emit every output sample for this input pixel before fetching
                    // the next byte; this handles enlargement without dropping repeats.
                    sample_x <= sample_x + 1'b1;
                    source_x <= next_sample_source;
                    if (x_error_sum >= {1'b0, fit_width})
                        x_error <= x_error_sum - {1'b0, fit_width};
                    else x_error <= x_error_sum[15:0];
                    if (sample_x == fit_width - 1'b1 || x_step != 16'd0 || x_error_sum >= {1'b0, fit_width}) begin
                        if (capture_x == image_width - 1'b1) begin
                            line_valid <= 1; cached_row <= source_y; state <= ST_PIXEL;
                            source_x <= 0; x_error <= 0;
                        end else begin
                            capture_x <= capture_x + 1'b1; state <= ST_FETCH;
                        end
                    end
                end
                ST_PIXEL: begin
                    if (pixel_in_image) state <= ST_PIXEL_DATA;
                    else begin bmp_data <= 0; bmp_data_wr_en <= 1; state <= ST_SEND; end
                end
                ST_PIXEL_DATA: begin
                    bmp_data <= line_read_data; bmp_data_wr_en <= 1; state <= ST_SEND;
                end
                ST_SEND: if (bmp_data_ready) begin
                    bmp_data_wr_en <= 0;
                    // The line cache already contains floor-mapped output samples.
                    if (pixel_in_image) source_x <= source_x + 1'b1;
                    if (out_x == FRAME_WIDTH - 1) begin
                        out_x <= 0;
                        if (row_in_image) begin
                            if (y_error_sum >= {1'b0, fit_height}) begin
                                source_y <= source_y + y_step + 1'b1;
                                y_error <= y_error_sum - {1'b0, fit_height};
                            end else begin
                                source_y <= source_y + y_step; y_error <= y_error_sum[15:0];
                            end
                        end
                        if (out_y == FRAME_HEIGHT - 1) state <= ST_IDLE;
                        else begin out_y <= out_y + 1'b1; state <= ST_ROW; end
                    end else begin out_x <= out_x + 1'b1; state <= ST_PIXEL; end
                end
                ST_DRAIN: if (sd_sec_read_end) state <= ST_IDLE;
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule

// 单个 32 周期无符号除法器，仅在每张图开始时执行三次参数计算。
module bmp_fit_divider (
    input wire clk, input wire rst, input wire start,
    input wire [31:0] numerator, denominator,
    output reg done, output reg [31:0] quotient, remainder
);
    reg busy;
    reg [5:0] bit_index;
    reg [31:0] quotient_work;
    reg [15:0] divisor;
    reg [16:0] remainder_work;
    // 本模块的除数是源宽高或适配宽高，均在 16 位范围内。
    wire [16:0] shifted_remainder = {remainder_work[15:0], quotient_work[31]};
    wire take_bit = shifted_remainder >= {1'b0, divisor};
    wire [16:0] next_remainder = take_bit ? shifted_remainder - {1'b0, divisor} : shifted_remainder;
    wire [31:0] next_quotient = {quotient_work[30:0], take_bit};
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 0; done <= 0; bit_index <= 0; quotient_work <= 0;
            divisor <= 1; remainder_work <= 0; quotient <= 0; remainder <= 0;
        end else begin
            done <= 0;
            if (start && !busy) begin
                quotient_work <= numerator; divisor <= denominator[15:0];
                remainder_work <= 0; bit_index <= 0; busy <= 1;
            end else if (busy) begin
                quotient_work <= next_quotient; remainder_work <= next_remainder;
                if (bit_index == 6'd31) begin
                    quotient <= next_quotient; remainder <= {15'd0, next_remainder}; busy <= 0; done <= 1;
                end else bit_index <= bit_index + 1'b1;
            end
        end
    end
endmodule
