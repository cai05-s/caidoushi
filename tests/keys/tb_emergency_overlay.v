`timescale 1ns/1ps
module tb_emergency_overlay;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, frame_start = 0, emergency_active = 0, de = 1;
    reg [9:0] x = 0, y = 0;
    wire [23:0] rgb;
    integer ix, iy;
    emergency_osd_overlay dut (.clk(clk), .rst(rst), .frame_start(frame_start),
        .emergency_active(emergency_active), .in_de(de), .pixel_x(x), .pixel_y(y),
        .rgb_in(24'h123456), .rgb_out(rgb));
    task ticks;
        input integer count;
        repeat(count) begin @(posedge clk); #1; end
    endtask
    initial begin
        ticks(3); rst = 0; ticks(3);
        x = 320; y = 240; emergency_active = 1; ticks(4);
        frame_start = 1; ticks(1); frame_start = 0;
        // 顶部字幕以外，检查完整 640x428 区域，确保只有四像素边框覆盖原图。
        for (iy = 52; iy < 480; iy = iy + 1) begin
            for (ix = 0; ix < 640; ix = ix + 1) begin
                x = ix; y = iy; #1;
                if (ix < 4 || ix >= 636 || iy >= 476) begin
                    if (rgb != 24'hff3030) $fatal(1, "missing border at %0d,%0d", ix, iy);
                end else if (rgb != 24'h123456)
                    $fatal(1, "poster obscured at %0d,%0d", ix, iy);
            end
        end
        x = 0; y = 240; emergency_active = 0; ticks(4);
        if (rgb != 24'hff3030) $fatal(1, "emergency cleared mid-frame");
        frame_start = 1; ticks(1); frame_start = 0;
        if (rgb != 24'h123456) $fatal(1, "border remains after exit frame");
        emergency_active = 1; ticks(4);
        if (rgb != 24'h123456) $fatal(1, "emergency changed mid-frame");
        $display("PASS full-raster border geometry and frame-synchronous entry/exit");
        $finish;
    end
endmodule
