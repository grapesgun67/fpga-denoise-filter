`include "line_buffer_bram.v"

module denoise_core #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                      aclk,
    input  wire                      aresetn,

    input  wire [1:0]                output_mode,

    input  wire [DATA_WIDTH-1:0]     s_prev_axis_tdata,
    input  wire                      s_prev_axis_tvalid,
    output wire                      s_prev_axis_tready,
    input  wire                      s_prev_axis_tlast,
    input  wire                      s_prev_axis_tuser, 
    
    input  wire [DATA_WIDTH-1:0]     s_curr_axis_tdata,
    input  wire                      s_curr_axis_tvalid,
    output wire                      s_curr_axis_tready,
    input  wire                      s_curr_axis_tlast,
    input  wire                      s_curr_axis_tuser,

    output reg  [DATA_WIDTH-1:0]     m_axis_tdata,
    output reg                       m_axis_tvalid,
    input  wire                      m_axis_tready,
    output reg                       m_axis_tlast,
    output reg                       m_axis_tuser
);

    //////////////////////////////////////////////////////////////
    // line buffer
    //////////////////////////////////////////////////////////////    
    reg [10:0] pixel_x;
    always @(posedge aclk) begin
        if (!aresetn)
            pixel_x <= 0;
        else if (s_curr_axis_tvalid && s_curr_axis_tready && curr_state == IDLE)
            pixel_x <= (pixel_x == 1920 - 1) ? 0 : pixel_x + 1;
    end
    
    reg [10:0] pixel_y;
    always @(posedge aclk) begin
        if (!aresetn)
            pixel_y <= 0;
        else if (pixel_x == 1920 - 1 && s_curr_axis_tvalid && s_curr_axis_tready)
            pixel_y <= (pixel_y == 1080 - 1) ? 0 : pixel_y + 1;
    end

    // 주소 레지스터 선언
    reg [11:0] wr_addr;
    reg [11:0] rd_addr;
    wire [31:0] p00, p01, p02;
    wire [31:0] p10, p11, p12;
    wire [31:0] p20, p21, p22;
    
    wire en_wr = (curr_state == IDLE) && s_curr_axis_tvalid && s_curr_axis_tready;
    wire en_rd = (curr_state == CALC);
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            wr_addr <= 0;
            rd_addr <= 0;
        end else begin
            if (en_wr)
                wr_addr <= (wr_addr == 5760 - 1) ? 0 : wr_addr + 1;
            if (en_rd)
                rd_addr <= (rd_addr == 5760 - 1) ? 0 : rd_addr + 1;
        end
    end
    
    // BRAM 기반 라인 버퍼 인스턴스
    line_buffer_bram line_buffer (
        .clk(aclk),
        .rstn(aresetn),
        .en_wr(en_wr),
        .en_rd(en_rd),
        .pixel_in(s_curr_axis_tdata),
        .write_x(pixel_x),
        .write_row(write_row),
        .read_x(pixel_x),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );
    
    reg [2:0] r_top, r_mid, r_bot;//
    always @(posedge aclk) begin
        if (!aresetn) begin
            r_top <= 0; r_mid <= 1; r_bot <= 2;
        end
        else if (pixel_x == 1920 - 1 && s_curr_axis_tvalid && s_curr_axis_tready) begin
            r_top <= (r_top == 2) ? 0 : r_top + 1;
            r_mid <= (r_mid == 2) ? 0 : r_mid + 1;
            r_bot <= (r_bot == 2) ? 0 : r_bot + 1;
        end
    end  
    
    //////////////////////////////////////////////////////////////
    // wire
    //////////////////////////////////////////////////////////////  
    wire first_pixel = (pixel_x == 0 && pixel_y == 0);
    wire last_pixel  = (pixel_x == 1920 - 1 && pixel_y == 1080 - 1);
    wire tuser_gen   = (pixel_x == 0 && pixel_y == 0);              // AXI TUSER용
    wire tlast_gen   = (pixel_x == 1920 - 1);                       // AXI TLAST용
    
    //////////////////////////////////////////////////////////////
    // fsm
    //////////////////////////////////////////////////////////////  
    localparam [1:0] IDLE  = 2'd0,
                 WAIT  = 2'd1,
                 CALC  = 2'd2,
                 OUT   = 2'd3;

    reg [1:0] curr_state, next_state;    
    always @(posedge aclk) begin
        if (!aresetn)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end

    reg start_condition;
    always @(*) begin
        case (curr_state)
            IDLE:  next_state = (start_condition)      ? CALC : IDLE;
            CALC:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge aclk) begin
        if (!aresetn)
            start_condition <= 0;
        else if (pixel_y >= 2)
            start_condition <= 1;
        else if (curr_state == IDLE && next_state == CALC)
            start_condition <= 0;                
    end
    
    //////////////////////////////////////////////////////////////
    // CALC
    //////////////////////////////////////////////////////////////  
    reg [DATA_WIDTH:0] sum0_0, sum0_1, sum0_2, sum0_2_d;
    reg [DATA_WIDTH+1:0] sum1_0;
    // ====== stage 1 ======
    always @(posedge aclk) begin
        if (!aresetn) begin
            sum0_0 <= 0; sum0_1 <= 0; sum0_2 <= 0;
        end
        else begin
            sum0_0 <= p00 + p01 + p02;     
            sum0_1 <= p10 + p11 + p12;
            sum0_2 <= p20 + p21 + p22;
        end
    end
    
    // ====== stage 2 ======
    always @(posedge aclk) begin
     if (!aresetn) begin
            sum1_0 <= 0; sum0_2_d <= 0;
        end
        else begin
            sum1_0 <= sum0_0 + sum0_1;
            sum0_2_d <= sum0_2;
        end
    end
    
    // ====== stage 3 ======
    reg [DATA_WIDTH:0] sum_out;
    wire [DATA_WIDTH+2:0] full_sum = sum1_0 + sum0_2_d;
    always @(posedge aclk) begin
     if (!aresetn)
            sum_out <= 0;
        else
            sum_out <= full_sum >> 3;
    end
    
    //////////////////////////////////////////////////////////////
    // AXI protocol -> reday, valid, tlast, tuser pipeline(shift)
    //////////////////////////////////////////////////////////////       
    assign s_curr_axis_tready = (!m_axis_tvalid || m_axis_tready); // axi4-stream 정석 조건
    
    reg [2:0] valid_shift;
    always @(posedge aclk) begin
        if (!aresetn) begin
            valid_shift <= 0;
            m_axis_tvalid <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin // tready안왔을때 값유지하는 조건문
            valid_shift <= {valid_shift[1:0], s_curr_axis_tvalid};
            m_axis_tvalid <= valid_shift[2];
        end
    end

    reg [2:0] user_shift;
    always @(posedge aclk) begin
        if (!aresetn) begin
            user_shift <= 0;
            m_axis_tuser <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin // tready안왔을때 값유지하는 조건문
            user_shift <= {user_shift[1:0], tuser_gen};
            m_axis_tuser <= user_shift[2];
        end
    end

    reg [2:0] last_shift;
    always @(posedge aclk) begin
        if (!aresetn) begin
            last_shift <= 0;
            m_axis_tlast <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin
            last_shift <= {last_shift[1:0], tlast_gen};
            m_axis_tlast <= last_shift[2];
        end
    end
    
    ////////////////////////////////////////////////////////////////
    // set m_axis_tdata
    //////////////////////////////////////////////////////////////
    wire [DATA_WIDTH-1:0] data_selected;
    assign data_selected =  (output_mode == 2'd0) ? s_curr_axis_tdata :
                            (output_mode == 2'd1) ? 32'h00FF0000 :
                            (output_mode == 2'd2) ? sum_out : 32'd0;
    
    always @(posedge aclk) begin
        if (!aresetn)
            m_axis_tdata <= 0;
        else if (!m_axis_tvalid || m_axis_tready)
            m_axis_tdata <= data_selected;
    end

    ////////////////////////////////////////////////////////////////
    // Debug
    //////////////////////////////////////////////////////////////
    (* mark_debug = "true" *) wire                      dbg_s_curr_axis_tvalid; assign dbg_s_curr_axis_tvalid = s_curr_axis_tvalid;
    (* mark_debug = "true" *) wire                      dbg_s_curr_axis_tready; assign dbg_s_curr_axis_tready = s_curr_axis_tready;

    (* mark_debug = "true" *) reg  [DATA_WIDTH-1:0]     m_axis_tdata;
    (* mark_debug = "true" *) reg                       m_axis_tvalid;
    (* mark_debug = "true" *) wire                      dbg_m_axis_tready;      assign dbg_m_axis_tready = m_axis_tready;
    (* mark_debug = "true" *) reg                       m_axis_tlast;
    (* mark_debug = "true" *) reg                       m_axis_tuser;

    (* mark_debug = "true" *) reg [10:0] buffer_x;
    (* mark_debug = "true" *) reg [1:0]  buffer_y;

    (* mark_debug = "true" *) reg [10:0] pixel_x;
    (* mark_debug = "true" *) reg [10:0] pixel_y;

    (* mark_debug = "true" *) reg [35:0] acc_val, acc_val_copy;
    (* mark_debug = "true" *) reg [31:0] output_pixel;
    (* mark_debug = "true" *) reg [31:0] output_pixel_d2;

    (* mark_debug = "true" *) reg [11:0] wr_addr;
    (* mark_debug = "true" *) reg [11:0] rd_addr;

    (* mark_debug = "true" *) wire [31:0] dbg_p00; assign dbg_p00 = p00;
    (* mark_debug = "true" *) wire [31:0] dbg_p01; assign dbg_p00 = p01;
    (* mark_debug = "true" *) wire [31:0] dbg_p02; assign dbg_p00 = p02;
    (* mark_debug = "true" *) wire [31:0] dbg_p10; assign dbg_p00 = p10;
    (* mark_debug = "true" *) wire [31:0] dbg_p11; assign dbg_p00 = p11;
    (* mark_debug = "true" *) wire [31:0] dbg_p12; assign dbg_p00 = p12;
    (* mark_debug = "true" *) wire [31:0] dbg_p20; assign dbg_p00 = p20;
    (* mark_debug = "true" *) wire [31:0] dbg_p21; assign dbg_p00 = p21;
    (* mark_debug = "true" *) wire [31:0] dbg_p22; assign dbg_p00 = p22;
    
    (* mark_debug = "true" *) reg [2:0] valid_shift;
    (* mark_debug = "true" *) reg [2:0] user_shift;
    (* mark_debug = "true" *) reg [2:0] last_shift;
    
    (* mark_debug = "true" *) wire dbg_first_pixel; assign dbg_first_pixel = first_pixel;

    (* mark_debug = "true" *) reg [1:0] curr_state;
    (* mark_debug = "true" *) reg [1:0] next_state;
    
    (* mark_debug = "true" *) wire dbg_last_pixel; assign dbg_last_pixel = last_pixel;
    (* mark_debug = "true" *) wire dbg_tuser_gen; assign dbg_tuser_gen = tuser_gen;
    (* mark_debug = "true" *) wire dbg_tlast_gen; assign dbg_tlast_gen = tlast_gen;

endmodule