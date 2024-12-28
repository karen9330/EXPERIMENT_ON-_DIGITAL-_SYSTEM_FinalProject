`define TimeExpire_100Hz 32'd250000
`define TimeExpire_25MHz 32'd1
`define TimeExpire_2Hz 32'd12500000
`define TimeExpire_1Hz 32'd25000000

module main(
    input clk, rst,
    input [3:0] keypadCol,
    output hsync, vsync,
    output [3:0] VGA_R, VGA_G, VGA_B,
    output [6:0] display,  
    output [3:0] keypadRow 
);
    wire divClk_1Hz, divClk_2Hz, divClk_100Hz, divClk_25MHz;

    // 1Hz 時鐘分頻
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

    // 100Hz 時鐘分頻
    divider #(
        .TIME_EXPIRE(`TimeExpire_100Hz)
    ) divider_100Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_100Hz)
    );

    // 2Hz 時鐘分頻
    divider #(
        .TIME_EXPIRE(`TimeExpire_2Hz)
    ) divider_2Hz(
        .clk(clk),
        .rst(rst),
        .divClk(divClk_2Hz)
    );

    wire isCircle_w;
    wire [1:0] round_w, lives_w;
    wire [3:0] keyPressed; 
    wire [2:0] state_w;
    wire [3:0] position_w;
    wire [2:0] showCnt_w;

    //====================================================
    // Keypad 檢測模組
    //====================================================
    checkKeypad keypadInst (
        .clk(divClk_100Hz),
        .rst(rst),
        .keypadCol(keypadCol),
        .keypadRow(keypadRow),
        .position(keyPressed)
    );

    //====================================================
    // GameController (FSM)
    //====================================================
    gameController gameControllerInst (
        .clk(divClk_2Hz),
        .rst(rst),
        .isCorrect(isCircle_w),
        .keyPressed(keyPressed), 
        .round(round_w),
        .lives(lives_w),
        .state(state_w),
        .position(position_w)
    );

    //====================================================
    // VGA 顯示
    //====================================================
    vgaDisplay vgaDisplayInst( 
        .clk(divClk_25MHz),
        .rst(rst),
        .state(state_w),
        .position(position_w),
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

endmodule


//====================================================
// gameController
//====================================================
module gameController(
    input clk, rst,
    input [3:0] keyPressed,
    output reg isCorrect, 
    output reg [2:0] state,
	output reg [1:0] round,
    output reg [1:0] lives,
    output reg [3:0] position
);
	
    parameter R1 = 2'd0, R2 = 2'd1, R3 = 2'd2, R4 = 2'd3;

    // 狀態定義
    parameter IDLE=3'd0, SHOW_TASK=3'd1, PLAYING=3'd2,
              GAME_OVER=3'd3, WIN=3'd4, WAIT = 3'd5;

    reg [3:0] prevKeyPressed;
    reg [2:0] pressCnt;
	reg [2:0] showCnt;
    reg [2:0] waitCnt;
	 	
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
			position <= 4'b1111;
            state <= IDLE;
            isCorrect <= 1'd0;
			round <= 2'd0;
            lives <= 2'd3;
            waitCnt <= 2'd0;
            pressCnt <= 3'd0;
            prevKeyPressed <= 4'b1111;
        end 
        else begin
            case(state)
                IDLE: begin
                    if(waitCnt == 2'd1) begin
                        waitCnt <= 2'd0;
                        case(showCnt)
                            3'd0: position <= 4'd0;
                            3'd1: position <= 4'd4;
                            3'd2: position <= 4'd8;
                        endcase
                        if(showCnt == 3'd3) begin
                            showCnt <= 3'd0;
                            position <= 4'b1111;
                            state <= SHOW_TASK;
                        end
                        else showCnt <= showCnt + 1'd1;
                    end
                    else waitCnt <= waitCnt + 1'd1;
                end
                SHOW_TASK: begin
                case(round)
                    R1: begin
                        case (showCnt)
                            3'd0: position <= 3'd5;
                            3'd1: position <= 3'd4;
                            3'd2: position <= 3'd3;
                        endcase
                        if(showCnt == 3'd3) begin
                            showCnt <= 3'd0;
                            position <= 4'b1111;
                            state <= PLAYING;
                        end
                        else showCnt <= showCnt + 1;
                    end
                    R2: begin
                        case (showCnt)
                            3'd0: position <= 3'd5;
                            3'd1: position <= 3'd0;
                            3'd2: position <= 3'd4;
                            3'd3: position <= 3'd2;
                            3'd4: position <= 3'd7;
                        endcase
                        if(showCnt == 3'd5) begin
                            showCnt <= 3'd0;
                            position <= 4'b1111;
                            state <= PLAYING;
                        end
                        else showCnt <= showCnt + 1;
                    end
                    R3: begin
                        case (showCnt)
                            3'd0: position <= 3'd6;
                            3'd1: position <= 3'd5;
                            3'd2: position <= 3'd1;
                            3'd3: position <= 3'd4;
                            3'd4: position <= 3'd2;
                            3'd5: position <= 3'd3;
                        endcase
                        if(showCnt == 3'd6) begin
                            showCnt <= 3'd0;
                            position <= 4'b1111;
                            state <= PLAYING;
                        end
                        else showCnt <= showCnt + 1;
                    end
                    R4: begin
                        case (showCnt)
                            3'd0: position <= 3'd1;
                            3'd1: position <= 3'd7;
                            3'd2: position <= 3'd6;
                            3'd3: position <= 3'd5;
                            3'd4: position <= 3'd2;
                            3'd5: position <= 3'd3;
                            3'd6: position <= 3'd6;
                        endcase
                        if(showCnt == 3'd7) begin
                            position <= 4'b1111;
                            showCnt <= 3'd0;
                            state <= PLAYING;
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
                                            state <= WAIT;
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
											state <= WAIT;
                                        end
                                    end
                                    3'd2: begin
                                        if(keyPressed == 4'd3) begin
                                            isCorrect <= 1'd1;
                                            round <= round + 1'b1;
                                            state <= WAIT;
                                        end
                                        else begin
                                            isCorrect <= 1'd0;
                                            lives <= lives - 1'b1;
											state <= WAIT;
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
                                            state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
                                        end
                                    end
                                    3'd4: begin
                                        if(keyPressed == 4'd7) begin
                                            isCorrect <= 1'd1;
                                            round <= round + 1'b1;
                                            state <= WAIT;
                                        end
                                        else begin
                                            isCorrect <= 1'd0;
                                            lives <= lives - 1'b1;
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
                                        end
                                    end
                                    3'd5: begin
                                        if(keyPressed == 4'd3) begin
                                            isCorrect <= 1'd1;
                                            round <= round + 1'b1;
                                            state <= WAIT;
                                        end
                                        else begin
                                            isCorrect <= 1'd0;
                                            lives <= lives - 1'b1;
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
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
											state <= WAIT;
                                        end
                                    end
                                    3'd6: begin
                                        if(keyPressed == 4'd6) begin
                                            isCorrect <= 1'd1;
                                            state <= WAIT;
                                        end
                                        else begin
                                            isCorrect <= 1'd0;
                                            lives <= lives - 1'b1;
											state <= WAIT;
                                        end
                                    end
                                endcase
                            end
                        endcase
                        position <= keyPressed;
								
                    end
                end
                WAIT: begin
                    if(waitCnt == 3'd1) begin
                        waitCnt <= 3'd0;
                        position <= 4'b1111;
                        pressCnt <= 3'd0;
                        if(lives > 2'd0) begin
                            if(pressCnt == 3'd6 && isCorrect) begin
                                state <= WIN;
                            end
                            else begin										
                                isCorrect <= ~isCorrect;
                                state <= IDLE;
                            end
                        end
                        else state <= GAME_OVER;
                    end
                    else waitCnt <= waitCnt + 2'b1;
                end
                GAME_OVER: begin
                    case(waitCnt)   // 顯示一個大叉叉，由上到下左到右
                        3'd0: position <= 4'd0;
                        3'd1: position <= 4'd2;
                        3'd2: position <= 4'd4;
                        3'd3: position <= 4'd6;
                        3'd4: position <= 4'd8;
                    endcase
                    waitCnt <= waitCnt + 1'b1;
                end
                WIN: begin
                case(waitCnt)   // 顯示一個大叉叉，由上到下左到右
                        3'd0: position <= 4'd1;
                        3'd1: position <= 4'd3;
                        3'd2: position <= 4'd5;
                        3'd3: position <= 4'd7;
                        3'd4: position <= 4'd4;
                endcase
                waitCnt <= waitCnt + 1'd1;
                end
            endcase
        end
    end
endmodule

//====================================================
// keypad
//====================================================
module checkKeypad(
    input [3:0] keypadCol,
    input clk, rst,  // 100Hz 
    output reg [3:0] keypadRow,
    output reg [3:0] position
); 
 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            keypadRow <= 4'b1110;    
            position <= 4'b1111;   
        end
        else begin
            case({keypadRow, keypadCol})
                8'b1011_0111: begin
                    position <= 4'd0;
                end
                8'b1011_1011: begin 
                    position <= 4'd1;
                end
                8'b1011_1101: begin
                    position <= 4'd2;
                end
                8'b1101_0111: begin
                    position <= 4'd3;
                end
                8'b1101_1011: begin 
                    position <= 4'd4;
                end
                8'b1101_1101: begin 
                    position <= 4'd5;
                end
                8'b1110_0111: begin
                    position <= 4'd6;
                end
                8'b1110_1011: begin 
                    position <= 4'd7;
                end
                8'b1110_1101: begin
                    position <= 4'd8;
                end
                default: begin
                    position <= position;
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

//====================================================
// divider
//====================================================
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
		4'd6: out = 7'b0000010;
		4'd7: out = 7'b1111000;
		4'd8: out = 7'b0000000;
		4'd9: out = 7'b0010000;
		4'd10: out = 7'b0001000;
		4'd11: out = 7'b0000011;
		4'd12: out = 7'b1000110;
		4'd13: out = 7'b0100001;
		4'd14: out = 7'b0000110;
		default: out = 7'b0001110;
	endcase
end
endmodule 

module vgaDisplay(
    input  clk, rst,
    input  [2:0] state,
    input  [3:0] position,
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
	 
	parameter IDLE = 3'd0, SHOW_TASK = 3'd1, PLAYING = 3'd2,
              GAME_OVER = 3'd3, WIN = 3'd4, WAIT = 3'd5;

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
            if(state == SHOW_TASK || (prevState != state && state != WAIT)) begin
                for(i=0;i<9;i=i+1) grid[i] <= 2'b00;
                prevState <= state;
            end
            // 當 position<9 時 => 寫入對應格
            if(position < 4'd9) begin
                case(state)
                    IDLE, SHOW_TASK: begin
                        grid[position] <= 2'd2;
                    end
                    PLAYING, WAIT, GAME_OVER, WIN: begin
                        grid[position] <= (isCircle) ? 2'd2 : 2'd1;
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
                        if(state == IDLE) begin
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
                                if(state == WIN) begin
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