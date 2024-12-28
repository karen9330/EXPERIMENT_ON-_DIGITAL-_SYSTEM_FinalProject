`define TimeExpire 32'd25000000 // main
`define TimeExpireDotMatrix 32'd2500 // dotmatrix 
`define TimeExpirekeypad 32'd250000 // keypad

module top_module( clk , reset , chooseMode , start , out1 , out2  , keypadCol , keypadRow , dot_col , dot_row , R , G , B , HSync , VSync  );

/*
reset -> reset 按鈕
chooseMode start-> switch 選擇 mode , start == 1 遊戲才開始 ( 寫在 main 裡面 )
out1 , out2 -> 七段顯示器
dot_col , dot_row -> dot matrix
keypadCol , keypadRow -> keypad
R , G , B , HSync , VSync -> vga
*/

input clk , reset , chooseMode , start ;
input [3:0] keypadCol;


output reg [7:0] dot_row;
output reg [7:0] dot_col;
output reg [6:0] out1;
output reg [6:0] out2;
output reg [3:0] keypadRow;
output reg [3:0] R;
output reg [3:0] G;
output reg [3:0] B;
output reg HSync;
output reg VSync;



/* To-Do
	@ 除頻器
	@ 一個button切換mode -> output(mode) -> 切的時候要初始化下面所有reg變數
	@ 七段顯示器 -> input(AwinCnt,BwinCNT)
	@ dot matrix -> input(round)
	@ VGA -> input(board1,board2)
*/
/*state 目前狀態
	@ 0: 待輸入mode (mode 0:單機,mode 1:雙人)
	@ 1: 遊戲初始化
	@ 2: 遊戲進行中
	@ 3: 遊戲結束
	0->1->2->3->0
*/

reg [1:0] state;
reg [1:0] mode; //模式(mode 0:單機,mode 1:雙人)
reg [1:0] turn; //目前誰要下
reg [3:0] pos; //下在哪個位置 0~8,未輸入用4'd10代替
reg [8:0] board1; //玩家一下的位置
reg [8:0] board2; //玩家二or電腦下的位置
reg [1:0] winner; //該局贏家:1,2 平手:3
reg [2:0] round; //回合數
reg [2:0] AwinCNT; //玩家一比分
reg [2:0] BwinCNT; //玩家二or電腦比分
integer i;
integer j;
integer bot_pos;


// 除頻器
reg divclk;
reg [31:0] cnt;
reg divclkDotMatrix;
reg [31:0] cntDotMatrix;
reg divclkKeypad;
reg [31:0] cntKeypad;
always@( posedge clk or negedge reset )
begin
    if( !reset )
    begin
        cnt <= 32'd0;
        divclk <= 1'b0;
        divclkDotMatrix <= 32'd0;
        cntDotMatrix <= 1'b0;
        divclkKeypad <= 32'd0;
        cntKeypad <= 1'b0;
    end
    else
    begin
        if( cnt == `TimeExpire )
        begin
            cnt <= 32'd0;
            divclk <= ~divclk;
        end
        else
        begin
            cnt <= cnt + 32'd1;
        end

        if( cntDotMatrix == `TimeExpireDotMatrix )
        begin
            cntDotMatrix <= 32'd0;
            divclkDotMatrix<= ~divclkDotMatrix;
        end
        else
        begin
            cntDotMatrix <= cntDotMatrix + 32'd1;
        end

        if( cntKeypad == `TimeExpirekeypad )
        begin
            cntKeypad <= 32'd0;
            divclkKeypad<= ~divclkKeypad;
        end
        else
        begin
            cntKeypad <= cntKeypad + 32'd1;
        end
    end
end

//單機模式
task chess1;
	if(turn == 1'd0) begin
		//讀入pos
		if(pos != 4'd10) begin
			if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
				 board1 <= (board1 | (1 << pos));
				 turn <= turn ^ 1;
			end
		end
	end
	else if(turn == 1'd1) begin
			bot_pos <= 4'd10; //沒-1用10代替
		  //不下這格會輸
        for( i = 0 ; i < 3 ; i = i + 1) begin
            for( j = 0 ; j < 3 ; j = j + 1) begin
                if(i == 0) begin
                    if(((board1 & (1 << (j + 3))) && (board1 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                            bot_pos <= j;
                        end
                    end
                    if(((board1 & (1 << (j * 3 + 1))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                            bot_pos <= (j * 3);
                        end
                    end
                end
                else if(i == 1) begin
                    if(((board1 & (1 << (j))) && (board1 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                            bot_pos <= j + 3;
                        end
                    end
                    if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                            bot_pos <= (j * 3 + 1);
                        end
                    end
                end
                else if(i == 2) begin
                    if(((board1 & (1 << (j))) && (board1 & (1 << (j + 3)))) == 1) begin
                        if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                            bot_pos <= j + 6;
                        end
                    end
                    if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 1)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                            bot_pos <= (j * 3 + 2);
                        end
                    end
                end
            end
        end
        //不下中間會輸
        if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
            if(((board1 & (1 << 0)) && (board1 & (1 << 8)))) begin
                bot_pos <= 4'd4;
            end
            if(((board1 & (1 << 2)) && (board1 & (1 << 6)))) begin
                bot_pos <= 4'd4;
            end
        end
        //下這格會贏
        for( i = 0 ; i < 3 ; i = i + 1) begin
            for( j = 0 ; j < 3 ; j = j + 1) begin
                if(i == 0) begin
                    if(((board2 & (1 << (j + 3))) && (board2 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                            bot_pos <= j;
                        end
                    end
                    if(((board2 & (1 << (j * 3 + 1))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                            bot_pos <= (j * 3);
                        end
                    end
                end
                else if(i == 1) begin
                    if(((board2 & (1 << (j))) && (board2 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                            bot_pos <= j + 3;
                        end
                    end
                    if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                            bot_pos <= (j * 3 + 1);
                        end
                    end
                end
                else if(i == 2) begin
                    if(((board2 & (1 << (j))) && (board2 & (1 << (j + 3)))) == 1) begin
                        if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                            bot_pos <= j + 6;
                        end
                    end
                    if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 1)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                            bot_pos <= (j * 3 + 2);
                        end
                    end
                end
            end
        end
        //下中間會贏
        if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
            if(((board2 & (1 << 0)) && (board2 & (1 << 8)))) begin
                bot_pos <= 4'd4;
            end
            if(((board2 & (1 << 2)) && (board2 & (1 << 6)))) begin
                bot_pos <= 4'd4;
            end
        end
        //隨便選一格下
        if(bot_pos == 4'd10) begin
            for( i = 0 ; i < 9 ; i = i + 1) begin
                if(((board1 & (1 << i)) || (board2 & (1 << i))) == 0) begin
                    bot_pos <= i;
                end
            end
        end
        board2 <= (board2 | (1 << bot_pos));
        turn = turn ^ 1;
	end
endtask

//雙人模式
task chess2;
    //玩家1
    if(turn == 0) begin
			//讀入pos
			if(pos != 4'd10) begin
				if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
					 board1 <= (board1 | (1 << pos));
					 turn <= turn ^ 1;
				end
			end
    end
    //玩家2
    else if(turn == 1) begin
			//讀入pos
			if(pos != 4'd10) begin
				if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
					 board2 <= (board2 | (1 << pos));
					 turn <= turn ^ 1;
				end
			end
    end
endtask

//檢查有沒有人贏
task checkwin;
    /*
    board開1 << 9然後AND 1 << x去判斷第x位置
    1 2 4
    8 16 32
    64 128 256
    */
    for( i = 0 ; i < 3 ; i = i + 1) begin
        if(((board1 & (1 << (i * 3))) && (board1 & (1 << (i * 3 + 1))) && (board1 & (1 << (i * 3 + 2)))) == 1) begin
            winner <= 1;
        end
        else if(((board1 & (1 << i)) && (board1 & (1 << (i + 3))) && (board1 & (1 << (i + 6)))) == 1) begin
            winner <= 1;
        end
        if(((board2 & (1 << (i * 3))) && (board2 & (1 << (i * 3 + 1))) && (board2 & (1 << (i * 3 + 2)))) == 1) begin
            winner <= 2;
        end
        else if(((board2 & (1 << i)) && (board2 & (1 << (i + 3))) && (board2 & (1 << (i + 6)))) == 1) begin
            winner <= 2;
        end
    end
    if((board1 & 1) && (board1 & 16) && (board1 & 256)) begin
		winner <= 1;
	 end
    else if((board1 & 4) && (board1 & 16) && (board1 & 64)) begin
		winner <= 1;
	 end
    if((board2 & 1) && (board2 & 16) && (board2 & 256)) begin
		winner <= 2;
	 end
    else if((board2 & 4) && (board2 & 16) && (board2 & 64)) begin
		winner <= 2;
	 end
    if((board1 + board2) == ((1 << 9) - 1) && winner == 0) begin
		winner <= 3; //平手
	 end
endtask

//main
always@(posedge divclk or negedge reset) begin
	if(!reset) begin
			state <= 2'b00;
			mode <= 1'b0;
			turn <= 1'b0;
			board1 <= 1'b0;
			board2 <= 1'b0;
	end
	else begin
		//待輸入mode
		if(state == 2'd0) begin
            if( start == 1 ) begin
                mode <= chooseMode;
                state <= 2'd1;
            end
		end
		//遊戲初始化
		else if(state == 2'd1) begin
			state <= 2'd2;
			board1 <= 9'd0;
			board2 <= 9'd0;
			winner <= 2'd0;
			turn <= 1'd0;
            AwinCNT <= 6'd0;
            BwinCNT <= 6'd0;
		end
		//遊戲進行中
		else if(state == 2'd2) begin
			//單機模式
			if(mode == 1'd0) begin
				chess1();
			end
			//雙人模式
			else if(mode == 1'd1) begin
			    chess2();
			end
			checkwin();
			if(winner != 0) begin
				state <= 2'd3;
			end
		end
		//結束遊戲
		else if(state == 2'd3) begin
			state <= 2'd0;
		end
	end

end

// seven_seg_display ( score )
seven_seg_display A_Score( .num(AwinCNT) , .out(out1) );
seven_seg_display B_Score( .num(BwinCNT) , .out(out2) );

// dotmatrix ( round )
reg [2:0] output_cnt;
always@( posedge divclkDotMatrix or negedge reset )
begin
    if( !reset ) 
    begin
        output_cnt <= 0;
        dot_row <= 8'b0;
        dot_col <= 8'b0; 
    end
    else
    begin
        output_cnt <= output_cnt + 1;  
        case( output_cnt )
            3'd0 : dot_row <= 8'b01111111;
            3'd1 : dot_row <= 8'b10111111;
            3'd2 : dot_row <= 8'b11011111;
            3'd3 : dot_row <= 8'b11101111;
            3'd4 : dot_row <= 8'b11110111;
            3'd5 : dot_row <= 8'b11111011;
            3'd6 : dot_row <= 8'b11111101;
            3'd7 : dot_row <= 8'b11111110;
        endcase 

        if( round == 3'd1 ) begin
            case( output_cnt )
                3'd0 : dot_col <= 8'b00000000;
                3'd1 : dot_col <= 8'b00010000;
                3'd2 : dot_col <= 8'b00110000;
                3'd3 : dot_col <= 8'b01010000;
                3'd4 : dot_col <= 8'b00010000;
                3'd5 : dot_col <= 8'b00010000;
                3'd6 : dot_col <= 8'b01111100;
                3'd7 : dot_col <= 8'b00000000;
            endcase
        end
        else if( round == 3'd2 ) begin
            case( output_cnt )
                3'd0 : dot_col <= 8'b00000000;
                3'd1 : dot_col <= 8'b00111100;
                3'd2 : dot_col <= 8'b00000100;
                3'd3 : dot_col <= 8'b00111100;
                3'd4 : dot_col <= 8'b00100000;
                3'd5 : dot_col <= 8'b00100000;
                3'd6 : dot_col <= 8'b00111100;
                3'd7 : dot_col <= 8'b00000000;
            endcase
        end
        else if( round == 3'd3 ) begin
            case( output_cnt )
                3'd0 : dot_col <= 8'b00000000;
                3'd1 : dot_col <= 8'b00111100;
                3'd2 : dot_col <= 8'b00000100;
                3'd3 : dot_col <= 8'b00111100;
                3'd4 : dot_col <= 8'b00000100;
                3'd5 : dot_col <= 8'b00111100;
                3'd6 : dot_col <= 8'b00000000;
                3'd7 : dot_col <= 8'b00000000;
            endcase
        end
        else if( round == 3'd4) begin
            case( output_cnt )
                3'd0 : dot_col <= 8'b00000000;
                3'd1 : dot_col <= 8'b00100100;
                3'd2 : dot_col <= 8'b00100100;
                3'd3 : dot_col <= 8'b00111100;
                3'd4 : dot_col <= 8'b00000100;
                3'd5 : dot_col <= 8'b00000100;
                3'd6 : dot_col <= 8'b00000100;
                3'd7 : dot_col <= 8'b00000000;
            endcase
        end
        else if( round == 3'd5 ) begin
            case( output_cnt )
                3'd0 : dot_col <= 8'b00000000;
                3'd1 : dot_col <= 8'b00111100;
                3'd2 : dot_col <= 8'b00100000;
                3'd3 : dot_col <= 8'b00111100;
                3'd4 : dot_col <= 8'b00000100;
                3'd5 : dot_col <= 8'b00000100;
                3'd6 : dot_col <= 8'b00111100;
                3'd7 : dot_col <= 8'b00000000;
            endcase
        end
        else dot_col <= 8'b0; 
         
    end

end


// keypad( input )
reg [3:0] keypadBuf;
always@( posedge divclkKeypad or negedge reset )
begin
    if( !reset ) 
    begin
        keypadRow <= 4'b1110;
        keypadBuf <= 4'b0000;
    end
    else
    begin 
        case( {keypadRow , keypadCol} )
            8'b1110_1110 : keypadBuf <= 4'h7; 
            8'b1110_1101 : keypadBuf <= 4'h4; 
            8'b1110_1011 : keypadBuf <= 4'h1; 
            8'b1110_0111 : keypadBuf <= 4'h0; 
            8'b1101_1110 : keypadBuf <= 4'h8; 
            8'b1101_1101 : keypadBuf <= 4'h5; 
            8'b1101_1011 : keypadBuf <= 4'h2; 
            8'b1101_0111 : keypadBuf <= 4'ha; 
            8'b1011_1110 : keypadBuf <= 4'h9; 
            8'b1011_1101 : keypadBuf <= 4'h6; 
            8'b1011_1011 : keypadBuf <= 4'h3; 
            8'b1011_0111 : keypadBuf <= 4'hb; 
            8'b0111_1110 : keypadBuf <= 4'hc; 
            8'b0111_1101 : keypadBuf <= 4'hd; 
            8'b0111_1011 : keypadBuf <= 4'he; 
            8'b0111_0111 : keypadBuf <= 4'hf; 
            default : keypadBuf <= keypadBuf;
        endcase

        case ( keypadRow )
            4'b1110 : keypadRow <= 4'b1101;
            4'b1101 : keypadRow <= 4'b1011;
            4'b1011 : keypadRow <= 4'b0111;
            4'b0111 : keypadRow <= 4'b1110;
            default : keypadRow <= 4'b1110;
        endcase

        case ( keypadBuf )
            4'd0 : pos <= 4'd0;
            4'd1 : pos <= 4'd1;
            4'd2 : pos <= 4'd2;
            4'd3 : pos <= 4'd3;
            4'd4 : pos <= 4'd4;
            4'd5 : pos <= 4'd5;
            4'd6 : pos <= 4'd6;
            4'd7 : pos <= 4'd7;
            4'd8 : pos <= 4'd8;
            default : pos <= 4'd10;
        endcase
    end
end

endmodule

