module seven_seg_display( num , out );
input [6:0] num;
output reg [6:0] out ;

always @(*) begin
    case (num)
        4'd0: out = 7'b1000000; // 0
        4'd1: out = 7'b1111001; // 1
        4'd2: out = 7'b0100100; // 2
        4'd3: out = 7'b0110000; // 3
        4'd4: out = 7'b0011001; // 4
        4'd5: out = 7'b0010010; // 5
        4'd6: out = 7'b0000010; // 6
        4'd7: out = 7'b1111000; // 7
        4'd8: out = 7'b0000000; // 8
        4'd9: out = 7'b0010000; // 9
        4'd10: out = 7'b0001000; // A
        4'd11: out = 7'b0000011; // b
        4'd12: out = 7'b1000110; // C
        4'd13: out = 7'b0100001; // d
        4'd14: out = 7'b0000110; // E
        4'd15: out = 7'b0001110; // F
    endcase
end


endmodule
