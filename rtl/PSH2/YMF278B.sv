// synopsys translate_off
`define SIM
// synopsys translate_on

module YMF278B
(
	input              CLK,
	input              RST_N,
	input              EN,
	
	input              CE,
	
	input      [ 2: 0] A,
	input      [ 7: 0] DI,
	output     [ 7: 0] DO,
	input              RD_N,
	input              WR_N,
	input              CS_N,
	input              IC_N,
	
	output             IRQ_N,
	
	output     [20: 0] MA,
	input      [ 7: 0] MDI,
	output     [ 7: 0] MDO,
	output             MRD_N,
	output             MWR_N,
	output     [ 9: 0] MCS_N,
	
	output     [15: 0] OUT0_L,
	output     [15: 0] OUT0_R,
	output     [15: 0] OUT1_L,
	output     [15: 0] OUT1_R,
	output     [15: 0] OUT2_L,
	output     [15: 0] OUT2_R,
	
	input      [ 2: 0] SND_EN
	
`ifdef DEBUG
                      ,
	output             ATTACK_DBG,
	output             DECAY1_DBG,
	output             DECAY2_DBG,
	output             RELEASE_DBG,
	output signed [15:0] LVL_DBG,
	output signed [15:0] PAN_L_DBG,
	output signed [15:0] PAN_R_DBG
`endif
);

	import YMF278B_PKG::*;
	
	bit          NEW2;
	bit  [ 7: 0] TEST0;
	bit  [ 7: 0] TEST1;
	bit  [ 4: 0] MEMMODE;
	bit  [21: 0] MEMADDR;
	bit  [ 7: 0] MEMDAT;
	bit  [ 5: 0] MIXFM;
	bit  [ 5: 0] MIXPCM;
	bit          LD,LD2,BUSY;

	OP2_t        OP2;
	OP3_t        OP3;
	OP4_t        OP4;
	OP5_t        OP5;
	OP6_t        OP6;
	OP7_t        OP7;
		
	bit  [21: 0] WD_ADDR;
	bit          WD_READ;
	
	bit  [21: 0] MEM_A;
	bit  [ 7: 0] MEM_D;
	bit  [ 7: 0] MEM_Q;
	bit          MEM_WR;
	bit          MEM_RD;
	
	bit  [ 7: 0] REG_A;
	bit  [ 7: 0] REG_D;
	bit  [ 7: 0] REG_Q;
	bit          REG_WR;
	bit          REG_RD;
	
	wire         RES_N = IC_N;
	
	bit  [ 1: 0] CLK_DIV;
	bit  [ 2: 0] CYCLE_NUM;
	always @(posedge CLK) begin
		if (CE) begin
			CLK_DIV <= CLK_DIV + 2'd1;
			if (CLK_DIV == 2'd3) 
				CYCLE_NUM <= CYCLE_NUM + 3'd1;
		end 
	end
	
	wire SLOT0_EN = (CYCLE_NUM[2:1] == 2'b01);
	wire SLOT1_EN = (CYCLE_NUM[2:1] == 2'b11);
	
	wire CYCLE0_CE = ~CYCLE_NUM[0] & CLK_DIV == 2'd3 & CE;
	wire CYCLE1_CE =  CYCLE_NUM[0] & CLK_DIV == 2'd3 & CE;
	wire SLOT0_CE = SLOT0_EN & CYCLE1_CE;
	wire SLOT1_CE = SLOT1_EN & CYCLE1_CE;
		
	bit  [ 4: 0] EVOL_RA,AM_RA,SA_RA,FNUM_RA,LFO_RA;
	always_comb begin
		casex (CYCLE_NUM[2:1])
			2'b0x: begin
				SA_RA = OP2.SLOT;//OP2
				FNUM_RA = SLOT;//OP1
				AM_RA = SLOT;//OP1
				EVOL_RA = OP2.SLOT;//OP2
				LFO_RA = SLOT;//OP1
			end
			2'b1x: begin
				SA_RA = OP2.SLOT;//OP2
				FNUM_RA = OP4.SLOT;//OP4
				AM_RA = OP4.SLOT;//OP4
				EVOL_RA = OP4.SLOT;//OP4
				LFO_RA = OP4.SLOT;//OP4
			end
		endcase
	end
	
	//Operation 1: PLFO, PG, KEY ON/OFF
	bit          REG_KB[24],REG_LOAD[24];
	bit  [ 4: 0] SLOT;
	bit          RST;
	bit  [ 3: 0] OP1_OCT;
	bit          OP1_PREVERB;
	bit  [ 9: 0] OP1_FNUM;
	bit  [ 2: 0] OP1_LFO,OP1_VIB;
	bit          OP1_LFORST;
	bit  [ 8: 0] OP1_WTN;
	bit  [ 3: 0] OP1_LOAD_POS;
	always @(posedge CLK or negedge RST_N) begin
		bit  [ 9: 0] OP1_LFO_DIV;
		bit  [ 7: 0] OP1_LFO_DATA;
		bit          REG_KB_OLD[24];
		bit  [ 7: 0] PLFO_WAVE;
		bit  [22: 0] PHASE;
		bit  [ 7: 0] NEW_LFO_DATA;
		bit  [ 9: 0] NEW_LFO_DIV;
		bit  [ 3: 0] NEW_LOAD_POS;
		
		if (!RST_N) begin
			// synopsys translate_off
			{OP1_OCT,OP1_FNUM} <= '0;
			{OP1_LFO,OP1_VIB} <= '0;
			OP1_LFORST <= 0;
			OP1_WTN <= '0;
			REG_KB <= '{24{0}};
			REG_KB_OLD <= '{24{0}};
			REG_LOAD <= '{24{0}};
			SLOT <= '0;
			RST <= 1;
			// synopsys translate_on
			OP2 <= OP2_RESET;
		end else if (!RES_N) begin
			{OP1_OCT,OP1_FNUM} <= '0;
			{OP1_LFO,OP1_VIB} <= '0;
			OP1_LFORST <= 0;
			OP1_WTN <= '0;
			REG_KB <= '{24{0}};
			REG_KB_OLD <= '{24{0}};
			REG_LOAD <= '{24{0}};
			SLOT <= '0;
			RST <= 1;
			OP2 <= OP2_RESET;
		end else begin
			if (CYCLE0_CE) begin
				case (CYCLE_NUM[2:1])
					2'b00: begin
						{OP1_OCT,OP1_PREVERB,OP1_FNUM} <= REG_FNUM_Q[15:1];
						{OP1_LFO,OP1_VIB} <= REG_LFO_Q[5:0];
						OP1_LFORST <= REG_PAN_Q[5];
						OP1_WTN <= {REG_FNUM_Q[0],REG_WTN_Q};
						{OP1_LOAD_POS,OP1_LFO_DIV,OP1_LFO_DATA} <= LFO_RAM_Q;
					end
				endcase
			end
			
			//Key on/off, header load
			if (CYCLE1_CE) begin
				if (REG_PAN_SEL && REG_WR) begin
					REG_KB[REG_A[4:0] - 5'h8] <= REG_D[7];
				end
				if (REG_WTN_SEL && REG_WR) begin
					REG_LOAD[REG_A[4:0] - 5'h8] <= 1;
				end
			end
			if (SLOT1_CE) begin
				KEY_RAM_D[1:0] <= '0;
				if (REG_KB[SLOT] && !REG_KB_OLD[SLOT]) begin
					KEY_RAM_D[0] <= 1;
				end
				if (!REG_KB[SLOT] && REG_KB_OLD[SLOT]) begin
					KEY_RAM_D[1] <= 1;
				end
				REG_KB_OLD[SLOT] <= REG_KB[SLOT];
				
				if (REG_LOAD[SLOT]) REG_LOAD[SLOT] <= 0;
			end
			
			PLFO_WAVE <= VIBCalc(OP1_LFO_DATA, OP1_VIB);
			PHASE = PhaseCalc(OP1_FNUM, OP1_OCT, PLFO_WAVE);
			
			if (SLOT1_CE) begin
				OP2.SLOT <= SLOT;
				OP2.RST <= RST;
				OP2.KON <= KEY_RAM_Q[0];
				OP2.KOFF <= KEY_RAM_Q[1];
				OP2.LOAD <= KEY_RAM_Q[2];
				OP2.PHASE <= PHASE;
				OP2.WTN <= OP1_WTN;
				OP2.LOAD_POS <= OP1_LOAD_POS;

				SLOT <= SLOT + 5'd1;
				if (SLOT == 5'd23) begin
					SLOT <= '0;
					RST <= 0;
				end
			end
			
			//LFO
			if (SLOT1_CE) begin				
				if (!OP1_LFO_DIV) begin
					NEW_LFO_DIV = LFOFreqDiv(OP1_LFO);
					NEW_LFO_DATA = OP1_LFO_DATA + 8'd1;
				end else begin
					NEW_LFO_DIV = OP1_LFO_DIV - 10'd1;
					NEW_LFO_DATA = OP1_LFO_DATA;
				end
				if (OP1_LFORST) begin
					NEW_LFO_DIV = '0;
					NEW_LFO_DATA = '0;
				end
				
				if (KEY_RAM_Q[2])
					NEW_LOAD_POS = OP1_LOAD_POS + 4'd1;
				else
					NEW_LOAD_POS = '0;
				
				KEY_RAM_D[2] <= KEY_RAM_Q[2];
				if (NEW_LOAD_POS == 4'd12) KEY_RAM_D[2] <= 0;
				else if (REG_LOAD[SLOT]) KEY_RAM_D[2] <= 1;
				
				LFO_RAM_D <= {NEW_LOAD_POS,NEW_LFO_DIV,NEW_LFO_DATA};
			end
		end
	end
	
	bit  [ 2:0] KEY_RAM_D;
	bit  [ 2:0] KEY_RAM_Q;
	OPL4_KEY_RAM KEY_RAM(CLK, OP2.SLOT, KEY_RAM_D, SLOT1_CE, SLOT, KEY_RAM_Q);
	
	bit  [21:0] LFO_RAM_D;
	bit  [21:0] LFO_RAM_Q;
	OPL4_LFO_RAM LFO_RAM(CLK, OP2.SLOT, LFO_RAM_D, SLOT1_CE, LFO_RA, LFO_RAM_Q);

	
	//Operation 2: MD read, ADP
	bit  [ 1: 0] OP2_DATA_BIT;
	bit  [21: 0] OP2_SA;
	bit  [15: 0] OP2_LA;
	bit  [15: 0] OP2_EA;
//	SCR4_t       OP2_SCR4;
	
	always @(posedge CLK or negedge RST_N) begin
		EGState_t    OP2_EST;	//Current envelope state
		bit  [ 9: 0] OP2_EVOL;	//Current envelope volume
		bit  [ 8: 0] PHASE_INT;	//New phase integer
		bit  [13: 0] PHASE_FRAC;	//New phase fractional
		bit  [13: 0] CUR_PHASE_FRAC;//Current phase fractional
		bit  [15: 0] CUR_SO;		//Sample offset integer
		bit          CUR_SALOOP;//Sample address loop state
		bit  [15: 0] CALC_SO;
		bit  [15: 0] NEW_SAO;
		bit          NEW_SALOOP;
		bit          COMP;
		bit          ALLOW;
		
		if (!RST_N) begin
			// synopsys translate_off
			OP3 <= OP3_RESET;
			OP2_DATA_BIT <= '0;
			OP2_SA <= '0;
			OP2_LA <= '0;
			OP2_EA <= '0;
			WD_READ <= 0;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP3 <= OP3_RESET;
			OP2_DATA_BIT <= '0;
			OP2_SA <= '0;
			OP2_LA <= '0;
			OP2_EA <= '0;
			WD_READ <= 0;
		end else begin
			if (CYCLE0_CE) begin
				{OP2_DATA_BIT,OP2_SA} <= OP2.LOAD ? {2'b00 ,{10'b0000000000,OP2.WTN,3'b000} + {11'b00000000000,OP2.WTN,2'b00}} + OP2.LOAD_POS : REG_SA_Q;
				OP2_LA <= REG_LA_Q - 16'd1;
				OP2_EA <= ~(REG_EA_Q);
				case (CYCLE_NUM[2:1])
					2'b00: begin
						{OP2_EST,OP2_EVOL} <= EVOL_RAM_Q;
					end
				endcase
			end
		
			{CUR_SALOOP,CUR_SO} = OP2.KON ? '0 : SO_RAM_Q;
			COMP = ((CUR_SO /*+ 16'd1*/) > (/*!CUR_SALOOP ? OP2_LA :*/ OP2_EA));
			
			CUR_PHASE_FRAC = OP2.KON ? '0 : PHASE_FRAC_RAM_Q;
						
			ALLOW = 1;
			if (SLOT1_CE) begin
				//Sample offset
				if (OP2.RST || OP2.LOAD) begin
					{NEW_SALOOP,NEW_SAO} = '0;
					ALLOW = 0;
				end else if (OP2_EVOL >= 10'h3C0 && !OP2.KON) begin
					{NEW_SALOOP,NEW_SAO} = '0;
					ALLOW = 0;
				end else begin
					{NEW_SALOOP,NEW_SAO} = {CUR_SALOOP,CUR_SO};

//					if (!CUR_SALOOP) begin
//						if (COMP) begin
//							NEW_SALOOP = 1;
//						end
//					end else begin
						if (COMP) begin
							NEW_SAO = CUR_SO + (OP2_LA - OP2_EA);
						end
//					end
				end
				
				//Phase accum
				if (OP2.RST || OP2.LOAD)
					{PHASE_INT,PHASE_FRAC} = '0;
				else
					{PHASE_INT,PHASE_FRAC} = {9'b000000000,CUR_PHASE_FRAC} + OP2.PHASE;
				
				CALC_SO = NEW_SAO + {7'b0000000,PHASE_INT};
				SO_RAM_D <= {NEW_SALOOP,CALC_SO};
				
				OP3.SLOT <= OP2.SLOT;
				OP3.RST <= OP2.RST;
				OP3.KON <= OP2.KON;
				OP3.KOFF <= OP2.KOFF;
				OP3.LOAD <= OP2.LOAD;
				OP3.LOAD_POS <= OP2.LOAD_POS;
				OP3.ALLOW <= ALLOW;
				OP3.LOOP <= CUR_SALOOP;
				OP3.SO <= NEW_SAO;
//				OP3.MOD <= MDCalc(SOUSX, SOUSY, OP2_SCR4.MDL);
				OP3.PHASE_FRAC <= CUR_PHASE_FRAC;
				
				WD_SA <= OP2_SA;
				WD_DATA_LEN <= OP2_DATA_BIT;
				WD_READ <= ALLOW | OP2.LOAD;
				
				PHASE_FRAC_RAM_D <= ALLOW ? PHASE_FRAC : '0;
			end
		end
	end
	bit [16:0] SO_RAM_D;
	bit [16:0] SO_RAM_Q;
	OPL4_SO_RAM SO_RAM(CLK, OP3.SLOT, SO_RAM_D, SLOT1_CE, OP2.SLOT, SO_RAM_Q);
	
	bit  [13:0] PHASE_FRAC_RAM_D;
	bit  [13:0] PHASE_FRAC_RAM_Q;
	OPL4_PHASE_RAM PHASE_FRAC_RAM(CLK, OP3.SLOT, PHASE_FRAC_RAM_D, SLOT1_CE, OP2.SLOT, PHASE_FRAC_RAM_Q);
	
	//Operation 3:  
	bit  [21: 0] WD_SA;
	bit  [ 1: 0] WD_DATA_LEN;
	
	wire [21: 0] MOD_PHASE_CURR = /*OP3.MOD +*/ {16'h0000,OP3.PHASE_FRAC[13:8]};
	wire [15: 0] MOD_PHASE_INTEGER = MOD_PHASE_CURR[21:6];
	wire [16: 0] SO_MOD = {1'b0,OP3.SO + (!CYCLE_NUM[2] ? 16'd0 : 16'd1)} /*+ {MOD_PHASE_INTEGER[15],MOD_PHASE_INTEGER}*/;
	wire [21: 0] SO_MOD_BY_1 = {{5{SO_MOD[16]}},SO_MOD};
	wire [21: 0] SO_MOD_BY_1_5 = {{5{SO_MOD[16]}},SO_MOD} + {{6{SO_MOD[16]}},SO_MOD[16:1]};
	wire [21: 0] SO_MOD_BY_2 = {{4{SO_MOD[16]}},SO_MOD,1'b0};
	wire [21: 0] WD_OFFS = WD_DATA_LEN == 2'h0 ? SO_MOD_BY_1 : WD_DATA_LEN == 2'h1 ? SO_MOD_BY_1_5 : SO_MOD_BY_2;
	assign WD_ADDR = WD_SA + WD_OFFS + (!CYCLE_NUM[1] ? 16'd0 : 16'd1);
	
	always @(posedge CLK or negedge RST_N) begin
		bit  [15: 0] WD0,WD1;
		bit          SO0_CURR,SO0_NEXT;
		
		if (!RST_N) begin
			OP4 <= OP4_RESET;
			// synopsys translate_off
			OP4_WD0 <= '0;
			OP4_WD1 <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP4 <= OP4_RESET;
			OP4_WD0 <= '0;
			OP4_WD1 <= '0;
		end else begin
			if (CYCLE1_CE) begin
				case (CYCLE_NUM[2:1])
					2'h0: begin WD0[15:8] <= MDI; SO0_CURR <= SO_MOD[0]; end
					2'h1: WD0[7:0] <= MDI;
					2'h2: begin WD1[15:8] <= MDI; SO0_NEXT <= SO_MOD[0]; end
				endcase
			end
			
			if (SLOT1_CE) begin
				OP4.SLOT <= OP3.SLOT;
				OP4.RST <= OP3.RST;
				OP4.KON <= OP3.KON;
				OP4.KOFF <= OP3.KOFF;
				OP4.LOOP <= OP3.LOOP;
				OP4.MODF <= MOD_PHASE_CURR[5:0];
				OP4_WD0 <= WD0;
				OP4_WD1 <= {WD1[15:8],MDI};
				OP4_DATA_LEN <= WD_DATA_LEN;
				OP4_SO0_CURR <= SO0_CURR;
				OP4_SO0_NEXT <= SO0_NEXT;
			end
		end
	end
	
	//Operation 4: Interpolation, EG, ALFO
	bit  [15: 0] OP4_WD0,OP4_WD1;
	bit  [ 1: 0] OP4_DATA_LEN;
	bit          OP4_SO0_CURR,OP4_SO0_NEXT;
	
	bit  [ 3: 0] OP4_AR,OP4_D1R,OP4_D2R,OP4_RR,OP4_RC,OP4_DL;
	bit  [ 3: 0] OP4_OCT;
	bit  [ 9: 0] OP4_EVOL;	//Current envelope volume
	EGState_t    OP4_EST;	//Current envelope state
	bit  [14: 0] SCNT;		//Sample counter
	bit  [14: 0] SCNT_PREV;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			SCNT <= '0;
			SCNT_PREV <= '1;
		end else if (!RES_N) begin
			SCNT <= '0;
			SCNT_PREV <= '1;
		end else begin
			if (SLOT1_CE) begin
				if (OP4.SLOT == 5'd31) begin
					SCNT_PREV <= SCNT;
					SCNT <= SCNT + 1'd1;
				end
			end
		end
	end
	
	bit  [ 4: 0] EFF_RATE;	//Effective rate
	bit          EFF_RATE_OVR;	//Effective rate over
	bit  [ 3: 0] EFF_RATE_BIT;
	bit          ENV_STEP;
	always_comb begin
		bit  [ 4: 0] RATE;
		bit  [14: 0] SCNT_EDGE;
		
		SCNT_EDGE = (SCNT ^ SCNT_PREV) & (SCNT ^ 15'h0001);
		
		case (OP4_EST)
			EST_ATTACK: RATE = OP4_AR;	
			EST_DECAY1: RATE = OP4_D1R;
			EST_DECAY2: RATE = OP4_D2R;
			EST_RELEASE: RATE = OP4_RR;
		endcase
		if (OP4_EST == EST_RELEASE && OP4.KON) begin
			RATE = OP4_AR;
		end else if (OP4_EST != EST_RELEASE && OP4.KOFF) begin
			RATE = OP4_RR;
		end
		{EFF_RATE_OVR,EFF_RATE} = EffRateCalc(RATE, OP4_RC, OP4_OCT);
		EFF_RATE_BIT = EffRateBit(EFF_RATE);
		
		if (RATE == 5'h00 || (EFF_RATE_OVR && OP4_EST == EST_ATTACK)) 
			ENV_STEP <= 0;
		else if (EFF_RATE < 5'h18 && EFF_RATE[0])
			ENV_STEP <= SCNT_EDGE[EFF_RATE_BIT+1] | SCNT_EDGE[EFF_RATE_BIT+2];
		else
			ENV_STEP = SCNT_EDGE[EFF_RATE_BIT];
	end
	
	bit  [ 7: 0] OP4_LFO_DATA;
	bit  [ 2: 0] OP4_AM;
	always @(posedge CLK or negedge RST_N) begin
		bit  [10: 0] ATTACK_VOL_CALC,DECAY_VOL_CALC;
		bit  [ 9: 0] NEW_EVOL;
		bit  [ 1: 0] NEW_EST;
		bit  [10: 0] VOL_INC_BASE;
		bit  [ 4: 0] ERMAX;
		bit  [ 5: 0] SRAC;
		bit  [15: 0] WD0,WD1;
		
		if (!RST_N) begin
			OP5 <= OP5_RESET;
			// synopsys translate_off
			{OP4_AR,OP4_D1R,OP4_D2R,OP4_RR,OP4_RC,OP4_DL} <= '0;
			OP4_OCT <= '0;
			{OP4_EST,OP4_EVOL} <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP5 <= OP5_RESET;
			{OP4_AR,OP4_D1R,OP4_D2R,OP4_RR,OP4_RC,OP4_DL} <= '0;
			OP4_OCT <= '0;
			{OP4_EST,OP4_EVOL} <= '0;
		end else begin
			if (CYCLE0_CE) begin
				{OP4_AR,OP4_D1R} <= REG_RATE0_Q;
				{OP4_DL,OP4_D2R} <= REG_RATE1_Q;
				{OP4_RC,OP4_RR} <= REG_RATE2_Q;
				OP4_AM <= REG_AM_Q[2:0];
				case (CYCLE_NUM[2:1])
					2'b10: begin
						OP4_OCT <= REG_FNUM_Q[15:12];
						{OP4_EST,OP4_EVOL} <= EVOL_RAM_Q;
						OP4_LFO_DATA <= LFO_RAM_Q[7:0];
					end
				endcase
			end
			
			ERMAX = EFF_RATE > 5'h1E ? 5'h1E : EFF_RATE < 5'h18 ? 5'h18 : EFF_RATE;
			SRAC = ((6'h20 - {1'b0,ERMAX}) >> 1) + (ERMAX[0] && SCNT[EFF_RATE_BIT + 1] ? 5'h1 : 5'h0);
`ifdef DEBUG
			if (CYCLE1_CE) begin
				DECAY1_DBG <= 0;
				DECAY2_DBG <= 0;
				ATTACK_DBG <= 0;
				RELEASE_DBG <= 0;
			end
`endif
			if (SLOT1_CE) begin
				NEW_EVOL = OP4_EVOL;
				NEW_EST = OP4_EST;
				
				ATTACK_VOL_CALC = {1'b0,OP4_EVOL} + (ENV_STEP ? $signed($signed(~{1'b0,OP4_EVOL}) >>> SRAC[4:0]) : 11'd0);
				DECAY_VOL_CALC = {1'b0,OP4_EVOL} + (ENV_STEP ? $signed(10'd16 >>> SRAC[4:0]) : 11'd0);
				if (OP4.RST) begin
					NEW_EVOL = 10'h3FF;
					NEW_EST = EST_RELEASE;
				end else if (OP4_EST == EST_RELEASE && OP4.KON) begin
					NEW_EVOL = EFF_RATE_OVR ? 10'h000 : 10'h280;
					NEW_EST = EST_ATTACK;
`ifdef DEBUG
					ATTACK_DBG <= 1;
`endif
				end else if (OP4_EST != EST_RELEASE && OP4.KOFF) begin
					NEW_EST = EST_RELEASE;
`ifdef DEBUG
					RELEASE_DBG <= 1;
`endif
				end else begin
					case (OP4_EST)
						EST_ATTACK: begin
							if (!ATTACK_VOL_CALC[10]) begin
								NEW_EVOL = ATTACK_VOL_CALC[9:0];
							end else begin
								NEW_EVOL = 10'h000;
							end
							if (!OP4_EVOL) begin
								NEW_EST = EST_DECAY1;
`ifdef DEBUG
								DECAY1_DBG <= 1;
`endif
							end
						end
						
						EST_DECAY1: begin
							if (!DECAY_VOL_CALC[10]) begin
								NEW_EVOL = DECAY_VOL_CALC[9:0];
							end else begin
								NEW_EVOL = 10'h3FF;
							end
							if (OP4_EVOL[9:6] == OP4_DL) begin
								NEW_EST = EST_DECAY2;
`ifdef DEBUG
								DECAY2_DBG <= 1;
`endif
							end
						end
						
						EST_DECAY2: begin
							if (!DECAY_VOL_CALC[10]) begin
								NEW_EVOL = DECAY_VOL_CALC[9:0];
							end else begin
								NEW_EVOL = 10'h3FF;
							end
						end
						
						EST_RELEASE: begin
							if (!DECAY_VOL_CALC[10]) begin
								NEW_EVOL = DECAY_VOL_CALC[9:0];
							end else begin
								NEW_EVOL = 10'h3FF;
							end
						end
					endcase
				end
				EVOL_RAM_D <= {NEW_EST,NEW_EVOL};
				
				OP5.SLOT <= OP4.SLOT;
				OP5.RST <= OP4.RST;
				OP5.KON <= OP4.KON;
				OP5.KOFF <= OP4.KOFF;
				OP5.EVOL <= NEW_EVOL;
				
				WD0 = OP4_DATA_LEN == 2'b00 ? {OP4_WD0[15:8],8'h00} : 
				      OP4_DATA_LEN == 2'b01 ? (!OP4_SO0_CURR ? {OP4_WD0[15:8],OP4_WD0[7:4],4'h0} : {OP4_WD0[7:0],OP4_WD0[11:8],4'h0}) : 
							                     OP4_WD0;
				WD1 = OP4_DATA_LEN == 2'b00 ? {OP4_WD1[15:8],8'h00} : 
				      OP4_DATA_LEN == 2'b01 ? (!OP4_SO0_NEXT ? {OP4_WD1[15:8],OP4_WD1[7:4],4'h0} : {OP4_WD1[7:0],OP4_WD1[11:8],4'h0}) : 
							                     OP4_WD1;
				OP5.WD <= WD0;//Interpolate(WD0, WD1, OP4.MODF);
				
				OP5.ALFO <= AMCalc(OP4_LFO_DATA, OP4_AM);
			end
		end
	end
	bit [11:0] EVOL_RAM_D;
	bit [11:0] EVOL_RAM_Q;
	OPL4_EVOL_RAM EVOL_RAM(CLK, OP5.SLOT, EVOL_RAM_D, SLOT1_CE, EVOL_RA, EVOL_RAM_Q);

	//Operation 5: Level calculation
	always @(posedge CLK or negedge RST_N) begin	
		if (!RST_N) begin
			OP6 <= OP6_RESET;
			// synopsys translate_off
			// synopsys translate_on
		end else if (!RES_N) begin
			OP6 <= OP6_RESET;
		end else begin
			if (SLOT1_CE) begin
				OP6.SLOT <= OP5.SLOT;
				OP6.RST <= OP5.RST;
				OP6.KON <= OP5.KON;
				OP6.KOFF <= OP5.KOFF;
				OP6.LEVEL <= LevelAddALFO(OP5.EVOL, OP5.ALFO);
				OP6.WD <= OP5.WD;
			end
		end
	end

	//Operation 6: Level calculation
	bit  [ 6: 0] OP6_TL;
	bit          OP6_LDIR;
	always @(posedge CLK or negedge RST_N) begin
		bit [ 9: 0] LEVEL;
		
		if (!RST_N) begin
			OP7 <= OP7_RESET;
			// synopsys translate_off
			{OP6_TL,OP6_LDIR} <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP7 <= OP7_RESET;
			{OP6_TL,OP6_LDIR} <= '0;
		end else begin
			if (CYCLE0_CE) begin
				{OP6_TL,OP6_LDIR} <= REG_LEVEL_Q;
			end
			
			LEVEL = LevelAddTL(OP6_LDIR ? 10'h0 : OP6.LEVEL, OP6_TL);
			if (SLOT1_CE) begin
				OP7.SLOT <= OP6.SLOT;
				OP7.RST <= OP6.RST;
				OP7.KON <= OP6.KON;
				OP7.KOFF <= OP6.KOFF;
				OP7.SD <= VolCalc(OP6.WD, LEVEL);
			end
		end
	end
	
	//Operation 7: 
	bit  [ 3: 0] OP7_PAN;
	bit          OP7_CH;
	bit  [17: 0] ACC_L,ACC_R;
	always @(posedge CLK or negedge RST_N) begin
		bit [ 4:0] S;
		bit signed [15:0] TEMP;
		bit signed [15:0] PAN_L,PAN_R;
		
		if (!RST_N) begin
			// synopsys translate_off
			OP7_PAN <= '0;
			ACC_L <= 0;
			ACC_R <= 0;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP7_PAN <= '0;
			ACC_L <= 0;
			ACC_R <= 0;
		end else begin
			if (CYCLE0_CE) begin
				{OP7_CH,OP7_PAN} <= REG_PAN_Q[4:0];
			end
			
			S = OP7.SLOT;
			TEMP = !OP7_CH ? OP7.SD : '0;
			PAN_L = PanLCalc(TEMP,OP7_PAN);
			PAN_R = PanRCalc(TEMP,OP7_PAN);
			
			if (SLOT1_CE) begin
				if (S == 5'd0) begin
					ACC_L <= {{2{PAN_L[15]}},PAN_L[15:0]};
					ACC_R <= {{2{PAN_R[15]}},PAN_R[15:0]};
				end else begin
					ACC_L <= ACC_L + {{2{PAN_L[15]}},PAN_L[15:0]};
					ACC_R <= ACC_R + {{2{PAN_R[15]}},PAN_R[15:0]};
				end
			end
			
`ifdef DEBUG
			LVL_DBG <= TEMP;
			PAN_L_DBG <= PAN_L;
			PAN_R_DBG <= PAN_R;
`endif
		end
	end
	
	//Out
	bit  [15: 0] PCM_L,PCM_R;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			PCM_L <= '0;
			PCM_R <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			
		end else begin
			if (OP7.SLOT == 5'd0 && CYCLE_NUM[2:1] == 2'b00 && CYCLE1_CE) begin
				PCM_L <= (!SND_EN[2] ? 16'h0000 : TrimWave(ACC_L));
				PCM_R <= (!SND_EN[2] ? 16'h0000 : TrimWave(ACC_R));
			end
		end
	end
	
	//Memory
	bit          MEM_WREQ,MEM_RREQ;
	always @(posedge CLK or negedge RST_N) begin
		bit         MEM_START;
				
		if (!RST_N) begin
			MEM_A <= '0;
			MEM_WR <= 0;
			MEM_RD <= 0;
		end else begin
			if (!RES_N) begin
				MEM_A <= '0;
				MEM_WR <= 0;
				MEM_RD <= 0;
			end else if (CE) begin
				if (CYCLE1_CE) begin
					MEM_WR <= 0;
					MEM_RD <= 0;
					MEM_D <= MDI;
				end
				
				MEM_START <= CYCLE1_CE;
				if (MEM_START && WD_READ && !MEMMODE[0]) begin
					MEM_A <= WD_ADDR;
					MEM_WR <= 0;
					MEM_RD <= 1;
				end
				else if ((MEM_WREQ || MEM_RREQ) && MEMMODE[0]) begin
					MEM_A <= MEMADDR;
					MEM_WR <= MEM_WREQ;
					MEM_RD <= MEM_RREQ;
				end
			end
		end
	end
	assign MA = MEM_A[20:0];
	assign MDO = MEMDAT;
	assign MWR_N = ~MEM_WR;
	assign MRD_N = ~MEM_RD;
	assign MCS_N[0] = ~(MEM_A[21:19] ==? 3'b0??);
	assign MCS_N[1] = ~(MEM_A[21:19] ==? 3'b1??);
	assign MCS_N[2] = ~(MEM_A[21:19] ==? 3'b00?);
	assign MCS_N[3] = ~(MEM_A[21:19] ==? 3'b01?);
	assign MCS_N[4] = ~(MEM_A[21:19] ==? 3'b10?);
	assign MCS_N[5] = ~(MEM_A[21:19] ==? 3'b11?);
	assign MCS_N[6] = ~(MEM_A[21:19] == 3'b100);
	assign MCS_N[7] = ~(MEM_A[21:19] == 3'b101);
	assign MCS_N[8] = ~(MEM_A[21:19] == 3'b110);
	assign MCS_N[9] = ~(MEM_A[21:19] == 3'b111);
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		bit         WR_N_OLD,RD_N_OLD,CS_N_OLD;
		bit         REG_RD_DELAY;
		bit         REG_NEW_SEL;
		bit [ 3: 0] LD_WAIT;
		
		if (!RST_N) begin
			NEW2 <= 0;
			TEST0 <= '0;
			TEST1 <= '0;
			MEMMODE <= '0;
			MEMADDR <= '0;
			MEMDAT <= '0;
			MIXFM <= '0;
			MIXPCM <= '0;
			REG_Q <= '0;
			BUSY <= 0;
			LD <= 0;
			LD2 <= 0;
		end else begin
			if (!RES_N) begin
				NEW2 <= 0;
				TEST0 <= '0;
				TEST1 <= '0;
				MEMMODE <= '0;
				MEMADDR <= '0;
				MEMDAT <= '0;
				MIXFM <= {3'h3,3'h3};
				MIXPCM <= {3'h0,3'h0};
				LD2 <= 0;
			end else if (CE) begin
				if (CYCLE1_CE) begin
					REG_RD <= 0;
					REG_WR <= 0;
					BUSY <= 0;
				end
				
				WR_N_OLD <= WR_N;
				RD_N_OLD <= RD_N;
				CS_N_OLD <= CS_N;
				if (RD_N && !RD_N_OLD && !CS_N_OLD && A == 3'h0) begin
					if (LD2) LD2 <= 0;
				end
				if (!RD_N && RD_N_OLD && !CS_N && A == 3'h5 && NEW2) begin
					REG_RD <= 1;
					BUSY <= 1;
				end
				if (!WR_N && WR_N_OLD && !CS_N) begin
					REG_NEW_SEL <= 0;
					case (A)
						3'h2: REG_NEW_SEL <= (DI == 8'h05);
						3'h3: if (REG_NEW_SEL && DI[1]) begin NEW2 <= 1; LD2 <= 1; end
						3'h4: if (NEW2) REG_A <= DI;
						3'h5: if (NEW2) begin
							REG_D <= DI;
							REG_WR <= 1;
							BUSY <= 1;
						end
					endcase
				end
				
				if (OP7.SLOT == 5'd23 && SLOT1_CE) begin
					if (LD_WAIT) LD_WAIT <= LD_WAIT - 4'd1;
					else LD <= 0;
				end
				
				MEM_WREQ <= 0;
				MEM_RREQ <= 0;
				REG_RD_DELAY <= REG_RD;
				if (REG_WR && CYCLE1_CE) begin
					case (REG_A)
						8'h00: TEST0 <= REG_D;
						8'h01: TEST1 <= REG_D;
						8'h02: MEMMODE[4:0] <= REG_D[4:0];
						8'h03: MEMADDR[21:16] <= REG_D[4:0];
						8'h04: MEMADDR[15:8] <= REG_D;
						8'h05: MEMADDR[7:0] <= REG_D;
						8'h06: MEMDAT <= REG_D; 
						8'hF8: MIXFM <= REG_D[5:0];
						8'hF9: MIXPCM <= REG_D[5:0];
						default:;
					endcase
					if (REG_WTN_SEL) begin
						LD <= 1;
						LD_WAIT <= 4'd12;
					end
					MEM_WREQ <= (REG_A == 8'h06);
				end else if (REG_RD_DELAY) begin
					if (REG_WTN_SEL) REG_Q <= REG_WTN_Q;
					else if (REG_FNUM0_SEL) REG_Q <= REG_FNUM_Q[15:8];
					else if (REG_FNUM1_SEL) REG_Q <= REG_FNUM_Q[7:0];
					else if (REG_LEVEL_SEL) REG_Q <= REG_LEVEL_Q;
					else if (REG_PAN_SEL) REG_Q <= REG_PAN_Q;
					else if (REG_LFO_SEL) REG_Q <= REG_LFO_Q;
					else if (REG_RATE0_SEL) REG_Q <= REG_RATE0_Q;
					else if (REG_RATE1_SEL) REG_Q <= REG_RATE1_Q;
					else if (REG_RATE2_SEL) REG_Q <= REG_RATE2_Q;
					else if (REG_AM_SEL) REG_Q <= REG_AM_Q;
					else begin
						case (REG_A)
							8'h00: REG_Q <= TEST0;
							8'h01: REG_Q <= TEST1;
							8'h02: REG_Q <= {3'b001,MEMMODE};
							8'h03: REG_Q <= {2'b00,MEMADDR[21:16]};
							8'h04: REG_Q <= MEMADDR[15:8];
							8'h05: REG_Q <= MEMADDR[7:0];
							8'h06: REG_Q <= MEMDAT;
							8'hF8: REG_Q <= {2'b00,MIXFM};
							8'hF9: REG_Q <= {2'b00,MIXPCM};
							default: REG_Q <= '0;
						endcase
						MEM_RREQ <= (REG_A == 8'h06);
					end
				end
			end
		end
	end

	
	wire       REG_SA0_LOAD   = (OP3.LOAD_POS == 4'h0);
	wire       REG_SA1_LOAD   = (OP3.LOAD_POS == 4'h1);
	wire       REG_SA2_LOAD   = (OP3.LOAD_POS == 4'h2);
	bit [23:0] REG_SA_Q;
	OPL4_REG_RAM #(5,8) REG_SA0  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,   OP2.RST ? 1'b1 : OP3.LOAD ? (REG_SA0_LOAD & SLOT0_CE) : 1'b0  , SA_RA, REG_SA_Q[23:16]);
	OPL4_REG_RAM #(5,8) REG_SA1  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,   OP2.RST ? 1'b1 : OP3.LOAD ? (REG_SA1_LOAD & SLOT0_CE) : 1'b0  , SA_RA, REG_SA_Q[15:8]);
	OPL4_REG_RAM #(5,8) REG_SA2  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,   OP2.RST ? 1'b1 : OP3.LOAD ? (REG_SA2_LOAD & SLOT0_CE) : 1'b0  , SA_RA, REG_SA_Q[7:0]);
	
	wire       REG_LA0_LOAD  = (OP3.LOAD_POS == 4'h3);
	wire       REG_LA1_LOAD  = (OP3.LOAD_POS == 4'h4);
	bit [15:0] REG_LA_Q;
	OPL4_REG_RAM #(5,8) REG_LA0  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,  OP2.RST ? 1'b1 : OP3.LOAD ? (REG_LA0_LOAD & SLOT0_CE) : 1'b0 , SA_RA, REG_LA_Q[15:8]);
	OPL4_REG_RAM #(5,8) REG_LA1  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,  OP2.RST ? 1'b1 : OP3.LOAD ? (REG_LA1_LOAD & SLOT0_CE) : 1'b0 , SA_RA, REG_LA_Q[7:0]);
	
	wire       REG_EA0_LOAD  = (OP3.LOAD_POS == 4'h5);
	wire       REG_EA1_LOAD  = (OP3.LOAD_POS == 4'h6);
	bit [15:0] REG_EA_Q;
	OPL4_REG_RAM #(5,8) REG_EA0  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,  OP2.RST ? 1'b1 : OP3.LOAD ? (REG_EA0_LOAD & SLOT0_CE) : 1'b0 , SA_RA, REG_EA_Q[15:8]);
	OPL4_REG_RAM #(5,8) REG_EA1  (CLK, OP2.RST ? OP2.SLOT : OP3.SLOT, OP2.RST ? '0 : MEM_D,  OP2.RST ? 1'b1 : OP3.LOAD ? (REG_EA1_LOAD & SLOT0_CE) : 1'b0 , SA_RA, REG_EA_Q[7:0]);
	
	wire       REG_WTN_SEL = (REG_A >= 8'h08 && REG_A <= 8'h1F);
	bit [ 7:0] REG_WTN_Q;
	OPL4_REG_RAM #(5,8) REG_WTN  (CLK, OP4.RST ? OP4.SLOT :                       REG_A[4:0]-5'h08, OP4.RST ? '0 :                    REG_D, OP4.RST ? 1'b1 : (REG_WR & REG_WTN_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h08 : SLOT), REG_WTN_Q);
	
	wire       REG_FNUM0_SEL = (REG_A >= 8'h38 && REG_A <= 8'h4F);
	wire       REG_FNUM1_SEL = (REG_A >= 8'h20 && REG_A <= 8'h37);
	bit [15:0] REG_FNUM_Q;
	OPL4_REG_RAM #(5,8) REG_FNUM0(CLK,     RST ?     SLOT :                       REG_A[4:0]-5'h18,     RST ? '0 :                    REG_D,     RST ? 1'b1 : (REG_WR & REG_FNUM0_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h18 : FNUM_RA ), REG_FNUM_Q[15:8]);
	OPL4_REG_RAM #(5,8) REG_FNUM1(CLK,     RST ?     SLOT :                       REG_A[4:0]-5'h00,     RST ? '0 :                    REG_D,     RST ? 1'b1 : (REG_WR & REG_FNUM1_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h00 : FNUM_RA ), REG_FNUM_Q[7:0]);
	
	wire       REG_LEVEL_SEL = (REG_A >= 8'h50 && REG_A <= 8'h67);
	bit [ 7:0] REG_LEVEL_Q;
	OPL4_REG_RAM #(5,8) REG_LEVEL(CLK,     RST ?     SLOT :                       REG_A[4:0]-5'h10,     RST ? '0 :                    REG_D,     RST ? 1'b1 : (REG_WR & REG_LEVEL_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h10 : OP6.SLOT ), REG_LEVEL_Q);
	
	wire       REG_PAN_SEL = (REG_A >= 8'h68 && REG_A <= 8'h7F);
	bit [ 7:0] REG_PAN_Q;
	OPL4_REG_RAM #(5,8) REG_PAN  (CLK,     RST ?     SLOT :                       REG_A[4:0]-5'h08,     RST ? '0 :                    REG_D,     RST ? 1'b1 : (REG_WR & REG_PAN_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h08 : OP7.SLOT ), REG_PAN_Q);
	
	wire       REG_LFO_SEL = (REG_A >= 8'h80 && REG_A <= 8'h97);
	wire       REG_LFO_LOAD  = (OP3.LOAD_POS == 4'h7);
	bit [ 7:0] REG_LFO_Q;
	OPL4_REG_RAM #(5,8) REG_LFO  (CLK,     RST ?     SLOT : OP3.LOAD ? OP3.SLOT : REG_A[4:0]-5'h00,     RST ? '0 : OP3.LOAD ? MEM_D : REG_D,     RST ? 1'b1 : OP3.LOAD ? (REG_LFO_LOAD & SLOT0_CE) : (REG_WR & REG_LFO_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h00 : LFO_RA ), REG_LFO_Q);
	
	wire       REG_RATE0_SEL = (REG_A >= 8'h98 && REG_A <= 8'hAF);
	wire       REG_RATE0_LOAD  = (OP3.LOAD_POS == 4'h8);
	bit [ 7:0] REG_RATE0_Q;
	OPL4_REG_RAM #(5,8) REG_RATE0(CLK,     RST ?     SLOT : OP3.LOAD ? OP3.SLOT : REG_A[4:0]-5'h18,     RST ? '0 : OP3.LOAD ? MEM_D : REG_D,     RST ? 1'b1 : OP3.LOAD ? (REG_RATE0_LOAD & SLOT0_CE) : (REG_WR & REG_RATE0_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h18 : OP4.SLOT ), REG_RATE0_Q);
	
	wire       REG_RATE1_SEL = (REG_A >= 8'hB0 && REG_A <= 8'hC7);
	wire       REG_RATE1_LOAD  = (OP3.LOAD_POS == 4'h9);
	bit [ 7:0] REG_RATE1_Q;
	OPL4_REG_RAM #(5,8) REG_RATE1(CLK,     RST ?     SLOT : OP3.LOAD ? OP3.SLOT : REG_A[4:0]-5'h10,     RST ? '0 : OP3.LOAD ? MEM_D : REG_D,     RST ? 1'b1 : OP3.LOAD ? (REG_RATE1_LOAD & SLOT0_CE) : (REG_WR & REG_RATE1_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h10 : OP4.SLOT ), REG_RATE1_Q);
	
	wire       REG_RATE2_SEL = (REG_A >= 8'hC8 && REG_A <= 8'hDF);
	wire       REG_RATE2_LOAD  = (OP3.LOAD_POS == 4'hA);
	bit [ 7:0] REG_RATE2_Q;
	OPL4_REG_RAM #(5,8) REG_RATE2(CLK,     RST ?     SLOT : OP3.LOAD ? OP3.SLOT : REG_A[4:0]-5'h08,     RST ? '0 : OP3.LOAD ? MEM_D : REG_D,     RST ? 1'b1 : OP3.LOAD ? (REG_RATE2_LOAD & SLOT0_CE) : (REG_WR & REG_RATE2_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h08 : OP4.SLOT ), REG_RATE2_Q);
	
	wire       REG_AM_SEL = (REG_A >= 8'hE0 && REG_A <= 8'hF7);
	wire       REG_AM_LOAD  = (OP3.LOAD_POS == 4'hB);
	bit [ 7:0] REG_AM_Q;
	OPL4_REG_RAM #(5,8) REG_AM   (CLK,     RST ?     SLOT : OP3.LOAD ? OP3.SLOT : REG_A[4:0]-5'h00,     RST ? '0 : OP3.LOAD ? MEM_D : REG_D,     RST ? 1'b1 : OP3.LOAD ? (REG_AM_LOAD & SLOT0_CE) : (REG_WR & REG_AM_SEL & CYCLE1_CE), (REG_RD ? REG_A[4:0]-5'h00 : OP4.SLOT ), REG_AM_Q);
	
	
	//OPL3
	bit  [ 7: 0] OPL3_DO;
	bit  [15: 0] OPL3_OUT_A;
	bit  [15: 0] OPL3_OUT_B;
	bit  [15: 0] OPL3_OUT_C;
	bit  [15: 0] OPL3_OUT_D;
	
	assign OPL3_DO = '0;
	assign {OPL3_OUT_A,OPL3_OUT_B,OPL3_OUT_C,OPL3_OUT_D} = '0;
	
	
	assign DO = A == 3'h5 ? REG_Q : OPL3_DO | {6'b000000,LD|LD2,BUSY};
	
	assign OUT0_L = OPL3_OUT_C;
	assign OUT0_R = OPL3_OUT_D;
	
	assign OUT1_L = PCM_L;
	assign OUT1_R = PCM_R;
	
	assign OUT2_L = MixCalc(PCM_L, MIXPCM[2:0]) + MixCalc(OPL3_OUT_A, MIXFM[2:0]);
	assign OUT2_R = MixCalc(PCM_R, MIXPCM[5:3]) + MixCalc(OPL3_OUT_B, MIXFM[5:3]);
	
endmodule

module OPL4_KEY_RAM
(
	input         CLK,
	
	input  [ 4: 0] WRADDR,
	input  [ 2: 0] DATA,
	input          WREN,
	input  [ 4: 0] RDADDR,
	output [ 2: 0] Q
);

	wire [2:0] sub_wire0;
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RDADDR),
				.wraddress (WRADDR),
				.wren (WREN),
				.byteena (1'b1),
				.q (sub_wire0),
				.aclr (1'b0),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.byte_size = 8,
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 3,
		altdpram_component.widthad = 5,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
endmodule

module OPL4_PHASE_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [13: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [13: 0] Q);

	wire [13:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (1'b1),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({14{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 14,
		altsyncram_component.width_b = 14,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;

endmodule

module OPL4_LFO_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [21: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [21: 0] Q);

	wire [21:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (1'b1),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({22{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 22,
		altsyncram_component.width_b = 22,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;

endmodule

module OPL4_SO_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [16: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [16: 0] Q);

	wire [16:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (1'b1),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({17{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 17,
		altsyncram_component.width_b = 17,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
endmodule

module OPL4_EVOL_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [11: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [11: 0] Q);

	wire [11:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (1'b1),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({12{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 12,
		altsyncram_component.width_b = 12,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;

endmodule

module OPL4_REG_RAM
#(
	parameter aw = 5, dw = 8
)
(
	input            CLK,
	
	input  [aw-1: 0] WRADDR,
	input  [dw-1: 0] DATA,
	input            WREN,
	input  [aw-1: 0] RDADDR,
	output [dw-1: 0] Q
);

`ifdef SIM
	
	reg [dw-1:0] MEM [2**aw];
	
	always @(posedge CLK) begin
		if (WREN) begin
			MEM[WRADDR] <= DATA;
		end
		Q <= MEM[RDADDR];
	end
	
`else

	wire [dw-1:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (1'b1),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({dw{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
//		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**aw,
		altsyncram_component.numwords_b = 2**aw,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = aw,
		altsyncram_component.widthad_b = aw,
		altsyncram_component.width_a = dw,
		altsyncram_component.width_b = dw,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
`endif
	
endmodule
