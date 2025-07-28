[2025-06-24]
1. 문제 : verilog 내에서 사용 가능량을 초과해서 LUT as Distributed RAM를 사용하는 설계

2. 수정 방법 : Line Buffer를 라인별로 명시적 분리방법을 사용
    1) 수정 전 : (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line_buffer [0:1920*3-1];
    2) 수정 후    
        (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line0 [0:LINE_WIDTH-1];
        (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line1 [0:LINE_WIDTH-1];
        (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line2 [0:LINE_WIDTH-1];