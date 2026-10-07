`timescale 1ns/1ps
module player_settings_osd(
    input wire de,
    input wire [9:0] x,y,
    input wire [63:0] settings,
    input wire [23:0] rgb_in,
    output reg [23:0] rgb_out
);
    function [4:0] glyph;
        input [7:0] c;input [2:0] row;
        reg [34:0] bitmap;
        begin
            case(c)
                8'd48:bitmap=35'b01110_10001_10011_10101_11001_10001_01110;
                8'd49:bitmap=35'b00100_01100_00100_00100_00100_00100_01110;
                8'd50:bitmap=35'b01110_10001_00001_00010_00100_01000_11111;
                8'd51:bitmap=35'b11110_00001_00001_01110_00001_00001_11110;
                8'd52:bitmap=35'b00010_00110_01010_10010_11111_00010_00010;
                8'd53:bitmap=35'b11111_10000_10000_11110_00001_00001_11110;
                8'd54:bitmap=35'b01110_10000_10000_11110_10001_10001_01110;
                8'd55:bitmap=35'b11111_00001_00010_00100_01000_01000_01000;
                8'd56:bitmap=35'b01110_10001_10001_01110_10001_10001_01110;
                8'd57:bitmap=35'b01110_10001_10001_01111_00001_00001_01110;
                8'd65:bitmap=35'b01110_10001_10001_11111_10001_10001_10001;
                8'd66:bitmap=35'b11110_10001_10001_11110_10001_10001_11110;
                8'd67:bitmap=35'b01111_10000_10000_10000_10000_10000_01111;
                8'd68:bitmap=35'b11110_10001_10001_10001_10001_10001_11110;
                8'd69:bitmap=35'b11111_10000_10000_11110_10000_10000_11111;
                8'd70:bitmap=35'b11111_10000_10000_11110_10000_10000_10000;
                8'd71:bitmap=35'b01110_10001_10000_10111_10001_10001_01110;
                8'd72:bitmap=35'b10001_10001_10001_11111_10001_10001_10001;
                8'd73:bitmap=35'b01110_00100_00100_00100_00100_00100_01110;
                8'd75:bitmap=35'b10001_10010_10100_11000_10100_10010_10001;
                8'd76:bitmap=35'b10000_10000_10000_10000_10000_10000_11111;
                8'd77:bitmap=35'b10001_11011_10101_10101_10001_10001_10001;
                8'd78:bitmap=35'b10001_11001_10101_10011_10001_10001_10001;
                8'd79:bitmap=35'b01110_10001_10001_10001_10001_10001_01110;
                8'd80:bitmap=35'b11110_10001_10001_11110_10000_10000_10000;
                8'd82:bitmap=35'b11110_10001_10001_11110_10100_10010_10001;
                8'd83:bitmap=35'b01111_10000_10000_01110_00001_00001_11110;
                8'd84:bitmap=35'b11111_00100_00100_00100_00100_00100_00100;
                8'd85:bitmap=35'b10001_10001_10001_10001_10001_10001_01110;
                8'd86:bitmap=35'b10001_10001_10001_10001_10001_01010_00100;
                8'd87:bitmap=35'b10001_10001_10001_10101_10101_11011_10001;
                8'd88:bitmap=35'b10001_10001_01010_00100_01010_10001_10001;
                8'd89:bitmap=35'b10001_10001_01010_00100_00100_00100_00100;
                8'd62:bitmap=35'b10000_01000_00100_00010_00100_01000_10000;
                8'd37:bitmap=35'b11001_11010_00100_01000_10110_00110_00000;
                default:bitmap=0;
            endcase
            glyph=bitmap[34-row*5 -:5];
        end
    endfunction
    function [7:0] hexchar;
        input [3:0] n;
        begin hexchar=n<10?8'd48+{4'd0,n}:8'd55+{4'd0,n};end
    endfunction
    wire menu=settings[20] && settings[21];
    wire [2:0] volume=settings[19]?settings[2:0]:settings[5:3];
    wire [2:0] brightness=settings[19]?settings[8:6]:settings[11:9];
    wire [1:0] period=settings[13:12];
    wire status_visible=settings[21] && (settings[25:24]!=0 || settings[26]);
    reg [127:0] text_line;
    reg [7:0] character;
    reg [4:0] pixels;
    reg [9:0] local_x,local_y;
    reg [3:0] row_index;
    reg panel,hit;
    always @* begin
        text_line="                ";character=32;pixels=0;local_x=0;local_y=0;row_index=0;panel=0;hit=0;
        if(menu && x>=32 && x<160 && y>=112 && y<272) begin
            panel=1;local_x=x-10'd32;local_y=y-10'd112;row_index=local_y[7:4];
            case(row_index)
                0:text_line=settings[19]?"SET DAY         ":"SET NIGHT       ";
                1:begin text_line=" VOL  0         ";text_line[79:72]=hexchar({1'b0,volume});end
                2:begin
                    case(brightness)
                        0:text_line=" BRI  20%       ";1:text_line=" BRI  40%       ";
                        2:text_line=" BRI  60%       ";3:text_line=" BRI  80%       ";
                        default:text_line=" BRI  100%      ";
                    endcase
                end
                3:case(period)
                    0:text_line=" TIME 2S        ";1:text_line=" TIME 3S        ";
                    2:text_line=" TIME 5S        ";3:text_line=" TIME 10S       ";
                endcase
                4:text_line=settings[14]?" AUTO ON        ":" AUTO OFF       ";
                5:text_line="KEY1 NEXT       ";6:text_line="KEY4 CHANGE     ";7:text_line="KEY3 SAVE       ";
                8:text_line="READY           ";
                9:begin text_line="ID              ";text_line[103:56]={hexchar(settings[63:60]),hexchar(settings[59:56]),hexchar(settings[55:52]),hexchar(settings[51:48]),hexchar(settings[47:44]),hexchar(settings[43:40])};end
                default:;
            endcase
            if(row_index>=1 && row_index<=4 && row_index=={2'b0,settings[23:22]}+4'd1)
                text_line[127:120]=8'd62;
        end else if(!menu && status_visible && x>=8 && x<136 && y>=432 && y<440) begin
            panel=1;local_x=x-10'd8;local_y=y-10'd432;row_index=8;
        end
        if(panel && row_index==8) begin
            case(settings[25:24])
                1:text_line="PENDING         ";2:text_line="SAVING          ";
                3:begin text_line="ERROR           ";text_line[79:64]={hexchar(settings[39:36]),hexchar(settings[35:32])};end
                default:text_line=settings[26]?"SAVED           ":"READY           ";
            endcase
        end
        if(panel) begin
            character=text_line[127-local_x[6:3]*8 -:8];pixels=glyph(character,local_y[2:0]);
            if(local_x[2:0]<5 && local_y[2:0]<7 && (!menu || !local_y[3])) hit=pixels[4-local_x[2:0]];
        end
        if(!de) rgb_out=0;
        else if(hit) rgb_out=24'hffffff;
        else rgb_out=panel?24'h102038:rgb_in;
    end
endmodule
