`timescale 1ns/1ps
module player_settings_flash #(
    parameter [17:0] DEFAULTS={3'd0,1'b1,2'd1,3'd2,3'd4,3'd1,3'd2}
)(
    input wire clk,rst_n,save_start,
    input wire [17:0] save_settings,
    output wire busy,
    output reg load_done,load_valid,
    output reg [17:0] loaded_settings,
    output reg save_done,save_ok,
    output reg [7:0] error_code,
    output wire [23:0] jedec_id,
    input wire flash_miso,
    output wire flash_cs_n,flash_sclk,flash_mosi,flash_wp_n,flash_hold_n
);
    localparam [3:0] PF_START=0,PF_WAIT=1,READ_START=2,READ_WAIT=3,
        CHECK_INIT=4,CHECK_BITS=5,CHECK_DONE=6,READY=7,
        SAVE_INIT=8,SAVE_BITS=9,SAVE_CRC=10,SAVE_START=11,SAVE_WAIT=12;
    reg [3:0] state;
    reg flash_available,boot_finished,boot_abort;
    reg [27:0] boot_count;
    reg [3:0] slot,active_slot,newest_slot;
    reg any_valid,invalid_nonblank;
    reg [31:0] newest_sequence,active_sequence,save_sequence;
    reg [17:0] newest_settings,save_settings_q;
    reg [255:0] write_record;
    reg read_failed;
    reg [15:0] crc;
    reg [7:0] crc_byte;
    reg [7:0] bits_left;
    reg pf_start,store_start,store_write;
    reg [23:0] store_address;
    wire pf_owner=state==PF_START || state==PF_WAIT;
    wire pf_done,pf_accepted,pf_error,store_done,store_error;
    wire [3:0] pf_code,store_code;
    wire [255:0] store_read_data;
    // The store holds read_data while idle; no new request occurs throughout
    // CHECK_INIT/CHECK_BITS/CHECK_DONE. Reuse that stable record in place.
    wire [255:0] record=store_read_data;
    wire pf_cs,pf_clk,pf_mosi,pf_wp,pf_hold,st_cs,st_clk,st_mosi,st_wp,st_hold;
    // Stage one byte while preserving all 224 MSB-first CRC cycles.
    // At the last bit of a byte, bits_left[7:3]+3 selects the next byte.
    wire [4:0] crc_next_byte_index = bits_left[7:3] + 5'd3;
    wire crc_input_bit = crc_byte[7];
    wire [15:0] crc_step={crc[14:0],1'b0} ^ ((crc[15]^crc_input_bit)?16'h1021:16'h0000);
    wire [31:0] record_sequence={record[135:128],record[143:136],record[151:144],record[159:152]};
    wire [17:0] record_settings={3'd0,record[160],record[169:168],record[178:176],
        record[186:184],record[194:192],record[202:200]};
    wire fields_good=record[255:224]==32'h48584346 && record[223:216]==1 &&
        record[215:208]==32 && record[207:200]<=4 && record[199:192]<=4 &&
        record[191:184]<=4 && record[183:176]<=4 && record[175:168]<=3 &&
        record[167:160]<=1 && record[127:32]==0 && record[15:0]==16'ha55a;
    // Failed reads previously supplied an all-zero record: always invalid,
    // never blank, with zero input bits for the complete CRC traversal.
    wire record_good=!read_failed && fields_good && {record[23:16],record[31:24]}==crc;
    wire record_blank=!read_failed && (&record);
    wire [31:0] sequence_delta=record_sequence-newest_sequence;
    wire record_newer=record_sequence!=newest_sequence && !sequence_delta[31];
    wire [23:0] slot_address=24'h7f0000+{slot,12'd0};
    assign busy=!boot_finished || state!=READY;
    assign flash_cs_n=pf_owner?pf_cs:st_cs;
    assign flash_sclk=pf_owner?pf_clk:st_clk;
    assign flash_mosi=pf_owner?pf_mosi:st_mosi;
    assign flash_wp_n=pf_owner?pf_wp:st_wp;
    assign flash_hold_n=pf_owner?pf_hold:st_hold;

    function [255:0] make_record;
        input [17:0] settings;
        input [31:0] sequence_value;
        begin
            make_record=0;
            make_record[255:224]=32'h48584346; // HXCF
            make_record[223:216]=8'd1;make_record[215:208]=8'd32;
            make_record[207:200]={5'd0,settings[2:0]};
            make_record[199:192]={5'd0,settings[5:3]};
            make_record[191:184]={5'd0,settings[8:6]};
            make_record[183:176]={5'd0,settings[11:9]};
            make_record[175:168]={6'd0,settings[13:12]};
            make_record[167:160]={7'd0,settings[14]};
            make_record[159:128]={sequence_value[7:0],sequence_value[15:8],sequence_value[23:16],sequence_value[31:24]};
            make_record[15:0]=16'ha55a;
        end
    endfunction

    w25q64_preflight_reader #(.SPI_CLK_DIV(5),.STARTUP_CYCLES(1000000)) u_identity(
        .clk(clk),.rst_n(rst_n && !boot_abort),.start(pf_start),.flash_miso(flash_miso),
        .flash_cs_n(pf_cs),.flash_sclk(pf_clk),.flash_mosi(pf_mosi),.flash_wp_n(pf_wp),.flash_hold_n(pf_hold),
        .busy(),.done(pf_done),.accepted(pf_accepted),.error(pf_error),.error_code(pf_code),
        .jedec_id(jedec_id),.status1(),.status2(),.status3());
    w25q64_record_store #(.RECORD_BYTES(32),.COMMIT_LAST(1),.CLK_DIV(5),
        .ALLOWED_BASE(24'h7f0000),.ALLOWED_LIMIT(24'h800000)) u_store(
        .clk(clk),.rst_n(rst_n && !pf_owner && !boot_abort),.start(store_start),
        .op_write(store_write),.address(store_address),.write_data(write_record),
        .busy(),.done(store_done),.error(store_error),.error_code(store_code),
        .read_data(store_read_data),.request_dropped(),
        .spi_cs_n(st_cs),.spi_sclk(st_clk),.spi_mosi(st_mosi),.spi_miso(flash_miso),
        .spi_wp_n(st_wp),.spi_hold_n(st_hold));

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=PF_START;flash_available<=0;boot_finished<=0;boot_abort<=0;boot_count<=0;
            slot<=0;active_slot<=0;newest_slot<=0;any_valid<=0;invalid_nonblank<=0;
            newest_sequence<=0;active_sequence<=0;save_sequence<=0;
            newest_settings<=DEFAULTS;save_settings_q<=DEFAULTS;
            read_failed<=0;write_record<=0;crc<=16'hffff;crc_byte<=0;bits_left<=0;
            pf_start<=0;store_start<=0;store_write<=0;store_address<=24'h7f0000;
            load_done<=0;load_valid<=0;loaded_settings<=DEFAULTS;
            save_done<=0;save_ok<=0;error_code<=0;
        end else begin
            pf_start<=0;store_start<=0;load_done<=0;save_done<=0;save_ok<=0;
            if(!boot_finished) boot_count<=boot_count+1'b1;
            case(state)
                PF_START:begin pf_start<=1;state<=PF_WAIT;end
                PF_WAIT:if(pf_done) begin
                    if(pf_accepted && !pf_error) begin flash_available<=1;slot<=0;any_valid<=0;invalid_nonblank<=0;state<=READ_START;end
                    else begin error_code<=8'h70;boot_finished<=1;load_done<=1;state<=READY;end
                end
                READ_START:begin
                    store_address<=slot_address;
                    store_write<=0;store_start<=1;state<=READ_WAIT;
                end
                READ_WAIT:if(store_done) begin
                    read_failed<=store_error;
                    if(store_error) error_code<=8'h71;
                    state<=CHECK_INIT;
                end
                CHECK_INIT:begin
                    crc<=16'hffff;bits_left<=224;state<=CHECK_BITS;
                    crc_byte<=read_failed?8'd0:record[255:248];
                end
                CHECK_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;
                    if(bits_left[2:0]==3'd1 && bits_left!=8'd1)
                        crc_byte<=read_failed?8'd0:record[{crc_next_byte_index,3'b000} +: 8];
                    else crc_byte<={crc_byte[6:0],1'b0};
                    if(bits_left==1) state<=CHECK_DONE;
                end
                CHECK_DONE:begin
                    if(record_good && (!any_valid || record_newer)) begin
                        newest_sequence<=record_sequence;
                        newest_settings<=record_settings;
                        newest_slot<=slot;
                        any_valid<=1;
                    end else if(!record_blank && !record_good) begin
                        invalid_nonblank<=1;
                    end
                    if(slot==4'd15) begin
                        boot_finished<=1;load_done<=1;state<=READY;
                        load_valid<=any_valid || record_good;
                        if(any_valid || record_good) begin
                            loaded_settings<=record_good && (!any_valid || record_newer) ? record_settings : newest_settings;
                            active_sequence<=record_good && (!any_valid || record_newer) ? record_sequence : newest_sequence;
                            active_slot<=record_good && (!any_valid || record_newer) ? slot : newest_slot;
                        end else begin
                            loaded_settings<=DEFAULTS;active_sequence<=0;active_slot<=0;
                            if(invalid_nonblank || (!record_blank && !record_good)) error_code<=8'h72;
                        end
                    end else begin
                        slot<=slot+1'b1;state<=READ_START;
                    end
                end
                READY:if(save_start) begin
                    if(!flash_available || boot_abort) begin save_done<=1;error_code<=8'h70;end
                    else begin
                        slot<=any_valid?((active_slot==4'd15)?4'd0:(active_slot+1'b1)):4'd0;
                        save_sequence<=active_sequence+1'b1;save_settings_q<=save_settings;
                        write_record<=make_record(save_settings,active_sequence+1'b1);state<=SAVE_INIT;
                    end
                end
                SAVE_INIT:begin
                    crc<=16'hffff;bits_left<=224;state<=SAVE_BITS;
                    crc_byte<=write_record[255:248];
                end
                SAVE_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;
                    if(bits_left[2:0]==3'd1 && bits_left!=8'd1)
                        crc_byte<=write_record[{crc_next_byte_index,3'b000} +: 8];
                    else crc_byte<={crc_byte[6:0],1'b0};
                    if(bits_left==1) state<=SAVE_CRC;
                end
                SAVE_CRC:begin write_record[31:16]<={crc[7:0],crc[15:8]};state<=SAVE_START;end
                SAVE_START:begin
                    store_address<=slot_address;
                    store_write<=1;store_start<=1;state<=SAVE_WAIT;
                end
                SAVE_WAIT:if(store_done) begin
                    save_done<=1;save_ok<=!store_error;state<=READY;
                    if(store_error) error_code<=store_code==7?8'h73:8'h74;
                    else begin active_slot<=slot;active_sequence<=save_sequence;any_valid<=1;error_code<=0;end
                end
                default:begin state<=READY;boot_finished<=1;load_done<=1;error_code<=8'h71;end
            endcase
            // Bound boot service failure without blocking video or controls.
            // This abort only applies to read-only startup, never to a save.
            if(!boot_finished && boot_count>=28'd249999999) begin
                boot_abort<=1;boot_finished<=1;flash_available<=0;state<=READY;
                loaded_settings<=DEFAULTS;load_valid<=0;load_done<=1;error_code<=8'h71;
            end
        end
    end
endmodule
