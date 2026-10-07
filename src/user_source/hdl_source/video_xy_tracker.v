module video_xy_tracker #(
    parameter integer H_ACTIVE = 640,
    parameter integer V_ACTIVE = 480
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        hs,
    input  wire        vs,
    input  wire        de,
    output reg [9:0]   pixel_x,
    output reg [9:0]   pixel_y,
    output reg         frame_start
);

reg hs_d;
reg vs_d;
reg de_d;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        hs_d        <= 1'b0;
        vs_d        <= 1'b0;
        de_d        <= 1'b0;
        pixel_x     <= 10'd0;
        pixel_y     <= 10'd0;
        frame_start <= 1'b0;
    end else begin
        hs_d        <= hs;
        vs_d        <= vs;
        de_d        <= de;
        frame_start <= vs & ~vs_d;

        if (vs & ~vs_d) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else if (de && !de_d) begin
            pixel_x <= 10'd0;
            if (pixel_y < V_ACTIVE - 1)
                pixel_y <= pixel_y + 1'b1;
        end else if (de) begin
            if (pixel_x < H_ACTIVE - 1)
                pixel_x <= pixel_x + 1'b1;
        end
    end
end

endmodule
