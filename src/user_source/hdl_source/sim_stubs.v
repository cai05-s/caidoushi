// iverilog 静态检查用的黑盒桩：对应 TD 工程中的加密 IP/原语，
// 仅在本地语法检查时替代，不参与 TD 综合。
module wfifo_32_32_512 (input clkr, input clkw, input rst, input we, input re, input [31:0] di, output empty_flag, output full_flag, output [8:0] wrusedw, output [8:0] rdusedw, output [31:0] dout);
endmodule

module rfifo_32_32_512 (input clkr, input clkw, input rst, input we, input re, input [31:0] di, output empty_flag, output full_flag, output [8:0] wrusedw, output [8:0] rdusedw, output [31:0] dout);
endmodule

module sdr_as_ram #(parameter self_refresh_open = 1) (input Sdr_clk, input Sdr_clk_sft, input Rst, output Sdr_init_done, output Sdr_init_ref_vld, output Sdr_busy, input App_ref_req, input App_wr_en, input [22:0] App_wr_addr, input [3:0] App_wr_dm, input [31:0] App_wr_din, input App_rd_en, input [22:0] App_rd_addr, output Sdr_rd_en, output [31:0] Sdr_rd_dout, output SDRAM_CLK, output SDR_RAS, output SDR_CAS, output SDR_WE, output [1:0] SDR_BA, output [10:0] SDR_ADDR, output [3:0] SDR_DM, inout [31:0] SDR_DQ);
endmodule

module EG_PHY_SDRAM_2M_32 (input clk, input ras_n, input cas_n, input we_n, input [10:0] addr, input [1:0] ba, inout [31:0] dq, input cs_n, input dm0, input dm1, input dm2, input dm3, input cke);
endmodule
