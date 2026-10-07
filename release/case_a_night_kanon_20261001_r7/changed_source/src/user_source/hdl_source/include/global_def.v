


`define   DATA_WIDTH                        32
`define   ADDR_WIDTH                        21
`define   DM_WIDTH                          4

`define   ROW_WIDTH                        11
`define   BA_WIDTH                        2

`define	  SDR_CLK_PERIOD				(1000000000/125000000)
// init_cnt counts 0..threshold inclusive, so subtract one: 3906 cycles x 2048 rows = 63.996 ms
`define   SELF_REFRESH_INTERVAL			(64000000/`SDR_CLK_PERIOD/(1 << `ROW_WIDTH) - 1)

