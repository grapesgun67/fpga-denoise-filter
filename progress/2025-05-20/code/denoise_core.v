module denoise_core #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                      aclk,
    input  wire                      aresetn,

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

    reg [DATA_WIDTH-1:0] prev_data_buf;
    reg [DATA_WIDTH-1:0] curr_data_buf;
    
    assign s_prev_axis_tready = s_curr_axis_tvalid && m_axis_tready;
    assign s_curr_axis_tready = s_prev_axis_tvalid && m_axis_tready;

    always @(posedge aclk) begin
        if (s_prev_axis_tvalid && s_prev_axis_tready)
            prev_data_buf <= s_prev_axis_tdata;
        if (s_curr_axis_tvalid && s_curr_axis_tready)
            curr_data_buf <= s_curr_axis_tdata;
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata  <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
            m_axis_tuser  <= 0;
        end
        
        else begin
            if (s_prev_axis_tvalid && s_curr_axis_tvalid && m_axis_tready) begin
                m_axis_tdata <= curr_data_buf;
                m_axis_tvalid <= 1;
                m_axis_tlast <= s_curr_axis_tlast;
                m_axis_tuser <= s_curr_axis_tuser;
            end
            else if (m_axis_tvalid && !m_axis_tready) begin
                m_axis_tvalid <= m_axis_tvalid; // hold
            end 
            else begin
                m_axis_tvalid <= 0;
            end
        end
    end

endmodule