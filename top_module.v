`define TimeExpire_10000Hz 32'd2500
`define TimeExpire_100Hz 32'd250000
`define TimeExpire_25MHz 32'd1
`define TimeExpire_2Hz 32'd12500000
`define TimeExpire_1Hz 32'd25000000

module top_module(
    input clk, rst,
    input [3:0] keypadCol,
    input [1:0] mode_w,
    input start_w,
    input debug_w,
    output hsync, vsync,
    output [3:0] VGA_R, VGA_G, VGA_B,
    output [6:0] displayA, // mode 12
    output [6:0] displayB, // mode 12 
    output [3:0] keypadRow,
    output [7:0] dot_row,
    output [7:0] dot_col
);
    wire divClk_1Hz, divClk_2Hz, divClk_100Hz, divClk_10000Hz, divClk_25MHz;

    // 1Hz
    divider #(
        .TIME_EXPIRE(`TimeExpire_1Hz)
    ) divider_1Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_1Hz)
    );

    // 25MHz
    divider #(
        .TIME_EXPIRE(`TimeExpire_25MHz)
    ) divider_25MHz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_25MHz)
    );

    // 100Hz 
    divider #(
        .TIME_EXPIRE(`TimeExpire_100Hz)
    ) divider_100Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_100Hz)
    );

    // 2Hz 
    divider #(
        .TIME_EXPIRE(`TimeExpire_2Hz)
    ) divider_2Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_2Hz)
    );

    // 10000Hz 時鐘分頻
    divider #(
        .TIME_EXPIRE(`TimeExpire_10000Hz)
    ) divider_10000Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_10000Hz)
    );

    //記憶遊戲
    wire isCircle_w;
    wire [2:0] round_w, lives_w;
    wire [3:0] keyPressed; 
    wire [2:0] state3_w;
    wire [3:0] VGA_pos_w;
    wire [2:0] showCnt_w;
    wire [2:0] a_cnt, b_cnt;

    checkKeypad keypadInst (
        .clk(divClk_100Hz),
        .rst(rst),
        .keypadCol(keypadCol),
        .keypadRow(keypadRow),
        .VGA_pos(keyPressed)
    );

    gameController gameControllerInst (
        .clk(divClk_2Hz),
        .rst(rst),
        .debug(debug_w),
        .isCorrect(isCircle_w),
        .keyPressed(keyPressed), 
        .round(round_w),
        .lives(lives_w),
        .state3(state3_w),
        .VGA_pos(VGA_pos_w),
        .chooseMode(mode_w),
        .AwinCNT(a_cnt),
        .BwinCNT(b_cnt),
        .start(start_w)
    );

    vgaDisplay vgaDisplayInst( 
        .clk(divClk_25MHz),
        .rst(rst),
        .state3(state3_w),
        .VGA_pos(VGA_pos_w),
        .isCircle(isCircle_w), 
        .hsync(hsync),
        .vsync(vsync),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );

    sevenDisplay sevenDisplayInst(
        .in(lives_w),
        .out(display)
    );
    
    sevenDisplay sevenDisplayInstMode12A(
        .in(a_cnt),
        .out(displayA)
    );

    sevenDisplay sevenDisplayInstMode12B(
        .in(b_cnt),
        .out(displayB)
    );

    dotMatrix dotMatrixInst(
        .clk(divClk_10000Hz),
        .start(start_w),
        .rst(rst),
        .round(round_w),
        .dot_row(dot_row),
        .dot_col(dot_col)
    );

endmodule

module gameController(
    input clk, rst,
    input [1:0]chooseMode, //模式(mode 0:單機,mode 1:雙人)
    input start,
    input [3:0] keyPressed,
    input debug,
    output reg [2:0] lives,
    output reg isCorrect, 
    output reg [3:0] state3,
	output reg [2:0] round,
    output reg [3:0] VGA_pos,
    output reg [2:0] AwinCNT, //玩家一比分
    output reg [2:0] BwinCNT //玩家二or電腦比分
);
	
    parameter R1 = 3'd1, R2 = 3'd2, R3 = 3'd3, R4 = 3'd4;

    // 狀態定義
    parameter IDLE=4'd0, SHOW_TASK=4'd1, PLAYING=4'd2,
              GAME_OVER=4'd3, WIN=4'd4, WAIT = 4'd5,
              TIC_TAC_TOE_player1win = 4'd6,TIC_TAC_TOE_player2win = 4'd7;

    reg [3:0] prevKeyPressed;
    reg [2:0] pressCnt;
	reg [2:0] showCnt;
    reg [2:0] waitCnt;
    reg [1:0] state;
    reg isFirstTime;

    reg turn; //目前誰要下
    reg [1:0] mode;
    reg [1:0] preMode;
    //reg [3:0] pos; //下在哪個位置 0~8,未輸入用4'd10代替
    reg [8:0] board1; //玩家一下的位置
    reg [8:0] board2; //玩家二or電腦下的位置
    reg [1:0] winner; //該局贏家:1,2 平手:3
    integer i;
    integer j;
    reg [3:0] bot_pos;

	//單機模式
    task chess1;
        if(turn == 1'd0) begin
			isCorrect = 1'd0;
            //讀入pos
            if(keyPressed != 4'd10) begin
                if((((1 << keyPressed) & board1) == 0) && (((1 << keyPressed) & board2) == 0)) begin
                    board1 = ((board1) | ((1 << keyPressed)));
                    VGA_pos = keyPressed;
					turn = turn ^ 1;
                end
            end
        end
        else if(turn == 1'd1) begin
            bot_pos = 4'd10; //沒-1用10代替
			isCorrect = 1'd1;
            //不下這格會輸
            for( i = 0 ; i < 3 ; i = i + 1) begin
                for( j = 0 ; j < 3 ; j = j + 1) begin
                    if(i == 0) begin
                        if(((board1 & (1 << (j + 3))) && (board1 & (1 << (j + 6)))) == 1) begin
                            if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                                bot_pos = j;
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                        else if(((board1 & (1 << (j * 3 + 1))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                            if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                                bot_pos = (j * 3);
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                    end
                    else if(i == 1) begin
                        if(((board1 & (1 << (j))) && (board1 & (1 << (j + 6)))) == 1) begin
                            if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                                bot_pos = j + 3;
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                        else if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 2)))) == 1) begin
                            if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                                bot_pos = (j * 3 + 1);
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
							    turn = turn ^ 1;
								disable chess1;
                            end
                        end
                    end
                    else if(i == 2) begin
                        if(((board1 & (1 << (j))) && (board1 & (1 << (j + 3)))) == 1) begin
                            if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                                bot_pos = j + 6;
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                        else if(((board1 & (1 << (j * 3))) && (board1 & (1 << (j * 3 + 1)))) == 1) begin
                            if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                                bot_pos = (j * 3 + 2);
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                    end
                end
            end
            //不下中間會輸
            if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
                if(((board1 & (1 << 0)) && (board1 & (1 << 8)))) begin
                    bot_pos = 4'd4;
                    VGA_pos = bot_pos;
                    board2 = (board2 | (1 << bot_pos));
                    turn = turn ^ 1;
                    disable chess1;
                end
                else if(((board1 & (1 << 2)) && (board1 & (1 << 6)))) begin
                    bot_pos = 4'd4;
                    VGA_pos = bot_pos;
                    board2 = (board2 | (1 << bot_pos));
                    turn = turn ^ 1;
                    disable chess1;
                end
            end
            //下這格會贏
            for( i = 0 ; i < 3 ; i = i + 1) begin
                for( j = 0 ; j < 3 ; j = j + 1) begin
                    if(i == 0) begin
                        if(((board2 & (1 << (j + 3))) && (board2 & (1 << (j + 6)))) == 1) begin
                            if(((board1 & (1 << j)) || (board2 & (1 << j))) == 0) begin
                                bot_pos = j;
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                        else if(((board2 & (1 << (j * 3 + 1))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                            if(((board1 & (1 << (j * 3))) || (board2 & (1 << (j * 3)))) == 0) begin
                                bot_pos = (j * 3);
								VGA_pos = bot_pos;
								board2 = (board2 | (1 << bot_pos));
								turn = turn ^ 1;
								disable chess1;
                            end
                        end
                    end
                    else if(i == 1) begin
                        if(((board2 & (1 << (j))) && (board2 & (1 << (j + 6)))) == 1) begin
                            if(((board1 & (1 << (j + 3))) || (board2 & (1 << (j + 3)))) == 0) begin
                                bot_pos = j + 3;
                                VGA_pos = bot_pos;
                                board2 = (board2 | (1 << bot_pos));
                                turn = turn ^ 1;
                                disable chess1;
                            end
                        end
                        else if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 2)))) == 1) begin
                            if(((board1 & (1 << (j * 3 + 1))) || (board2 & (1 << (j * 3 + 1)))) == 0) begin
                                bot_pos = (j * 3 + 1);
                                VGA_pos = bot_pos;
                                board2 = (board2 | (1 << bot_pos));
                                turn = turn ^ 1;
                                disable chess1;
                            end
                        end
                    end
                    else if(i == 2) begin
                        if(((board2 & (1 << (j))) && (board2 & (1 << (j + 3)))) == 1) begin
                            if(((board1 & (1 << (j + 6))) || (board2 & (1 << (j + 6)))) == 0) begin
                                bot_pos = j + 6;
                                VGA_pos = bot_pos;
                                board2 = (board2 | (1 << bot_pos));
                                turn = turn ^ 1;
                                disable chess1;
                            end
                        end
                        else if(((board2 & (1 << (j * 3))) && (board2 & (1 << (j * 3 + 1)))) == 1) begin
                            if(((board1 & (1 << (j * 3 + 2))) || (board2 & (1 << (j * 3 + 2)))) == 0) begin
                                bot_pos = (j * 3 + 2);
                                VGA_pos = bot_pos;
                                board2 = (board2 | (1 << bot_pos));
                                turn = turn ^ 1;
                                disable chess1;
                            end
                        end
                    end
                end
            end
            //下中間會贏
            if(((board1 & (1 << 4)) || (board2 & (1 << 4))) == 0) begin
                if(((board2 & (1 << 0)) && (board2 & (1 << 8)))) begin
                    bot_pos = 4'd4;
                    VGA_pos = bot_pos;
                    board2 = (board2 | (1 << bot_pos));
                    turn = turn ^ 1;
                    disable chess1;
                end
                else if(((board2 & (1 << 2)) && (board2 & (1 << 6)))) begin
                    bot_pos = 4'd4;
                    VGA_pos = bot_pos;
                    board2 = (board2 | (1 << bot_pos));
                    turn = turn ^ 1;
                    disable chess1;
                end
            end
            //隨便選一格下
            if(bot_pos == 4'd10) begin
                for( i = 0 ; i < 9 ; i = i + 1) begin
                    if(((board1 & (1 << i)) || (board2 & (1 << i))) == 0) begin
                        bot_pos = i;
                        isCorrect = 1'd1;
                        VGA_pos = bot_pos;
                        board2 = (board2 | (1 << bot_pos));
                        turn = turn ^ 1;
                        disable chess1;
                    end
                end
            end
        end
    endtask

    //雙人模式
    task chess2;
        //玩家1
        if(turn == 0) begin
            //讀入pos
            if(keyPressed != 4'd10) begin
                if(((1 << keyPressed) & board1) == 0 && ((1 << keyPressed) & board2) == 0) begin
                    board1 = (board1 | (1 << keyPressed));
                    turn = turn ^ 1;
                    isCorrect <= 1'd0;
                    VGA_pos <= keyPressed;
                end
            end
        end
        //玩家2
        else if(turn == 1) begin
            //讀入pos
            if(keyPressed != 4'd10) begin
                if(((1 << keyPressed) & board1) == 0 && ((1 << keyPressed) & board2) == 0) begin
                    board2 = (board2 | (1 << keyPressed));
                    turn = turn ^ 1;
                    isCorrect <= 1'd1;
                    VGA_pos <= keyPressed;
                end
            end
        end
    endtask

    //檢查有沒有人贏
    task checkwin;
		begin
            if(debug == 1) winner <= 2'd1;
            /*
            board開1 << 9然後AND 1 << x去判斷第x位置
            1 2 4
            8 16 32
            64 128 256
            */
            for( i = 0 ; i < 3 ; i = i + 1) begin
                if(((board1 & (1 << (i * 3))) && (board1 & (1 << (i * 3 + 1))) && (board1 & (1 << (i * 3 + 2)))) == 1) begin
                    winner <= 2'd1;
                    disable checkwin;
                end
                else if(((board1 & (1 << i)) && (board1 & (1 << (i + 3))) && (board1 & (1 << (i + 6)))) == 1) begin
                    winner <= 2'd1;
                    disable checkwin;
                end
                else if(((board2 & (1 << (i * 3))) && (board2 & (1 << (i * 3 + 1))) && (board2 & (1 << (i * 3 + 2)))) == 1) begin
                    winner <= 2'd2;
                    disable checkwin;
                end
                else if(((board2 & (1 << i)) && (board2 & (1 << (i + 3))) && (board2 & (1 << (i + 6)))) == 1) begin
                    winner <= 2'd2;
                    disable checkwin;
                end
            end
            if((board1 & 1) && (board1 & 16) && (board1 & 256)) begin
                winner <= 2'd1;
                disable checkwin;
            end
            else if((board1 & 4) && (board1 & 16) && (board1 & 64)) begin
                winner <= 2'd1;
                disable checkwin;
            end
            else if((board2 & 1) && (board2 & 16) && (board2 & 256)) begin
                winner <= 2'd2;
                disable checkwin;
            end
            else if((board2 & 4) && (board2 & 16) && (board2 & 64)) begin
                winner <= 2'd2;
                disable checkwin;
            end
            else if((board1 + board2) == ((1 << 9) - 1) && winner == 0) begin
                winner <= 2'd3; //平手
                disable checkwin;
            end
	    end
    endtask
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
			VGA_pos <= 4'b1111;
            state3 <= IDLE;
            isCorrect <= 1'd0;
			round <= 3'd1;
            waitCnt <= 2'd0;
            pressCnt <= 3'd0;
            prevKeyPressed <= 4'b1111;
            state <= 2'd0;
			mode <= chooseMode;
            preMode <= chooseMode;
			turn = 1'b0;
			board1 = 1'b0;
			board2 = 1'b0;
            isFirstTime <= 1'd1;
        end
        else begin
            if(start == 1'd1) begin
                if( chooseMode != preMode ) begin
                    round <= 3'd1;
                    lives <= 3'd6;
                    AwinCNT = 3'd6;  
                    BwinCNT = 3'd6;
                    preMode <= mode;
                end
                //遊戲一、二
                if((chooseMode == 2'd0) || (chooseMode == 2'd1)) begin
                    //待輸入mode
                    if(state == 2'd0) begin
                        state3 <= IDLE;
                        mode <= chooseMode;
                        state <= 2'd1;
                    end
                    //遊戲初始化
                    else if(state == 2'd1) begin
                        if( round <= 3'd1 ) begin
                            AwinCNT = 3'd0;
                            BwinCNT = 3'd0;
                            board1 = 9'd0;
                            board2 = 9'd0;
                            winner = 2'd0;
                            turn = 1'd0;
                        end
                        state <= 2'd2;
                    end
                    //遊戲進行中
                    else if(state == 2'd2) begin
                        state3 <= PLAYING;
                        //單機模式
                        if(mode == 2'd0) begin
                            chess1();
                        end
                        //雙人模式
                        else if(mode == 2'd1) begin
                            chess2();
                        end
                        checkwin();
                        //遊戲結束
                        if(winner != 2'd0) begin
                            state <= 2'd3;
                        end
                    end
                    //結束遊戲
                    else if(state == 2'd3) begin
                        state <= 2'd0;
                        round <= round + 1;
                        if( winner == 2'd1 ) AwinCNT = AwinCNT + 1;
                        else if( winner == 2'd2 ) BwinCNT = BwinCNT + 1;
						else round <= round - 1;
                        if(round <= 3'd5 && winner != 2'd3) begin // 因為 round 的增加會在下一個 clk 來時，所以在這裡要判斷 3'd5
                            round <= 3'd1;
                            if(AwinCNT > BwinCNT) state3 <= TIC_TAC_TOE_player1win;
                            else state3 <= TIC_TAC_TOE_player2win;
                        end
                    end
                end 
                //遊戲三
                else if(chooseMode == 2'd2) begin
                    if(isFirstTime == 1'd1) begin
                        lives <= 3'd3;
                        isFirstTime <= ~isFirstTime;
                    end
                    case(state3)
                        IDLE: begin
                            if(waitCnt == 2'd1) begin
                                waitCnt <= 2'd0;
                                case(showCnt)
                                    3'd0: VGA_pos <= 4'd0;
                                    3'd1: VGA_pos <= 4'd4;
                                    3'd2: VGA_pos <= 4'd8;
                                endcase
                                if(showCnt == 3'd3) begin
                                    showCnt <= 3'd0;
                                    VGA_pos <= 4'b1111;
                                    state3 <= SHOW_TASK;
                                end
                                else showCnt <= showCnt + 1'd1;
                            end
                            else waitCnt <= waitCnt + 1'd1;
                        end
                        SHOW_TASK: begin
                        case(round)
                            R1: begin
                                case (showCnt)
                                    3'd0: VGA_pos <= 3'd5;
                                    3'd1: VGA_pos <= 3'd4;
                                    3'd2: VGA_pos <= 3'd3;
                                endcase
                                if(showCnt == 3'd3) begin
                                    showCnt <= 3'd0;
                                    VGA_pos <= 4'b1111;
                                    state3 <= PLAYING;
                                end
                                else showCnt <= showCnt + 1;
                            end
                            R2: begin
                                case (showCnt)
                                    3'd0: VGA_pos <= 3'd5;
                                    3'd1: VGA_pos <= 3'd0;
                                    3'd2: VGA_pos <= 3'd4;
                                    3'd3: VGA_pos <= 3'd2;
                                    3'd4: VGA_pos <= 3'd7;
                                endcase
                                if(showCnt == 3'd5) begin
                                    showCnt <= 3'd0;
                                    VGA_pos <= 4'b1111;
                                    state3 <= PLAYING;
                                end
                                else showCnt <= showCnt + 1;
                            end
                            R3: begin
                                case (showCnt)
                                    3'd0: VGA_pos <= 3'd6;
                                    3'd1: VGA_pos <= 3'd5;
                                    3'd2: VGA_pos <= 3'd1;
                                    3'd3: VGA_pos <= 3'd4;
                                    3'd4: VGA_pos <= 3'd2;
                                    3'd5: VGA_pos <= 3'd3;
                                endcase
                                if(showCnt == 3'd6) begin
                                    showCnt <= 3'd0;
                                    VGA_pos <= 4'b1111;
                                    state3 <= PLAYING;
                                end
                                else showCnt <= showCnt + 1;
                            end
                            R4: begin
                                case (showCnt)
                                    3'd0: VGA_pos <= 3'd1;
                                    3'd1: VGA_pos <= 3'd7;
                                    3'd2: VGA_pos <= 3'd6;
                                    3'd3: VGA_pos <= 3'd5;
                                    3'd4: VGA_pos <= 3'd2;
                                    3'd5: VGA_pos <= 3'd3;
                                    3'd6: VGA_pos <= 3'd6;
                                endcase
                                if(showCnt == 3'd7) begin
                                    VGA_pos <= 4'b1111;
                                    showCnt <= 3'd0;
                                    state3 <= PLAYING;
                                end
                                else showCnt <= showCnt + 1;
                                end
                                default: showCnt <= showCnt;
                        endcase
                        end
                        PLAYING: begin
                            if (keyPressed != prevKeyPressed) begin
                                prevKeyPressed <= keyPressed;  // 更新 prevKeyPressed
                                case (round)
                                    R1: begin
                                        case (pressCnt)
                                            3'd0: begin
                                                if(keyPressed == 4'd5) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd1: begin
                                                if(keyPressed == 4'd4) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd2: begin
                                                if(keyPressed == 4'd3) begin
                                                    isCorrect <= 1'd1;
                                                    round <= round + 1'b1;
                                                    state3 <= WAIT;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                        endcase
                                    end
                                    R2: begin
                                        case (pressCnt)
                                            3'd0: begin
                                                if(keyPressed == 4'd5) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd1: begin
                                                if(keyPressed == 4'd0) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd2: begin
                                                if(keyPressed == 4'd4) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd3: begin
                                                if(keyPressed == 4'd2) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd4: begin
                                                if(keyPressed == 4'd7) begin
                                                    isCorrect <= 1'd1;
                                                    round <= round + 1'b1;
                                                    state3 <= WAIT;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                        endcase
                                    end
                                    R3: begin
                                        case (pressCnt)
                                            3'd0: begin
                                                if(keyPressed == 4'd6) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd1: begin
                                                if(keyPressed == 4'd5) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                                
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end 
                                            3'd2: begin
                                                if(keyPressed == 4'd1) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end 
                                            3'd3: begin
                                                if(keyPressed == 4'd4) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd4: begin
                                                if(keyPressed == 4'd2) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd5: begin
                                                if(keyPressed == 4'd3) begin
                                                    isCorrect <= 1'd1;
                                                    round <= round + 1'b1;
                                                    state3 <= WAIT;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                        endcase
                                    end
                                    R4: begin
                                        case (pressCnt)
                                            3'd0: begin
                                                if(keyPressed == 4'd1) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end    
                                            3'd1: begin
                                                if(keyPressed == 4'd7) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end    
                                            3'd2: begin
                                                if(keyPressed == 4'd6) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end 
                                            3'd3: begin
                                                if(keyPressed == 4'd5) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end 
                                            3'd4: begin
                                                if(keyPressed == 4'd2) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd5: begin
                                                if(keyPressed == 4'd3) begin
                                                    isCorrect <= 1'd1;
                                                    pressCnt <= pressCnt + 1'b1;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                            3'd6: begin
                                                if(keyPressed == 4'd6) begin
                                                    isCorrect <= 1'd1;
                                                    state3 <= WAIT;
                                                end
                                                else begin
                                                    isCorrect <= 1'd0;
                                                    lives <= lives - 1'b1;
                                                    state3 <= WAIT;
                                                end
                                            end
                                        endcase
                                    end
                                endcase
                                VGA_pos <= keyPressed;
                                        
                            end
                        end
                        WAIT: begin
                            if(waitCnt == 3'd1) begin
                                waitCnt <= 3'd0;
                                VGA_pos <= 4'b1111;
                                pressCnt <= 3'd0;
                                if(lives > 2'd0) begin
                                    if(pressCnt == 3'd6 && isCorrect) begin
                                        state3 <= WIN;
                                    end
                                    else begin										
                                        isCorrect <= ~isCorrect;
                                        state3 <= IDLE;
                                    end
                                end
                                else state3 <= GAME_OVER;
                            end
                            else waitCnt <= waitCnt + 2'b1;
                        end
                        GAME_OVER: begin
                            case(waitCnt)   // 顯示一個大叉叉，由上到下左到右
                                3'd0: VGA_pos <= 4'd0;
                                3'd1: VGA_pos <= 4'd2;
                                3'd2: VGA_pos <= 4'd4;
                                3'd3: VGA_pos <= 4'd6;
                                3'd4: VGA_pos <= 4'd8;
                            endcase
                            waitCnt <= waitCnt + 1'b1;
                        end
                        WIN: begin
                        case(waitCnt)   // 顯示一個大圈圈
                                3'd0: VGA_pos <= 4'd1;
                                3'd1: VGA_pos <= 4'd3;
                                3'd2: VGA_pos <= 4'd5;
                                3'd3: VGA_pos <= 4'd7;
                                3'd4: VGA_pos <= 4'd4;
                        endcase
                        waitCnt <= waitCnt + 1'd1;
                        end
                    endcase
                end
            end
            else begin
                state3 <= IDLE;
                isFirstTime <= 1'b1;
                round <= 1;
                lives <= 3'd6;
                AwinCNT = 3'd6;
                BwinCNT = 3'd6;
				preMode <= mode; 
            end
        end
        
    end
endmodule

module checkKeypad(
    input [3:0] keypadCol,
    input clk, rst,  // 100Hz 
    output reg [3:0] keypadRow,
    output reg [3:0] VGA_pos
); 
 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            keypadRow <= 4'b1110;    
            VGA_pos <= 4'b1111;   
        end
        else begin
            case({keypadRow, keypadCol})
                8'b1011_0111: begin
                    VGA_pos <= 4'd0;
                end
                8'b1011_1011: begin 
                    VGA_pos <= 4'd1;
                end
                8'b1011_1101: begin
                    VGA_pos <= 4'd2;
                end
                8'b1101_0111: begin
                    VGA_pos <= 4'd3;
                end
                8'b1101_1011: begin 
                    VGA_pos <= 4'd4;
                end
                8'b1101_1101: begin 
                    VGA_pos <= 4'd5;
                end
                8'b1110_0111: begin
                    VGA_pos <= 4'd6;
                end
                8'b1110_1011: begin 
                    VGA_pos <= 4'd7;
                end
                8'b1110_1101: begin
                    VGA_pos <= 4'd8;
                end
                default: begin
                    VGA_pos <= VGA_pos;
                end
            endcase
                
            case(keypadRow)
                4'b1011: keypadRow <= 4'b1101;
                4'b1101: keypadRow <= 4'b1110;
                4'b1110: keypadRow <= 4'b1011;
                default: keypadRow <= 4'b1011;
            endcase
        end
    end
endmodule

module divider #(
    parameter TIME_EXPIRE = 32'd250000 
)(
    input clk,
    input rst,
    output reg divClk
);
    reg [31:0] cnt;

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            cnt <= 0;
            divClk <= 1'b0;
        end
        else begin
            if(cnt == TIME_EXPIRE - 1) begin
                cnt <= 32'd0;
                divClk <= ~divClk;
            end
            else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule

module sevenDisplay(
	input [3:0] in,
	output reg [6:0] out
);

always@(in)
begin
	case(in)
		4'd0: out = 7'b1000000;
		4'd1: out = 7'b1111001;
		4'd2: out = 7'b0100100;
		4'd3: out = 7'b0110000;
		4'd4: out = 7'b0011001;
		4'd5: out = 7'b0010010;
		//4'd6: out = 7'b0000010;
		//4'd7: out = 7'b1111000;
		//4'd8: out = 7'b0000000;
		//4'd9: out = 7'b0010000;
		//4'd10: out = 7'b0001000;
		//4'd11: out = 7'b0000011;
		//4'd12: out = 7'b1000110;
		//4'd13: out = 7'b0100001;
		//4'd14: out = 7'b0000110;
		default: out = 7'b1111111;
	endcase
end
endmodule 

module vgaDisplay(
    input  clk, rst,
    input  [3:0] state3,
    input  [3:0] VGA_pos,
    input  isCircle,
    output hsync, vsync,
    output reg [3:0] VGA_R, VGA_G, VGA_B
);

    //==== VGA 計數器 ====
    reg [9:0] h_cnt, v_cnt;
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end
        else begin
            if(h_cnt == 799) begin
                h_cnt <= 10'd0;
                if(v_cnt == 524)
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end
            else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    //==== VGA sync ====
    assign hsync = ~((h_cnt >= 656) && (h_cnt < 752));
    assign vsync = ~((v_cnt >= 490) && (v_cnt < 492));

    parameter CELL_SIZE = 160;  
    parameter GRID_COLS = 3;   // 3 欄
    parameter GRID_ROWS = 3;   // 3 行
	 
	parameter IDLE = 4'd0, SHOW_TASK = 4'd1, PLAYING = 4'd2,
              GAME_OVER = 4'd3, WIN = 4'd4, WAIT = 4'd5,TIC_TAC_TOE_player1win = 4'd6,TIC_TAC_TOE_player2win = 4'd7;

    //==== 要把 3×160=480 的區域置中 => 左邊 offset_x=80 ====
    localparam OFFSET_X = 80;  // 左邊留 80 px
    localparam GRID_WIDTH = GRID_COLS * CELL_SIZE; // 3*160=480

    //---- 計算 "有效繪畫區" 的 h_mod / v_mod ----
    //    若在 [OFFSET_X .. OFFSET_X+480) 內，就對應到 0～480，
    //    否則視為畫面外(左黑邊/右黑邊)。
    wire [9:0] h_mod;
    wire inRangeX = (h_cnt >= OFFSET_X && h_cnt < OFFSET_X + GRID_WIDTH);
    assign h_mod = (inRangeX) ? (h_cnt - OFFSET_X) : 10'd1023; 

    // 垂直方向正好 480(3×160) => offset_y=0
    wire inRangeY = (v_cnt < GRID_ROWS*CELL_SIZE); 
    wire [9:0] v_mod = (inRangeY) ? v_cnt : 10'd1023;

    //---- 根據 h_mod,v_mod 計算 col, row ----
    wire [1:0] col = (h_mod < GRID_WIDTH) ? (h_mod / CELL_SIZE) : 2'd3; 
    wire [1:0] row = (v_mod < GRID_WIDTH) ? (v_mod / CELL_SIZE) : 2'd3;

    //---- 計算 index (0~8) ----
    wire col_valid = (col < GRID_COLS); // col=3 => invalid
    wire row_valid = (row < GRID_ROWS);
    wire [3:0] index = row*GRID_COLS + col;

    //---- local_x, local_y ----
    wire [9:0] local_x = h_mod - (col * CELL_SIZE); 
    wire [9:0] local_y = v_mod - (row * CELL_SIZE);

    //==== grid array & prevState ====
    reg [1:0] grid[0:8]; // 0=空,1=叉,2=圈
    reg [2:0] prevState;
    integer i;

    //==== 狀態改變 => 清空 grid ====
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            for(i=0;i<9;i=i+1) begin
                grid[i] <= 2'b00;
            end
            prevState <= IDLE; 
        end
        else begin
            // 狀態切換
            if(state3 == SHOW_TASK || (prevState != state3 && state3 != WAIT)) begin
                for(i=0;i<9;i=i+1) grid[i] <= 2'b00;
                prevState <= state3;
            end
            // 模式一、二 的 玩家一贏
            if(state3 == TIC_TAC_TOE_player1win) begin
                for(i = 0 ; i < 9 ; i = i + 1) begin
                    grid[i] <= 2'd0;
                end
            end
            // 模式一、二 的 玩家二贏
            if(state3 == TIC_TAC_TOE_player2win) begin
                for(i = 0 ; i < 9 ; i = i + 1) begin
                    grid[i] <= 2'd1;
                end
            end
            // 當 VGA_pos<9 時 => 寫入對應格
            if(VGA_pos < 4'd9) begin
                case(state3)
                    IDLE, SHOW_TASK: begin
                        grid[VGA_pos] <= 2'd2;
                    end
                    PLAYING, WAIT, GAME_OVER, WIN: begin
                        grid[VGA_pos] <= (isCircle) ? 2'd2 : 2'd1;
                    end
                    TIC_TAC_TOE_player1win: begin
                        grid[VGA_pos] <= 2'd0;
                    end
                    TIC_TAC_TOE_player2win: begin
                        grid[VGA_pos] <= 2'd1;
                    end
                endcase
            end
        end
    end

    parameter CELL_THICKNESS = 4; // 線條寬度
    parameter CELL_OFFSET = 15;   // 控制縮小比例 (數值越大，叉叉越小)

    always @(posedge clk) begin
        // 預設為黑色
        VGA_R <= 4'h0;
        VGA_G <= 4'h0;
        VGA_B <= 4'h0;

        if(h_cnt < 640 && v_cnt < 480) begin
            if (((h_cnt >= OFFSET_X + CELL_SIZE - CELL_THICKNESS/2 && h_cnt <= OFFSET_X + CELL_SIZE + CELL_THICKNESS/2) ||
                (h_cnt >= OFFSET_X + 2 * CELL_SIZE - CELL_THICKNESS/2 && h_cnt <= OFFSET_X + 2 * CELL_SIZE + CELL_THICKNESS/2)) && inRangeY) begin
                // 加粗垂直線條
                VGA_R <= 4'hF;
                VGA_G <= 4'hF;
                VGA_B <= 4'hF;
            end 
            else if (((v_cnt >= CELL_SIZE - CELL_THICKNESS/2 && v_cnt <= CELL_SIZE + CELL_THICKNESS/2) ||
                    (v_cnt >= 2 * CELL_SIZE - CELL_THICKNESS/2 && v_cnt <= 2 * CELL_SIZE + CELL_THICKNESS/2)) && inRangeX) begin
                // 加粗水平線條
                VGA_R <= 4'hF;
                VGA_G <= 4'hF;
                VGA_B <= 4'hF;
            end 
            else if( col_valid && row_valid) begin
                case(grid[index])
                    2'b01: begin

                        if ((local_x >= local_y - CELL_THICKNESS && local_x <= local_y + CELL_THICKNESS && 
                                local_x >= CELL_OFFSET && local_y >= CELL_OFFSET && 
                                local_x < CELL_SIZE - CELL_OFFSET && local_y < CELL_SIZE - CELL_OFFSET) ||
                                (local_x + local_y >= CELL_SIZE - 1 - CELL_THICKNESS && 
                                local_x + local_y <= CELL_SIZE - 1 + CELL_THICKNESS &&
                                local_x >= CELL_OFFSET && local_y >= CELL_OFFSET && 
                                local_x < CELL_SIZE - CELL_OFFSET && local_y < CELL_SIZE - CELL_OFFSET)) begin
                                VGA_R <= 4'hff;
                                VGA_G <= 4'hc0;
                                VGA_B <= 4'hcb;
                        end
                    end
                    2'b10: begin
                        if(state3 == IDLE) begin
                            if ((((local_x - CELL_SIZE/2)**2 + (local_y - CELL_SIZE/2)**2) <= (CELL_SIZE/3)**2)) begin
                                VGA_R <= 4'hf;
                                VGA_G <= 4'hf;
                                VGA_B <= 4'hf;
                            end
                        end
                        else begin
                            // 空心圓
                            if ((((local_x - CELL_SIZE/2)**2 + (local_y - CELL_SIZE/2)**2) >= (CELL_SIZE/3 - 6)**2) &&
                                (((local_x - CELL_SIZE/2)**2 + (local_y - CELL_SIZE/2)**2) <= (CELL_SIZE/3 + 6)**2)) begin
                                if(state3 == WIN) begin
                                    VGA_R <= 4'h0; // 綠色
                                    VGA_G <= 4'hf;
                                    VGA_B <= 4'h0;
                                end
                                else begin
                                    VGA_R <= 4'h0;  // 藍色
                                    VGA_G <= 4'h0;
                                    VGA_B <= 4'hf;
                                end
                            end
                        end
                    end 
                    default: begin
                        VGA_R <= 4'h0;
                        VGA_G <= 4'h0;
                        VGA_B <= 4'h0;
                    end
                endcase
            end
        end
    end
endmodule 

module dotMatrix(
    input rst,
    input clk,
    input start,
    input round,
    output reg [7:0] dot_row,
    output reg [7:0] dot_col
);

    reg [2:0] output_cnt;
    always@( posedge clk or negedge rst ) begin
        if( !rst ) 
        begin
            output_cnt <= 0;
            dot_row <= 8'b0;
            dot_col <= 8'b0; 
        end
        else
        begin
            if( start ) begin
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

                if( round <= 3'd1 ) begin
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
                else if( round <= 3'd2 ) begin
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
                else if( round <= 3'd3 ) begin
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
                else if( round <= 3'd4) begin
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
                else if( round <= 3'd5 ) begin
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
            else dot_col <= 8'b0;
        end

    end

endmodule 