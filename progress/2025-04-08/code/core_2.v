`timescale 1ns / 1ps

module noise_reduction_core #(
    parameter DATA_WIDTH = 40
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire [DATA_WIDTH-1:0]     in_data,
    input  wire                     in_valid,
    input  wire                     in_user,  // (사용 안 할 거야)
    input  wire                     in_last,
    output wire                     in_ready,

    output reg  [DATA_WIDTH-1:0]     out_data,
    output reg                      out_valid,
    output reg                      out_user, // 수정
    output reg                      out_last,
    input  wire                     out_ready
);

    // 내부 레지스터
    reg [DATA_WIDTH-1:0] in_data_latched;
    reg in_last_latched;
    reg latch_valid;
    reg [15:0] pixel_cnt;  // ★ 픽셀 카운터 추가 (최대 1920 넘을 수 있으니 16bit)
    reg out_user_next;

    assign in_ready = out_ready; // stream backpressure connect

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            in_data_latched <= {DATA_WIDTH{1'b0}};
            in_last_latched <= 1'b0;
            latch_valid <= 1'b0;
        end
        else if (in_valid && in_ready) begin
            in_data_latched <= in_data;
            in_last_latched <= in_last;
            latch_valid <= 1'b1;
        end
        else if (out_ready) begin
            latch_valid <= 1'b0;
        end
    end

    // Pixel Count Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pixel_cnt <= 16'd0;
            out_user_next <= 1'b0;
        end
        else if (in_valid && in_ready) begin
            if (pixel_cnt == 0) begin
                out_user_next <= 1'b1;   // 프레임 첫 pixel에서만 user=1
            end
            else begin
                out_user_next <= 1'b0;
            end

            if (in_last) begin
                pixel_cnt <= 16'd0;      // 줄 끝나면 픽셀카운터 리셋
            end
            else begin
                pixel_cnt <= pixel_cnt + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            out_data <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
            out_user <= 1'b0;
            out_last <= 1'b0;
        end
        else begin
            if (latch_valid) begin
                out_data <= in_data_latched;
                out_valid <= 1'b1;
                out_user <= out_user_next;  // ★ latch에서 user 주는 방식 변경
                out_last <= in_last_latched;
            end
            else if (out_ready) begin
                out_valid <= 1'b0;
                out_user <= 1'b0;
                out_last <= 1'b0;
            end
        end
    end

endmodule