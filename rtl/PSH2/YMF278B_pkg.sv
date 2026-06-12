package YMF278B_PKG;


	typedef bit [1:0] EGState_t;
	parameter EGState_t EST_ATTACK  = 2'b00;
	parameter EGState_t EST_DECAY1  = 2'b01;
	parameter EGState_t EST_DECAY2  = 2'b10;
	parameter EGState_t EST_RELEASE = 2'b11;
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit         LOAD;
		bit [22: 0] PHASE;
		bit [ 8: 0] WTN;
		bit [ 3: 0] LOAD_POS;
	} OP2_t;
	parameter OP2_t OP2_RESET = '{5'h00,1'b0,1'b0,1'b0,1'b0,23'h000000,9'h000,4'h0};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit         LOAD;
		bit [ 3: 0] LOAD_POS;
		bit         ALLOW;
		bit         LOOP;	//Loop processing 
		bit [13: 0] PHASE_FRAC;//Phase fractional
		bit [15: 0] SO;	//Sample offset
		bit [21: 0] MOD;	//Modulation
	} OP3_t;
	parameter OP3_t OP3_RESET = '{5'h00,1'b0,1'b0,1'b0,1'b0,4'h0,1'b0,1'b0,14'h0000,16'h0000,22'h000000};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit         LOOP;//Loop processing 
		bit [ 5: 0] MODF;	//Modulation fractional
	} OP4_t;
	parameter OP4_t OP4_RESET = '{5'h00,1'b0,1'b0,1'b0,1'b0,6'h00};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] WD;	//Wave form data
		bit [ 9: 0] EVOL;	//Envelope volume
		bit [ 7: 0] ALFO; //ALFO wave
	} OP5_t;
	parameter OP5_t OP5_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000,10'h000,8'h00};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] WD;	//Wave form data
		bit [ 9: 0] LEVEL;//Level
	} OP6_t;
	parameter OP6_t OP6_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000,10'h000};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] SD;	//Slot out data
	} OP7_t;
	parameter OP7_t OP7_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000};

	function bit [22:0] PhaseCalc(bit [9:0] FNUM, bit [3:0] OCT, bit signed [7:0] PLFO_WAVE);
		bit [26:0] P;
		bit [3:0] S;
		bit [10:0] F;
		bit [14:0] TEMP;
		bit [11:0] FM;
		
		S = OCT^4'h8;
		F = 11'h400 + FNUM;
		TEMP = $signed(PLFO_WAVE) * F[10:4];
		FM = {{3{TEMP[14]}},TEMP[14:6]};
		P = {15'b000000000000000,{1'b0,F}+FM}<<(S-1);
		
		return P[26:4];
	endfunction
	
	function bit [9:0] LFOFreqDiv(bit [2:0] LFO);
		bit [10:0] RET;
		
		case (LFO)
			3'h0: RET = 10'd1013;
			3'h1: RET = 10'd85;
			3'h2: RET = 10'd54;
			3'h3: RET = 10'd41;
			3'h4: RET = 10'd33;
			3'h5: RET = 10'd29;
			3'h6: RET = 10'd28;
			3'h7: RET = 10'd25;
		endcase
		
		return RET - 10'd1;
	endfunction
	
	function bit [7:0] AMCalc(bit [7:0] DATA, bit [2:0] AM);
		return AM ? ((DATA&8'hFE)>>(~AM)) : '0;
	endfunction
	
	function bit [7:0] VIBCalc(bit [7:0] DATA, bit [2:0] VIB);
		bit [7:0] RET;
		
		RET = VIB ? $signed($signed(DATA&8'hFE)>>>(~VIB)) : '0;
		
		return RET;
	endfunction
	
	function bit [15:0] Interpolate(input bit [15:0] WAVE0, input bit [15:0] WAVE1, bit [5:0] PHASE);
		bit [ 6:0] PHASE_NEG;
		bit [21:0] TEMP0,TEMP1;
		bit [21:0] SUM;
		
		PHASE_NEG = 7'h40 - PHASE;
		TEMP0 = $signed(WAVE0) * PHASE_NEG;
		TEMP1 = $signed(WAVE1) * PHASE;
		SUM = $signed(TEMP0) + $signed(TEMP1);
	
		return SUM[21:6];
	endfunction
		
	function bit [5:0] EffRateCalc(bit [4:0] RATE, bit [3:0] KRS, bit [3:0] OCT);
		bit [4:0] RES;
		bit [5:0] TEMP;
		bit [3:0] KEY_EG_SCALE;
		bit [5:0] TEMP2;
		bit [4:0] RATE_SCALE,RATE_SCALE2;
		
		TEMP = {2'b00,KRS} + {OCT[3],OCT[3],OCT};
		if (KRS == 4'hF) 
			KEY_EG_SCALE = '0;
		else
			KEY_EG_SCALE = TEMP[5] ? 4'h0 : TEMP[4] ? 4'hF : TEMP[3:0];
		
		TEMP2 = {1'b0,RATE} + {2'b00,KEY_EG_SCALE};
		RES = TEMP2[5] ? 5'h1F : TEMP2[4:0];
			
		return {TEMP2[5],RES};
	endfunction
	
	function bit [3:0] EffRateBit(bit [4:0] ERATE);
		bit [4:0] TEMP;

		TEMP = 5'h18 - (ERATE > 5'h18 ? 5'h18 : ERATE[4:0]);
			
		return TEMP[4:1];
	endfunction
	
	function bit [9:0] LevelAddALFO(bit [9:0] LEVEL, bit [7:0] ALFO);
		bit [10:0] SUM;
		
		SUM = {1'b0,LEVEL} + {3'b000,ALFO};
		
		return !SUM[10] ? SUM[9:0] : 10'h3FF;
	endfunction
	
	function bit [9:0] LevelAddTL(bit [9:0] LEVEL, bit [6:0] TL);
		bit [10:0] SUM;
		
		SUM = {1'b0,LEVEL} + {1'b0,TL,3'b000};
		
		return !SUM[10] ? SUM[9:0] : 10'h3FF;
	endfunction

	function bit signed [15:0] VolCalc(bit signed [15:0] WAVE, bit [9:0] LEVEL);
		bit [22:0] MULT;
		bit [15:0] RES;
		
		MULT = $signed(WAVE) * ({2'b01,~LEVEL[5:0]});
		RES = $signed($signed(MULT[22:7])>>>LEVEL[9:6]);
		
		return RES;
	endfunction
	
	function bit signed [15:0] PanLCalc(bit signed [15:0] WAVE, bit [3:0] PAN);
		bit [15:0] TEMP;
		
		TEMP = $signed($signed(WAVE)>>>{PAN[2:0],1'b0});
		return !PAN[3] ? $signed(TEMP) : WAVE;
	endfunction
	
	function bit signed [15:0] PanRCalc(bit signed [15:0] WAVE, bit [3:0] PAN);
		bit [15:0] TEMP;
		
		TEMP = $signed($signed(WAVE)>>>{PAN[2:0],1'b0});
		return  PAN[3] ? $signed(TEMP) : WAVE;
	endfunction
	
	function bit signed [15:0] MixCalc(bit signed [15:0] WAVE, bit [2:0] MIX);
		bit [15:0] TEMP;
		
		TEMP = $signed($signed(WAVE)>>>{MIX,1'b0});
		
		return TEMP;
	endfunction
	
	function bit signed [15:0] TrimWave(bit signed [17:0] WAVE);
		return WAVE[17] && WAVE[16:15] != 2'b11 ? 16'h8000 : !WAVE[17] && WAVE[16:15] != 2'b00 ? 16'h7FFF : WAVE[15:0];
	endfunction
	
endpackage
