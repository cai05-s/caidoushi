`timescale 1ns/1ps

// MQ-2/MQ-135 digital comparator input.
// The common LM393 modules drive DO low when the threshold is exceeded.
// A long assertion is required before entering emergency and a longer clear
// interval is required before returning to normal playback.
module smoke_sensor_emergency #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer ACTIVE_LOW = 1,
    parameter integer TRIGGER_MS = 1500,
    parameter integer CLEAR_MS = 8000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire smoke_do,
    output reg  emergency_active,
    output reg  sensor_active
);
    localparam integer TRIGGER_CYCLES = (CLK_HZ / 1000) * TRIGGER_MS;
    localparam integer CLEAR_CYCLES   = (CLK_HZ / 1000) * CLEAR_MS;
    reg do_meta, do_sync;
    reg [31:0] trigger_count;
    reg [31:0] clear_count;
    wire active_now = ACTIVE_LOW ? !do_sync : do_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            do_meta          <= 1'b0;
            do_sync          <= 1'b0;
            trigger_count    <= 32'd0;
            clear_count      <= 32'd0;
            sensor_active    <= 1'b0;
            emergency_active <= 1'b0;
        end else begin
            do_meta <= smoke_do;
            do_sync <= do_meta;
            sensor_active <= active_now;

            if (active_now) begin
                clear_count <= 32'd0;
                if (trigger_count < TRIGGER_CYCLES)
                    trigger_count <= trigger_count + 1'b1;
                if (trigger_count >= TRIGGER_CYCLES - 1)
                    emergency_active <= 1'b1;
            end else begin
                trigger_count <= 32'd0;
                if (clear_count < CLEAR_CYCLES)
                    clear_count <= clear_count + 1'b1;
                if (clear_count >= CLEAR_CYCLES - 1)
                    emergency_active <= 1'b0;
            end
        end
    end
endmodule
