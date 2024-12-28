module top_module(clk,reset);
input clk,reset;
reg divclk;
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
reg [2:0] state;
reg [1:0] mode; //模式(mode 0:單機,mode 1:雙人)
reg [1:0] turn; //目前誰要下
reg [4:0] pos; //下在哪個位置 0~8,未輸入用4'd10代替
reg [9:0] board1; //玩家一下的位置
reg [9:0] board2; //玩家二or電腦下的位置
reg [2:0] winner; //該局贏家:1,2 平手:3
reg [5:0] round; //回合數
reg [5:0] AwinCNT; //玩家一比分
reg [5:0] BwinCNT; //玩家二or電腦比分
integer i;
integer j;
integer ww;

//單機模式
task chess1;
	if(turn == 1'd0) begin
		//讀入pos
		if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
			 board1 <= (board1 | (1 << pos));
			 turn <= turn ^ 1;
		end
	end
	else if(turn == 1'd1) begin
			pos <= 4'd10; //沒-1用10代替
		  //不下這格會輸
        for( i = 0 ; i < 3 ; i = i + 1) begin
            for( j = 0 ; j < 3 ; j = j + 1) begin
                if(i == 0) begin
                    if(((board1 & (1 << (j + 3))) && (board1 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                            pos <= j;
                        end
                    end
                    if(((board1 & (1 << (j * 3 + 1))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                            pos <= (j * 3);
                        end
                    end
                end
                else if(i == 1) begin
                    if(((board1 & (1 << (j))) && (board1 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                            pos <= j + 3;
                        end
                    end
                    if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                            pos <= (j * 3 + 1);
                        end
                    end
                end
                else if(i == 2) begin
                    if(((board1 & (1 << (j))) && (board1 & (1 << (j + 3)))) == 1) begin
                        if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                            pos <= j + 6;
                        end
                    end
                    if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 1)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                            pos <= (j * 3 + 2);
                        end
                    end
                end
            end
        end
        //不下中間會輸
        if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
            if(((board1 & (1 << 0)) && (board1 & (1 << 8)))) begin
                pos <= 4'd4;
            end
            if(((board1 & (1 << 2)) && (board1 & (1 << 6)))) begin
                pos <= 4'd4;
            end
        end
        //下這格會贏
        for( i = 0 ; i < 3 ; i = i + 1) begin
            for( j = 0 ; j < 3 ; j = j + 1) begin
                if(i == 0) begin
                    if(((board2 & (1 << (j + 3))) && (board2 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                            pos <= j;
                        end
                    end
                    if(((board2 & (1 << (j * 3 + 1))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                            pos <= (j * 3);
                        end
                    end
                end
                else if(i == 1) begin
                    if(((board2 & (1 << (j))) && (board2 & (1 << (j + 6)))) == 1) begin
                        if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                            pos <= j + 3;
                        end
                    end
                    if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                            pos <= (j * 3 + 1);
                        end
                    end
                end
                else if(i == 2) begin
                    if(((board2 & (1 << (j))) && (board2 & (1 << (j + 3)))) == 1) begin
                        if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                            pos <= j + 6;
                        end
                    end
                    if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 1)))) == 1) begin
                        if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                            pos <= (j * 3 + 2);
                        end
                    end
                end
            end
        end
        //下中間會贏
        if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
            if(((board2 & (1 << 0)) && (board2 & (1 << 8)))) begin
                pos <= 4'd4;
            end
            if(((board2 & (1 << 2)) && (board2 & (1 << 6)))) begin
                pos <= 4'd4;
            end
        end
        //隨便選一格下
        if(pos == 4'd10) begin
            for( i = 0 ; i < 9 ; i = i + 1) begin
                if(((board1 & (1 << i)) || (board2 & (1 << i))) == 0) begin
                    pos <= i;
                end
            end
        end
        board2 <= (board2 | (1 << pos));
        turn = turn ^ 1;
	end
endtask

//雙人模式
task chess2;
    //玩家1
    if(turn == 0) begin
			//讀入pos
			if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
				 board1 <= (board1 | (1 << pos));
				 turn <= turn ^ 1;
			end
    end
    //玩家2
    else if(turn == 1) begin
			//讀入pos
			if(((1 << pos) & board1) == 0 && ((1 << pos) & board2) == 0) begin
				 board2 <= (board2 | (1 << pos));
				 turn = turn ^ 1;
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
			pos <= 1'b0;
			board1 <= 1'b0;
			board2 <= 1'b0;
	end
	else begin
		//待輸入mode
		if(state == 2'd0) begin
			state <= 2'd1;
		end
		//遊戲初始化
		else if(state == 2'd1) begin
			state <= 2'd2;
			board1 <= 9'd0;
			board2 <= 9'd0;
			winner <= 2'd0;
			turn <= 1'd0;
			pos <= 4'd10;
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

endmodule
