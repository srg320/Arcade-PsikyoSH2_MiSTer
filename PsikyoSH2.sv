//============================================================================
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off 

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

	assign ADC_BUS  = 'Z;
	assign {UART_RTS, UART_TXD, UART_DTR} = 0;
	assign BUTTONS   = {1'b0,osd_btn};
	assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
	assign USER_OUT = 'Z;

	assign AUDIO_S = 1;
	assign AUDIO_MIX = 0;
	assign HDMI_FREEZE = 0;
	assign VGA_DISABLE = 0;
	
	assign LED_DISK  = 0;
	assign LED_POWER = 0;
	assign LED_USER  = 0;
	assign VGA_SCALER = 0;
	assign HDMI_BLACKOUT = 1;
	assign FB_FORCE_BLANK = 0;
	


	///////////////////////////////////////////////////
	//
	// Status Bit Map:
	//             Upper                             Lower              
	// 0         1         2         3          4         5         6   	   7         8         9
	// 01234567890123456789012345678901 23456789012345678901234567890123 45678901234567890123456789012345
	// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
	// XXXXXXXXX                        X
	
	`include "build_id.v"
	localparam CONF_STR = {
		"Arcade-PsikyoSH2;;",
		"FS1,BIN,Load bios;",
		"FS2,BIN,Load cartridge;",
		"-;",
//		"O[32],Debug mode,Off,On;",
//		"-;",
		
		"P1,Audio & Video;",
		"P1O[2:1],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
		"P1O[4:3],Rotate,No,CCW,CW;",
		"P1O[5],Flip 180,Off,On;",
		"P1O[8:6],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer,HV-Integer;",

//		"P2,Input;",

		"R0,Reset;",
		"J1,B1,B2,B3,B4,Start,Coin,Test,Service;",
		"V,v",`BUILD_DATE
	};

	wire [127:0] status;
	wire [ 15:0] menumask;
	wire [  1:0] buttons;
	wire [ 13:0] joystick_0,joystick_1,joystick_2,joystick_3,joystick_4;
	wire [  7:0] joy0_x0,joy0_y0,joy0_x1,joy0_y1,joy1_x0,joy1_y0,joy1_x1,joy1_y1;
	wire         ioctl_download,ioctl_upload;
	wire         ioctl_upload_req;
	wire         ioctl_wr,ioctl_rd;
	wire [ 25:0] ioctl_addr;
	wire [ 15:0] ioctl_data,ioctl_din;
	wire [  7:0] ioctl_index;
	reg          ioctl_wait = 0;
	
	reg  [ 31:0] sd_lba = '0;
	reg          sd_rd = 0;
	reg          sd_wr = 0;
	wire         sd_ack;
	wire [  7:0] sd_buff_addr;
	wire [ 15:0] sd_buff_dout;
	wire [ 15:0] sd_buff_din0;
	wire [ 15:0] sd_buff_din;
	wire         sd_buff_wr;
	wire [  1:0] img_mounted;
	wire         img_readonly;
	wire [ 63:0] img_size;
	
	wire         forced_scandoubler;
	wire         new_vmode = 0;
	wire [ 10:0] ps2_key;
	wire [ 24:0] ps2_mouse;
	wire [ 15:0] ps2_mouse_ext;
	
	wire [ 64:0] RTC;
	
	wire [ 35:0] EXT_BUS;
	
	wire [ 21:0] gamma_bus;
	wire [ 15:0] sdram_sz;
	
	hps_io #(.CONF_STR(CONF_STR), .WIDE(1)) hps_io
	(
		.clk_sys(clk_sys),
		.HPS_BUS(HPS_BUS),
	
		.joystick_0(joystick_0),
		.joystick_1(joystick_1),
		.joystick_2(joystick_2),
		.joystick_3(joystick_3),
		.joystick_4(joystick_4),
		.joystick_l_analog_0({joy0_y0, joy0_x0}),
		.joystick_l_analog_1({joy1_y0, joy1_x0}),
		.joystick_r_analog_0({joy0_y1, joy0_x1}),
		.joystick_r_analog_1({joy1_y1, joy1_x1}),
	
		.buttons(buttons),
		.forced_scandoubler(forced_scandoubler),
		.new_vmode(new_vmode),
	
		.status(status),
		.status_in(status),
		.status_set(0),
		.status_menumask(menumask),
	
		.ioctl_download(ioctl_download),
		.ioctl_index(ioctl_index),
		.ioctl_upload(ioctl_upload),
		.ioctl_upload_req(ioctl_upload_req),
		.ioctl_upload_index(8'h04),
		.ioctl_addr(ioctl_addr),
		.ioctl_dout(ioctl_data),
		.ioctl_din(ioctl_din),
		.ioctl_wr(ioctl_wr),
		.ioctl_rd(ioctl_rd),
		.ioctl_wait(ioctl_wait),
	
		.sd_lba('{sd_lba}),
		.sd_rd(sd_rd),
		.sd_wr(sd_wr),
		.sd_ack(sd_ack),
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din('{sd_buff_din}),
		.sd_buff_wr(sd_buff_wr),
		.img_mounted(img_mounted),
		.img_readonly(img_readonly),
		.img_size(img_size),
	
		.gamma_bus(gamma_bus),
		.sdram_sz(sdram_sz),
	
		.ps2_key(ps2_key),
		.ps2_mouse(ps2_mouse),
		.ps2_mouse_ext(ps2_mouse_ext),
		
		.RTC(RTC),
	
		.EXT_BUS(EXT_BUS)
	);
	
	assign menumask = '0;
	
	wire eep_download = ioctl_download & (ioctl_index[5:2] == 4'b0000 && ioctl_index[1:0] == 2'h0);
	wire bios_download = ioctl_download & (ioctl_index[5:2] == 4'b0000 && ioctl_index[1:0] == 2'h1);
	wire cart_download = ioctl_download & (ioctl_index[5:2] == 4'b0000 && ioctl_index[1:0] == 2'h2);
	wire save_download = ioctl_download & (ioctl_index[5:2] == 4'b0001);
	wire save_upload = ioctl_upload & (ioctl_index[5:2] == 4'b0001);
	
	reg osd_btn = 0;

	///////////////////////////////////////////////////
	wire clk_sys, clk_ram, locked;
	pll pll
	(
		.refclk(CLK_50M),
		.rst(0),
		.outclk_0(clk_sys),
		.outclk_1(clk_ram),
		.locked(locked)
	);
	
	wire reset = RESET | status[0] | buttons[1];
	
	reg rst_ram = 0;
	reg download;
	always @(posedge clk_sys) begin
		reg [7:0] delay_cnt;
		
		download <= bios_download || cart_download;
		if (delay_cnt) delay_cnt <= delay_cnt - 8'd1;
		else rst_ram <= 0;
		
		if ((!bios_download && !cart_download && download) || reset) begin
			rst_ram <= 1;
			delay_cnt <= '1;
		end
	end
	
	//[1:0] - ver: 0-PS3,1-PS5
	//[2] - debug mode
	reg  [7:0] BOARD_VER = 8'h01;
	always @(posedge clk_sys) begin
		if (eep_download && ioctl_wr && ioctl_addr[8:0] == 9'h100) begin
			BOARD_VER <= ioctl_data[7:0];
		end
	end
	
	wire rst_sys = reset | download | rst_ram;

	wire [7:0] joy1 = ~{joystick_0[3],joystick_0[2],joystick_0[0],joystick_0[1],joystick_0[4],joystick_0[5],joystick_0[6],joystick_0[8]};
	wire [7:0] joy2 = ~{joystick_1[3],joystick_1[2],joystick_1[0],joystick_1[1],joystick_1[4],joystick_1[5],joystick_1[6],joystick_1[8]};
	wire [7:0] joy3 = ~{joystick_0[6],joystick_0[7],2'b00,joystick_1[6],joystick_1[7],2'b00};
	
	wire [19: 1] ROM_A;
	wire [31: 0] ROM_D;
	wire         PROM_CE_N;
	wire         DROM_CE_N;
	wire         ROM_OE_N;
	
	wire [19: 2] DRAM_A;
	wire [31: 0] DRAM_DI;
	wire [31: 0] DRAM_DO;
	wire [ 3: 0] DRAM_WE_N;
	wire         DRAM_RD_N;
	wire         DRAM_CE_N;
	
	wire         MEM_WAIT_N;
	
	wire [24: 0] GFX_ROM_A;
	wire [31: 0] GFX_ROM_D;
	wire         GFX_ROM_RD_N;
	
	wire [21: 0] SOUND_ROM_A;
	wire [ 7: 0] SOUND_ROM_D;
	wire         SOUND_ROM_RD_N;
	
	wire [ 6: 0] EEP_MEM_A;
	wire [15: 0] EEP_MEM_DI;
	wire         EEP_MEM_WREN;
	wire [15: 0] EEP_MEM_DO;
	
	wire [ 7: 0] R, G, B;
	wire         HS_N,VS_N;
	wire         DCLK;
	wire         HBL_N, VBL_N;
	wire         DCE_R;
	wire         V240;
	wire [15: 0] SOUND_L;
	wire [15: 0] SOUND_R;
	
	PSH2 #("") psh2
	(
		.CLK(clk_sys),
		.RST_N(~rst_sys),
		.EN(1'b1),
		
		.CE(1'b1),
		
		.RES_N(~status[0]),
		
		.ROM_A(ROM_A),
		.ROM_D(ROM_D),
		.PROM_CE_N(PROM_CE_N),
		.DROM_CE_N(DROM_CE_N),
		.ROM_OE_N(ROM_OE_N),
		
		.DRAM_A(DRAM_A),
		.DRAM_DI(DRAM_DI),
		.DRAM_DO(DRAM_DO),
		.DRAM_WE_N(DRAM_WE_N),
		.DRAM_RD_N(DRAM_RD_N),
		.DRAM_CE_N(DRAM_CE_N),
		
		.MEM_WAIT_N(MEM_WAIT_N),
		
		.GFX_ROM_A(GFX_ROM_A),
		.GFX_ROM_D(GFX_ROM_D),
		.GFX_ROM_RD_N(GFX_ROM_RD_N),
		
		.SOUND_ROM_A(SOUND_ROM_A),
		.SOUND_ROM_D(SOUND_ROM_D),
		.SOUND_ROM_RD_N(SOUND_ROM_RD_N),
		
		.EEP_MEM_A(ioctl_addr[7:1]),
		.EEP_MEM_DI(ioctl_data),
		.EEP_MEM_WREN(eep_download & ~ioctl_addr[8] & ioctl_wr),
		.EEP_MEM_DO(EEP_MEM_DO),
		
		.R(R),
		.G(G),
		.B(B),
		.DCLK(DCLK),
		.VS_N(VS_N),
		.HS_N(HS_N),
		.HBL_N(HBL_N),
		.VBL_N(VBL_N),
		.V240(V240),
		
		.SOUND_L(SOUND_L),
		.SOUND_R(SOUND_R),
		
		.P1(joy1),
		.P2(joy2),
		.P3(joy3),
		.P4(~{1'b0,BOARD_VER[2],joystick_0[9],joystick_0[10],2'b11,joystick_1[8],joystick_0[8]}),
		
		.VER(BOARD_VER[1:0]),
		
		.SCRN_EN(SCRN_EN),
		.SND_EN(SND_EN)
		
`ifdef DEBUG
		,
		.DBG_PAUSE(DBG_BREAK)
`endif
	);

	assign AUDIO_L = SOUND_L;
	assign AUDIO_R = SOUND_R;

	
	//ROM (GFX-0x0000000..0x3C00000,Sound-0x3C00000..0x3FFFFFF)
	wire [31:0] sdr1_dout1;
	wire [15:0] sdr1_dout2;
	sdram1 sdram1
	(
		.SDRAM_CLK(SDRAM_CLK),
		.SDRAM_A(SDRAM_A),
		.SDRAM_BA(SDRAM_BA),
		.SDRAM_DQ(SDRAM_DQ),
		.SDRAM_DQML(SDRAM_DQML),
		.SDRAM_DQMH(SDRAM_DQMH),
		.SDRAM_nCS(SDRAM_nCS),
		.SDRAM_nWE(SDRAM_nWE),
		.SDRAM_nRAS(SDRAM_nRAS),
		.SDRAM_nCAS(SDRAM_nCAS),
		.SDRAM_CKE(SDRAM_CKE),
		
		.clk(clk_ram),
		.init(status[0]),
		.sync(cart_download ? ioctl_wr : DCLK),
	
		.waddr(ioctl_addr[25:1]),
		.wr  (cart_download),
		.din (ioctl_data),
		
		.raddr1({GFX_ROM_A[23:0],1'b0}),
		.rd1 (~GFX_ROM_RD_N),
		.dout1(sdr1_dout1),
		
		.raddr2(SOUND_ROM_A[21:1]),
		.rd2 (~SOUND_ROM_RD_N),
		.dout2(sdr1_dout2)
	);
	assign GFX_ROM_D = sdr1_dout1;
	assign SOUND_ROM_D = SOUND_ROM_A[0] ? sdr1_dout2[15:8] : sdr1_dout2[7:0];

	//Prog/Data ROM, DRAM
	always @(posedge clk_sys) begin
		ioctl_wait <= (bios_download && bios_busy);
	end
	
	wire [15:0] drom_do;
	wire [31:0] dram_do,prom_do;
	wire        dram_busy,prom_busy,drom_busy,bios_busy;
	ddram ddram
	(
		.*,
		.clk(clk_ram),
		.rst(reset || rst_ram),
		
		//CPU bus (DRAM)
		.dram_addr(DRAM_A[19:2]),
		.dram_din (DRAM_DO),
		.dram_wr  (~{4{DRAM_CE_N}} & ~DRAM_WE_N),
		.dram_rd  (~DRAM_CE_N & ~DRAM_RD_N),
		.dram_dout(dram_do),
		.dram_busy(dram_busy),
	
		//CPU bus (PROG ROM)
		.prom_addr(ROM_A[19:2]),
		.prom_rd  (~PROM_CE_N & ~ROM_OE_N),
		.prom_dout(prom_do),
		.prom_busy(prom_busy),
	
		//CPU bus (DATA ROM)
		.drom_addr(ROM_A[19:1]),
		.drom_rd  (~DROM_CE_N & ~ROM_OE_N),
		.drom_dout(drom_do),
		.drom_busy(drom_busy),
	
		//BIOS/CART load
		.bios_addr({6'b000000,ioctl_addr[20:1]}),
		.bios_din ({ioctl_data[7:0],ioctl_data[15:8]}),
		.bios_wr  ({2{bios_download & ioctl_wr}}),
		.bios_busy(bios_busy),
	
		//FB
		.fb_addr(fb_addr),
		.fb_din (fb_data),
		.fb_we  ({8{fb_we}}&fb_be),
		.fb_busy(fb_busy)
	);

	assign DRAM_DI = dram_do;
	assign ROM_D = !PROM_CE_N ? prom_do : {16'h0000,drom_do};
	assign MEM_WAIT_N = !DRAM_CE_N ? ~dram_busy : 
							  !PROM_CE_N ? ~prom_busy : ~drom_busy;

/////////////////////////  Video  /////////////////////////////	
	assign VGA_F1 = 0;
	assign VGA_SL = '0;

	reg DCLK_old;
	always @(posedge clk_sys) begin
		DCLK_old <= DCLK;
	end
	wire ce_pix = DCLK & ~DCLK_old;

	assign CLK_VIDEO = clk_sys;
	assign CE_PIXEL = ce_pix;
	assign {VGA_R,VGA_G,VGA_B} = {R,G,B};
	assign VGA_HS = ~HS_N;
	assign VGA_VS = ~VS_N;
	wire vga_de = ~(~VBL_N | ~HBL_N);
	
	wire [1:0] ar = status[2:1];
	wire [1:0] rotate_sel = status[4:3];
	wire       rotate_en  = (rotate_sel != 2'd0);
	wire       rotate_ccw = (rotate_sel == 2'd1);
	wire       flip_180   = status[5];
	wire [2:0] scale = status[8:6];
	
	wire [11:0] orig_arx = (!V240 ? 12'd4 : 12'd10);
	wire [11:0] orig_ary = (!V240 ? 12'd3 : 12'd7);
	wire [11:0] arx = (!ar) ? (rotate_en ? orig_ary : orig_arx) : (ar - 1'd1);
	wire [11:0] ary = (!ar) ? (rotate_en ? orig_arx : orig_ary) : 12'd0;
	
	video_freak video_freak
	(
		.CLK_VIDEO(CLK_VIDEO),
		.CE_PIXEL(CE_PIXEL),
		.VGA_VS(VGA_VS),
		.HDMI_WIDTH(HDMI_WIDTH),
		.HDMI_HEIGHT(HDMI_HEIGHT),
		.VGA_DE(VGA_DE),
		.VIDEO_ARX(VIDEO_ARX),
		.VIDEO_ARY(VIDEO_ARY),
		.VGA_DE_IN(vga_de),
		.ARX(arx),
		.ARY(ary),
		.CROP_SIZE(12'd0),
		.CROP_OFF(5'd0),
		.SCALE(scale) 
	);
	
	wire [31: 3] fb_addr;
	wire [63: 0] fb_data;
	wire         fb_we;
	wire [ 7: 0] fb_be;
	wire         fb_busy;
	screen_rotate screen_rotate
	(
		.CLK_VIDEO     (CLK_VIDEO),
		.CE_PIXEL      (CE_PIXEL),

		.VGA_R         (VGA_R),
		.VGA_G         (VGA_G),
		.VGA_B         (VGA_B),
		.VGA_HS        (VGA_HS),
		.VGA_VS        (VGA_VS),
		.VGA_DE        (vga_de),

		.rotate_ccw    (rotate_ccw),
		.no_rotate     (~rotate_en),
		.flip          (flip_180),
		.video_rotated (),

		.FB_EN         (FB_EN),
		.FB_FORMAT     (FB_FORMAT),
		.FB_WIDTH      (FB_WIDTH),
		.FB_HEIGHT     (FB_HEIGHT),
		.FB_BASE       (FB_BASE),
		.FB_STRIDE     (FB_STRIDE),
		.FB_VBL        (FB_VBL),
		.FB_LL         (FB_LL),

		.DDRAM_CLK     (),
		.DDRAM_BUSY    (fb_busy),
		.DDRAM_BURSTCNT(),
		.DDRAM_ADDR    (fb_addr),
		.DDRAM_DIN     (fb_data),
		.DDRAM_BE      (fb_be),
		.DDRAM_WE      (fb_we),
		.DDRAM_RD      ()
	);

//	video_mixer #(.LINE_LENGTH(320), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
//	(
//		.*,
//	
//		.ce_pix(ce_pix),	
//		.scandoubler(scandoubler),
//		.hq2x(hq2x),	
//		.freeze_sync(),
//	
//		.VGA_DE(vga_de),
//		.R(R),
//		.G(G),
//		.B(B),
//	
//		// Positive pulses.
//		.HSync(~HS_N), 
//		.VSync(~VS_N),  
//		.HBlank(~HBL_N),
//		.VBlank(~VBL_N) 
//	);
	
	//debug
	reg  [ 5: 0] SCRN_EN = 6'b111111;
	reg  [ 2: 0] SND_EN = 3'b111;
	reg          DBG_PAUSE = 0;
	reg          DBG_BREAK = 0;
	reg          DBG_RUN = 0;
	
	reg  [ 7: 0] DBG_EXT = '0;
`ifdef DEBUG
	
	wire         pressed = ps2_key[9];
	wire [ 8: 0] code    = ps2_key[8:0];
	always @(posedge clk_sys) begin
		reg old_state = 0, VBL_N_OLD;
		
		VBL_N_OLD <= VBL_N;
		
		if (VBL_N && !VBL_N_OLD) begin
			if (DBG_PAUSE && !DBG_BREAK) DBG_BREAK <= 1;
			else if ((DBG_RUN || !DBG_PAUSE) && DBG_BREAK) DBG_BREAK <= 0;
			DBG_RUN <= 0;
		end
		
		DBG_EXT <= '0;
		
		old_state <= ps2_key[10];
		if((ps2_key[10] != old_state) && pressed) begin
			casex(code)
				'h005: begin SCRN_EN[0] <= ~SCRN_EN[0]; end 	// F1
				'h006: begin SCRN_EN[1] <= ~SCRN_EN[1]; end 	// F2
				'h004: begin SCRN_EN[2] <= ~SCRN_EN[2]; end 	// F3
				'h00C: begin SCRN_EN[3] <= ~SCRN_EN[3]; end 	// F4
				'h003: begin SCRN_EN[4] <= ~SCRN_EN[4]; end 	// F5
				'h00B: begin SCRN_EN[5] <= ~SCRN_EN[5]; end 	// F6
				'h083: begin SND_EN[0] <= ~SND_EN[0]; end 	// F7
				'h00A: begin SND_EN[1] <= ~SND_EN[1]; end 	// F8
				'h001: begin SND_EN[2] <= ~SND_EN[2]; end 	// F9
				'h009: begin SCRN_EN <= '1; SND_EN <= '1; DBG_EXT <= '0; end 	// F10
//				'h078: begin DBG_BREAK <= ~DBG_BREAK; end 	// F11
				'h078: begin DBG_RUN <= 1; end 	// F11
				'h177: begin DBG_PAUSE <= ~DBG_PAUSE; end 	// Pause
			endcase
		end
		
		if(pressed) begin
			casex(code)
				'h016: begin DBG_EXT[0] <= 1; end 	// 1
				'h01E: begin DBG_EXT[1] <= 1; end 	// 2
				'h026: begin DBG_EXT[2] <= 1; end 	// 3
				'h025: begin DBG_EXT[3] <= 1; end 	// 4
				'h02E: begin DBG_EXT[4] <= 1; end 	// 5
				'h036: begin DBG_EXT[5] <= 1; end 	// 6
				'h03D: begin DBG_EXT[6] <= 1; end 	// 7
				'h03E: begin DBG_EXT[7] <= 1; end 	// 8
				default:;
			endcase
		end
	end
`endif

endmodule
