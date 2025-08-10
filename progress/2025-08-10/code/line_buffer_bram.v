module line_buffer_bram #(
    parameter DATA_WIDTH = 32,
    parameter LINE_WIDTH = 1920
)(
    input  wire                      clk,
    input  wire                      rstn,

    input  wire                      en_wr,
    input  wire                      en_rd,

    input  wire [DATA_WIDTH-1:0]     pixel_in,
    input  wire [10:0]               write_x,
    input  wire [1:0]                write_row,

    input  wire [10:0]               read_x,
    input  wire [10:0]               read_y,

    output reg [DATA_WIDTH-1:0]     p00, p01, p02,
    output reg [DATA_WIDTH-1:0]     p10, p11, p12,
    output reg [DATA_WIDTH-1:0]     p20, p21, p22
);

    // === 라인별로 명시적 분리 === //
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line0 [0:LINE_WIDTH-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line1 [0:LINE_WIDTH-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line2 [0:LINE_WIDTH-1];

    // === Write === //
    always @(posedge clk) begin
        if (en_wr) begin
            case (write_row)
                2'd0: line0[write_x] <= pixel_in;
                2'd1: line1[write_x] <= pixel_in;
                2'd2: line2[write_x] <= pixel_in;
            endcase
        end
    end

    // === Read === //   
    wire [10:0] px_m = (read_x == 0)            ? 11'd0     : read_x - 1;
    wire [10:0] px_p = (read_x == LINE_WIDTH-1) ? read_x    : read_x + 1;

    wire [1:0] r0 = read_y % 3;
    wire [1:0] r1 = (read_y + 1) % 3;
    wire [1:0] r2 = (read_y + 2) % 3;

    always @(posedge clk) begin
        if (!rstn) begin
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
        end
        else begin
            if (en_rd) begin
                p00 <=  (r0 == 0) ? line0[px_m] :
                        (r0 == 1) ? line1[px_m] : line2[px_m];
                p01 <=  (r0 == 0) ? line0[read_x] :
                        (r0 == 1) ? line1[read_x] : line2[read_x];
                p02 <=  (r0 == 0) ? line0[px_p] :
                        (r0 == 1) ? line1[px_p] : line2[px_p];
                        
                p10 <=  (r1 == 0) ? line0[px_m] :
                        (r1 == 1) ? line1[px_m] : line2[px_m];
                p11 <=  (r1 == 0) ? line0[read_x] :
                        (r1 == 1) ? line1[read_x] : line2[read_x];
                p12 <=  (r1 == 0) ? line0[px_p] :
                        (r1 == 1) ? line1[px_p] : line2[px_p];
    
                p20 <=  (r2 == 0) ? line0[px_m] :
                        (r2 == 1) ? line1[px_m] : line2[px_m];
                p21 <=  (r2 == 0) ? line0[read_x] :
                        (r2 == 1) ? line1[read_x] : line2[read_x];
                p22 <=  (r2 == 0) ? line0[px_p] :
                        (r2 == 1) ? line1[px_p] : line2[px_p];
            end                 
        end
    end        
                                  
endmodule