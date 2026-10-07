# Flash 鍥哄寲涓庤劚鏈哄惎鍔?
鏈洰褰曠殑 `case_a_sdram_timing_power_20261002_r5.bit` 宸茬敱 TD R5 瀹屾垚缁煎悎銆佸竷灞€甯冪嚎鍜?bit 鐢熸垚銆侶X4S20 鐨勯厤缃?Flash 璧颁笓鐢?MSPI 寮曡剼锛岀敤鎴峰弬鏁?Flash 璧扮嫭绔嬬殑 W25Q64 寮曡剼锛涗袱鑰呬笉鑳芥贩鐢ㄣ€?
鍦ㄨ繛鎺?HX4S20銆乁SB-JTAG 鍜岀數婧愬悗锛屾墦寮€ TD R5 鐨勫伐绋?`src/td_project/HDMI1.4b_Transmitter_v1.0.al`锛屽厛鐢?`case_a_sdram_timing_power_20261002_r5.bit` 鍋氫竴娆?SRAM 涓嬭浇纭 HDMI 鍜?TF 姝ｅ父锛屽啀鍦?TD 鐨?**Download/Program Flash** 瀵硅瘽妗嗛€夋嫨鍚屼竴涓?bit 鏂囦欢锛岀洰鏍囬€夋嫨閰嶇疆 Flash锛圡SPI / W25Q16锛夛紝鎵ц Erase/Program/Verify銆傚畬鎴愬悗鎷旀帀 USB-JTAG锛屽彧淇濈暀鏉夸笂鐢垫簮骞堕噸鏂颁笂鐢碉紱閰嶇疆 Flash 浼氳嚜鍔ㄥ姞杞?bitstream锛孯TL 涓?`AUTO_PLAY_ON_BOOT=1` 浼氳嚜鍔ㄥ紑濮嬭疆鎾€?
鍙傛暟璁剧疆浣跨敤鏉胯浇鐢ㄦ埛 W25Q64 鐨?`0x7FE000` 鍜?`0x7FF000` 涓や釜 4 KiB 鎵囧尯銆傝繘鍏ヨ彍鍗曟椂鎷?SW2=1锛欿EY1 閫夋嫨椤圭洰锛孠EY4 鏀瑰€硷紝KEY3 绔嬪嵆淇濆瓨锛涢€€鍑鸿彍鍗曞悗淇濇寔 2 绉掍篃浼氳嚜鍔ㄤ繚瀛樸€傞煶閲忎簲妗ｄ负闈欓煶銆佷綆銆佷腑銆侀珮銆佹渶澶э紙0/25/50/75/100%锛夛紱杞挱鍛ㄦ湡涓?2/3/5/10 绉掋€備繚瀛樺畬鎴愬悗 OSD 鏄剧ず `SAVED`锛屼笅娆′笂鐢电敱 Flash 鎭㈠銆?
鏈 bit 鐨?SHA-256锛?
`f3e62cc5a772f0942daf52302a18a8b8e65dc7ee432fefe5c1e151f61a25ec02`

TD 鎶ュ憡鐨勫叏灞€ setup WNS 涓?-6.565 ns锛宧old WNS 涓?0.023 ns锛沚it 鐢熸垚鎴愬姛涓嶇瓑浜庡凡缁忓畬鎴愬紑鍙戞澘涓嬭浇銆丗lash 鍥哄寲鎴栨柇鐢靛疄娴嬶紝杩欎笁椤归渶瑕佸湪瀹炵墿涓婃墽琛屽苟璁板綍銆?



本版本参数 Flash 已升级为 16 个 4 KiB 槽位循环写入，地址范围 0x7F0000-0x7FFFFF；上电扫描全部槽位并恢复序号最新且 CRC 正确的记录。







