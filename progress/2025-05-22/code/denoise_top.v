module denoise_top #
(
    parameter DATA_WIDTH = 32
)
(
    // AXI4-Lite Interface Signals
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,


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

    reg [1:0] output_mode_reg;
    reg [31:0] axi_rdata;
    reg axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    reg [1:0] axi_bresp, axi_rresp;
    
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_arready = axi_arready;
    assign s_axi_rvalid  = axi_rvalid;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rdata   = axi_rdata;
    
    // WRITE FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 0;
            axi_wready  <= 0;
            axi_bvalid  <= 0;
            axi_bresp   <= 2'b00;
            output_mode_reg <= 2'b00;
        end else begin
            axi_awready <= (s_axi_awvalid && !axi_awready);
            axi_wready  <= (s_axi_wvalid  && !axi_wready);
    
            if (s_axi_awvalid && s_axi_wvalid && !axi_bvalid) begin
                if (s_axi_awaddr[3:0] == 4'h0) begin
                    output_mode_reg <= s_axi_wdata[1:0];
                end
                axi_bvalid <= 1;
            end else if (s_axi_bready) begin
                axi_bvalid <= 0;
            end
        end
    end
    
    // READ FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 0;
            axi_rvalid  <= 0;
            axi_rresp   <= 2'b00;
            axi_rdata   <= 0;
        end else begin
            axi_arready <= (s_axi_arvalid && !axi_arready);
            if (s_axi_arvalid && !axi_rvalid) begin
                if (s_axi_araddr[3:0] == 4'h0)
                    axi_rdata <= {30'b0, output_mode_reg};
                axi_rvalid <= 1;
            end else if (s_axi_rready) begin
                axi_rvalid <= 0;
            end
        end
    end

    denoise_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_denoise_core (
        .aclk(aclk),
        .aresetn(aresetn),
        
        .output_mode(output_mode_reg),
        
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