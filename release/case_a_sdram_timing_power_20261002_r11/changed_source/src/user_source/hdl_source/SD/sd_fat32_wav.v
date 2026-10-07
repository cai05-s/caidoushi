// Read-only FAT32 / RIFF PCM source. All ports belong to clk (the SD clock).
// One owned request is one complete 512-byte sector. The only byte storage is
// a synchronous RAM; parsing never infers a 512-to-1 combinational byte mux.
// Supported media: 512 B sectors, FAT32 clusters 1..128 sectors, 1 or 2 FATs,
// primary MBR FAT32 partition (first type 0b/0c/1b/1c) or superfloppy, SFN
// KANON   WAV in the root. Active FAT selection in BPB_ExtFlags is honoured.
// WAV: RIFF/WAVE, PCM1, stereo, 48000 Hz, 16 bits; fmt precedes data. Extra
// chunks, odd chunk padding and sector/fragment boundaries are supported.
// Bounds: root <=4096 sectors; pre-data metadata <=1 MiB; file <1 GiB.
// No writes, no directory recursion, no exFAT/FAT16, no extensible WAV.
module sd_fat32_wav (
    input             clk,
    input             rst,
    input             restart,
    input             enable,
    input             sd_init_done,
    input             sd_io_error,
    output            req,
    output reg [31:0] req_addr,
    input             req_accept,
    input      [7:0]  rd_data,
    input             rd_valid,
    input             rd_end,
    output reg        pcm_valid,
    output reg [31:0] pcm_data,
    input             pcm_ready,
    output reg        file_ready,
    output reg [7:0]  error_code
);

localparam [7:0]
    S_IDLE=0, S_IO_REQ=1, S_IO_WAIT=2,
    S_BYTE_ADDR=3, S_BYTE_WAIT=4, S_BYTE_DONE=5,
    S_BOOT_BEGIN=6, S_BOOT_BYTE=7, S_BOOT_CHECK=8,
    S_GEOM0=9, S_GEOM1=10, S_GEOM2=11, S_GEOM3=12,
    S_SEEK0=13, S_SEEK1=14,
    S_DIR_BEGIN=15, S_DIR_BYTE=16, S_DIR_CHECK=17,
    S_ADVANCE=18, S_FAT_BYTE=19, S_FAT_CHECK=20,
    S_FILE_BEGIN=21, S_RIFF_BYTE=22, S_RIFF_CHECK=23,
    S_CHUNK_BEGIN=24, S_CHUNK_BYTE=25, S_CHUNK_CHECK=26,
    S_FMT_BYTE=27, S_FMT_CHECK=28, S_SKIP=29, S_SKIP_BYTE=30,
    S_PCM_NEXT=31, S_PCM_BYTE=32, S_PCM_HOLD=33,
    S_ERROR=34, S_GEOM1B=35;

reg [7:0] state, io_return, byte_return, seek_return;
reg abort_pending;
reg [9:0] rx_count;
reg rx_overflow;
reg [7:0] sector_ram [0:511];
reg [8:0] ram_addr;
reg [7:0] ram_q, byte_value;
reg [9:0] sector_pos, seek_pos;
reg raw_bytes, directory_stream;
reg [8:0] boot_index;
reg first_boot;

// This separate, unreset RAM process is the TD block-RAM inference pattern.
always @(posedge clk) begin
    if (state == S_IO_WAIT && rd_valid && rx_count < 10'd512)
        sector_ram[rx_count[8:0]] <= rd_data;
    ram_q <= sector_ram[ram_addr];
end

assign req = (state == S_IO_REQ);

reg [15:0] bpb_bytes, bpb_reserved, bpb_root_entries;
reg [15:0] bpb_total16, bpb_fat16, bpb_flags, bpb_version, boot_signature;
reg [7:0] bpb_spc, bpb_fats;
reg [31:0] bpb_total32, bpb_fat32, bpb_root;
reg [5:0] mbr_index;
reg [7:0] mbr_type;
reg [31:0] mbr_lba, mbr_size, partition_lba, partition_size;
reg partition_found;
reg [31:0] volume_lba, volume_size, metadata_size, fat_size, fat_base;
reg [31:0] data_sectors_q;
reg [32:0] volume_end, partition_end;
reg [31:0] data_base, cluster_offset;
reg [7:0] sectors_per_cluster;
reg [2:0] cluster_shift;
wire [31:0] data_cluster_count = data_sectors_q >> cluster_shift;
reg [27:0] cluster_count, max_cluster, current_cluster;
reg [6:0] cluster_sector;
reg [27:0] chain_hops, chain_anchor, chain_power, chain_length;
reg [12:0] directory_sectors;
reg [1:0] fat_index;
reg [31:0] fat_value;

reg [4:0] directory_index;
reg directory_match;
reg [7:0] directory_first, directory_attr;
reg [31:0] directory_cluster, directory_size;
reg [31:0] file_size, file_position;
reg [3:0] field_index;
reg [31:0] riff_tag, riff_size, wave_tag, riff_end;
reg [31:0] chunk_tag, chunk_size, skip_remaining;
reg [15:0] fmt_format, fmt_channels, fmt_align, fmt_bits;
reg [31:0] fmt_rate, fmt_byte_rate;
reg fmt_seen;
reg [31:0] data_size, data_remaining, data_file_position;
reg [27:0] data_cluster;
reg [6:0] data_cluster_sector;
reg [9:0] data_sector_pos;
reg [1:0] pcm_index;
reg [23:0] pcm_partial;

function [7:0] short_name_byte;
    input [3:0] index;
    begin
        case (index)
            0: short_name_byte=8'h4b; // K
            1: short_name_byte=8'h41; // A
            2: short_name_byte=8'h4e; // N
            3: short_name_byte=8'h4f; // O
            4: short_name_byte=8'h4e; // N
            8: short_name_byte=8'h57; // W
            9: short_name_byte=8'h41; // A
            10: short_name_byte=8'h56; // V
            default: short_name_byte=8'h20;
        endcase
    end
endfunction

function good_cluster_size;
    input [7:0] count;
    begin
        case (count)
            1,2,4,8,16,32,64,128: good_cluster_size=1'b1;
            default: good_cluster_size=1'b0;
        endcase
    end
endfunction

task fail;
    input [7:0] code;
    begin
        error_code <= code;
        file_ready <= 1'b0;
        pcm_valid <= 1'b0;
        state <= S_ERROR;
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= S_IDLE; io_return <= S_IDLE; byte_return <= S_IDLE;
        seek_return <= S_IDLE; abort_pending <= 0;
        req_addr <= 0; rx_count <= 0; rx_overflow <= 0;
        ram_addr <= 0; byte_value <= 0; sector_pos <= 0; seek_pos <= 0;
        raw_bytes <= 1; directory_stream <= 0;
        pcm_valid <= 0; pcm_data <= 0; file_ready <= 0; error_code <= 0;
        first_boot <= 1; boot_index <= 0;
        bpb_bytes <= 0; bpb_reserved <= 0; bpb_root_entries <= 0;
        bpb_total16 <= 0; bpb_fat16 <= 0; bpb_flags <= 0;
        bpb_version <= 0; boot_signature <= 0; bpb_spc <= 0; bpb_fats <= 0;
        bpb_total32 <= 0; bpb_fat32 <= 0; bpb_root <= 0;
        mbr_index <= 0; mbr_type <= 0; mbr_lba <= 0; mbr_size <= 0;
        partition_lba <= 0; partition_size <= 0; partition_found <= 0;
        volume_lba <= 0; volume_size <= 0; metadata_size <= 0; data_sectors_q <= 0;
        fat_size <= 0; fat_base <= 0; volume_end <= 0; partition_end <= 0;
        data_base <= 0; cluster_offset <= 0; sectors_per_cluster <= 0;
        cluster_shift <= 0; cluster_count <= 0; max_cluster <= 0;
        current_cluster <= 0; cluster_sector <= 0; chain_hops <= 0;
        chain_anchor <= 0; chain_power <= 1; chain_length <= 0;
        directory_sectors <= 0; fat_index <= 0; fat_value <= 0;
        directory_index <= 0; directory_match <= 0;
        directory_first <= 0; directory_attr <= 0;
        directory_cluster <= 0; directory_size <= 0;
        file_size <= 0; file_position <= 0; field_index <= 0;
        riff_tag <= 0; riff_size <= 0; wave_tag <= 0; riff_end <= 0;
        chunk_tag <= 0; chunk_size <= 0; skip_remaining <= 0;
        fmt_format <= 0; fmt_channels <= 0; fmt_align <= 0; fmt_bits <= 0;
        fmt_rate <= 0; fmt_byte_rate <= 0; fmt_seen <= 0;
        data_size <= 0; data_remaining <= 0; data_file_position <= 0;
        data_cluster <= 0; data_cluster_sector <= 0; data_sector_pos <= 0;
        pcm_index <= 0; pcm_partial <= 0;
    end else if (sd_io_error ||
                 (!sd_init_done && state != S_IDLE && state != S_ERROR)) begin
        // The shared controller resets its transaction on these conditions.
        // Unlike restart/disable, there is no old sector left to drain.
        abort_pending <= 0;
        fail(8'h43);
    end else if (restart) begin
        error_code <= 0; file_ready <= 0; pcm_valid <= 0;
        // Include a same-cycle accept. Withdrawing a merely pending request is
        // safe; an accepted request remains owned until its end indication.
        if ((state == S_IO_WAIT && !rd_end) ||
            (state == S_IO_REQ && req_accept)) begin
            abort_pending <= 1;
            if (state == S_IO_REQ) begin rx_count <= 0; rx_overflow <= 0; end
            state <= S_IO_WAIT;
        end else begin
            abort_pending <= 0;
            state <= S_IDLE;
        end
    end else if (!enable) begin
        file_ready <= 0; pcm_valid <= 0;
        // Preserve a latched error while the wrapper clears its async FIFO.
        if ((state == S_IO_WAIT && !rd_end) ||
            (state == S_IO_REQ && req_accept)) begin
            abort_pending <= 1;
            if (state == S_IO_REQ) begin rx_count <= 0; rx_overflow <= 0; end
            state <= S_IO_WAIT;
        end else begin
            abort_pending <= 0;
            state <= S_IDLE;
        end
    end else begin
        case (state)
            S_IDLE: begin
                if (sd_init_done && error_code == 0) begin
                    first_boot <= 1;
                    partition_found <= 0; partition_lba <= 0;
                    partition_size <= 0; volume_lba <= 0;
                    req_addr <= 0; io_return <= S_BOOT_BEGIN;
                    state <= S_IO_REQ;
                end
            end
            S_IO_REQ: begin
                if (req_accept) begin
                    rx_count <= 0; rx_overflow <= 0;
                    state <= S_IO_WAIT;
                end
            end
            S_IO_WAIT: begin
                if (rd_valid) begin
                    if (rx_count < 10'd512) rx_count <= rx_count + 1'b1;
                    else rx_overflow <= 1;
                end
                if (rd_end) begin
                    if (abort_pending) begin
                        abort_pending <= 0;
                        state <= S_IDLE;
                    end else if (rx_overflow ||
                        !((rx_count == 10'd512 && !rd_valid) ||
                          (rx_count == 10'd511 && rd_valid))) fail(8'h43);
                    else state <= io_return;
                end
            end

            // Address, synchronous-RAM latency, then registered-byte consume.
            S_BYTE_ADDR: begin
                if (sector_pos == 10'd512) begin
                    if (raw_bytes) fail(8'h43);
                    else state <= S_ADVANCE;
                end else if (!raw_bytes && !directory_stream &&
                    (file_position >= file_size ||
                     (!file_ready && file_position >= 32'd1048576)))
                    fail(8'h42);
                else begin
                    ram_addr <= sector_pos[8:0];
                    state <= S_BYTE_WAIT;
                end
            end
            S_BYTE_WAIT: state <= S_BYTE_DONE;
            S_BYTE_DONE: begin
                byte_value <= ram_q;
                sector_pos <= sector_pos + 1'b1;
                if (!raw_bytes && !directory_stream)
                    file_position <= file_position + 1'b1;
                state <= byte_return;
            end

            S_BOOT_BEGIN: begin
                raw_bytes <= 1; sector_pos <= 0; boot_index <= 0;
                mbr_index <= 0;
                bpb_bytes <= 0; bpb_reserved <= 0; bpb_root_entries <= 0;
                bpb_total16 <= 0; bpb_fat16 <= 0; bpb_flags <= 0;
                bpb_version <= 0; boot_signature <= 0;
                bpb_spc <= 0; bpb_fats <= 0;
                bpb_total32 <= 0; bpb_fat32 <= 0; bpb_root <= 0;
                mbr_type <= 0; mbr_lba <= 0; mbr_size <= 0;
                byte_return <= S_BOOT_BYTE; state <= S_BYTE_ADDR;
            end
            S_BOOT_BYTE: begin
                case (boot_index)
                    11: bpb_bytes[7:0] <= byte_value;
                    12: bpb_bytes[15:8] <= byte_value;
                    13: bpb_spc <= byte_value;
                    14: bpb_reserved[7:0] <= byte_value;
                    15: bpb_reserved[15:8] <= byte_value;
                    16: bpb_fats <= byte_value;
                    17: bpb_root_entries[7:0] <= byte_value;
                    18: bpb_root_entries[15:8] <= byte_value;
                    19: bpb_total16[7:0] <= byte_value;
                    20: bpb_total16[15:8] <= byte_value;
                    22: bpb_fat16[7:0] <= byte_value;
                    23: bpb_fat16[15:8] <= byte_value;
                    32: bpb_total32[7:0] <= byte_value;
                    33: bpb_total32[15:8] <= byte_value;
                    34: bpb_total32[23:16] <= byte_value;
                    35: bpb_total32[31:24] <= byte_value;
                    36: bpb_fat32[7:0] <= byte_value;
                    37: bpb_fat32[15:8] <= byte_value;
                    38: bpb_fat32[23:16] <= byte_value;
                    39: bpb_fat32[31:24] <= byte_value;
                    40: bpb_flags[7:0] <= byte_value;
                    41: bpb_flags[15:8] <= byte_value;
                    42: bpb_version[7:0] <= byte_value;
                    43: bpb_version[15:8] <= byte_value;
                    44: bpb_root[7:0] <= byte_value;
                    45: bpb_root[15:8] <= byte_value;
                    46: bpb_root[23:16] <= byte_value;
                    47: bpb_root[31:24] <= byte_value;
                    510: boot_signature[7:0] <= byte_value;
                    511: boot_signature[15:8] <= byte_value;
                    default: begin end
                endcase
                if (first_boot && boot_index >= 9'd446 && boot_index < 9'd510) begin
                    case (mbr_index[3:0])
                        4: mbr_type <= byte_value;
                        8: mbr_lba[7:0] <= byte_value;
                        9: mbr_lba[15:8] <= byte_value;
                        10: mbr_lba[23:16] <= byte_value;
                        11: mbr_lba[31:24] <= byte_value;
                        12: mbr_size[7:0] <= byte_value;
                        13: mbr_size[15:8] <= byte_value;
                        14: mbr_size[23:16] <= byte_value;
                        15: begin
                            if (!partition_found &&
                                (mbr_type == 8'h0b || mbr_type == 8'h0c ||
                                 mbr_type == 8'h1b || mbr_type == 8'h1c)) begin
                                partition_found <= 1;
                                partition_lba <= mbr_lba;
                                partition_size <= {byte_value,mbr_size[23:0]};
                            end
                        end
                        default: begin end
                    endcase
                    mbr_index <= mbr_index + 1'b1;
                end
                if (boot_index == 9'd511) state <= S_BOOT_CHECK;
                else begin boot_index <= boot_index + 1'b1; state <= S_BYTE_ADDR; end
            end
            S_BOOT_CHECK: begin
                if (boot_signature != 16'haa55) fail(8'h40);
                else if (bpb_bytes == 16'd512 && bpb_root_entries == 0 &&
                         bpb_fat16 == 0 && good_cluster_size(bpb_spc))
                    state <= S_GEOM0;
                else if (first_boot && partition_found && partition_lba != 0 &&
                         partition_size != 0 &&
                         ({1'b0,partition_lba}+{1'b0,partition_size}) <= 33'h100000000) begin
                    first_boot <= 0; volume_lba <= partition_lba;
                    req_addr <= partition_lba; io_return <= S_BOOT_BEGIN;
                    state <= S_IO_REQ;
                end else fail(8'h40);
            end
            S_GEOM0: begin
                if (bpb_reserved == 0 || (bpb_fats != 1 && bpb_fats != 2) ||
                    bpb_fat32 == 0 || bpb_fat32 > 32'h00200000 ||
                    bpb_version != 0 || (bpb_flags & 16'hff70) != 0 ||
                    (bpb_flags[7] && bpb_flags[3:0] >= bpb_fats) ||
                    (bpb_total16 != 0 && bpb_total32 != 0)) fail(8'h40);
                else begin
                    volume_size <= bpb_total32 != 0 ? bpb_total32 : {16'd0,bpb_total16};
                    metadata_size <= {16'd0,bpb_reserved} +
                        (bpb_fats == 2 ? (bpb_fat32 << 1) : bpb_fat32);
                    fat_size <= bpb_fat32;
                    fat_base <= volume_lba + {16'd0,bpb_reserved};
                    sectors_per_cluster <= bpb_spc;
                    case (bpb_spc)
                        1: cluster_shift <= 0;
                        2: cluster_shift <= 1;
                        4: cluster_shift <= 2;
                        8: cluster_shift <= 3;
                        16: cluster_shift <= 4;
                        32: cluster_shift <= 5;
                        64: cluster_shift <= 6;
                        default: cluster_shift <= 7;
                    endcase
                    state <= S_GEOM1;
                end
            end
            S_GEOM1: begin
                volume_end <= {1'b0,volume_lba} + {1'b0,volume_size};
                partition_end <= {1'b0,partition_lba} + {1'b0,partition_size};
                if (volume_size <= metadata_size) fail(8'h40);
                else begin
                    // Split the 32-bit subtraction from the shift/limit logic.
                    // This removes the long subtract+shift+compare path from
                    // one SD-clock cycle without changing the FAT geometry.
                    data_sectors_q <= volume_size - metadata_size;
                    state <= S_GEOM1B;
                end
            end
            S_GEOM1B: begin
                // The upper bound is checked before narrowing to 28 bits.
                if (data_cluster_count > 32'h0fffffee)
                        fail(8'h40);
                else begin
                    cluster_count <= data_cluster_count[27:0];
                    data_base <= volume_lba + metadata_size;
                    if (bpb_flags[7] && bpb_flags[0]) fat_base <= fat_base + fat_size;
                    state <= S_GEOM2;
                end
            end
            S_GEOM2: begin
                if (volume_end > 33'h100000000 ||
                    (!first_boot && (volume_end > partition_end || volume_size > partition_size)) ||
                    cluster_count < 28'd65525 ||
                    ({1'b0,cluster_count}+29'd2) > ({1'b0,fat_size} << 7) ||
                    bpb_root < 2 || bpb_root > {4'd0,cluster_count}+32'd1)
                    fail(8'h40);
                else begin max_cluster <= cluster_count+1'b1; state <= S_GEOM3; end
            end
            S_GEOM3: begin
                current_cluster <= bpb_root[27:0]; cluster_sector <= 0;
                chain_hops <= 0; chain_anchor <= bpb_root[27:0];
                chain_power <= 1; chain_length <= 0;
                directory_sectors <= 1; directory_stream <= 1;
                seek_pos <= 0; seek_return <= S_DIR_BEGIN; state <= S_SEEK0;
            end

            // Split cluster scaling from absolute LBA addition for 100 MHz.
            S_SEEK0: begin
                cluster_offset <= ({4'd0,current_cluster}-32'd2) << cluster_shift;
                state <= S_SEEK1;
            end
            S_SEEK1: begin
                req_addr <= data_base + cluster_offset + {25'd0,cluster_sector};
                sector_pos <= seek_pos; raw_bytes <= 0;
                io_return <= seek_return; state <= S_IO_REQ;
            end
            S_DIR_BEGIN: begin
                directory_index <= 0; directory_match <= 1;
                directory_cluster <= 0; directory_size <= 0;
                directory_first <= 0; directory_attr <= 0;
                byte_return <= S_DIR_BYTE; state <= S_BYTE_ADDR;
            end
            S_DIR_BYTE: begin
                if (directory_index < 11 && byte_value != short_name_byte(directory_index[3:0]))
                    directory_match <= 0;
                case (directory_index)
                    0: directory_first <= byte_value;
                    11: directory_attr <= byte_value;
                    20: directory_cluster[23:16] <= byte_value;
                    21: directory_cluster[31:24] <= byte_value;
                    26: directory_cluster[7:0] <= byte_value;
                    27: directory_cluster[15:8] <= byte_value;
                    28: directory_size[7:0] <= byte_value;
                    29: directory_size[15:8] <= byte_value;
                    30: directory_size[23:16] <= byte_value;
                    31: directory_size[31:24] <= byte_value;
                    default: begin end
                endcase
                if (directory_index == 31) state <= S_DIR_CHECK;
                else begin directory_index <= directory_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_DIR_CHECK: begin
                if (directory_first == 0) fail(8'h41);
                else if (directory_match && directory_first != 8'he5 &&
                         (directory_attr & 8'h18) == 0) begin
                    if (directory_cluster < 2 || directory_cluster > {4'd0,max_cluster})
                        fail(8'h43);
                    else if (directory_size < 44 || directory_size >= 32'h40000000)
                        fail(8'h42);
                    else begin
                        current_cluster <= directory_cluster[27:0]; cluster_sector <= 0;
                        chain_hops <= 0; chain_anchor <= directory_cluster[27:0];
                        chain_power <= 1; chain_length <= 0;
                        file_size <= directory_size; file_position <= 0;
                        directory_stream <= 0;
                        seek_pos <= 0; seek_return <= S_FILE_BEGIN; state <= S_SEEK0;
                    end
                end else state <= S_DIR_BEGIN;
            end
            S_ADVANCE: begin
                if (directory_stream && directory_sectors >= 13'd4096) fail(8'h43);
                else begin
                    if (directory_stream) directory_sectors <= directory_sectors+1'b1;
                    if ({1'b0,cluster_sector}+8'd1 < sectors_per_cluster) begin
                        cluster_sector <= cluster_sector+1'b1;
                        seek_pos <= 0; seek_return <= S_BYTE_ADDR; state <= S_SEEK0;
                    end else begin
                        // FAT entry is four bytes and cannot straddle a sector.
                        req_addr <= fat_base + {11'd0,current_cluster[27:7]};
                        io_return <= S_BYTE_ADDR;
                        sector_pos <= {1'b0,current_cluster[6:0],2'b00};
                        raw_bytes <= 1; fat_index <= 0; fat_value <= 0;
                        // byte_return normally points at a directory/WAV/PCM
                        // consumer. Preserve it while the FAT owns the RAM.
                        seek_return <= byte_return;
                        byte_return <= S_FAT_BYTE; state <= S_IO_REQ;
                    end
                end
            end
            S_FAT_BYTE: begin
                case (fat_index)
                    0: fat_value[7:0] <= byte_value;
                    1: fat_value[15:8] <= byte_value;
                    2: fat_value[23:16] <= byte_value;
                    3: fat_value[31:24] <= byte_value;
                    default: begin end
                endcase
                if (fat_index == 3) state <= S_FAT_CHECK;
                else begin fat_index <= fat_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_FAT_CHECK: begin
                if (fat_value[27:0] >= 28'hffffff8) begin
                    if (directory_stream) fail(8'h41);
                    else fail(8'h43);
                end else if (fat_value[27:0] < 2 || fat_value[27:0] > max_cluster ||
                             fat_value[27:0] == current_cluster ||
                             fat_value[27:0] == chain_anchor || chain_hops >= cluster_count)
                    fail(8'h43);
                else begin
                    current_cluster <= fat_value[27:0]; cluster_sector <= 0;
                    chain_hops <= chain_hops+1'b1;
                    // Brent cycle detection adds no second FAT read or table.
                    // Directory/file byte bounds also limit all traversals.
                    if (chain_length+28'd1 == chain_power) begin
                        chain_anchor <= fat_value[27:0]; chain_length <= 0;
                        if (!chain_power[27]) chain_power <= chain_power << 1;
                    end else chain_length <= chain_length+1'b1;
                    byte_return <= seek_return;
                    seek_pos <= 0; seek_return <= S_BYTE_ADDR; state <= S_SEEK0;
                end
            end

            S_FILE_BEGIN: begin
                field_index <= 0; riff_tag <= 0; riff_size <= 0; wave_tag <= 0;
                fmt_seen <= 0; byte_return <= S_RIFF_BYTE; state <= S_BYTE_ADDR;
            end
            S_RIFF_BYTE: begin
                case (field_index)
                    0: riff_tag[7:0] <= byte_value;
                    1: riff_tag[15:8] <= byte_value;
                    2: riff_tag[23:16] <= byte_value;
                    3: riff_tag[31:24] <= byte_value;
                    4: riff_size[7:0] <= byte_value;
                    5: riff_size[15:8] <= byte_value;
                    6: riff_size[23:16] <= byte_value;
                    7: riff_size[31:24] <= byte_value;
                    8: wave_tag[7:0] <= byte_value;
                    9: wave_tag[15:8] <= byte_value;
                    10: wave_tag[23:16] <= byte_value;
                    11: wave_tag[31:24] <= byte_value;
                    default: begin end
                endcase
                if (field_index == 11) state <= S_RIFF_CHECK;
                else begin field_index <= field_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_RIFF_CHECK: begin
                if (riff_tag != 32'h46464952 || wave_tag != 32'h45564157 ||
                    riff_size < 36 || {1'b0,riff_size}+33'd8 > {1'b0,file_size})
                    fail(8'h42);
                else begin riff_end <= riff_size+32'd8; state <= S_CHUNK_BEGIN; end
            end
            S_CHUNK_BEGIN: begin
                if (file_position > riff_end-32'd8) fail(8'h42);
                else begin
                    field_index <= 0; chunk_tag <= 0; chunk_size <= 0;
                    byte_return <= S_CHUNK_BYTE; state <= S_BYTE_ADDR;
                end
            end
            S_CHUNK_BYTE: begin
                case (field_index)
                    0: chunk_tag[7:0] <= byte_value;
                    1: chunk_tag[15:8] <= byte_value;
                    2: chunk_tag[23:16] <= byte_value;
                    3: chunk_tag[31:24] <= byte_value;
                    4: chunk_size[7:0] <= byte_value;
                    5: chunk_size[15:8] <= byte_value;
                    6: chunk_size[23:16] <= byte_value;
                    7: chunk_size[31:24] <= byte_value;
                    default: begin end
                endcase
                if (field_index == 7) state <= S_CHUNK_CHECK;
                else begin field_index <= field_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_CHUNK_CHECK: begin
                // 33-bit addition rejects a wrapping size plus odd-byte pad.
                if ({1'b0,chunk_size}+{32'd0,chunk_size[0]} >
                    {1'b0,riff_end}-{1'b0,file_position}) fail(8'h42);
                else if (chunk_tag == 32'h61746164) begin // data
                    if (!fmt_seen || chunk_size == 0 || chunk_size[1:0] != 0)
                        fail(8'h42);
                    else begin
                        data_size <= chunk_size; data_remaining <= chunk_size;
                        data_cluster <= current_cluster;
                        data_cluster_sector <= cluster_sector;
                        data_sector_pos <= sector_pos;
                        data_file_position <= file_position;
                        file_ready <= 1; state <= S_PCM_NEXT;
                    end
                end else if (chunk_tag == 32'h20746d66) begin // fmt
                    if (chunk_size < 16) fail(8'h42);
                    else begin
                        field_index <= 0; fmt_format <= 0; fmt_channels <= 0;
                        fmt_rate <= 0; fmt_byte_rate <= 0; fmt_align <= 0; fmt_bits <= 0;
                        skip_remaining <= chunk_size-32'd16+{31'd0,chunk_size[0]};
                        byte_return <= S_FMT_BYTE; state <= S_BYTE_ADDR;
                    end
                end else begin
                    skip_remaining <= chunk_size+{31'd0,chunk_size[0]};
                    state <= S_SKIP;
                end
            end
            S_FMT_BYTE: begin
                case (field_index)
                    0: fmt_format[7:0] <= byte_value;
                    1: fmt_format[15:8] <= byte_value;
                    2: fmt_channels[7:0] <= byte_value;
                    3: fmt_channels[15:8] <= byte_value;
                    4: fmt_rate[7:0] <= byte_value;
                    5: fmt_rate[15:8] <= byte_value;
                    6: fmt_rate[23:16] <= byte_value;
                    7: fmt_rate[31:24] <= byte_value;
                    8: fmt_byte_rate[7:0] <= byte_value;
                    9: fmt_byte_rate[15:8] <= byte_value;
                    10: fmt_byte_rate[23:16] <= byte_value;
                    11: fmt_byte_rate[31:24] <= byte_value;
                    12: fmt_align[7:0] <= byte_value;
                    13: fmt_align[15:8] <= byte_value;
                    14: fmt_bits[7:0] <= byte_value;
                    15: fmt_bits[15:8] <= byte_value;
                    default: begin end
                endcase
                if (field_index == 15) state <= S_FMT_CHECK;
                else begin field_index <= field_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_FMT_CHECK: begin
                if (fmt_format != 1 || fmt_channels != 2 || fmt_rate != 48000 ||
                    fmt_byte_rate != 192000 || fmt_align != 4 || fmt_bits != 16)
                    fail(8'h42);
                else begin fmt_seen <= 1; state <= S_SKIP; end
            end
            S_SKIP: begin
                if (skip_remaining == 0) state <= S_CHUNK_BEGIN;
                else begin byte_return <= S_SKIP_BYTE; state <= S_BYTE_ADDR; end
            end
            S_SKIP_BYTE: begin
                skip_remaining <= skip_remaining-1'b1; state <= S_SKIP;
            end
            S_PCM_NEXT: begin
                if (data_remaining == 0) begin
                    // Repeat only declared PCM bytes. The final output frame
                    // has already handshaken before this cursor is restored.
                    current_cluster <= data_cluster; cluster_sector <= data_cluster_sector;
                    file_position <= data_file_position; data_remaining <= data_size;
                    chain_hops <= 0; chain_anchor <= data_cluster;
                    chain_power <= 1; chain_length <= 0;
                    seek_pos <= data_sector_pos; seek_return <= S_PCM_NEXT;
                    state <= S_SEEK0;
                end else begin
                    pcm_index <= 0; pcm_partial <= 0;
                    byte_return <= S_PCM_BYTE; state <= S_BYTE_ADDR;
                end
            end
            S_PCM_BYTE: begin
                data_remaining <= data_remaining-1'b1;
                case (pcm_index)
                    0: pcm_partial[7:0] <= byte_value;
                    1: pcm_partial[15:8] <= byte_value;
                    2: pcm_partial[23:16] <= byte_value;
                    3: begin
                        pcm_data <= {byte_value,pcm_partial};
                        pcm_valid <= 1; state <= S_PCM_HOLD;
                    end
                    default: begin end
                endcase
                if (pcm_index != 3) begin pcm_index <= pcm_index+1'b1; state <= S_BYTE_ADDR; end
            end
            S_PCM_HOLD: begin
                if (pcm_ready) begin pcm_valid <= 0; state <= S_PCM_NEXT; end
            end
            S_ERROR: begin pcm_valid <= 0; file_ready <= 0; end
            default: fail(8'h43);
        endcase
    end
end
endmodule
