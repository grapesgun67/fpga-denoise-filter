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
    output reg                       m_axis_tuser,
    
    input wire [15:0]               target_data_cnt,
    input wire [15:0]               target_last_cnt,
    input wire [1:0]                enable_manual_tuser
);
    ////////////////////////////////////////////////////////////
    // localparam
    //////////////////////////////////////////////////////////////    
    localparam [10:0] H_RES = 11'd1920;
    localparam [10:0] V_RES = 11'd1080;
    
    wire s_valid = s_curr_axis_tvalid && s_curr_axis_tready;
    
    //////////////////////////////////////////////////////////////
    // line buffer
    //////////////////////////////////////////////////////////////
    reg [10:0] pixel_x;
    always @(posedge aclk) begin
        if (!aresetn)
            pixel_x <= 0;
        else if (s_curr_axis_tvalid && s_curr_axis_tready)
            pixel_x <= (pixel_x == H_RES - 1) ? 0 : pixel_x + 1;
    end
    
    reg [10:0] pixel_y;
    always @(posedge aclk) begin
        if (!aresetn)
            pixel_y <= 0;
        else if (pixel_x == H_RES - 1 && s_curr_axis_tvalid && s_curr_axis_tready)
            pixel_y <= (pixel_y == V_RES - 1) ? 0 : pixel_y + 1;
    end

    // 주소 레지스터 선언
    wire [31:0] p00, p01, p02;
    wire [31:0] p10, p11, p12;
    wire [31:0] p20, p21, p22;
    
    wire en_wr = (curr_state == IDLE) && s_curr_axis_tvalid && s_curr_axis_tready;
    wire en_rd = (curr_state == CALC);

    reg [2:0] write_row;
    always @(posedge aclk) begin
        if (!aresetn)
            write_row <= 0;
        else if (pixel_x == H_RES-1 && s_curr_axis_tvalid && s_curr_axis_tready) begin
            write_row <= (write_row == 2) ? 0 : write_row + 1;
        end
    end
    
    reg [10:0] read_y;
    always @(posedge aclk) begin
        if (!aresetn)
            read_y <= 0;
        else if (s_curr_axis_tvalid && s_curr_axis_tready) begin
            if (pixel_y >= 2)
                read_y <= pixel_y - 2;
            else
                read_y <= 0;
        end
    end
    
    // BRAM 기반 라인 버퍼 인스턴스..
    line_buffer_bram line_buffer (
        .clk(aclk),
        .rstn(aresetn),
        .en_wr(en_wr),
        .en_rd(en_rd),
        .pixel_in(s_curr_axis_tdata),
        .write_x(pixel_x),
        .write_row(write_row),
        .read_x(pixel_x),
        .read_y(read_y),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    //////////////////////////////////////////////////////////////
    // wire
    //////////////////////////////////////////////////////////////  
    wire first_pixel = (pixel_x == 0 && pixel_y == 0);
    wire last_pixel  = (pixel_x == H_RES - 1 && pixel_y == V_RES - 1);
//    wire tuser_gen   = (pixel_x == 0 && pixel_y == 0 && curr_state == IDLE); // AXI TUSER용
//    wire tlast_gen   = (pixel_x == H_RES-1 && curr_state == IDLE && s_curr_axis_tvalid); // AXI TLAST용
    
    //////////////////////////////////////////////////////////////
    // fsm
    //////////////////////////////////////////////////////////////  
    localparam [1:0] IDLE  = 2'd0,
                     CALC  = 2'd1;

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
            IDLE:  next_state = (start_condition && s_valid) ? CALC : IDLE;
            CALC:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge aclk) begin
        if (!aresetn)
            start_condition <= 0;
        else if (pixel_y >= 2 && s_valid)
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
        else if (s_valid) begin
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
        else if (s_valid) begin
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
        else if (s_valid)
            sum_out <= full_sum >> 3;
    end
    
    //////////////////////////////////////////////////////////////
    // AXI protocol -> reday, valid, tlast, tuser pipeline(shift)
    //////////////////////////////////////////////////////////////       
    assign s_curr_axis_tready = (!m_axis_tvalid || m_axis_tready); // axi4-stream 정석 조건
    
    reg [1:0] valid_shift;
    always @(posedge aclk) begin
        if (!aresetn) begin
            valid_shift <= 0;
            m_axis_tvalid <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin // tready안왔을때 값유지하는 조건문
            valid_shift <= {valid_shift[0], s_curr_axis_tvalid};
            m_axis_tvalid <= valid_shift[1];
        end
    end

    reg [1:0] user_shift;
    wire tuser_auto   = (pixel_x == 0 && pixel_y == 0);
    wire tuser_manual = (pixel_x == target_data_cnt && pixel_y == target_last_cnt);    
    wire tuser_gen = (enable_manual_tuser == 1) ? tuser_manual : tuser_auto;
    always @(posedge aclk) begin
        if (!aresetn) begin
            user_shift <= 0;
            m_axis_tuser <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin // tready안왔을때 값유지하는 조건문
            user_shift <= {user_shift[0], tuser_gen};
            m_axis_tuser <= user_shift[1];
        end
    end

    reg [1:0] last_shift;
    wire tlast_auto   = (pixel_x == H_RES-1 && s_curr_axis_tvalid && s_curr_axis_tready);
    wire tlast_manual = (pixel_x == target_data_cnt && s_curr_axis_tvalid && s_curr_axis_tready);
    wire tlast_gen = (enable_manual_tuser == 2) ? tlast_manual : tlast_auto;
    always @(posedge aclk) begin
        if (!aresetn) begin
            last_shift <= 0;
            m_axis_tlast <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin
            last_shift <= {last_shift[0], tlast_gen};
            m_axis_tlast <= last_shift[1];
        end
    end
    
    ////////////////////////////////////////////////////////////////
    // set m_axis_tdata
    //////////////////////////////////////////////////////////////    
    wire [DATA_WIDTH-1:0] data_selected;
    assign data_selected =  (pixel_y < 2) ? s_curr_axis_tdata           :  
                            (output_mode == 2'd0) ? s_curr_axis_tdata   :
                            (output_mode == 2'd1) ? 32'h00FF0000        :
                            (output_mode == 2'd2) ? sum_out             : 32'd0;
                            
                            
    reg [DATA_WIDTH-1:0] data_shift [0:1];
    always @(posedge aclk) begin
        if (!aresetn) begin
            data_shift[0] <= 0;
            data_shift[1] <= 0;
        end
        else if (!m_axis_tvalid || m_axis_tready) begin
            data_shift[0] <= data_selected;
            data_shift[1] <= data_shift[0];
        end
    end
    
    always @(posedge aclk) begin
        if (!aresetn)
            m_axis_tdata <= 0;
        else if (!m_axis_tvalid || m_axis_tready)
            m_axis_tdata <= data_shift[1];
    end
    
    //////////////////////////////////////////////////////////////
    // Debug..
    //////////////////////////////////////////////////////////////
    (* mark_debug = "true" *) wire                      dbg_s_curr_axis_tvalid; assign dbg_s_curr_axis_tvalid = s_curr_axis_tvalid;
    (* mark_debug = "true" *) wire                      dbg_s_curr_axis_tready; assign dbg_s_curr_axis_tready = s_curr_axis_tready;

    (* mark_debug = "true" *) reg  [DATA_WIDTH-1:0]     m_axis_tdata;
    (* mark_debug = "true" *) reg                       m_axis_tvalid;
    (* mark_debug = "true" *) wire                      dbg_m_axis_tready;      assign dbg_m_axis_tready = m_axis_tready;
    (* mark_debug = "true" *) reg                       m_axis_tlast;
    (* mark_debug = "true" *) reg                       m_axis_tuser;

    (* mark_debug = "true" *) reg [10:0] pixel_x;
    (* mark_debug = "true" *) reg [10:0] pixel_y;

//    (* mark_debug = "true" *) wire [31:0] dbg_p00; assign dbg_p00 = p00;
//    (* mark_debug = "true" *) wire [31:0] dbg_p01; assign dbg_p01 = p01;
//    (* mark_debug = "true" *) wire [31:0] dbg_p02; assign dbg_p02 = p02;
//    (* mark_debug = "true" *) wire [31:0] dbg_p10; assign dbg_p10 = p10;
//    (* mark_debug = "true" *) wire [31:0] dbg_p11; assign dbg_p11 = p11;
//    (* mark_debug = "true" *) wire [31:0] dbg_p12; assign dbg_p12 = p12;
//    (* mark_debug = "true" *) wire [31:0] dbg_p20; assign dbg_p20 = p20;
//    (* mark_debug = "true" *) wire [31:0] dbg_p21; assign dbg_p21 = p21;
//    (* mark_debug = "true" *) wire [31:0] dbg_p22; assign dbg_p22 = p22;
    
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
