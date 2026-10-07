`timescale 1ns/1ps
module video_status_osd #(parameter DIAGNOSTICS=0)(
    input wire clk,input wire rst,input wire de,input wire enable,
    input wire [9:0] pixel_x,input wire [9:0] pixel_y,input wire [3:0] image_index,
    input wire auto_enable,input wire [2:0] bright_level,input wire [2:0] contrast_level,
    input wire view_mode,input wire [15:0] image_width,input wire [15:0] image_height,
    input wire image_info_valid,input wire [7:0] image_error,input wire [23:0] rgb_in,
    input wire [255:0] diagnostics,
    output reg [23:0] rgb_out
);
    function [4:0] font_row;
        input [3:0] v; input [2:0] r;
        begin
            case(v)
                4'h0: case(r) 0:font_row=5'b11111;1:font_row=5'b10001;2:font_row=5'b10001;3:font_row=5'b10001;4:font_row=5'b10001;5:font_row=5'b10001;default:font_row=5'b11111;endcase
                4'h1: case(r) 0:font_row=5'b00100;1:font_row=5'b01100;2:font_row=5'b00100;3:font_row=5'b00100;4:font_row=5'b00100;5:font_row=5'b00100;default:font_row=5'b11111;endcase
                4'h2: case(r) 0:font_row=5'b11111;1:font_row=5'b00001;2:font_row=5'b00001;3:font_row=5'b11111;4:font_row=5'b10000;5:font_row=5'b10000;default:font_row=5'b11111;endcase
                4'h3: case(r) 0:font_row=5'b11111;1:font_row=5'b00001;2:font_row=5'b00001;3:font_row=5'b11111;4:font_row=5'b00001;5:font_row=5'b00001;default:font_row=5'b11111;endcase
                4'h4: case(r) 0:font_row=5'b10001;1:font_row=5'b10001;2:font_row=5'b10001;3:font_row=5'b11111;4:font_row=5'b00001;5:font_row=5'b00001;default:font_row=5'b00001;endcase
                4'h5: case(r) 0:font_row=5'b11111;1:font_row=5'b10000;2:font_row=5'b11111;3:font_row=5'b00001;4:font_row=5'b00001;5:font_row=5'b11111;default:font_row=5'b11111;endcase
                4'h6: case(r) 0:font_row=5'b11111;1:font_row=5'b10000;2:font_row=5'b11111;3:font_row=5'b10001;4:font_row=5'b10001;5:font_row=5'b11111;default:font_row=5'b11111;endcase
                4'h7: case(r) 0:font_row=5'b11111;1:font_row=5'b00001;2:font_row=5'b00010;3:font_row=5'b00100;4:font_row=5'b01000;5:font_row=5'b01000;default:font_row=5'b01000;endcase
                4'h8: case(r) 0:font_row=5'b11111;1:font_row=5'b10001;2:font_row=5'b10001;3:font_row=5'b11111;4:font_row=5'b10001;5:font_row=5'b10001;default:font_row=5'b11111;endcase
                4'h9: case(r) 0:font_row=5'b11111;1:font_row=5'b10001;2:font_row=5'b10001;3:font_row=5'b11111;4:font_row=5'b00001;5:font_row=5'b00001;default:font_row=5'b11111;endcase
                4'ha: case(r) 0:font_row=5'b01110;1:font_row=5'b10001;2:font_row=5'b10001;3:font_row=5'b11111;4:font_row=5'b10001;5:font_row=5'b10001;default:font_row=5'b10001;endcase
                4'hb: case(r) 0:font_row=5'b11110;1:font_row=5'b10001;2:font_row=5'b11110;3:font_row=5'b10001;4:font_row=5'b10001;5:font_row=5'b11110;default:font_row=5'b11110;endcase
                4'hc: case(r) 0:font_row=5'b01111;1:font_row=5'b10000;2:font_row=5'b10000;3:font_row=5'b10000;4:font_row=5'b10000;5:font_row=5'b01111;default:font_row=5'b01111;endcase
                4'hd: case(r) 0:font_row=5'b00000;1:font_row=5'b00100;2:font_row=5'b00100;3:font_row=5'b00000;4:font_row=5'b00100;5:font_row=5'b00100;default:font_row=5'b00000;endcase
                4'he: case(r) 0:font_row=5'b11111;1:font_row=5'b10000;2:font_row=5'b11110;3:font_row=5'b10000;4:font_row=5'b10000;5:font_row=5'b11111;default:font_row=5'b11111;endcase
                4'hf: case(r) 0:font_row=5'b11111;1:font_row=5'b00100;2:font_row=5'b00100;3:font_row=5'b00100;4:font_row=5'b00100;5:font_row=5'b00100;default:font_row=5'b00100;endcase
                default: font_row=5'b00000;
            endcase
        end
    endfunction
    function [4:0] hex_row;
        input [3:0] v; input [2:0] r;
        begin
            if(v==4'hd) begin
                case(r) 0,6:hex_row=5'b11110; default:hex_row=5'b10001; endcase
            end else if(v==4'hf) begin
                case(r) 0:hex_row=5'b11111;3:hex_row=5'b11110;default:hex_row=5'b10000;endcase
            end else hex_row=font_row(v,r);
        end
    endfunction
    reg [63:0] diag_line;
    reg diag_background;
    // 尺寸改变时用 16 拍 double-dabble 转十进制，像素通路不再做除法。
    reg [15:0] width_seen, height_seen, width_bcd, height_bcd;
    reg [31:0] width_shift, height_shift;
    reg [31:0] width_adjusted, height_adjusted;
    reg [4:0] digit_cycles;
    integer digit_index;
    always @* begin
        width_adjusted = width_shift;
        height_adjusted = height_shift;
        for (digit_index = 16; digit_index < 32; digit_index = digit_index + 4) begin
            if (width_shift[digit_index +: 4] >= 5)
                width_adjusted[digit_index +: 4] = width_shift[digit_index +: 4] + 4'd3;
            if (height_shift[digit_index +: 4] >= 5)
                height_adjusted[digit_index +: 4] = height_shift[digit_index +: 4] + 4'd3;
        end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            width_seen <= 0; height_seen <= 0; width_bcd <= 0; height_bcd <= 0;
            width_shift <= 0; height_shift <= 0; digit_cycles <= 0;
        end else if (digit_cycles != 0) begin
            width_shift <= width_adjusted << 1;
            height_shift <= height_adjusted << 1;
            digit_cycles <= digit_cycles - 1'b1;
            if (digit_cycles == 1) begin
                width_bcd <= width_adjusted[30:15];
                height_bcd <= height_adjusted[30:15];
            end
        end else if (image_info_valid && (image_width != width_seen || image_height != height_seen)) begin
            width_seen <= image_width; height_seen <= image_height;
            width_shift <= {16'd0, image_width}; height_shift <= {16'd0, image_height};
            digit_cycles <= 16;
        end
    end
    reg [3:0] char_value; reg [2:0] char_row; reg [4:0] glyph_row; reg hit; reg [6:0] osd_col;
    always @* begin
        diag_line=0; diag_background=0;
        char_value=0; char_row=pixel_y[2:0]; osd_col=pixel_x[6:0]-7'd8; glyph_row=0; hit=0;
        // Show image, autoplay and brightness only; fixed contrast/view fields are hidden.
        if (enable && pixel_y>=10'd8 && pixel_y<10'd16 && pixel_x>=10'd8 && pixel_x<10'd40) begin
            case(osd_col[6:3])
                0:char_value=image_index;1:char_value=auto_enable?4'ha:4'he;2:char_value=4'hb;3:char_value={1'b0,bright_level};
                default:char_value=0;
            endcase
            glyph_row=font_row(char_value,char_row); if(osd_col[2:0]<5 && char_row<7) hit=glyph_row[4-osd_col[2:0]];
        end
        if (enable && image_info_valid && pixel_y>=10'd18 && pixel_y<10'd26 && pixel_x>=10'd8 && pixel_x<10'd80) begin
            case(osd_col[6:3])
                0:char_value=width_bcd[15:12];1:char_value=width_bcd[11:8];2:char_value=width_bcd[7:4];3:char_value=width_bcd[3:0];
                4:char_value=4'hd;
                5:char_value=height_bcd[15:12];6:char_value=height_bcd[11:8];7:char_value=height_bcd[7:4];default:char_value=height_bcd[3:0];
            endcase
            char_row=pixel_y[2:0]-3'd2; glyph_row=font_row(char_value,char_row); if(osd_col[2:0]<5 && char_row<7) hit=glyph_row[4-osd_col[2:0]];
        end
        // Error reporting was previously an unused input. Keep production
        // fault visibility separate from the optional diagnostic register dump.
        if (image_error!=0 && pixel_y>=8 && pixel_y<16 && pixel_x>=48 && pixel_x<72) begin
            case((pixel_x-48)>>3)
                0:char_value=4'he;1:char_value=image_error[7:4];default:char_value=image_error[3:0];
            endcase
            glyph_row=hex_row(char_value,pixel_y[2:0]);
            if(pixel_x[2:0]<5 && pixel_y[2:0]<7) hit=glyph_row[4-pixel_x[2:0]];
        end
        if (DIAGNOSTICS && pixel_x>=8 && pixel_x<136 && pixel_y>=384 && pixel_y<416) begin
            diag_background=1; char_row=pixel_y[2:0];
            case(pixel_y[4:3])
                0:diag_line=diagnostics[127:64];1:diag_line=diagnostics[63:0];
                2:diag_line=diagnostics[255:192];default:diag_line=diagnostics[191:128];
            endcase
            char_value=diag_line[63-4*osd_col[6:3] -:4];
            glyph_row=hex_row(char_value,char_row); hit=0;
            if(osd_col[2:0]<5 && char_row<7) hit=glyph_row[4-osd_col[2:0]];
        end
        if (!de) rgb_out=0; else if(hit) rgb_out=24'hffff00; else rgb_out=diag_background?24'h101020:rgb_in;
    end
endmodule
