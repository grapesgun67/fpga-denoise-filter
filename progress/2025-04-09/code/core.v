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
    reg [10:0] line_cnt;
    reg out_user_next;

    assign in_ready = (latch_valid == 0) && out_ready;

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

    // line Count Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            line_cnt <= 11'd0;
            out_user_next <= 1'b0;
        end

        else if (in_valid && in_ready) begin
            if (in_last) begin
                if (line_cnt == 1080 - 1) begin
                    out_user_next <= 1'b1;   // 프레임 첫 pixel에서만 user=1
	                line_cnt <= 11'd0;
                end
                else begin
                    out_user_next <= 1'b0;
                    line_cnt <= line_cnt + 1'b1;
                end
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