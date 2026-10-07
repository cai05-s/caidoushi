`timescale 1ns/1ps
module frame_read_write
#
(
	parameter MEM_DATA_BITS          = 32,
	parameter READ_DATA_BITS         = 32,
	parameter WRITE_DATA_BITS        = 32,
	parameter ADDR_BITS              = 21,
	parameter BURST_BITS             = 9,//
	parameter BURST_SIZE             = 256,
	parameter WRITE_V_FLIP           = 1,      // 1: vertical flip when writing TF/BMP frame into SDRAM
	parameter FRAME_WIDTH            = 640,
	parameter FRAME_HEIGHT           = 480
) 
(
	input                            rst,                  
	input                            mem_clk,                    // external memory controller user interface clock
	input							 Sdr_init_done,
	input							 Sdr_init_ref_vld,
    input							 Sdr_busy,
	
    /*
    output                           rd_burst_req,               // to external memory controller,send out a burst read request
	output[BURST_BITS - 1:0]         rd_burst_len,               // to external memory controller,data length of the burst read request, not bytes
	output[ADDR_BITS - 1:0]          rd_burst_addr,              // to external memory controller,base address of the burst read request 
	input                            rd_burst_data_valid,        // from external memory controller,read data valid 
	input[MEM_DATA_BITS - 1:0]       rd_burst_data,              // from external memory controller,read request data
	input                            rd_burst_finish,            // from external memory controller,burst read finish
	*/
	output							 App_rd_en,
	output[ADDR_BITS - 1:0]			 App_rd_addr,
	input							 Sdr_rd_en,					 //read_data_valid
	input[MEM_DATA_BITS - 1:0]		 Sdr_rd_dout,
	
	input                            read_clk,                   // data read module clock
	input                            read_req,                   // data read module read request,keep '1' until read_req_ack = '1'
	output                           read_req_ack,               // data read module read request response
	output                           read_finish,                // data read module read request finish
	input[ADDR_BITS - 1:0]           read_addr_0,                // data read module read request base address 0, used when read_addr_index = 0
	input[ADDR_BITS - 1:0]           read_addr_1,                // data read module read request base address 1, used when read_addr_index = 1
	input[ADDR_BITS - 1:0]           read_addr_2,                // data read module read request base address 1, used when read_addr_index = 2
	input[ADDR_BITS - 1:0]           read_addr_3,                // data read module read request base address 1, used when read_addr_index = 3
	input[ADDR_BITS - 1:0]           read_addr_4, // 第五个常驻帧基址

	input[2:0]                       read_addr_index,            // select valid base address from read_addr_0 read_addr_1 read_addr_2 read_addr_3
	input[ADDR_BITS - 1:0]           read_len,                   // data read module read request data length
	input                            read_en,                    // data read module read request for one data, read_data valid next clock
	output[READ_DATA_BITS  - 1:0]    read_data,                  // read data
	/*
	output                           wr_burst_req,               // to external memory controller,send out a burst write request
	output[BURST_BITS - 1:0]         wr_burst_len,               // to external memory controller,data length of the burst write request, not bytes
	output[ADDR_BITS - 1:0]          wr_burst_addr,              // to external memory controller,base address of the burst write request 
	input                            wr_burst_data_req,          // from external memory controller,write data request ,before data 1 clock
	output[MEM_DATA_BITS - 1:0]      wr_burst_data,              // to external memory controller,write data
	input                            wr_burst_finish,            // from external memory controller,burst write finish
	*/
	output							 App_wr_en,
	output[ADDR_BITS - 1:0]			 App_wr_addr,
	output[MEM_DATA_BITS - 1:0]	 App_wr_din,
	output[3:0]						 App_wr_dm,
	
	//
	input                            write_clk,                  // data write module clock
	input                            write_req,                  // data write module write request,keep '1' until read_req_ack = '1'
	output                           write_req_ack,              // data write module write request response
	output                           write_ready,                // write_clk 域：FIFO 可接收一个像素
	output                           write_finish,               // data write module write request finish
	input[ADDR_BITS - 1:0]           write_addr_0,               // data write module write request base address 0, used when write_addr_index = 0
	input[ADDR_BITS - 1:0]           write_addr_1,               // data write module write request base address 1, used when write_addr_index = 1
	input[ADDR_BITS - 1:0]           write_addr_2,               // data write module write request base address 1, used when write_addr_index = 2
	input[ADDR_BITS - 1:0]           write_addr_3,               // data write module write request base address 1, used when write_addr_index = 3
	input[ADDR_BITS - 1:0]           write_addr_4, // 第五个常驻帧基址

	input[2:0]                       write_addr_index,           // select valid base address from write_addr_0 write_addr_1 write_addr_2 write_addr_3
	input[ADDR_BITS - 1:0]           write_len,                  // data write module write request data length
	input                            write_en,                   // data write module write request for one data
	input[WRITE_DATA_BITS - 1:0]     write_data,                // write data
	input                            frame_start,
    input                            display_enable,
    input                            pixel_rst,
    input                            write_abort,
    output                           write_idle_sd,
    output [2:0]                     reader_bank_sd,
    output                           reader_bank_valid_sd,
    output [7:0]                     reader_error,
    output [255:0]                   reader_diagnostics,
    output                           read_underflow,
	output                           read_fifo_empty,
	output[8:0]                      read_fifo_level

);
// Full five-bank bridge. Commands, returned words and bank ownership are
// accounted in mem_clk; pixel and SD clients use held-payload handshakes.
localparam [10:0] RD_BURST = 11'd128;
localparam [ADDR_BITS:0] FRAME_WORDS = FRAME_WIDTH * FRAME_HEIGHT;
localparam [10:0] FIFO_LIMIT = 11'd503; // native FIFO usable depth511, reserve8
localparam [10:0] MAX_INFLIGHT = 11'd256;
localparam [4:0] TURN_GAP = 5'd12;
localparam [16:0] RETURN_TIMEOUT = 17'd125000; // 1ms at125MHz
localparam [2:0] R_OFF=0, R_DRAIN=1, R_RESET=2, R_RELEASE=3, R_RUN=4, R_FAULT=5;
localparam [2:0] W_IDLE=0, W_ACK=1, W_ACTIVE=2, W_DRAIN=3, W_ABORT=4, W_REJECT=5;
localparam [1:0] BUS_IDLE=0, BUS_READ=1, BUS_WRITE=2, BUS_GAP=3;
wire common_rst = rst | pixel_rst;
localparam [15:0] LAST_COLUMN=FRAME_WIDTH-1;
localparam [ADDR_BITS-1:0] FLIP_JUMP=FRAME_WIDTH*2-1;
localparam [ADDR_BITS-1:0] FLIP_OFFSET=(FRAME_HEIGHT-1)*FRAME_WIDTH;
wire mem_local_reset_n, pix_local_reset_n, sd_local_reset_n;
wire mem_local_rst=!mem_local_reset_n;
wire pix_local_rst=!pix_local_reset_n;
wire sd_local_rst=!sd_local_reset_n;
reset_sync u_cache_mem_reset(.clk(mem_clk),.ext_rst_n(!common_rst),.rst_n_sync(mem_local_reset_n));
reset_sync u_cache_pix_reset(.clk(read_clk),.ext_rst_n(!common_rst),.rst_n_sync(pix_local_reset_n));
reset_sync u_cache_sd_reset(.clk(write_clk),.ext_rst_n(!common_rst),.rst_n_sync(sd_local_reset_n));

function [ADDR_BITS-1:0] read_base;
    input [2:0] bank;
    begin
        case(bank)
            0:read_base=read_addr_0; 1:read_base=read_addr_1;
            2:read_base=read_addr_2; 3:read_base=read_addr_3;
            4:read_base=read_addr_4; default:read_base=0;
        endcase
    end
endfunction
function [ADDR_BITS-1:0] write_base;
    input [2:0] bank;
    begin
        case(bank)
            0:write_base=write_addr_0; 1:write_base=write_addr_1;
            2:write_base=write_addr_2; 3:write_base=write_addr_3;
            4:write_base=write_addr_4; default:write_base=0;
        endcase
    end
endfunction

// Pixel mailbox: change payload only when the last request was acknowledged.
reg request_toggle_pix, capture_pending_pix;
reg [2:0] request_bank_pix;
reg [ADDR_BITS-1:0] request_len_pix;
reg request_ack_mem;
reg [2:0] ack_sync_pix;
reg ack_seen_pix, frame_window_pix, frame_expected_pix, frame_armed_pix;
reg frame_bad_pix;
reg [ADDR_BITS:0] consumed_pix;
reg underflow_toggle_pix;
reg pixel_fault_short;
reg [ADDR_BITS:0] fault_consumed_pix;
reg [9:0] fifo_min_pix, fault_min_pix;
reg [READ_DATA_BITS-1:0] pixel_response;
reg underflow_sticky_pix;
wire prefetch_valid, prefetch_empty;
wire [31:0] prefetch_data;
wire [8:0] raw_read_level;
wire pixel_pop = read_en && frame_armed_pix && !frame_bad_pix && prefetch_valid;
wire pixel_missing = read_en && frame_expected_pix && !frame_bad_pix &&
                     (!frame_armed_pix || !prefetch_valid);
wire request_free_pix = request_toggle_pix == ack_sync_pix[2];
wire ack_event_pix = ack_sync_pix[2] != ack_seen_pix;
assign read_data = pixel_response;
assign read_req_ack = request_free_pix; // legacy output, frame_start is authority
assign read_underflow = underflow_sticky_pix;
assign read_fifo_empty = prefetch_empty;
assign read_fifo_level = raw_read_level;

always @(posedge read_clk or posedge pix_local_rst) begin
    if(pix_local_rst) begin
        request_toggle_pix<=0; capture_pending_pix<=0;
        request_bank_pix<=0; request_len_pix<=0; ack_sync_pix<=0; ack_seen_pix<=0;
        frame_window_pix<=0; frame_expected_pix<=0; frame_armed_pix<=0;
        frame_bad_pix<=0; consumed_pix<=0; pixel_response<=0;
        underflow_toggle_pix<=0; pixel_fault_short<=0; underflow_sticky_pix<=0; fault_consumed_pix<=0;
        fifo_min_pix<=10'd511; fault_min_pix<=0;
    end else begin
        ack_sync_pix <= {ack_sync_pix[1:0],request_ack_mem};
        // Register BEFORE the queue advances: restores the legacy next-cycle
        // read response expected by video_delay, including each line's first pixel.
        pixel_response <= pixel_pop ? prefetch_data : 32'd0;
        if (read_en) frame_window_pix<=0;
        if (pixel_pop) begin
            consumed_pix<=consumed_pix+1'b1;
            if (consumed_pix < FRAME_WORDS-22'd512 && {1'b0,raw_read_level}<fifo_min_pix)
                fifo_min_pix<={1'b0,raw_read_level};
        end
        if (pixel_missing) begin
            frame_bad_pix<=1; pixel_fault_short<=0; underflow_sticky_pix<=1;
            underflow_toggle_pix<=~underflow_toggle_pix;
            fault_consumed_pix<=consumed_pix; fault_min_pix<=fifo_min_pix;
        end
        if (ack_event_pix) begin
            ack_seen_pix<=ack_sync_pix[2];
            // A late acknowledgement must never arm a frame halfway through DE.
            if (frame_window_pix && !read_en && !frame_bad_pix)
                frame_armed_pix<=1;
        end
        if (frame_start) begin
            if(frame_expected_pix && !frame_bad_pix && consumed_pix!=FRAME_WORDS) begin
                underflow_toggle_pix<=~underflow_toggle_pix; pixel_fault_short<=1;
                underflow_sticky_pix<=1; fault_consumed_pix<=consumed_pix; fault_min_pix<=fifo_min_pix;
            end
            frame_window_pix<=1; frame_expected_pix<=display_enable;
            frame_armed_pix<=0; frame_bad_pix<=0; consumed_pix<=0;
            fifo_min_pix<=10'd511; capture_pending_pix<=display_enable;
        end else if (capture_pending_pix) begin
            capture_pending_pix<=0;
            if (request_free_pix) begin
                request_bank_pix<=read_addr_index; request_len_pix<=read_len;
                request_toggle_pix<=~request_toggle_pix;
            end
        end
    end
end

// Independent diagnostic mailbox remains responsive even if a lost return
// deliberately prevents the frame/bank acknowledgement from completing.
reg diag_request_pix, diag_ack_mem;
reg [2:0] diag_ack_sync_pix, diag_req_sync_mem;
reg diag_seen_pix, diag_seen_mem;
reg [255:0] diag_hold_mem, diag_pixel;
assign reader_diagnostics=diag_pixel;
assign reader_error=diag_pixel[7:0];
always @(posedge read_clk or posedge pix_local_rst) begin
    if(pix_local_rst) begin
        diag_request_pix<=0; diag_ack_sync_pix<=0; diag_seen_pix<=0; diag_pixel<=0;
    end else begin
        diag_ack_sync_pix<={diag_ack_sync_pix[1:0],diag_ack_mem};
        if(frame_start && diag_request_pix==diag_ack_sync_pix[2])
            diag_request_pix<=~diag_request_pix;
        if(diag_ack_sync_pix[2]!=diag_seen_pix) begin
            diag_seen_pix<=diag_ack_sync_pix[2]; diag_pixel<=diag_hold_mem;
        end
    end
end

reg [2:0] req_sync_mem, req_bank_sync1_mem, req_bank_sync2_mem;
reg [ADDR_BITS-1:0] req_len_sync1_mem, req_len_sync2_mem;
reg request_seen_mem;
reg [2:0] rstate, wstate, pending_bank_mem, active_bank_mem, writer_bank_mem;
reg bank_valid_mem, pending_legal_mem;
reg [ADDR_BITS-1:0] pending_len_mem, read_total_mem, write_total_mem;
reg [ADDR_BITS:0] issued_mem, returned_mem, written_mem;
reg [9:0] inflight_mem;
reg [ADDR_BITS-1:0] read_address_mem, write_address_mem;
reg [15:0] write_x_mem;
reg [1:0] bus_owner;
reg [8:0] burst_left_mem;
reg [4:0] gap_mem;
reg last_was_write;
reg [3:0] reset_count_mem;
reg [16:0] return_timer_mem;
reg read_done_mem, write_done_mem;
reg [2:0] wr_req_sync_mem, wr_bank_sync1_mem, wr_bank_sync2_mem;
reg [ADDR_BITS-1:0] wr_len_sync1_mem, wr_len_sync2_mem;
reg wr_ack_mem;
reg abort_toggle_sd, abort_ack_mem;
reg [2:0] abort_ack_sync_sd;
reg [1:0] writer_idle_sync_sd;
assign write_idle_sd=writer_idle_sync_sd[1] && (abort_toggle_sd==abort_ack_sync_sd[2]);
reg [2:0] abort_sync_mem;
reg abort_seen_mem, abort_pending_mem;
wire request_event_mem=req_sync_mem[2]!=request_seen_mem;
wire abort_event_mem=abort_sync_mem[2]!=abort_seen_mem;
wire writer_locked=wstate!=W_IDLE && wstate!=W_REJECT;
wire pending_read_bank=(rstate!=R_OFF && rstate!=R_RUN && rstate!=R_FAULT);
wire incoming_write_conflict=(bank_valid_mem && wr_bank_sync2_mem==active_bank_mem) ||
    (pending_read_bank && wr_bank_sync2_mem==pending_bank_mem) ||
    (request_event_mem && wr_bank_sync2_mem==req_bank_sync2_mem);
wire current_bank_conflict=bank_valid_mem && writer_locked && writer_bank_mem==active_bank_mem;
wire controller_available=Sdr_init_done && !Sdr_busy && !Sdr_init_ref_vld;
wire read_fifo_reset=mem_local_rst || pix_local_rst || rstate==R_RESET;
wire write_fifo_reset=mem_local_rst || sd_local_rst || wstate==W_ACK || wstate==W_ABORT;
reg [2:0] read_release_mem, read_release_pix, write_release_sd;
reg [1:0] read_release_sync_mem;
wire read_fifo_ready=read_release_mem[2] && read_release_sync_mem[1];

always @(posedge read_clk or posedge read_fifo_reset) begin
    if(read_fifo_reset) read_release_pix<=0;
    else read_release_pix<={read_release_pix[1:0],1'b1};
end
always @(posedge mem_clk or posedge read_fifo_reset) begin
    if(read_fifo_reset) begin read_release_mem<=0; read_release_sync_mem<=0; end
    else begin
        read_release_mem<={read_release_mem[1:0],1'b1};
        read_release_sync_mem<={read_release_sync_mem[0],read_release_pix[2]};
    end
end
always @(posedge write_clk or posedge write_fifo_reset) begin
    if(write_fifo_reset) write_release_sd<=0;
    else write_release_sd<={write_release_sd[1:0],1'b1};
end
always @(posedge write_clk or posedge sd_local_rst) begin
    if(sd_local_rst) begin abort_toggle_sd<=0; abort_ack_sync_sd<=0; writer_idle_sync_sd<=0; end
    else begin
        abort_ack_sync_sd<={abort_ack_sync_sd[1:0],abort_ack_mem};
        writer_idle_sync_sd<={writer_idle_sync_sd[0],wstate==W_IDLE};
        if(write_abort) abort_toggle_sd<=~abort_toggle_sd;
    end
end
assign write_req_ack=wr_ack_mem;
assign read_finish=read_done_mem;
assign write_finish=write_done_mem;

// Actual memory bank acknowledgement, not the fade controller's requested bank.
// Bank payload stays stable from RESET through this acknowledgement and until
// the next pixel frame request; SD sees payload2FF before event3FF.
reg [2:0] bank_ack_sync_sd, bank_data1_sd, bank_data2_sd, bank_ack_data_sd;
reg bank_ack_seen_sd, bank_valid1_sd, bank_valid2_sd, bank_ack_valid_sd;
assign reader_bank_sd=bank_ack_data_sd;
assign reader_bank_valid_sd=bank_ack_valid_sd;
always @(posedge write_clk or posedge sd_local_rst) begin
    if(sd_local_rst) begin
        bank_ack_sync_sd<=0; bank_ack_seen_sd<=0; bank_data1_sd<=0; bank_data2_sd<=0;
        bank_ack_data_sd<=0; bank_valid1_sd<=0; bank_valid2_sd<=0; bank_ack_valid_sd<=0;
    end else begin
        bank_ack_sync_sd<={bank_ack_sync_sd[1:0],request_ack_mem};
        bank_data1_sd<=active_bank_mem; bank_data2_sd<=bank_data1_sd;
        bank_valid1_sd<=bank_valid_mem; bank_valid2_sd<=bank_valid1_sd;
        if(bank_ack_sync_sd[2]!=bank_ack_seen_sd) begin
            bank_ack_seen_sd<=bank_ack_sync_sd[2];
            bank_ack_data_sd<=bank_data2_sd; bank_ack_valid_sd<=bank_valid2_sd;
        end
    end
end

wire [31:0] read_raw_data, write_fifo_data;
wire read_raw_valid, read_raw_empty, read_raw_pop, read_fifo_full;
wire write_fifo_full, write_fifo_empty;
wire [8:0] read_used_mem, write_used_mem;
wire raw_return_ok=Sdr_rd_en && (inflight_mem!=0 || App_rd_en);
wire raw_return_extra=Sdr_rd_en && !raw_return_ok;
reg [31:0] return_data_q;
reg return_valid_q;
always @(posedge mem_clk or posedge mem_local_rst) begin
    if(mem_local_rst) begin return_data_q<=0; return_valid_q<=0; end
    else begin
        return_data_q<=Sdr_rd_dout;
        return_valid_q<=raw_return_ok && rstate==R_RUN && !request_event_mem;
    end
end
wire read_fifo_write=return_valid_q && !read_fifo_reset && !read_fifo_full && rstate==R_RUN;
assign write_ready=!write_fifo_full && write_release_sd[2] && !write_abort;
rfifo_32_32_512 read_buf(
    .rst(read_fifo_reset),.clkw(mem_clk),.clkr(read_clk),
    .we(read_fifo_write),.di(return_data_q),.re(read_raw_pop),
    .dout(read_raw_data),.valid(read_raw_valid),.empty_flag(read_raw_empty),
    .full_flag(read_fifo_full),.wrusedw(read_used_mem),.rdusedw(raw_read_level),
    .afull(),.aempty()
);
fifo_prefetch_2 #(.DATA_WIDTH(32)) read_prefetch_m0(
    .clk(read_clk),.rst(read_fifo_reset | !read_release_pix[2]),
    .raw_empty(read_raw_empty | !read_release_pix[2]),.raw_valid(read_raw_valid),.raw_data(read_raw_data),
    .raw_read_en(read_raw_pop),.consume(pixel_pop),
    .out_valid(prefetch_valid),.out_empty(prefetch_empty),.out_data(prefetch_data)
);
wfifo_32_32_512 write_buf(
    .rst(write_fifo_reset),.clkw(write_clk),.clkr(mem_clk),
    .we(write_en && write_ready),.di(write_data),.re(App_wr_en),
    .dout(write_fifo_data),.valid(),.empty_flag(write_fifo_empty),
    .full_flag(write_fifo_full),.wrusedw(),.rdusedw(write_used_mem),.afull(),.aempty()
);
assign App_rd_en=(bus_owner==BUS_READ) && burst_left_mem!=0;
assign App_rd_addr=read_address_mem;
assign App_wr_en=(bus_owner==BUS_WRITE) && burst_left_mem!=0 &&
                 !current_bank_conflict;
assign App_wr_addr=write_address_mem;
assign App_wr_din=write_fifo_data;
assign App_wr_dm=4'b0000;

// burst_left includes every granted but not yet strobed command. Therefore
// occupancy + in-flight + unissued grant is the complete reservation.
wire [10:0] reserved_mem={2'b0,read_used_mem}+{1'b0,inflight_mem}+
    ((bus_owner==BUS_READ)?{2'b0,burst_left_mem}:11'd0)+{10'd0,return_valid_q};
// These eligibility bits are computed during the mandatory burst gap. At
// BUS_IDLE at least12 clocks have elapsed since any consumption of a granted
// reservation, so the registered decision cannot reuse stale burst credit.
reg read_space_q, inflight_space_q, write_words_q, read_low_q;
always @(posedge mem_clk or posedge mem_local_rst) begin
    if(mem_local_rst) begin read_space_q<=0; inflight_space_q<=0; write_words_q<=0; read_low_q<=1; end
    else begin
        read_space_q<=({2'b0,read_used_mem}+{1'b0,inflight_mem}) <= FIFO_LIMIT-RD_BURST-11'd1; // reserve the return pipeline slot, even when empty
        inflight_space_q<=inflight_mem<=MAX_INFLIGHT-RD_BURST;
        write_words_q<=write_used_mem>=9'd128;
        read_low_q<=read_used_mem<9'd256;
    end
end
wire [8:0] next_read_words=9'd128;
wire [8:0] next_write_words=9'd128;
wire want_read=rstate==R_RUN && issued_mem<FRAME_WORDS &&
    !request_event_mem && read_fifo_ready &&
    read_space_q && inflight_space_q;
wire want_write=wstate==W_ACTIVE && !abort_pending_mem && !abort_event_mem &&
    written_mem<FRAME_WORDS && write_words_q &&
    !current_bank_conflict;
wire grant_read=bus_owner==BUS_IDLE && controller_available && want_read &&
    (!want_write || read_low_q || last_was_write);
wire grant_write=bus_owner==BUS_IDLE && controller_available && want_write &&
    !grant_read && inflight_mem==0;
wire read_overrun=request_event_mem && rstate==R_RUN &&
    (issued_mem!=FRAME_WORDS || returned_mem!=FRAME_WORDS);
wire short_frame=request_event_mem && rstate==R_RUN &&
    issued_mem==FRAME_WORDS && returned_mem!=FRAME_WORDS;
wire read_timeout=inflight_mem!=0 && !Sdr_rd_en && return_timer_mem==RETURN_TIMEOUT-17'd1;
wire write_underflow=bus_owner==BUS_WRITE && write_fifo_empty;
wire illegal_read=request_event_mem && (req_bank_sync2_mem>4 || req_len_sync2_mem!=FRAME_WORDS);
wire illegal_write=wstate==W_IDLE && wr_req_sync_mem[2] &&
    (wr_bank_sync2_mem>4 || wr_len_sync2_mem!=FRAME_WORDS);
wire rejected_write=wstate==W_IDLE && wr_req_sync_mem[2] && incoming_write_conflict;
wire rejected_read=request_event_mem && writer_locked && req_bank_sync2_mem==writer_bank_mem;
wire read_overflow=return_valid_q && rstate==R_RUN && read_fifo_full;

always @(posedge mem_clk or posedge mem_local_rst) begin
    if(mem_local_rst) begin
        req_sync_mem<=0; req_bank_sync1_mem<=0; req_bank_sync2_mem<=0;
        req_len_sync1_mem<=0; req_len_sync2_mem<=0;
        wr_req_sync_mem<=0; wr_bank_sync1_mem<=0; wr_bank_sync2_mem<=0;
        wr_len_sync1_mem<=0; wr_len_sync2_mem<=0; abort_sync_mem<=0;
    end else begin
        req_sync_mem<={req_sync_mem[1:0],request_toggle_pix};
        req_bank_sync1_mem<=request_bank_pix; req_bank_sync2_mem<=req_bank_sync1_mem;
        req_len_sync1_mem<=request_len_pix; req_len_sync2_mem<=req_len_sync1_mem;
        wr_req_sync_mem<={wr_req_sync_mem[1:0],write_req};
        wr_bank_sync1_mem<=write_addr_index; wr_bank_sync2_mem<=wr_bank_sync1_mem;
        wr_len_sync1_mem<=write_len; wr_len_sync2_mem<=wr_len_sync1_mem;
        abort_sync_mem<={abort_sync_mem[1:0],abort_toggle_sd};
    end
end

always @(posedge mem_clk or posedge mem_local_rst) begin
    if(mem_local_rst) begin
        request_seen_mem<=0; request_ack_mem<=0;
        rstate<=R_OFF; pending_bank_mem<=0; active_bank_mem<=0; bank_valid_mem<=0; pending_legal_mem<=0;
        pending_len_mem<=0; read_total_mem<=0; issued_mem<=0; returned_mem<=0;
        inflight_mem<=0; read_address_mem<=0; reset_count_mem<=0;
        return_timer_mem<=0; read_done_mem<=0;
        bus_owner<=BUS_IDLE; burst_left_mem<=0; gap_mem<=0; last_was_write<=1;
        wstate<=W_IDLE; writer_bank_mem<=0; write_total_mem<=0; written_mem<=0;
        write_address_mem<=0; write_x_mem<=0; wr_ack_mem<=0; write_done_mem<=0;
        abort_seen_mem<=0; abort_pending_mem<=0; abort_ack_mem<=0;
    end else begin
        read_done_mem<=0; write_done_mem<=0;
        if(inflight_mem==0 || Sdr_rd_en) return_timer_mem<=0;
        else if(return_timer_mem<RETURN_TIMEOUT-17'd1) return_timer_mem<=return_timer_mem+1'b1;
        case({App_rd_en,raw_return_ok})
            2'b10:inflight_mem<=inflight_mem+1'b1;
            2'b01:inflight_mem<=inflight_mem-1'b1;
            default:;
        endcase
        if(raw_return_ok) begin
            returned_mem<=returned_mem+1'b1;
            if(rstate==R_RUN && returned_mem+1'b1==FRAME_WORDS)
                read_done_mem<=1;
        end
        if(App_rd_en) begin
            issued_mem<=issued_mem+1'b1; read_address_mem<=read_address_mem+1'b1;
        end
        if(App_wr_en) begin
            written_mem<=written_mem+1'b1;
            if(WRITE_V_FLIP) begin
                if(write_x_mem==LAST_COLUMN) begin
                    write_x_mem<=0; write_address_mem<=write_address_mem-FLIP_JUMP;
                end else begin write_x_mem<=write_x_mem+1'b1; write_address_mem<=write_address_mem+1'b1; end
            end else write_address_mem<=write_address_mem+1'b1;
        end
        // Once granted, finish a burst. A new frame waits for this burst and
        // its actual responses; it cannot clear FIFO under an old response.
        if(bus_owner==BUS_READ || bus_owner==BUS_WRITE) gap_mem<=TURN_GAP;
        case(bus_owner)
            BUS_IDLE:begin
                if(grant_read) begin bus_owner<=BUS_READ; burst_left_mem<=next_read_words; last_was_write<=0; end
                else if(grant_write) begin bus_owner<=BUS_WRITE; burst_left_mem<=next_write_words; last_was_write<=1; end
            end
            BUS_READ:begin
                if(App_rd_en) begin
                    burst_left_mem<=burst_left_mem-1'b1;
                    if(burst_left_mem==1) begin bus_owner<=BUS_GAP; end
                end
            end
            BUS_WRITE:begin
                if(write_underflow || current_bank_conflict) begin
                    bus_owner<=BUS_GAP; abort_pending_mem<=1;
                end else if(App_wr_en) begin
                    burst_left_mem<=burst_left_mem-1'b1;
                    if(burst_left_mem==1) begin bus_owner<=BUS_GAP; end
                end
            end
            BUS_GAP:begin
                if(gap_mem!=0) gap_mem<=gap_mem-1'b1;
                else bus_owner<=BUS_IDLE;
            end
            default:bus_owner<=BUS_IDLE;
        endcase
        case(rstate)
            R_DRAIN:if(inflight_mem==0 && !return_valid_q && bus_owner==BUS_IDLE && controller_available &&
                !(writer_locked && writer_bank_mem==pending_bank_mem)) begin
                if(!pending_legal_mem) rstate<=R_FAULT;
                else begin
                    rstate<=R_RESET; reset_count_mem<=4;
                    active_bank_mem<=pending_bank_mem; bank_valid_mem<=1;
                    read_total_mem<=FRAME_WORDS[ADDR_BITS-1:0];
                end
            end
            R_RESET:begin
                issued_mem<=0; returned_mem<=0; read_address_mem<=read_base(active_bank_mem);
                if(reset_count_mem==0) rstate<=R_RELEASE;
                else reset_count_mem<=reset_count_mem-1'b1;
            end
            R_RELEASE:if(read_fifo_ready) begin
                rstate<=R_RUN; request_ack_mem<=request_seen_mem;
            end
            default:;
        endcase
        if(request_event_mem) begin
            request_seen_mem<=req_sync_mem[2];
            pending_bank_mem<=req_bank_sync2_mem; pending_len_mem<=req_len_sync2_mem;
            pending_legal_mem<=!illegal_read;
            rstate<=R_DRAIN;
        end
        if(read_overflow || raw_return_extra || read_timeout) rstate<=R_FAULT;

        case(wstate)
            W_IDLE:begin
                wr_ack_mem<=0; abort_pending_mem<=0;
                if(wr_req_sync_mem[2] && Sdr_init_done && !abort_event_mem) begin
                    if(illegal_write || incoming_write_conflict) wstate<=W_REJECT;
                    else begin
                        writer_bank_mem<=wr_bank_sync2_mem; write_total_mem<=FRAME_WORDS[ADDR_BITS-1:0];
                        wstate<=W_ACK; wr_ack_mem<=1;
                    end
                end
            end
            W_ACK:begin
                // Clear counters/address while the FIFO reset is held, not on
                // the bank-validation/admission path driving many register CEs.
                written_mem<=0; write_x_mem<=0;
                write_address_mem<=write_base(writer_bank_mem)+
                    (WRITE_V_FLIP ? FLIP_OFFSET : {ADDR_BITS{1'b0}});
                if(!wr_req_sync_mem[2]) begin wr_ack_mem<=0; wstate<=W_ACTIVE; end
            end
            W_ACTIVE:if(written_mem==FRAME_WORDS) wstate<=W_DRAIN;
            W_DRAIN:if(bus_owner==BUS_IDLE && controller_available) begin
                if(!abort_pending_mem) write_done_mem<=1;
                wstate<=W_IDLE;
            end
            W_ABORT:if(!wr_req_sync_mem[2] && !abort_event_mem) begin
                wstate<=W_IDLE; abort_pending_mem<=0; abort_ack_mem<=abort_seen_mem;
            end
            W_REJECT:if(!wr_req_sync_mem[2]) wstate<=W_IDLE;
            default:wstate<=W_IDLE;
        endcase
        if(abort_pending_mem && bus_owner==BUS_IDLE) begin
            wstate<=W_ABORT; wr_ack_mem<=0;
        end
        if(abort_event_mem) begin abort_seen_mem<=abort_sync_mem[2]; abort_pending_mem<=1; end
    end
end

// Sticky first-fault record and saturating episode counters. Flags are never
// cleared by successful frame recovery, so auto-recovery cannot hide a defect.
reg [2:0] underflow_sync_mem;
reg underflow_seen_mem;
reg [1:0] pixel_short_sync_mem;
reg [ADDR_BITS:0] fault_consumed1_mem, fault_consumed2_mem;
reg [9:0] fault_min1_mem, fault_min2_mem;
wire underflow_event=underflow_sync_mem[2]!=underflow_seen_mem;
wire [7:0] fault_flags={raw_return_extra,read_timeout,
    illegal_read || illegal_write || rejected_read || rejected_write || current_bank_conflict,
    write_underflow,read_overflow,read_overrun,
    short_frame || (underflow_event && pixel_short_sync_mem[1]),
    underflow_event && !pixel_short_sync_mem[1]};
reg [7:0] fault_previous, fault_sticky, fault_flags_q;
reg illegal_fault_q;
wire [7:0] fault_edges=fault_flags_q & ~fault_previous;
reg [15:0] fault_count[0:7];
reg [127:0] first_fault;
reg first_fault_pixel, first_fault_valid;
reg [127:0] fault_record_q, fault_sample_q;
reg fault_pixel_q, fault_pixel_sample_q;
reg [2:0] first_fault_sync_pix, freeze_sync_mem;
reg freeze_valid_pix;
reg [19:0] freeze_consumed_pix, freeze_consumed1_mem, freeze_consumed2_mem;
reg [9:0] freeze_min_pix, freeze_min1_mem, freeze_min2_mem;
always @(posedge read_clk or posedge pix_local_rst) begin
    if(pix_local_rst) begin
        first_fault_sync_pix<=0; freeze_valid_pix<=0;
        freeze_consumed_pix<=0; freeze_min_pix<=0;
    end else begin
        first_fault_sync_pix<={first_fault_sync_pix[1:0],first_fault[7:0]!=0};
        if(first_fault_sync_pix[2] && !freeze_valid_pix) begin
            freeze_valid_pix<=1;
            freeze_consumed_pix<=consumed_pix[19:0]; freeze_min_pix<=fifo_min_pix;
        end
    end
end
reg [7:0] fault_code;
integer fi;
always @* begin
    if(fault_flags_q[7]) fault_code=8'h67;
    else if(fault_flags_q[6]) fault_code=8'h68;
    else if(fault_flags_q[5]) fault_code=illegal_fault_q?8'h65:8'h66;
    else if(fault_flags_q[4]) fault_code=8'h69;
    else if(fault_flags_q[3]) fault_code=8'h62;
    else if(fault_flags_q[1]) fault_code=8'h64;
    else if(fault_flags_q[2]) fault_code=8'h61;
    else if(fault_flags_q[0]) fault_code=8'h63;
    else fault_code=0;
end
always @(posedge mem_clk or posedge mem_local_rst) begin
    if(mem_local_rst) begin
        underflow_sync_mem<=0; underflow_seen_mem<=0; pixel_short_sync_mem<=0;
        fault_consumed1_mem<=0; fault_consumed2_mem<=0; fault_min1_mem<=0; fault_min2_mem<=0;
        fault_previous<=0; fault_sticky<=0; first_fault<=0; first_fault_pixel<=0; first_fault_valid<=0; fault_record_q<=0; fault_pixel_q<=0; fault_sample_q<=0; fault_pixel_sample_q<=0;
        fault_flags_q<=0; illegal_fault_q<=0;
        freeze_sync_mem<=0; freeze_consumed1_mem<=0; freeze_consumed2_mem<=0;
        freeze_min1_mem<=0; freeze_min2_mem<=0;
        for(fi=0;fi<8;fi=fi+1) fault_count[fi]<=0;
        diag_req_sync_mem<=0; diag_seen_mem<=0; diag_ack_mem<=0; diag_hold_mem<=0;
    end else begin
        underflow_sync_mem<={underflow_sync_mem[1:0],underflow_toggle_pix};
        pixel_short_sync_mem<={pixel_short_sync_mem[0],pixel_fault_short};
        underflow_seen_mem<=underflow_sync_mem[2];
        fault_consumed1_mem<=fault_consumed_pix; fault_consumed2_mem<=fault_consumed1_mem;
        fault_min1_mem<=fault_min_pix; fault_min2_mem<=fault_min1_mem;
        freeze_sync_mem<={freeze_sync_mem[1:0],freeze_valid_pix};
        freeze_consumed1_mem<=freeze_consumed_pix; freeze_consumed2_mem<=freeze_consumed1_mem;
        freeze_min1_mem<=freeze_min_pix; freeze_min2_mem<=freeze_min1_mem;
        if(freeze_sync_mem[2] && !first_fault_pixel) begin
            first_fault[91:72]<=freeze_consumed2_mem;
            first_fault[101:92]<=freeze_min2_mem;
        end
        fault_flags_q<=fault_flags; illegal_fault_q<=illegal_read || illegal_write;
        fault_previous<=fault_flags_q; fault_sticky<=fault_sticky | fault_flags_q;
        for(fi=0;fi<8;fi=fi+1)
            if(fault_edges[fi] && fault_count[fi]!=16'hffff) fault_count[fi]<=fault_count[fi]+1'b1;
        // Sample fault data without a wide conditional enable, then freeze
        // the first nonzero sample on the following clock. Event and counters
        // refer to the same sample; diagnostics do not lengthen grant timing.
        fault_sample_q<=0;
        fault_sample_q[15:8]<=fault_flags;
        fault_sample_q[19:16]<={1'b0,request_event_mem?req_bank_sync2_mem:pending_bank_mem};
        fault_sample_q[23:20]<={1'b0,active_bank_mem};
        fault_sample_q[27:24]<={1'b0,(rejected_write || illegal_write)?wr_bank_sync2_mem:writer_bank_mem};
        fault_sample_q[31:28]<={writer_locked,bank_valid_mem,bus_owner};
        fault_sample_q[51:32]<=issued_mem[19:0];
        fault_sample_q[71:52]<=returned_mem[19:0];
        fault_sample_q[91:72]<=fault_consumed2_mem[19:0];
        fault_sample_q[101:92]<=underflow_event?fault_min2_mem:{1'b0,read_used_mem};
        fault_sample_q[111:102]<=inflight_mem;
        // A simultaneous pixel fault also supplies a valid stop-position sample,
        // even if a higher-priority memory error supplies the displayed code.
        fault_pixel_sample_q<=underflow_event;
        fault_record_q<=fault_sample_q;
        fault_record_q[7:0]<=fault_code;
        fault_pixel_q<=fault_pixel_sample_q;
        if(!first_fault_valid && fault_record_q[7:0]!=0) begin
            first_fault<=fault_record_q; first_fault_pixel<=fault_pixel_q; first_fault_valid<=1;
        end
        diag_req_sync_mem<={diag_req_sync_mem[1:0],diag_request_pix};
        if(diag_req_sync_mem[2]!=diag_seen_mem) begin
            diag_seen_mem<=diag_req_sync_mem[2]; diag_ack_mem<=diag_req_sync_mem[2];
            diag_hold_mem[127:0]<=first_fault;
            for(fi=0;fi<8;fi=fi+1) diag_hold_mem[128+fi*16 +:16]<=fault_count[fi];
            // Live banks occupy the unused upper first-record16 bits.
            diag_hold_mem[127:112]<={1'b0,writer_locked,bank_valid_mem,1'b0,
                1'b0,writer_bank_mem,1'b0,active_bank_mem,1'b0,pending_bank_mem};
        end
    end
end
endmodule
