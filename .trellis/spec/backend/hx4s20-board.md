# HX4S20 board resources and pin reference

## Authority and lookup contract

This is the project's canonical board memory. Read this file at session start
and before answering a board-resource or pin question. Users do not need to
resupply the manual. Names such as `SW3`, `sw3`, `开关3`, `拨码3`, and `拨码开关3`
refer to the board switch below; `按键3` means **KEY3**, not SW3.

Keep **physical wiring** separate from **current RTL behavior**. The board
tables are fixed facts; the application section is a dated source-code snapshot.
Update that section whenever an external control's role changes. If future
constraints conflict with the manual, report both and check the copied source;
do not silently invent a pin or rewrite a hardware fact to fit software.

- Board: HX4S20; FPGA: Anlogic EG4S20BG256.
- Manual: [HX4S20开发板手册-HDL版2410.pdf](../../../doc/board/HX4S20开发板手册-HDL版2410.pdf).
- Original source: `C:/Users/27348/Desktop/HX4S20开发板手册-HDL版2410.pdf`.
- Manual length: 23 PDF pages. Page references below are 1-based PDF pages,
  matching the visible printed page numbers.
- SHA256: `e6d066fdc433259697bcf5dfe9eb791cf8a87d289c75e69fa40172d716afccfe`.
- Reviewed: 2026-10-01; tables extracted and relevant circuit figures visually checked.
- `IN` / `OUT` / `IO` below are relative to the FPGA. Unimplemented interfaces
  remain board resources; their presence does not mean the current RTL uses them.

## Quick lookup: switches, keys, indicators

### SW1–SW6 / 拨码开关 / 乒乓开关

SW1–SW4 are FPGA inputs: **up = 1, down = 0** (p18, figure 2-19).
Figure net labels are zero-based `SW_0`..`SW_3`, while board names are SW1..SW4.

The current smoke-alert build adds `smoke_do` on J1 pin 1 / GPIOA_0 / FPGA
pin D14. It expects a 3.3 V digital comparator output from an MQ-2/MQ-135
module; the common module is low-active when smoke exceeds its threshold.

| Board name / aliases | FPGA pin | Direction / physical behavior | Source |
|---|---|---|---|
| SW1 / sw1 / 开关1 / 拨码1 / SW_0 | C8 | IN; up=1, down=0 | p18 |
| SW2 / sw2 / 开关2 / 拨码2 / SW_1 | C7 | IN; up=1, down=0 | p18 |
| SW3 / sw3 / 开关3 / 拨码3 / SW_2 | C6 | IN; up=1, down=0 | p18 |
| SW4 / sw4 / 开关4 / 拨码4 / SW_3 | C5 | IN; up=1, down=0 | p18 |
| SW5 / 蜂鸣器硬件开关 | — | Hardware switch; up disconnects, down connects buzzer drive | pp17–18 |
| SW6 / 数码管与双色LED选择开关 | — | Hardware switch; up selects seven-segment displays, down selects dual-color LEDs | pp14,18 |

SW5 and SW6 have no ordinary FPGA input assignment in the manual. Do not create
`sw5`/`sw6` GPIO constraints. **SW6**, not SW2, selects LEDs versus seven-segment displays.

### KEY1–KEY4 / 按键

All four keys are active-low inputs: **pressed = 0, released = 1** (pp18–19).

| Board name / aliases | FPGA pin | Direction / level | Source |
|---|---|---|---|
| KEY1 / key1 / 按键1 | A2 | IN; active low | pp18–19 |
| KEY2 / key2 / 按键2 | B2 | IN; active low | pp18–19 |
| KEY3 / key3 / 按键3 | B1 | IN; active low | pp18–19 |
| KEY4 / key4 / 按键4 | C1 | IN; active low | pp18–19 |

### Independent LEDs and buzzer

Figure 2-3 (p6) shows four green LEDs with grounded cathodes: high turns on.
Schematic nets `LED0`..`LED3` correspond to physical LED1..LED4; avoid off-by-one names.

| Board signal | FPGA pin | Direction / level | Source |
|---|---|---|---|
| LED1 | A4 | OUT; high=on | p6 |
| LED2 | A3 | OUT; high=on | p6 |
| LED3 | C10 | OUT; high=on | p6 |
| LED4 | B12 | OUT; high=on | p6 |
| BUZZER / 蜂鸣器 | H11 | OUT; low=sound, high=off; also gated by SW5 | pp17–18 |

The four independent LEDs are distinct from the eight dual-color LEDs below.
Do not label an independent LED as a physical red LED merely because RTL uses it
as an emergency indicator.

## FPGA, memory, clocks and power

| Resource | Board/device capability | Source |
|---|---|---|
| FPGA package | EG4S20BG256, BGA256 | pp5–6 |
| LUTs / flip-flops | 19,600 / 19,600 | p6 comparison-table image |
| Distributed RAM | 156,800 bits; not bytes | p6 comparison-table image |
| Embedded RAM | 64 × 9k + 16 × 32k; total shown as 1,088k bits | p6 comparison-table image |
| Multipliers | 29 × M18x18 | p6 comparison-table image |
| Configuration SRAM | 4,988,928 bits | p6 comparison-table image |
| PLL / low-skew GCLK | 4 / 16 | p6 comparison-table image |
| User IO banks | 4 for the BG256 package | p6 comparison-table image |
| User IO count | Manual table: maximum 193; TD R5 report denominator: 188; these are different source counts | p6; R5 area report |
| Embedded SDRAM | 2M × 32 bits = 8 MiB; 21-bit word-address interface in this project | pp5–6; `include/global_def.v` |
| Board clock / CLK / clk | 50 MHz input on R7 | pp21–22 |
| USB power rails | USB 5 V; board derives 3.3 V, 2.5 V, 1.2 V | p9 |
| Expansion IO level | 3.3 V IO; 5 V header supply pins are not 5 V-tolerant GPIO | pp6–7,12–13 |

SDRAM's internal controller connections are not ordinary J1/J2 expansion pins.
Keep the existing encrypted SDRAM IP and its board-specific constraints.
Five software frame banks are address partitions, not five physical IO banks.

## Seven-segment displays / 数码管 and dual-color LEDs

Eight digits, arranged as two four-digit common-anode displays. Segment outputs
are **low=on**; digit selects are **high=enabled**. SW6 selects the physical load.
Dual-color LED channels are **high=on**, as described on p15.

| Segment / physical red LED | FPGA pin | Digit select / physical green LED | FPGA pin | Source |
|---|---|---|---|---|
| DIG0 / a / LED6 red | C15 | SEL0 / digit1 from left / LED6 green | F16 | p16 |
| DIG1 / b / LED7 red | C16 | SEL1 / digit2 from left / LED7 green | E16 | p16 |
| DIG2 / c / LED8 red | B6 | SEL2 / digit3 from left / LED8 green | E12 | p16 |
| DIG3 / d / LED9 red | A5 | SEL3 / digit4 from left / LED9 green | E10 | p16 |
| DIG4 / e / LED10 red | B5 | SEL4 / digit5 from left / LED10 green | C13 | p16 |
| DIG5 / f / LED11 red | A8 | SEL5 / digit6 from left / LED11 green | F10 | p16; see errata |
| DIG6 / g / LED12 red | A7 | SEL6 / digit7 from left / LED12 green | E11 | p17 |
| DIG7 / DP / LED13 red | A6 | SEL7 / digit8 from left / LED13 green | D11 | p17 |

All entries above are FPGA outputs. Current RTL exposes **six** `seg_sel` bits,
mapped to physical SEL2..SEL7; it does not drive the first two physical digits.

## TF / SD card

The slot is on the back of the board. Board supports SD wiring; current design
uses SPI and contiguous physical sectors, not full FAT32 cluster traversal.

| Board signal / SPI alias | FPGA pin | Current port | Direction in SPI | Source |
|---|---|---|---|---|
| SD_DAT3 / CS | A12 | sd_ncs | OUT; active-low select | p20 |
| SD_DAT2 | A11 | — | Unused in SPI; data IO in SD mode | p20 |
| SD_DAT1 | B15 | — | Unused in SPI; data IO in SD mode | p20 |
| SD_DAT0 / MISO | B14 | sd_miso | IN | p20 |
| SD_CLK / SCLK | A14 | sd_dclk | OUT | p20 |
| SD_CMD / MOSI | A13 | sd_mosi | OUT | p20 |

## HDMI_A and HDMI_B

Both connectors are wired directly to FPGA and can be used for input or output.
TMDS direction depends on the selected design. The current design transmits via
**HDMI_B**; positive TMDS pins use `LVDS33`, with their paired negative pins
handled by the differential output primitive. DDC uses 3.3 V IO in `pin.adc`.

| Signal suffix | HDMI_A pin | HDMI_B pin | Current HDMI_B port / role | Source |
|---|---|---|---|---|
| D2_P | B3 | E1 | HDMI_D2_P; TMDS OUT | p8; p11 |
| D2_N | D3 | D1 | Paired negative TMDS output | p8; p11 |
| D1_P | E3 | F1 | HDMI_D1_P; TMDS OUT | p8; p11 |
| D1_N | E4 | F2 | Paired negative TMDS output | p8; p11 |
| D0_P | F5 | G5 | HDMI_D0_P; TMDS OUT | p8; p11 |
| D0_N | F4 | G6 | Paired negative TMDS output | p8; p11 |
| CLK_P | K1 | C3 | HDMI_CLK_P; TMDS OUT | p8; p12 |
| CLK_N | J1 | C2 | Paired negative clock output | p8; p12 |
| SCL | P1 | P2 | HDMI_DDC_SCL; OUT in current top | p8; p11 |
| SDA | R1 | R2 | HDMI_DDC_SDA; IO | p8; p11 |
| HPD | K2 | J6 | Not connected by current top; transmitter-side IN | p8; p12 |
| CEC | K3 | K5 | Not connected by current top; bidirectional bus | p8; p12; see errata |

Lookup aliases: `HDMI_A` = `HDMIA`; `HDMI_B` = `HDMIB`.

## VGA

Unused by the current active top. All VGA signals are outputs in a transmitter.
The manual provides 12 data bits, four per color; retain the VGAD numbering when
working from this table, and consult figure 2-12 for connector color wiring.

| Signal | FPGA pin | Source |
|---|---|---|
| VGA_HS | E7 | p12 |
| VGA_VS | F7 | p12 |
| VGAD0 | F6 | p12 |
| VGAD1 | E6 | p12 |
| VGAD2 | D6 | p12 |
| VGAD3 | D5 | p12 |
| VGAD4 | T5 | p12 |
| VGAD5 | P5 | p12 |
| VGAD6 | N5 | p12 |
| VGAD7 | N6 | p12 |
| VGAD8 | R5 | p12 |
| VGAD9 | L7 | p12 |
| VGAD10 | L8 | p12 |
| VGAD11 | E13 | p12 |

## USB UART and JTAG

UART uses CH340G. Figure 2-10 was visually checked: board net RXD connects to
CH340 TXD, and board net TXD connects to CH340 RXD. The names in this table are
therefore already from the FPGA's transmit/receive perspective.

| Signal / alias | FPGA pin | Direction / role | Source |
|---|---|---|---|
| RXD / UART_RX | F12 | IN; CH340 TXD -> FPGA | p11, figure 2-10 |
| TXD / UART_TX | D12 | OUT; FPGA -> CH340 RXD | p11, figure 2-10 |
| FPGA_TCK / JTAG_TCK | C14 | IN; programming clock | p10 |
| FPGA_TDI / JTAG_TDI | C12 | IN; programming data | p10 |
| FPGA_TMS / JTAG_TMS | A15 | IN; programming state select | p10 |
| FPGA_TDO / JTAG_TDO | E14 | OUT; programming data | p10 |

The onboard USB-JTAG is an Anlogic USB Cable interface; its USB connection also
supplies board power (pp9–10). Do not reassign dedicated programming pins as
ordinary free GPIO. UART is not used by the current active top.

## Ethernet / 千兆网口

RTL8211 PHY and HR911130A connector, unused by the current active top (pp20–21).
Directions below describe FPGA-to-PHY RGMII operation, not a claimed implemented MAC.

| Manual signal | FPGA pin | Direction / role | Source |
|---|---|---|---|
| MDC0 | L13 | OUT; management clock | p21 |
| MDIO0 | M13 | IO; management data | p21 |
| RXCTI/PHY_AD | T13 | Receive control / strap-related label; see errata | p21 |
| TXCLK | T12 | OUT; transmit clock | p21 |
| RXD0 | P6 | IN | p21 |
| RXD1 | M6 | IN | p21 |
| RXD2 | T9 | IN | p21 |
| RXD3 | N9 | IN | p21 |
| TXD0 | T4 | OUT | p21 |
| TXD1 | T6 | OUT | p21 |
| TXD2 | M7 | OUT | p21 |
| TXD3 | T8 | OUT | p21 |
| TXCTL | T7 | OUT; transmit control | p21 |
| RXC | T14 | IN; receive clock | p21 |

## User SPI Flash and configuration Flash

Two different chips and pin groups; do not substitute one for the other.
The user Flash is documented as W25Q64, 64 Mbit = 8 MiB (p17). Figure 2-17 uses
the label W25X64; retain that discrepancy when selecting an exact device driver.
The configuration Flash is labeled W25Q16 in the heading and figure on p22;
its capacity prose is inconsistent (see errata). Confirm actual chip/JEDEC ID
before capacity-dependent erase/program operations.

| Chip / signal | FPGA pin | Direction / level in standard SPI | Source |
|---|---|---|---|
| User FLASH_CS | P8 | OUT; active low | p17 |
| User FLASH_SDO / MISO | N8 | IN; Flash DO -> FPGA | p17, figure 2-17 |
| User FLASH_SDI / MOSI | P7 | OUT; FPGA -> Flash DI | p17, figure 2-17 |
| User FLASH_SCLK | M9 | OUT | p17 |
| User FLASH_WP | P9 | OUT; active-low write protect; IO2 in quad mode | p17 |
| User FLASH_HOLD | R9 | OUT; active-low hold; IO3 in quad mode | p17 |
| Configuration MSPI_CLK | R11 | Dedicated configuration clock | p22 |
| Configuration MSPI_MISO | P10 | Configuration data IN | p22 |
| Configuration MSPI_CS | T3 | Dedicated select, active low | p22 |
| Configuration MSPI_MOSI | T10 | Configuration data OUT | p22 |

Normal bitstream configuration uses the dedicated MSPI function; the manual
states that user RTL need not manually constrain these configuration pins.
The active application now uses the separate user W25Q64 pins for the
16-slot player-settings journal (current RTL verified 2026-10-03); configuration-Flash programming remains a
TD download/program step.

## J1 / JP1 and J2 / JP2 expansion headers

Each 40-pin header supplies 36 GPIOs (18 differential pairs), 5 V, 3.3 V and two
grounds. GPIO direction is design-selectable. Check physical pin-1 orientation:
the manual describes J1 pin1 at upper left (p13), J2 pin1 at lower right (p7)
in its depicted board orientation; use the connector notch and the figures.
Power contacts below are **not FPGA pins**.

| Header contact | J1 signal | J1 FPGA pin / supply | J2 signal | J2 FPGA pin / supply |
|---:|---|---|---|---|
| 1 | GPIOA_0 | D14 | GPIOB_0 | P4 |
| 2 | GPIOA_1 | G11 | GPIOB_1 | N4 |
| 3 | GPIOA_2 | G12 | GPIOB_2 | N3 |
| 4 | GPIOA_3 | F13 | GPIOB_3 | M5 |
| 5 | GPIOA_4 | H13 | GPIOB_4 | M3 |
| 6 | GPIOA_5 | H14 | GPIOB_5 | M4 |
| 7 | GPIOA_6 | J14 | GPIOB_6 | L3 |
| 8 | GPIOA_7 | J13 | GPIOB_7 | J3 |
| 9 | GPIOA_8 | K12 | GPIOB_8 | J4 |
| 10 | GPIOA_9 | L14 | GPIOB_9 | H4 |
| 11 | Supply | 5V | Supply | 5V |
| 12 | Ground | GND | Ground | GND |
| 13 | GPIOA_10 | M14 | GPIOB_10 | N1 |
| 14 | GPIOA_11 | P11 | GPIOB_11 | M2 |
| 15 | GPIOA_12 | L10 | GPIOB_12 | M1 |
| 16 | GPIOA_13 | M10 | GPIOB_13 | L1 |
| 17 | GPIOA_14 | D16 | GPIOB_14 | H2 |
| 18 | GPIOA_15 | E15 | GPIOB_15 | H1 |
| 19 | GPIOA_16 | F14 | GPIOB_16 | G1 |
| 20 | GPIOA_17 | F15 | GPIOB_17 | G3 |
| 21 | GPIOA_18 | G16 | GPIOB_18 | L4 |
| 22 | GPIOA_19 | G14 | GPIOB_19 | L5 |
| 23 | GPIOA_20 | K15 | GPIOB_20 | K6 |
| 24 | GPIOA_21 | J16 | GPIOB_21 | H3 |
| 25 | GPIOA_22 | H15 | GPIOB_22 | H5 |
| 26 | GPIOA_23 | H16 | GPIOB_23 | F3 |
| 27 | GPIOA_24 | K16 | GPIOB_24 | E2 |
| 28 | GPIOA_25 | M16 | GPIOB_25 | J11 |
| 29 | Supply | 3.3V | Supply | 3.3V |
| 30 | Ground | GND | Ground | GND |
| 31 | GPIOA_26 | M15 | GPIOB_26 | J12 |
| 32 | GPIOA_27 | L16 | GPIOB_27 | K11 |
| 33 | GPIOA_28 | N16 | GPIOB_28 | K14 |
| 34 | GPIOA_29 | N14 | GPIOB_29 | L12 |
| 35 | GPIOA_30 | P16 | GPIOB_30 | M12 |
| 36 | GPIOA_31 | P15 | GPIOB_31 | M11 |
| 37 | GPIOA_32 | R16 | GPIOB_32 | N12 |
| 38 | GPIOA_33 | R15 | GPIOB_33 | P14 |
| 39 | GPIOA_34 | T15 | GPIOB_34 | P12 |
| 40 | GPIOA_35 | R14 | GPIOB_35 | R12 |

J1 source: p13. J2 source: pp7–8. Current active top has no expansion-header
ports; commented I2S constraints and old test tops do not establish active use.

## Current project assignments — inspected 2026-10-01

Sources: [pin.adc](../../../src/user_source/constraints_source/pin.adc),
[top_tf_hdmi_audio.v](../../../src/user_source/hdl_source/top_tf_hdmi_audio.v),
[sd_card_bmp.v](../../../src/user_source/hdl_source/SD/sd_card_bmp.v).
Hardware pin validation checks **active**, uncommented constraints only.

| Resource | RTL port | FPGA pin | Current behavior |
|---|---|---|---|
| KEY1 | key1 | A2 | Pause/resume normal autoplay |
| KEY2 | key2 | B2 | Enter/exit emergency; cached image5 is bank4 |
| KEY3 | key3 | B1 | Rescan TF and progressively refresh frame cache; repeated presses during preload ignored |
| KEY4 | key4 | C1 | Next ready normal image; no longer external reset |
| SW1 | sw1 | C8 | Up=background music on, down=off; emergency audio stays enabled |
| SW2 | sw2 | C7 | Settings-menu selector; up enters the parameter menu, down returns to playback |
| SW3 | sw3 | C6 | Up=day100%/B0, down=night60%/B1 with KANON.WAV; sole day/night selector |
| SW4 | sw4 | C5 | Reserved/unused; port and constraint retained; no effect on settings or debounce |
| LED1 | led[0] | A4 | Valid frame and normal mode |
| LED2 | led[1] | A3 | Emergency mode |
| LED3 | led[2] | C10 | No valid frame |
| LED4 | led[3] | B12 | Image/SD error present |
| Buzzer | buzzer | H11 | Low while emergency is active, independent of SW1; SW5 is the hardware gate |
| Board oscillator | clk | R7 | 50 MHz reference |
| TF SPI clock | sd_dclk | A14 | SPI clock output |
| TF SPI MISO | sd_miso | B14 | SPI data input |
| TF SPI MOSI | sd_mosi | A13 | SPI data output |
| TF SPI CS | sd_ncs | A12 | SPI chip select, active low |
| HDMI_B DDC SCL | HDMI_DDC_SCL | P2 | DDC clock output |
| HDMI_B DDC SDA | HDMI_DDC_SDA | R2 | DDC bidirectional data |
| HDMI_B CLK_P | HDMI_CLK_P | C3 | Differential clock positive leg |
| HDMI_B D0_P | HDMI_D0_P | G5 | Differential data0 positive leg |
| HDMI_B D1_P | HDMI_D1_P | F1 | Differential data1 positive leg |
| HDMI_B D2_P | HDMI_D2_P | E1 | Differential data2 positive leg |
| DIG0 / a | seg_data[0] | C15 | Active-low segment |
| DIG1 / b | seg_data[1] | C16 | Active-low segment |
| DIG2 / c | seg_data[2] | B6 | Active-low segment |
| DIG3 / d | seg_data[3] | A5 | Active-low segment |
| DIG4 / e | seg_data[4] | B5 | Active-low segment |
| DIG5 / f | seg_data[5] | A8 | Active-low segment |
| DIG6 / g | seg_data[6] | A7 | Active-low segment |
| DIG7 / DP | seg_data[7] | A6 | Active-low decimal point |
| Physical SEL2 / digit3 | seg_sel[0] | E12 | Active-high digit select |
| Physical SEL3 / digit4 | seg_sel[1] | E10 | Active-high digit select |
| Physical SEL4 / digit5 | seg_sel[2] | C13 | Active-high digit select |
| Physical SEL5 / digit6 | seg_sel[3] | F10 | Active-high digit select |
| Physical SEL6 / digit7 | seg_sel[4] | E11 | Active-high digit select |
| Physical SEL7 / digit8 | seg_sel[5] | D11 | Active-high digit select |

### Scene/music behavior — updated 2026-10-01

| SW3 (SW4 ignored) | Brightness / OSD | Music | Digital gain / 256 |
|---|---|---|---|
| Up=1 | 100% / B0 | Day image melodies 1..4 | 128 / 50% |
| Down=0 | ~60% / B1 (coefficient154) | Night: root `KANON.WAV` | 255 / ~99.6%; source normalized |

Contrast is fixed normal; its old C0 label and trailing fixed view-mode 0 are
hidden from R6 onward. The first OSD row shows image index, autoplay state and
B0/B1 only (for example, 1AB0); the second row still shows image dimensions.
SW3 down alone selects night during playback: the complete user-provided
`C:/Users/27348/Desktop/canon_44k1_16b_mono.wav` is converted to root `KANON.WAV`
(PCM16 stereo 48000 Hz) and streamed from FAT32 in a loop; SW2 only opens the
settings menu and does not select a night track. Night keeps the configured ~60% video brightness; the supplied
recording is normalized and played at full FPGA gain. SW1 controls HDMI background music only; emergency HDMI gain
stays128 and the buzzer follows emergency regardless of SW1. SW5 can physically
disconnect the buzzer. Four day image melodies are synthesized; night music is read from TF.
In day mode, normal image changes select the corresponding legacy melody and
produce a 100ms cue; night image changes do not affect KANON playback.

Switches are synchronized in the pixel domain; SW2 is sampled as the settings-menu selector and SW4 is masked before debounce.
SW1/SW3 are accepted after50ms of effective-word stability plus the next frame
boundary. SW2 menu changes cannot restart audio; SW4 cannot postpone acceptance. Background gain changes
take100ms; profile changes use100ms out then100ms in. Brightness ramps by4 per
frame; music selects the target scene without waiting for the brightness ramp.
Detailed contract: [day/night audio](daynight-audio.md).

KEY1/KEY3/KEY4 normal functions are ignored in emergency mode. Switch settings
may still change; current music settings are restored when emergency ends.
Reset is internal power-on/PLL reset.
Derived clocks: SD=100 MHz, SDRAM=125 MHz, pixel=25 MHz, HDMI serial=125 MHz;
these are current PLL settings, not additional board oscillators.
Output is 640×480. Five resident RGB888+padding frames consume 6,144,000 bytes.
Build utilization/timing history belongs to release manifests and the task
handoff, not the board capacity table. Physical validation is not inferred from
the existence of a bitstream or from this documentation update.

## Manual errata and historical corrections

| Ambiguity / incorrect statement | Recorded treatment |
|---|---|
| Earlier conversation called SW2 the LED/display selector | Corrected: SW2=C7 input; SW6 is the hardware selector (pp14,18) |
| p5 overview says five keys | Detailed pp18–19 and four-pin table identify KEY1–KEY4 only |
| p5 prose says BRAM 1008K; p6 image says total ERAM 1,088k bits | Use the resource-table breakdown: 64×9k + 16×32k; preserve the disagreement |
| p6 maximum IO=193 versus TD report available IO=188 | Keep source-specific counts; do not claim 193 currently available user pads |
| p16 calls DIG5 the d segment | p14 explicitly maps DIG[0..7] to a,b,c,d,e,f,g,DP; use f for DIG5, A8 unchanged |
| p12 HDMI_B table labels its CEC row HDMIA_CEC | Record as HDMI_B CEC=K5 by section/connector context; HDMI_A CEC=K3 on p8 |
| Expansion-section headings alternate J1/J2/JP1/JP2 | Use table titles and GPIOA/J1 versus GPIOB/J2 assignments, plus physical pin1 orientation |
| p21 RXCTI/PHY_AD spelling | Preserve exact label and T13; validate PHY strap/direction requirements against figure/datasheet before implementing Ethernet |
| User Flash section says W25Q64 but figure symbol says W25X64 | Pin group is known; exact populated part should be checked before device-specific commands |
| p22 names/draws W25Q16 but prose says 64M-bit | W25Q16 designation conventionally means 16 Mbit (2 MiB); mark prose inconsistent, verify actual part/JEDEC ID before programming by capacity |

## Acceptance and maintenance

Recorded checks: [board-memory verification](../../../doc/board/verification.md).

- A lookup of `SW3` must yield C6, input, up=1/down=0, its sole day/night role,
  and p18 without rereading the desktop PDF.
- `按键3` must yield KEY3/B1; `SW6` must yield the hardware display selector,
  not a fabricated FPGA pin. `KEY4` must describe the current next-image role.
- Keep all 38 active current-top port mappings consistent with `pin.adc`.
- Verify all tabulated manual pin groups, including 40 contacts on each header;
  record any source ambiguity instead of guessing.
- Start-of-session entry points in both directory levels link here. The copied
  PDF and relative links must remain valid after moving the complete project.
- Changes to board resources or current control roles must update this file.
  Do not create a second competing pin map in a journal or task PRD.
