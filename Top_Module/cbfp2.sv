`timescale 1ns / 1ps

module cbfp2 (
    input logic clk,
    input logic rstn,
    input logic [4:0] idx0[15:0],  //최대 shift idx 23bit
    input logic cbfp2_valid,
    input logic [4:0] idx1[15:0],  //최대 shift idx 25bit, cbfp0와 7clk different

    input logic signed [15:0] i_bfly22_re[15:0],  //(+-+-+-...) 16bit
    input logic signed [15:0] i_bfly22_im[15:0],  //(+-+-+-...) 16bit

    output logic dout_valid,
    output logic signed [12:0] dout_re[0:511],  // <9.4>
    output logic signed [12:0] dout_im[0:511]  // <9.4>
);
    int i;
    logic [5:0] sum_idx[15:0];
    logic [4:0] reorder_cnt;
    logic reorder_valid;
    logic delay_reorder[0:30];
    logic signed [12:0] reg_cbfp2_re[15:0];
    logic signed [12:0] reg_cbfp2_im[15:0];
    logic signed [12:0] cbfp2_re[15:0];
    logic signed [12:0] cbfp2_im[15:0];

    always_comb begin
        for (i = 0; i < 16; i = i + 1) begin
            sum_idx[i] = idx0[i] + idx1[i];
        end
    end

    always_comb begin
        for (i = 0; i < 16; i = i + 1) begin
            if (sum_idx[i] >= 23) begin
                reg_cbfp2_re[i] = 0;
                reg_cbfp2_im[i] = 0;
            end else begin
                if (sum_idx[i] >= 9) begin
                    reg_cbfp2_re[i] = i_bfly22_re[i] >>> sum_idx[i] - 9;
                    reg_cbfp2_im[i] = i_bfly22_im[i] >>> sum_idx[i] - 9;
                end else begin
                    reg_cbfp2_re[i] = i_bfly22_re[i] >>> 9 - sum_idx[i];
                    reg_cbfp2_im[i] = i_bfly22_im[i] >>> 9 - sum_idx[i];
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int j = 0; j < 16; j = j + 1) begin
                cbfp2_re[j] <= 0;
                cbfp2_im[j] <= 0;
            end
        end else begin
            for (int j = 0; j < 16; j = j + 1) begin
                cbfp2_re[j] <= reg_cbfp2_re[i];
                cbfp2_im[j] <= reg_cbfp2_im[i];
            end
        end
    end
    counter #(
        .COUNT_MAX_VAL(5)      // 카운트 폭을 직접 지정 (예: 4비트 → 0..15 순환)
    ) U_REORDER_CNT(
        .clk(clk),
        .rstn(rstn),
        .en(reorder_valid),  // 카운트 인에이블
        .count_out(reorder_cnt)  // 현재 카운트 값
    );
    
    always_ff @(posedge clk, posedge rstn) begin
        if (!rstn) begin
            reorder_valid <= 0;
        end else begin
            reorder_valid <= cbfp2_valid;
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 31; i++) begin
                delay_reorder[i] <= 0;
            end
            dout_valid <= 0;
        end else begin
            delay_reorder[0] <= 0;
            for (i = 1; i < 30; i++) begin
                delay_reorder[i+1] <= delay_reorder[i];
            end
            dout_valid <= delay_reorder[30];
        end
    end

    always @(*) begin
        case (reorder_cnt)
            0: begin
                dout_re[0]   = cbfp2_re[0];
                dout_im[0]   = cbfp2_im[0];
                dout_re[256] = cbfp2_re[1];
                dout_im[256] = cbfp2_im[1];
                dout_re[128] = cbfp2_re[2];
                dout_im[128] = cbfp2_im[2];
                dout_re[384] = cbfp2_re[3];
                dout_im[384] = cbfp2_im[3];
                dout_re[64]  = cbfp2_re[4];
                dout_im[64]  = cbfp2_im[4];
                dout_re[320] = cbfp2_re[5];
                dout_im[320] = cbfp2_im[5];
                dout_re[192] = cbfp2_re[6];
                dout_im[192] = cbfp2_im[6];
                dout_re[448] = cbfp2_re[7];
                dout_im[448] = cbfp2_im[7];
                dout_re[32]  = cbfp2_re[8];
                dout_im[32]  = cbfp2_im[8];
                dout_re[288] = cbfp2_re[9];
                dout_im[288] = cbfp2_im[9];
                dout_re[160] = cbfp2_re[10];
                dout_im[160] = cbfp2_im[10];
                dout_re[416] = cbfp2_re[11];
                dout_im[416] = cbfp2_im[11];
                dout_re[96]  = cbfp2_re[12];
                dout_im[96]  = cbfp2_im[12];
                dout_re[352] = cbfp2_re[13];
                dout_im[352] = cbfp2_im[13];
                dout_re[224] = cbfp2_re[14];
                dout_im[224] = cbfp2_im[14];
                dout_re[480] = cbfp2_re[15];
                dout_im[480] = cbfp2_im[15];
            end
            1: begin
                dout_re[16]  = cbfp2_re[0];
                dout_im[16]  = cbfp2_im[0];
                dout_re[272] = cbfp2_re[1];
                dout_im[272] = cbfp2_im[1];
                dout_re[144] = cbfp2_re[2];
                dout_im[144] = cbfp2_im[2];
                dout_re[400] = cbfp2_re[3];
                dout_im[400] = cbfp2_im[3];
                dout_re[80]  = cbfp2_re[4];
                dout_im[80]  = cbfp2_im[4];
                dout_re[336] = cbfp2_re[5];
                dout_im[336] = cbfp2_im[5];
                dout_re[208] = cbfp2_re[6];
                dout_im[208] = cbfp2_im[6];
                dout_re[464] = cbfp2_re[7];
                dout_im[464] = cbfp2_im[7];
                dout_re[48]  = cbfp2_re[8];
                dout_im[48]  = cbfp2_im[8];
                dout_re[304] = cbfp2_re[9];
                dout_im[304] = cbfp2_im[9];
                dout_re[176] = cbfp2_re[10];
                dout_im[176] = cbfp2_im[10];
                dout_re[432] = cbfp2_re[11];
                dout_im[432] = cbfp2_im[11];
                dout_re[112] = cbfp2_re[12];
                dout_im[112] = cbfp2_im[12];
                dout_re[368] = cbfp2_re[13];
                dout_im[368] = cbfp2_im[13];
                dout_re[240] = cbfp2_re[14];
                dout_im[240] = cbfp2_im[14];
                dout_re[496] = cbfp2_re[15];
                dout_im[496] = cbfp2_im[15];

            end
            2: begin
                dout_re[8]   = cbfp2_re[0];
                dout_im[8]   = cbfp2_im[0];
                dout_re[264] = cbfp2_re[1];
                dout_im[264] = cbfp2_im[1];
                dout_re[136] = cbfp2_re[2];
                dout_im[136] = cbfp2_im[2];
                dout_re[392] = cbfp2_re[3];
                dout_im[392] = cbfp2_im[3];
                dout_re[72]  = cbfp2_re[4];
                dout_im[72]  = cbfp2_im[4];
                dout_re[328] = cbfp2_re[5];
                dout_im[328] = cbfp2_im[5];
                dout_re[200] = cbfp2_re[6];
                dout_im[200] = cbfp2_im[6];
                dout_re[456] = cbfp2_re[7];
                dout_im[456] = cbfp2_im[7];
                dout_re[40]  = cbfp2_re[8];
                dout_im[40]  = cbfp2_im[8];
                dout_re[296] = cbfp2_re[9];
                dout_im[296] = cbfp2_im[9];
                dout_re[168] = cbfp2_re[10];
                dout_im[168] = cbfp2_im[10];
                dout_re[424] = cbfp2_re[11];
                dout_im[424] = cbfp2_im[11];
                dout_re[104] = cbfp2_re[12];
                dout_im[104] = cbfp2_im[12];
                dout_re[360] = cbfp2_re[13];
                dout_im[360] = cbfp2_im[13];
                dout_re[232] = cbfp2_re[14];
                dout_im[232] = cbfp2_im[14];
                dout_re[488] = cbfp2_re[15];
                dout_im[488] = cbfp2_im[15];

            end
            3: begin
                dout_re[24]  = cbfp2_re[0];
                dout_im[24]  = cbfp2_im[0];
                dout_re[280] = cbfp2_re[1];
                dout_im[280] = cbfp2_im[1];
                dout_re[152] = cbfp2_re[2];
                dout_im[152] = cbfp2_im[2];
                dout_re[408] = cbfp2_re[3];
                dout_im[408] = cbfp2_im[3];
                dout_re[88]  = cbfp2_re[4];
                dout_im[88]  = cbfp2_im[4];
                dout_re[344] = cbfp2_re[5];
                dout_im[344] = cbfp2_im[5];
                dout_re[216] = cbfp2_re[6];
                dout_im[216] = cbfp2_im[6];
                dout_re[472] = cbfp2_re[7];
                dout_im[472] = cbfp2_im[7];
                dout_re[56]  = cbfp2_re[8];
                dout_im[56]  = cbfp2_im[8];
                dout_re[312] = cbfp2_re[9];
                dout_im[312] = cbfp2_im[9];
                dout_re[184] = cbfp2_re[10];
                dout_im[184] = cbfp2_im[10];
                dout_re[440] = cbfp2_re[11];
                dout_im[440] = cbfp2_im[11];
                dout_re[120] = cbfp2_re[12];
                dout_im[120] = cbfp2_im[12];
                dout_re[376] = cbfp2_re[13];
                dout_im[376] = cbfp2_im[13];
                dout_re[248] = cbfp2_re[14];
                dout_im[248] = cbfp2_im[14];
                dout_re[504] = cbfp2_re[15];
                dout_im[504] = cbfp2_im[15];

            end
            4: begin
                dout_re[4]   = cbfp2_re[0];
                dout_im[4]   = cbfp2_im[0];
                dout_re[260] = cbfp2_re[1];
                dout_im[260] = cbfp2_im[1];
                dout_re[132] = cbfp2_re[2];
                dout_im[132] = cbfp2_im[2];
                dout_re[388] = cbfp2_re[3];
                dout_im[388] = cbfp2_im[3];
                dout_re[68]  = cbfp2_re[4];
                dout_im[68]  = cbfp2_im[4];
                dout_re[324] = cbfp2_re[5];
                dout_im[324] = cbfp2_im[5];
                dout_re[196] = cbfp2_re[6];
                dout_im[196] = cbfp2_im[6];
                dout_re[452] = cbfp2_re[7];
                dout_im[452] = cbfp2_im[7];
                dout_re[36]  = cbfp2_re[8];
                dout_im[36]  = cbfp2_im[8];
                dout_re[292] = cbfp2_re[9];
                dout_im[292] = cbfp2_im[9];
                dout_re[164] = cbfp2_re[10];
                dout_im[164] = cbfp2_im[10];
                dout_re[420] = cbfp2_re[11];
                dout_im[420] = cbfp2_im[11];
                dout_re[100] = cbfp2_re[12];
                dout_im[100] = cbfp2_im[12];
                dout_re[356] = cbfp2_re[13];
                dout_im[356] = cbfp2_im[13];
                dout_re[228] = cbfp2_re[14];
                dout_im[228] = cbfp2_im[14];
                dout_re[484] = cbfp2_re[15];
                dout_im[484] = cbfp2_im[15];

            end

            5: begin
                dout_re[20]  = cbfp2_re[0];
                dout_im[20]  = cbfp2_im[0];
                dout_re[276] = cbfp2_re[1];
                dout_im[276] = cbfp2_im[1];
                dout_re[148] = cbfp2_re[2];
                dout_im[148] = cbfp2_im[2];
                dout_re[404] = cbfp2_re[3];
                dout_im[404] = cbfp2_im[3];
                dout_re[84]  = cbfp2_re[4];
                dout_im[84]  = cbfp2_im[4];
                dout_re[340] = cbfp2_re[5];
                dout_im[340] = cbfp2_im[5];
                dout_re[212] = cbfp2_re[6];
                dout_im[212] = cbfp2_im[6];
                dout_re[468] = cbfp2_re[7];
                dout_im[468] = cbfp2_im[7];
                dout_re[52]  = cbfp2_re[8];
                dout_im[52]  = cbfp2_im[8];
                dout_re[308] = cbfp2_re[9];
                dout_im[308] = cbfp2_im[9];
                dout_re[180] = cbfp2_re[10];
                dout_im[180] = cbfp2_im[10];
                dout_re[436] = cbfp2_re[11];
                dout_im[436] = cbfp2_im[11];
                dout_re[116] = cbfp2_re[12];
                dout_im[116] = cbfp2_im[12];
                dout_re[372] = cbfp2_re[13];
                dout_im[372] = cbfp2_im[13];
                dout_re[244] = cbfp2_re[14];
                dout_im[244] = cbfp2_im[14];
                dout_re[500] = cbfp2_re[15];
                dout_im[500] = cbfp2_im[15];

            end
            6: begin
                dout_re[12]  = cbfp2_re[0];
                dout_im[12]  = cbfp2_im[0];
                dout_re[268] = cbfp2_re[1];
                dout_im[268] = cbfp2_im[1];
                dout_re[140] = cbfp2_re[2];
                dout_im[140] = cbfp2_im[2];
                dout_re[396] = cbfp2_re[3];
                dout_im[396] = cbfp2_im[3];
                dout_re[76]  = cbfp2_re[4];
                dout_im[76]  = cbfp2_im[4];
                dout_re[332] = cbfp2_re[5];
                dout_im[332] = cbfp2_im[5];
                dout_re[204] = cbfp2_re[6];
                dout_im[204] = cbfp2_im[6];
                dout_re[460] = cbfp2_re[7];
                dout_im[460] = cbfp2_im[7];
                dout_re[44]  = cbfp2_re[8];
                dout_im[44]  = cbfp2_im[8];
                dout_re[300] = cbfp2_re[9];
                dout_im[300] = cbfp2_im[9];
                dout_re[172] = cbfp2_re[10];
                dout_im[172] = cbfp2_im[10];
                dout_re[428] = cbfp2_re[11];
                dout_im[428] = cbfp2_im[11];
                dout_re[108] = cbfp2_re[12];
                dout_im[108] = cbfp2_im[12];
                dout_re[364] = cbfp2_re[13];
                dout_im[364] = cbfp2_im[13];
                dout_re[236] = cbfp2_re[14];
                dout_im[236] = cbfp2_im[14];
                dout_re[492] = cbfp2_re[15];
                dout_im[492] = cbfp2_im[15];

            end
            7: begin
                dout_re[28]  = cbfp2_re[0];
                dout_im[28]  = cbfp2_im[0];
                dout_re[284] = cbfp2_re[1];
                dout_im[284] = cbfp2_im[1];
                dout_re[156] = cbfp2_re[2];
                dout_im[156] = cbfp2_im[2];
                dout_re[412] = cbfp2_re[3];
                dout_im[412] = cbfp2_im[3];
                dout_re[92]  = cbfp2_re[4];
                dout_im[92]  = cbfp2_im[4];
                dout_re[348] = cbfp2_re[5];
                dout_im[348] = cbfp2_im[5];
                dout_re[220] = cbfp2_re[6];
                dout_im[220] = cbfp2_im[6];
                dout_re[476] = cbfp2_re[7];
                dout_im[476] = cbfp2_im[7];
                dout_re[60]  = cbfp2_re[8];
                dout_im[60]  = cbfp2_im[8];
                dout_re[316] = cbfp2_re[9];
                dout_im[316] = cbfp2_im[9];
                dout_re[188] = cbfp2_re[10];
                dout_im[188] = cbfp2_im[10];
                dout_re[444] = cbfp2_re[11];
                dout_im[444] = cbfp2_im[11];
                dout_re[124] = cbfp2_re[12];
                dout_im[124] = cbfp2_im[12];
                dout_re[380] = cbfp2_re[13];
                dout_im[380] = cbfp2_im[13];
                dout_re[252] = cbfp2_re[14];
                dout_im[252] = cbfp2_im[14];
                dout_re[508] = cbfp2_re[15];
                dout_im[508] = cbfp2_im[15];

            end

            8: begin
                dout_re[2]   = cbfp2_re[0];
                dout_im[2]   = cbfp2_im[0];
                dout_re[258] = cbfp2_re[1];
                dout_im[258] = cbfp2_im[1];
                dout_re[130] = cbfp2_re[2];
                dout_im[130] = cbfp2_im[2];
                dout_re[386] = cbfp2_re[3];
                dout_im[386] = cbfp2_im[3];
                dout_re[66]  = cbfp2_re[4];
                dout_im[66]  = cbfp2_im[4];
                dout_re[322] = cbfp2_re[5];
                dout_im[322] = cbfp2_im[5];
                dout_re[194] = cbfp2_re[6];
                dout_im[194] = cbfp2_im[6];
                dout_re[450] = cbfp2_re[7];
                dout_im[450] = cbfp2_im[7];
                dout_re[34]  = cbfp2_re[8];
                dout_im[34]  = cbfp2_im[8];
                dout_re[290] = cbfp2_re[9];
                dout_im[290] = cbfp2_im[9];
                dout_re[162] = cbfp2_re[10];
                dout_im[162] = cbfp2_im[10];
                dout_re[418] = cbfp2_re[11];
                dout_im[418] = cbfp2_im[11];
                dout_re[98]  = cbfp2_re[12];
                dout_im[98]  = cbfp2_im[12];
                dout_re[354] = cbfp2_re[13];
                dout_im[354] = cbfp2_im[13];
                dout_re[226] = cbfp2_re[14];
                dout_im[226] = cbfp2_im[14];
                dout_re[482] = cbfp2_re[15];
                dout_im[482] = cbfp2_im[15];

            end
            9: begin
                dout_re[18]  = cbfp2_re[0];
                dout_im[18]  = cbfp2_im[0];
                dout_re[274] = cbfp2_re[1];
                dout_im[274] = cbfp2_im[1];
                dout_re[146] = cbfp2_re[2];
                dout_im[146] = cbfp2_im[2];
                dout_re[402] = cbfp2_re[3];
                dout_im[402] = cbfp2_im[3];
                dout_re[82]  = cbfp2_re[4];
                dout_im[82]  = cbfp2_im[4];
                dout_re[338] = cbfp2_re[5];
                dout_im[338] = cbfp2_im[5];
                dout_re[210] = cbfp2_re[6];
                dout_im[210] = cbfp2_im[6];
                dout_re[466] = cbfp2_re[7];
                dout_im[466] = cbfp2_im[7];
                dout_re[50]  = cbfp2_re[8];
                dout_im[50]  = cbfp2_im[8];
                dout_re[306] = cbfp2_re[9];
                dout_im[306] = cbfp2_im[9];
                dout_re[178] = cbfp2_re[10];
                dout_im[178] = cbfp2_im[10];
                dout_re[434] = cbfp2_re[11];
                dout_im[434] = cbfp2_im[11];
                dout_re[114] = cbfp2_re[12];
                dout_im[114] = cbfp2_im[12];
                dout_re[370] = cbfp2_re[13];
                dout_im[370] = cbfp2_im[13];
                dout_re[242] = cbfp2_re[14];
                dout_im[242] = cbfp2_im[14];
                dout_re[498] = cbfp2_re[15];
                dout_im[498] = cbfp2_im[15];
            end
            10: begin
                dout_re[10]  = cbfp2_re[0];
                dout_im[10]  = cbfp2_im[0];
                dout_re[266] = cbfp2_re[1];
                dout_im[266] = cbfp2_im[1];
                dout_re[138] = cbfp2_re[2];
                dout_im[138] = cbfp2_im[2];
                dout_re[394] = cbfp2_re[3];
                dout_im[394] = cbfp2_im[3];
                dout_re[74]  = cbfp2_re[4];
                dout_im[74]  = cbfp2_im[4];
                dout_re[330] = cbfp2_re[5];
                dout_im[330] = cbfp2_im[5];
                dout_re[202] = cbfp2_re[6];
                dout_im[202] = cbfp2_im[6];
                dout_re[458] = cbfp2_re[7];
                dout_im[458] = cbfp2_im[7];
                dout_re[42]  = cbfp2_re[8];
                dout_im[42]  = cbfp2_im[8];
                dout_re[298] = cbfp2_re[9];
                dout_im[298] = cbfp2_im[9];
                dout_re[170] = cbfp2_re[10];
                dout_im[170] = cbfp2_im[10];
                dout_re[426] = cbfp2_re[11];
                dout_im[426] = cbfp2_im[11];
                dout_re[106] = cbfp2_re[12];
                dout_im[106] = cbfp2_im[12];
                dout_re[362] = cbfp2_re[13];
                dout_im[362] = cbfp2_im[13];
                dout_re[234] = cbfp2_re[14];
                dout_im[234] = cbfp2_im[14];
                dout_re[490] = cbfp2_re[15];
                dout_im[490] = cbfp2_im[15];

            end
            11: begin
                dout_re[26]  = cbfp2_re[0];
                dout_im[26]  = cbfp2_im[0];
                dout_re[282] = cbfp2_re[1];
                dout_im[282] = cbfp2_im[1];
                dout_re[154] = cbfp2_re[2];
                dout_im[154] = cbfp2_im[2];
                dout_re[410] = cbfp2_re[3];
                dout_im[410] = cbfp2_im[3];
                dout_re[90]  = cbfp2_re[4];
                dout_im[90]  = cbfp2_im[4];
                dout_re[346] = cbfp2_re[5];
                dout_im[346] = cbfp2_im[5];
                dout_re[218] = cbfp2_re[6];
                dout_im[218] = cbfp2_im[6];
                dout_re[474] = cbfp2_re[7];
                dout_im[474] = cbfp2_im[7];
                dout_re[58]  = cbfp2_re[8];
                dout_im[58]  = cbfp2_im[8];
                dout_re[314] = cbfp2_re[9];
                dout_im[314] = cbfp2_im[9];
                dout_re[186] = cbfp2_re[10];
                dout_im[186] = cbfp2_im[10];
                dout_re[442] = cbfp2_re[11];
                dout_im[442] = cbfp2_im[11];
                dout_re[122] = cbfp2_re[12];
                dout_im[122] = cbfp2_im[12];
                dout_re[378] = cbfp2_re[13];
                dout_im[378] = cbfp2_im[13];
                dout_re[250] = cbfp2_re[14];
                dout_im[250] = cbfp2_im[14];
                dout_re[506] = cbfp2_re[15];
                dout_im[506] = cbfp2_im[15];

            end
            12: begin
                dout_re[6]   = cbfp2_re[0];
                dout_im[6]   = cbfp2_im[0];
                dout_re[262] = cbfp2_re[1];
                dout_im[262] = cbfp2_im[1];
                dout_re[134] = cbfp2_re[2];
                dout_im[134] = cbfp2_im[2];
                dout_re[390] = cbfp2_re[3];
                dout_im[390] = cbfp2_im[3];
                dout_re[70]  = cbfp2_re[4];
                dout_im[70]  = cbfp2_im[4];
                dout_re[326] = cbfp2_re[5];
                dout_im[326] = cbfp2_im[5];
                dout_re[198] = cbfp2_re[6];
                dout_im[198] = cbfp2_im[6];
                dout_re[454] = cbfp2_re[7];
                dout_im[454] = cbfp2_im[7];
                dout_re[38]  = cbfp2_re[8];
                dout_im[38]  = cbfp2_im[8];
                dout_re[294] = cbfp2_re[9];
                dout_im[294] = cbfp2_im[9];
                dout_re[166] = cbfp2_re[10];
                dout_im[166] = cbfp2_im[10];
                dout_re[422] = cbfp2_re[11];
                dout_im[422] = cbfp2_im[11];
                dout_re[102] = cbfp2_re[12];
                dout_im[102] = cbfp2_im[12];
                dout_re[358] = cbfp2_re[13];
                dout_im[358] = cbfp2_im[13];
                dout_re[230] = cbfp2_re[14];
                dout_im[230] = cbfp2_im[14];
                dout_re[486] = cbfp2_re[15];
                dout_im[486] = cbfp2_im[15];

            end
            13: begin
                dout_re[22]  = cbfp2_re[0];
                dout_im[22]  = cbfp2_im[0];
                dout_re[278] = cbfp2_re[1];
                dout_im[278] = cbfp2_im[1];
                dout_re[150] = cbfp2_re[2];
                dout_im[150] = cbfp2_im[2];
                dout_re[406] = cbfp2_re[3];
                dout_im[406] = cbfp2_im[3];
                dout_re[86]  = cbfp2_re[4];
                dout_im[86]  = cbfp2_im[4];
                dout_re[342] = cbfp2_re[5];
                dout_im[342] = cbfp2_im[5];
                dout_re[214] = cbfp2_re[6];
                dout_im[214] = cbfp2_im[6];
                dout_re[470] = cbfp2_re[7];
                dout_im[470] = cbfp2_im[7];
                dout_re[54]  = cbfp2_re[8];
                dout_im[54]  = cbfp2_im[8];
                dout_re[310] = cbfp2_re[9];
                dout_im[310] = cbfp2_im[9];
                dout_re[182] = cbfp2_re[10];
                dout_im[182] = cbfp2_im[10];
                dout_re[438] = cbfp2_re[11];
                dout_im[438] = cbfp2_im[11];
                dout_re[118] = cbfp2_re[12];
                dout_im[118] = cbfp2_im[12];
                dout_re[374] = cbfp2_re[13];
                dout_im[374] = cbfp2_im[13];
                dout_re[246] = cbfp2_re[14];
                dout_im[246] = cbfp2_im[14];
                dout_re[502] = cbfp2_re[15];
                dout_im[502] = cbfp2_im[15];

            end
            14: begin
                dout_re[14]  = cbfp2_re[0];
                dout_im[14]  = cbfp2_im[0];
                dout_re[270] = cbfp2_re[1];
                dout_im[270] = cbfp2_im[1];
                dout_re[142] = cbfp2_re[2];
                dout_im[142] = cbfp2_im[2];
                dout_re[398] = cbfp2_re[3];
                dout_im[398] = cbfp2_im[3];
                dout_re[78]  = cbfp2_re[4];
                dout_im[78]  = cbfp2_im[4];
                dout_re[334] = cbfp2_re[5];
                dout_im[334] = cbfp2_im[5];
                dout_re[206] = cbfp2_re[6];
                dout_im[206] = cbfp2_im[6];
                dout_re[462] = cbfp2_re[7];
                dout_im[462] = cbfp2_im[7];
                dout_re[46]  = cbfp2_re[8];
                dout_im[46]  = cbfp2_im[8];
                dout_re[302] = cbfp2_re[9];
                dout_im[302] = cbfp2_im[9];
                dout_re[174] = cbfp2_re[10];
                dout_im[174] = cbfp2_im[10];
                dout_re[430] = cbfp2_re[11];
                dout_im[430] = cbfp2_im[11];
                dout_re[110] = cbfp2_re[12];
                dout_im[110] = cbfp2_im[12];
                dout_re[366] = cbfp2_re[13];
                dout_im[366] = cbfp2_im[13];
                dout_re[238] = cbfp2_re[14];
                dout_im[238] = cbfp2_im[14];
                dout_re[494] = cbfp2_re[15];
                dout_im[494] = cbfp2_im[15];

            end
            15: begin
                dout_re[30]  = cbfp2_re[0];
                dout_im[30]  = cbfp2_im[0];
                dout_re[286] = cbfp2_re[1];
                dout_im[286] = cbfp2_im[1];
                dout_re[158] = cbfp2_re[2];
                dout_im[158] = cbfp2_im[2];
                dout_re[414] = cbfp2_re[3];
                dout_im[414] = cbfp2_im[3];
                dout_re[94]  = cbfp2_re[4];
                dout_im[94]  = cbfp2_im[4];
                dout_re[350] = cbfp2_re[5];
                dout_im[350] = cbfp2_im[5];
                dout_re[222] = cbfp2_re[6];
                dout_im[222] = cbfp2_im[6];
                dout_re[478] = cbfp2_re[7];
                dout_im[478] = cbfp2_im[7];
                dout_re[62]  = cbfp2_re[8];
                dout_im[62]  = cbfp2_im[8];
                dout_re[318] = cbfp2_re[9];
                dout_im[318] = cbfp2_im[9];
                dout_re[190] = cbfp2_re[10];
                dout_im[190] = cbfp2_im[10];
                dout_re[446] = cbfp2_re[11];
                dout_im[446] = cbfp2_im[11];
                dout_re[126] = cbfp2_re[12];
                dout_im[126] = cbfp2_im[12];
                dout_re[382] = cbfp2_re[13];
                dout_im[382] = cbfp2_im[13];
                dout_re[254] = cbfp2_re[14];
                dout_im[254] = cbfp2_im[14];
                dout_re[510] = cbfp2_re[15];
                dout_im[510] = cbfp2_im[15];

            end
            16: begin
                dout_re[1]   = cbfp2_re[0];
                dout_im[1]   = cbfp2_im[0];
                dout_re[257] = cbfp2_re[1];
                dout_im[257] = cbfp2_im[1];
                dout_re[129] = cbfp2_re[2];
                dout_im[129] = cbfp2_im[2];
                dout_re[385] = cbfp2_re[3];
                dout_im[385] = cbfp2_im[3];
                dout_re[65]  = cbfp2_re[4];
                dout_im[65]  = cbfp2_im[4];
                dout_re[321] = cbfp2_re[5];
                dout_im[321] = cbfp2_im[5];
                dout_re[193] = cbfp2_re[6];
                dout_im[193] = cbfp2_im[6];
                dout_re[449] = cbfp2_re[7];
                dout_im[449] = cbfp2_im[7];
                dout_re[33]  = cbfp2_re[8];
                dout_im[33]  = cbfp2_im[8];
                dout_re[289] = cbfp2_re[9];
                dout_im[289] = cbfp2_im[9];
                dout_re[161] = cbfp2_re[10];
                dout_im[161] = cbfp2_im[10];
                dout_re[417] = cbfp2_re[11];
                dout_im[417] = cbfp2_im[11];
                dout_re[97]  = cbfp2_re[12];
                dout_im[97]  = cbfp2_im[12];
                dout_re[353] = cbfp2_re[13];
                dout_im[353] = cbfp2_im[13];
                dout_re[225] = cbfp2_re[14];
                dout_im[225] = cbfp2_im[14];
                dout_re[481] = cbfp2_re[15];
                dout_im[481] = cbfp2_im[15];

            end
            17: begin
                dout_re[17]  = cbfp2_re[0];
                dout_im[17]  = cbfp2_im[0];
                dout_re[273] = cbfp2_re[1];
                dout_im[273] = cbfp2_im[1];
                dout_re[145] = cbfp2_re[2];
                dout_im[145] = cbfp2_im[2];
                dout_re[401] = cbfp2_re[3];
                dout_im[401] = cbfp2_im[3];
                dout_re[81]  = cbfp2_re[4];
                dout_im[81]  = cbfp2_im[4];
                dout_re[337] = cbfp2_re[5];
                dout_im[337] = cbfp2_im[5];
                dout_re[209] = cbfp2_re[6];
                dout_im[209] = cbfp2_im[6];
                dout_re[465] = cbfp2_re[7];
                dout_im[465] = cbfp2_im[7];
                dout_re[49]  = cbfp2_re[8];
                dout_im[49]  = cbfp2_im[8];
                dout_re[305] = cbfp2_re[9];
                dout_im[305] = cbfp2_im[9];
                dout_re[177] = cbfp2_re[10];
                dout_im[177] = cbfp2_im[10];
                dout_re[433] = cbfp2_re[11];
                dout_im[433] = cbfp2_im[11];
                dout_re[113] = cbfp2_re[12];
                dout_im[113] = cbfp2_im[12];
                dout_re[369] = cbfp2_re[13];
                dout_im[369] = cbfp2_im[13];
                dout_re[241] = cbfp2_re[14];
                dout_im[241] = cbfp2_im[14];
                dout_re[497] = cbfp2_re[15];
                dout_im[497] = cbfp2_im[15];

            end
            18: begin
                dout_re[9]   = cbfp2_re[0];
                dout_im[9]   = cbfp2_im[0];
                dout_re[265] = cbfp2_re[1];
                dout_im[265] = cbfp2_im[1];
                dout_re[137] = cbfp2_re[2];
                dout_im[137] = cbfp2_im[2];
                dout_re[393] = cbfp2_re[3];
                dout_im[393] = cbfp2_im[3];
                dout_re[73]  = cbfp2_re[4];
                dout_im[73]  = cbfp2_im[4];
                dout_re[329] = cbfp2_re[5];
                dout_im[329] = cbfp2_im[5];
                dout_re[201] = cbfp2_re[6];
                dout_im[201] = cbfp2_im[6];
                dout_re[457] = cbfp2_re[7];
                dout_im[457] = cbfp2_im[7];
                dout_re[41]  = cbfp2_re[8];
                dout_im[41]  = cbfp2_im[8];
                dout_re[297] = cbfp2_re[9];
                dout_im[297] = cbfp2_im[9];
                dout_re[169] = cbfp2_re[10];
                dout_im[169] = cbfp2_im[10];
                dout_re[425] = cbfp2_re[11];
                dout_im[425] = cbfp2_im[11];
                dout_re[105] = cbfp2_re[12];
                dout_im[105] = cbfp2_im[12];
                dout_re[361] = cbfp2_re[13];
                dout_im[361] = cbfp2_im[13];
                dout_re[233] = cbfp2_re[14];
                dout_im[233] = cbfp2_im[14];
                dout_re[489] = cbfp2_re[15];
                dout_im[489] = cbfp2_im[15];

            end
            19: begin
                dout_re[25]  = cbfp2_re[0];
                dout_im[25]  = cbfp2_im[0];
                dout_re[281] = cbfp2_re[1];
                dout_im[281] = cbfp2_im[1];
                dout_re[153] = cbfp2_re[2];
                dout_im[153] = cbfp2_im[2];
                dout_re[409] = cbfp2_re[3];
                dout_im[409] = cbfp2_im[3];
                dout_re[89]  = cbfp2_re[4];
                dout_im[89]  = cbfp2_im[4];
                dout_re[345] = cbfp2_re[5];
                dout_im[345] = cbfp2_im[5];
                dout_re[217] = cbfp2_re[6];
                dout_im[217] = cbfp2_im[6];
                dout_re[473] = cbfp2_re[7];
                dout_im[473] = cbfp2_im[7];
                dout_re[57]  = cbfp2_re[8];
                dout_im[57]  = cbfp2_im[8];
                dout_re[313] = cbfp2_re[9];
                dout_im[313] = cbfp2_im[9];
                dout_re[185] = cbfp2_re[10];
                dout_im[185] = cbfp2_im[10];
                dout_re[441] = cbfp2_re[11];
                dout_im[441] = cbfp2_im[11];
                dout_re[121] = cbfp2_re[12];
                dout_im[121] = cbfp2_im[12];
                dout_re[377] = cbfp2_re[13];
                dout_im[377] = cbfp2_im[13];
                dout_re[249] = cbfp2_re[14];
                dout_im[249] = cbfp2_im[14];
                dout_re[505] = cbfp2_re[15];
                dout_im[505] = cbfp2_im[15];

            end
            20: begin
                dout_re[5]   = cbfp2_re[0];
                dout_im[5]   = cbfp2_im[0];
                dout_re[261] = cbfp2_re[1];
                dout_im[261] = cbfp2_im[1];
                dout_re[133] = cbfp2_re[2];
                dout_im[133] = cbfp2_im[2];
                dout_re[389] = cbfp2_re[3];
                dout_im[389] = cbfp2_im[3];
                dout_re[69]  = cbfp2_re[4];
                dout_im[69]  = cbfp2_im[4];
                dout_re[325] = cbfp2_re[5];
                dout_im[325] = cbfp2_im[5];
                dout_re[197] = cbfp2_re[6];
                dout_im[197] = cbfp2_im[6];
                dout_re[453] = cbfp2_re[7];
                dout_im[453] = cbfp2_im[7];
                dout_re[37]  = cbfp2_re[8];
                dout_im[37]  = cbfp2_im[8];
                dout_re[293] = cbfp2_re[9];
                dout_im[293] = cbfp2_im[9];
                dout_re[165] = cbfp2_re[10];
                dout_im[165] = cbfp2_im[10];
                dout_re[421] = cbfp2_re[11];
                dout_im[421] = cbfp2_im[11];
                dout_re[101] = cbfp2_re[12];
                dout_im[101] = cbfp2_im[12];
                dout_re[357] = cbfp2_re[13];
                dout_im[357] = cbfp2_im[13];
                dout_re[229] = cbfp2_re[14];
                dout_im[229] = cbfp2_im[14];
                dout_re[485] = cbfp2_re[15];
                dout_im[485] = cbfp2_im[15];

            end
            21: begin
                dout_re[21]  = cbfp2_re[0];
                dout_im[21]  = cbfp2_im[0];
                dout_re[277] = cbfp2_re[1];
                dout_im[277] = cbfp2_im[1];
                dout_re[149] = cbfp2_re[2];
                dout_im[149] = cbfp2_im[2];
                dout_re[405] = cbfp2_re[3];
                dout_im[405] = cbfp2_im[3];
                dout_re[85]  = cbfp2_re[4];
                dout_im[85]  = cbfp2_im[4];
                dout_re[341] = cbfp2_re[5];
                dout_im[341] = cbfp2_im[5];
                dout_re[213] = cbfp2_re[6];
                dout_im[213] = cbfp2_im[6];
                dout_re[469] = cbfp2_re[7];
                dout_im[469] = cbfp2_im[7];
                dout_re[53]  = cbfp2_re[8];
                dout_im[53]  = cbfp2_im[8];
                dout_re[309] = cbfp2_re[9];
                dout_im[309] = cbfp2_im[9];
                dout_re[181] = cbfp2_re[10];
                dout_im[181] = cbfp2_im[10];
                dout_re[437] = cbfp2_re[11];
                dout_im[437] = cbfp2_im[11];
                dout_re[117] = cbfp2_re[12];
                dout_im[117] = cbfp2_im[12];
                dout_re[373] = cbfp2_re[13];
                dout_im[373] = cbfp2_im[13];
                dout_re[245] = cbfp2_re[14];
                dout_im[245] = cbfp2_im[14];
                dout_re[501] = cbfp2_re[15];
                dout_im[501] = cbfp2_im[15];

            end
            22: begin
                dout_re[13]  = cbfp2_re[0];
                dout_im[13]  = cbfp2_im[0];
                dout_re[269] = cbfp2_re[1];
                dout_im[269] = cbfp2_im[1];
                dout_re[141] = cbfp2_re[2];
                dout_im[141] = cbfp2_im[2];
                dout_re[397] = cbfp2_re[3];
                dout_im[397] = cbfp2_im[3];
                dout_re[77]  = cbfp2_re[4];
                dout_im[77]  = cbfp2_im[4];
                dout_re[333] = cbfp2_re[5];
                dout_im[333] = cbfp2_im[5];
                dout_re[205] = cbfp2_re[6];
                dout_im[205] = cbfp2_im[6];
                dout_re[461] = cbfp2_re[7];
                dout_im[461] = cbfp2_im[7];
                dout_re[45]  = cbfp2_re[8];
                dout_im[45]  = cbfp2_im[8];
                dout_re[301] = cbfp2_re[9];
                dout_im[301] = cbfp2_im[9];
                dout_re[173] = cbfp2_re[10];
                dout_im[173] = cbfp2_im[10];
                dout_re[429] = cbfp2_re[11];
                dout_im[429] = cbfp2_im[11];
                dout_re[109] = cbfp2_re[12];
                dout_im[109] = cbfp2_im[12];
                dout_re[365] = cbfp2_re[13];
                dout_im[365] = cbfp2_im[13];
                dout_re[237] = cbfp2_re[14];
                dout_im[237] = cbfp2_im[14];
                dout_re[493] = cbfp2_re[15];
                dout_im[493] = cbfp2_im[15];

            end
            23: begin
                dout_re[29]  = cbfp2_re[0];
                dout_im[29]  = cbfp2_im[0];
                dout_re[285] = cbfp2_re[1];
                dout_im[285] = cbfp2_im[1];
                dout_re[157] = cbfp2_re[2];
                dout_im[157] = cbfp2_im[2];
                dout_re[413] = cbfp2_re[3];
                dout_im[413] = cbfp2_im[3];
                dout_re[93]  = cbfp2_re[4];
                dout_im[93]  = cbfp2_im[4];
                dout_re[349] = cbfp2_re[5];
                dout_im[349] = cbfp2_im[5];
                dout_re[221] = cbfp2_re[6];
                dout_im[221] = cbfp2_im[6];
                dout_re[477] = cbfp2_re[7];
                dout_im[477] = cbfp2_im[7];
                dout_re[61]  = cbfp2_re[8];
                dout_im[61]  = cbfp2_im[8];
                dout_re[317] = cbfp2_re[9];
                dout_im[317] = cbfp2_im[9];
                dout_re[189] = cbfp2_re[10];
                dout_im[189] = cbfp2_im[10];
                dout_re[445] = cbfp2_re[11];
                dout_im[445] = cbfp2_im[11];
                dout_re[125] = cbfp2_re[12];
                dout_im[125] = cbfp2_im[12];
                dout_re[381] = cbfp2_re[13];
                dout_im[381] = cbfp2_im[13];
                dout_re[253] = cbfp2_re[14];
                dout_im[253] = cbfp2_im[14];
                dout_re[509] = cbfp2_re[15];
                dout_im[509] = cbfp2_im[15];

            end
            24: begin
                dout_re[3]   = cbfp2_re[0];
                dout_im[3]   = cbfp2_im[0];
                dout_re[259] = cbfp2_re[1];
                dout_im[259] = cbfp2_im[1];
                dout_re[131] = cbfp2_re[2];
                dout_im[131] = cbfp2_im[2];
                dout_re[387] = cbfp2_re[3];
                dout_im[387] = cbfp2_im[3];
                dout_re[67]  = cbfp2_re[4];
                dout_im[67]  = cbfp2_im[4];
                dout_re[323] = cbfp2_re[5];
                dout_im[323] = cbfp2_im[5];
                dout_re[195] = cbfp2_re[6];
                dout_im[195] = cbfp2_im[6];
                dout_re[451] = cbfp2_re[7];
                dout_im[451] = cbfp2_im[7];
                dout_re[35]  = cbfp2_re[8];
                dout_im[35]  = cbfp2_im[8];
                dout_re[291] = cbfp2_re[9];
                dout_im[291] = cbfp2_im[9];
                dout_re[163] = cbfp2_re[10];
                dout_im[163] = cbfp2_im[10];
                dout_re[419] = cbfp2_re[11];
                dout_im[419] = cbfp2_im[11];
                dout_re[99]  = cbfp2_re[12];
                dout_im[99]  = cbfp2_im[12];
                dout_re[355] = cbfp2_re[13];
                dout_im[355] = cbfp2_im[13];
                dout_re[227] = cbfp2_re[14];
                dout_im[227] = cbfp2_im[14];
                dout_re[483] = cbfp2_re[15];
                dout_im[483] = cbfp2_im[15];

            end
            25: begin
                dout_re[19]  = cbfp2_re[0];
                dout_im[19]  = cbfp2_im[0];
                dout_re[275] = cbfp2_re[1];
                dout_im[275] = cbfp2_im[1];
                dout_re[147] = cbfp2_re[2];
                dout_im[147] = cbfp2_im[2];
                dout_re[403] = cbfp2_re[3];
                dout_im[403] = cbfp2_im[3];
                dout_re[83]  = cbfp2_re[4];
                dout_im[83]  = cbfp2_im[4];
                dout_re[339] = cbfp2_re[5];
                dout_im[339] = cbfp2_im[5];
                dout_re[211] = cbfp2_re[6];
                dout_im[211] = cbfp2_im[6];
                dout_re[467] = cbfp2_re[7];
                dout_im[467] = cbfp2_im[7];
                dout_re[51]  = cbfp2_re[8];
                dout_im[51]  = cbfp2_im[8];
                dout_re[307] = cbfp2_re[9];
                dout_im[307] = cbfp2_im[9];
                dout_re[179] = cbfp2_re[10];
                dout_im[179] = cbfp2_im[10];
                dout_re[435] = cbfp2_re[11];
                dout_im[435] = cbfp2_im[11];
                dout_re[115] = cbfp2_re[12];
                dout_im[115] = cbfp2_im[12];
                dout_re[371] = cbfp2_re[13];
                dout_im[371] = cbfp2_im[13];
                dout_re[243] = cbfp2_re[14];
                dout_im[243] = cbfp2_im[14];
                dout_re[499] = cbfp2_re[15];
                dout_im[499] = cbfp2_im[15];

            end
            26: begin
                dout_re[11]  = cbfp2_re[0];
                dout_im[11]  = cbfp2_im[0];
                dout_re[267] = cbfp2_re[1];
                dout_im[267] = cbfp2_im[1];
                dout_re[139] = cbfp2_re[2];
                dout_im[139] = cbfp2_im[2];
                dout_re[395] = cbfp2_re[3];
                dout_im[395] = cbfp2_im[3];
                dout_re[75]  = cbfp2_re[4];
                dout_im[75]  = cbfp2_im[4];
                dout_re[331] = cbfp2_re[5];
                dout_im[331] = cbfp2_im[5];
                dout_re[203] = cbfp2_re[6];
                dout_im[203] = cbfp2_im[6];
                dout_re[459] = cbfp2_re[7];
                dout_im[459] = cbfp2_im[7];
                dout_re[43]  = cbfp2_re[8];
                dout_im[43]  = cbfp2_im[8];
                dout_re[299] = cbfp2_re[9];
                dout_im[299] = cbfp2_im[9];
                dout_re[171] = cbfp2_re[10];
                dout_im[171] = cbfp2_im[10];
                dout_re[427] = cbfp2_re[11];
                dout_im[427] = cbfp2_im[11];
                dout_re[107] = cbfp2_re[12];
                dout_im[107] = cbfp2_im[12];
                dout_re[363] = cbfp2_re[13];
                dout_im[363] = cbfp2_im[13];
                dout_re[235] = cbfp2_re[14];
                dout_im[235] = cbfp2_im[14];
                dout_re[491] = cbfp2_re[15];
                dout_im[491] = cbfp2_im[15];

            end
            27: begin
                dout_re[27]  = cbfp2_re[0];
                dout_im[27]  = cbfp2_im[0];
                dout_re[283] = cbfp2_re[1];
                dout_im[283] = cbfp2_im[1];
                dout_re[155] = cbfp2_re[2];
                dout_im[155] = cbfp2_im[2];
                dout_re[411] = cbfp2_re[3];
                dout_im[411] = cbfp2_im[3];
                dout_re[91]  = cbfp2_re[4];
                dout_im[91]  = cbfp2_im[4];
                dout_re[347] = cbfp2_re[5];
                dout_im[347] = cbfp2_im[5];
                dout_re[219] = cbfp2_re[6];
                dout_im[219] = cbfp2_im[6];
                dout_re[475] = cbfp2_re[7];
                dout_im[475] = cbfp2_im[7];
                dout_re[59]  = cbfp2_re[8];
                dout_im[59]  = cbfp2_im[8];
                dout_re[315] = cbfp2_re[9];
                dout_im[315] = cbfp2_im[9];
                dout_re[187] = cbfp2_re[10];
                dout_im[187] = cbfp2_im[10];
                dout_re[443] = cbfp2_re[11];
                dout_im[443] = cbfp2_im[11];
                dout_re[123] = cbfp2_re[12];
                dout_im[123] = cbfp2_im[12];
                dout_re[379] = cbfp2_re[13];
                dout_im[379] = cbfp2_im[13];
                dout_re[251] = cbfp2_re[14];
                dout_im[251] = cbfp2_im[14];
                dout_re[507] = cbfp2_re[15];
                dout_im[507] = cbfp2_im[15];

            end
            28: begin
                dout_re[7]   = cbfp2_re[0];
                dout_im[7]   = cbfp2_im[0];
                dout_re[263] = cbfp2_re[1];
                dout_im[263] = cbfp2_im[1];
                dout_re[135] = cbfp2_re[2];
                dout_im[135] = cbfp2_im[2];
                dout_re[391] = cbfp2_re[3];
                dout_im[391] = cbfp2_im[3];
                dout_re[71]  = cbfp2_re[4];
                dout_im[71]  = cbfp2_im[4];
                dout_re[327] = cbfp2_re[5];
                dout_im[327] = cbfp2_im[5];
                dout_re[199] = cbfp2_re[6];
                dout_im[199] = cbfp2_im[6];
                dout_re[455] = cbfp2_re[7];
                dout_im[455] = cbfp2_im[7];
                dout_re[39]  = cbfp2_re[8];
                dout_im[39]  = cbfp2_im[8];
                dout_re[295] = cbfp2_re[9];
                dout_im[295] = cbfp2_im[9];
                dout_re[167] = cbfp2_re[10];
                dout_im[167] = cbfp2_im[10];
                dout_re[423] = cbfp2_re[11];
                dout_im[423] = cbfp2_im[11];
                dout_re[103] = cbfp2_re[12];
                dout_im[103] = cbfp2_im[12];
                dout_re[359] = cbfp2_re[13];
                dout_im[359] = cbfp2_im[13];
                dout_re[231] = cbfp2_re[14];
                dout_im[231] = cbfp2_im[14];
                dout_re[487] = cbfp2_re[15];
                dout_im[487] = cbfp2_im[15];

            end
            29: begin
                dout_re[23]  = cbfp2_re[0];
                dout_im[23]  = cbfp2_im[0];
                dout_re[279] = cbfp2_re[1];
                dout_im[279] = cbfp2_im[1];
                dout_re[151] = cbfp2_re[2];
                dout_im[151] = cbfp2_im[2];
                dout_re[407] = cbfp2_re[3];
                dout_im[407] = cbfp2_im[3];
                dout_re[87]  = cbfp2_re[4];
                dout_im[87]  = cbfp2_im[4];
                dout_re[343] = cbfp2_re[5];
                dout_im[343] = cbfp2_im[5];
                dout_re[215] = cbfp2_re[6];
                dout_im[215] = cbfp2_im[6];
                dout_re[471] = cbfp2_re[7];
                dout_im[471] = cbfp2_im[7];
                dout_re[55]  = cbfp2_re[8];
                dout_im[55]  = cbfp2_im[8];
                dout_re[311] = cbfp2_re[9];
                dout_im[311] = cbfp2_im[9];
                dout_re[183] = cbfp2_re[10];
                dout_im[183] = cbfp2_im[10];
                dout_re[439] = cbfp2_re[11];
                dout_im[439] = cbfp2_im[11];
                dout_re[119] = cbfp2_re[12];
                dout_im[119] = cbfp2_im[12];
                dout_re[375] = cbfp2_re[13];
                dout_im[375] = cbfp2_im[13];
                dout_re[247] = cbfp2_re[14];
                dout_im[247] = cbfp2_im[14];
                dout_re[503] = cbfp2_re[15];
                dout_im[503] = cbfp2_im[15];
            end
            30: begin
                dout_re[15]  = cbfp2_re[0];
                dout_im[15]  = cbfp2_im[0];
                dout_re[271] = cbfp2_re[1];
                dout_im[271] = cbfp2_im[1];
                dout_re[143] = cbfp2_re[2];
                dout_im[143] = cbfp2_im[2];
                dout_re[399] = cbfp2_re[3];
                dout_im[399] = cbfp2_im[3];
                dout_re[79]  = cbfp2_re[4];
                dout_im[79]  = cbfp2_im[4];
                dout_re[335] = cbfp2_re[5];
                dout_im[335] = cbfp2_im[5];
                dout_re[207] = cbfp2_re[6];
                dout_im[207] = cbfp2_im[6];
                dout_re[463] = cbfp2_re[7];
                dout_im[463] = cbfp2_im[7];
                dout_re[47]  = cbfp2_re[8];
                dout_im[47]  = cbfp2_im[8];
                dout_re[303] = cbfp2_re[9];
                dout_im[303] = cbfp2_im[9];
                dout_re[175] = cbfp2_re[10];
                dout_im[175] = cbfp2_im[10];
                dout_re[431] = cbfp2_re[11];
                dout_im[431] = cbfp2_im[11];
                dout_re[111] = cbfp2_re[12];
                dout_im[111] = cbfp2_im[12];
                dout_re[367] = cbfp2_re[13];
                dout_im[367] = cbfp2_im[13];
                dout_re[239] = cbfp2_re[14];
                dout_im[239] = cbfp2_im[14];
                dout_re[495] = cbfp2_re[15];
                dout_im[495] = cbfp2_im[15];

            end
            31: begin
                dout_re[31]  = cbfp2_re[0];
                dout_im[31]  = cbfp2_im[0];
                dout_re[287] = cbfp2_re[1];
                dout_im[287] = cbfp2_im[1];
                dout_re[159] = cbfp2_re[2];
                dout_im[159] = cbfp2_im[2];
                dout_re[415] = cbfp2_re[3];
                dout_im[415] = cbfp2_im[3];
                dout_re[95]  = cbfp2_re[4];
                dout_im[95]  = cbfp2_im[4];
                dout_re[351] = cbfp2_re[5];
                dout_im[351] = cbfp2_im[5];
                dout_re[223] = cbfp2_re[6];
                dout_im[223] = cbfp2_im[6];
                dout_re[479] = cbfp2_re[7];
                dout_im[479] = cbfp2_im[7];
                dout_re[63]  = cbfp2_re[8];
                dout_im[63]  = cbfp2_im[8];
                dout_re[319] = cbfp2_re[9];
                dout_im[319] = cbfp2_im[9];
                dout_re[191] = cbfp2_re[10];
                dout_im[191] = cbfp2_im[10];
                dout_re[447] = cbfp2_re[11];
                dout_im[447] = cbfp2_im[11];
                dout_re[127] = cbfp2_re[12];
                dout_im[127] = cbfp2_im[12];
                dout_re[383] = cbfp2_re[13];
                dout_im[383] = cbfp2_im[13];
                dout_re[255] = cbfp2_re[14];
                dout_im[255] = cbfp2_im[14];
                dout_re[511] = cbfp2_re[15];
                dout_im[511] = cbfp2_im[15];

            end
            default: begin
                for (int i = 0; i < 512; i++) begin
                    dout_im[i] = 0;
                end
            end
        endcase
    end

endmodule
