module denoise_top #
(
    parameter DATA_WIDTH = 32
)
(
    input wire                       aclk,
    input wire                       aresetn,

    // AXI4-Stream Slave (Input)
    input wire [DATA_WIDTH-1:0]      s_prev_axis_tdata,
    input wire                       s_prev_axis_tvalid,
    output wire                      s_prev_axis_tready,
    input wire                       s_prev_axis_tlast,
    input wire                       s_prev_axis_tuser,

    // AXI4-Stream Slave (Input)
    input wire [DATA_WIDTH-1:0]      s_curr_axis_tdata,
    input wire                       s_curr_axis_tvalid,
    output wire                      s_curr_axis_tready,
    input wire                       s_curr_axis_tlast,
    input wire                       s_curr_axis_tuser,

    // AXI4-Stream Master (Output)
    output wire [DATA_WIDTH-1:0]     m_axis_tdata,
    output wire                      m_axis_tvalid,
    input  wire                      m_axis_tready,
    output wire                      m_axis_tlast,
    output wire                      m_axis_tuser
);

    denoise_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_denoise_core (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_curr_axis_tdata(s_curr_axis_tdata),
        .s_curr_axis_tvalid(s_curr_axis_tvalid),
        .s_curr_axis_tready(s_curr_axis_tready),
        .s_curr_axis_tlast(s_curr_axis_tlast),
        .s_curr_axis_tuser(s_curr_axis_tuser),
        
        .s_prev_axis_tdata(s_prev_axis_tdata),
        .s_prev_axis_tvalid(s_prev_axis_tvalid),
        .s_prev_axis_tready(s_prev_axis_tready),
        .s_prev_axis_tlast(s_prev_axis_tlast),
        .s_prev_axis_tuser(s_prev_axis_tuser),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser)
    );

endmodule