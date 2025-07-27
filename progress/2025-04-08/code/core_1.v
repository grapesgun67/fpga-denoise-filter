`timescale 1ns / 1ps

module noise_reduction_core #(
    parameter DATA_WIDTH = 40
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire [DATA_WIDTH-1:0]    in_data,
    input  wire                     in_valid,
    input  wire                     in_user,
    input  wire                     in_last,
    output wire                     in_ready,

    output reg  [DATA_WIDTH-1:0]    out_data,
    output reg                      out_valid,
    output reg                      out_user,
    output reg                      out_last,
    input  wire                     out_ready
);

    // 내부 레지스터
    reg [DATA_WIDTH-1:0] in_data_latched;
    reg in_user_latched;
    reg in_last_latched;
    reg latch_valid;

    assign in_ready = out_ready; // stream backpressure connect

    // 테스트 패턴용 픽셀 값
    localparam [9:0] PIXEL_B = 10'h100;  // Blue
    localparam [9:0] PIXEL_G1 = 10'h180; // Green
    localparam [9:0] PIXEL_G2 = 10'h180; // Green
    localparam [9:0] PIXEL_R = 10'h300;  // Red

    wire [DATA_WIDTH-1:0] test_pattern_data;
    assign test_pattern_data = {PIXEL_B, PIXEL_G1, PIXEL_G2, PIXEL_R};

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            in_data_latched <= {DATA_WIDTH{1'b0}};
            in_user_latched <= 1'b0;
            in_last_latched <= 1'b0;
            latch_valid <= 1'b0;
        end
        else if (in_valid && in_ready) begin
            in_data_latched <= test_pattern_data; // 수정된 부분 (in_data 대신 테스트 패턴)
            in_user_latched <= in_user;
            in_last_latched <= in_last;
            latch_valid <= 1'b1;
        end
        else if (out_ready) begin
            latch_valid <= 1'b0;
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
                out_user <= in_user_latched;
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