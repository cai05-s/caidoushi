`timescale 1ns/1ps
module player_settings_control #(
    parameter integer CLK_HZ=50000000,
    parameter [17:0] DEFAULTS={3'd0,1'b1,2'd1,3'd2,3'd4,3'd1,3'd2}
)(
    input wire clk,rst_n,
    input wire [3:0] keys_n,
    input wire sw1,sw2,sw3,
    input wire emergency_active,
    input wire load_done,load_valid,
    input wire [17:0] loaded_settings,
    input wire flash_busy,save_done,save_ok,
    input wire [7:0] flash_error,
    input wire [23:0] jedec_id,
    output reg save_start,
    output reg [17:0] save_settings,
    output wire [63:0] control_packet
);
    localparam [26:0] SAVE_DELAY=CLK_HZ*2-1;
    localparam [21:0] SWITCH_DELAY=CLK_HZ/20-1;
    wire [3:0] press;
    genvar k;
    generate for(k=0;k<4;k=k+1) begin: keys
        key_press_debounce #(.CLK_FREQ_HZ(CLK_HZ),.DEBOUNCE_MS(50)) u_key(
            .clk(clk),.rst(!rst_n),.button_in(keys_n[k]),
            .press_pulse(press[k]),.button_stable_out());
    end endgenerate
    reg [2:0] sw_sync1,sw_sync2,sw_candidate,sw_stable;
    reg [21:0] switch_count;
    reg switches_ready,loaded;
    reg [1:0] emergency_sync;
    reg emergency_pending,emergency_target;
    wire emergency_guard=emergency_pending?emergency_target:emergency_sync[1];
    wire ready=loaded && switches_ready;
    // In normal playback, SW2 directly controls the menu visibility.  The
    // menu remains visible while SW2 is enabled; emergency mode still hides it.
    wire menu=sw_stable[1] && !emergency_guard;
    reg [17:0] live_settings,last_settings,saved_settings;
    reg saved_valid,touched,save_pending,retry_blocked;
    reg [26:0] stable_count,toast_count;
    reg [1:0] menu_item;
    reg next_toggle,rescan_toggle,emergency_toggle;
    wire dirty=touched && (!saved_valid || live_settings!=saved_settings);
    wire [1:0] storage_state=(flash_error!=0 || retry_blocked)?2'd3:
        (flash_busy && loaded)?2'd2:dirty?2'd1:2'd0;
    // Shared64-bit packet: settings17:0, switches18..20, ready21,
    // menu item23:22, store state25:24, saved toast26, command toggles27..29,
    // reserved31:30, error39:32, JEDEC63:40. Commands go to SD without frame delay.
    assign control_packet={jedec_id,flash_error,2'd0,emergency_toggle,rescan_toggle,
        next_toggle,(toast_count!=0 && !dirty),storage_state,menu_item,ready,
        menu,sw_stable[2],sw_stable[0],live_settings};
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sw_sync1<=0;sw_sync2<=0;sw_candidate<=0;sw_stable<=0;switch_count<=0;
            switches_ready<=0;emergency_sync<=0;emergency_pending<=0;emergency_target<=0;
            loaded<=0;live_settings<=DEFAULTS;last_settings<=DEFAULTS;saved_settings<=DEFAULTS;
            saved_valid<=0;touched<=0;save_pending<=0;retry_blocked<=0;
            stable_count<=0;toast_count<=0;menu_item<=0;
            next_toggle<=0;rescan_toggle<=0;emergency_toggle<=0;
            save_start<=0;save_settings<=DEFAULTS;
        end else begin
            save_start<=0;
            sw_sync1<={sw3,sw2,sw1};sw_sync2<=sw_sync1;
            emergency_sync<={emergency_sync[0],emergency_active};
            if(sw_sync2!=sw_candidate) begin sw_candidate<=sw_sync2;switch_count<=0;end
            else if(switch_count<SWITCH_DELAY) switch_count<=switch_count+1'b1;
            else begin sw_stable<=sw_candidate;switches_ready<=1;end
            if(emergency_pending && emergency_sync[1]==emergency_target) emergency_pending<=0;
            if(toast_count!=0) toast_count<=toast_count-1'b1;
            if(live_settings!=last_settings) begin
                last_settings<=live_settings;stable_count<=0;retry_blocked<=0;
            end else if(stable_count<SAVE_DELAY) stable_count<=stable_count+1'b1;

            if(load_done && !loaded) begin
                loaded<=1;live_settings<=loaded_settings;saved_settings<=loaded_settings;
                saved_valid<=load_valid;last_settings<=loaded_settings;stable_count<=0;
            end
            if(press[1]) begin
                emergency_toggle<=~emergency_toggle;
                emergency_target<=!emergency_guard;emergency_pending<=1;
            end else if(ready && !emergency_guard) begin
                if(press[0]) begin
                    if(menu) menu_item<=menu_item+1'b1;
                    else begin live_settings[14]<=!live_settings[14];touched<=1;end
                end else if(press[3]) begin
                    if(!menu) next_toggle<=~next_toggle;
                    else begin
                        touched<=1;
                        case(menu_item)
                            0:if(sw_stable[2]) live_settings[2:0]<=live_settings[2:0]==4?3'd0:live_settings[2:0]+1'b1;
                              else live_settings[5:3]<=live_settings[5:3]==4?3'd0:live_settings[5:3]+1'b1;
                            1:if(sw_stable[2]) live_settings[8:6]<=live_settings[8:6]==4?3'd0:live_settings[8:6]+1'b1;
                              else live_settings[11:9]<=live_settings[11:9]==4?3'd0:live_settings[11:9]+1'b1;
                            2:live_settings[13:12]<=live_settings[13:12]+1'b1;
                            3:live_settings[14]<=!live_settings[14];
                        endcase
                    end
                end else if(press[2]) begin
                    if(menu) begin save_pending<=1;retry_blocked<=0;end
                    else rescan_toggle<=~rescan_toggle;
                end
            end
            if(save_done) begin
                if(save_ok) begin
                    saved_settings<=save_settings;saved_valid<=1;retry_blocked<=0;
                    if(live_settings==save_settings) toast_count<=SAVE_DELAY;
                end else begin retry_blocked<=1;toast_count<=0;end
            end
            if(ready && !flash_busy && !save_done && !save_start &&
                (save_pending || (dirty && stable_count==SAVE_DELAY && !retry_blocked))) begin
                save_pending<=0;
                if(!saved_valid || live_settings!=saved_settings) begin
                    save_settings<=live_settings;save_start<=1;toast_count<=0;
                end else toast_count<=SAVE_DELAY;
            end
        end
    end
endmodule
