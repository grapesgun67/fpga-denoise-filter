[2025-06-24]
1. RNLM 구현에서 3x3 Line Buffer가 필요
    1) RNLM에서 patch 단위로 가중연산한 픽셀을 통해 denoise를 구현하기 때문이다
    2) 단 현재 다음 에러 로그 발생 : "[DRC UTLZ-1] Resource utilization: LUT as Distributed RAM over-utilized in Top Level Design (This design requires more LUT as Distributed RAM cells than are available in the target device. This design requires 20734 of such cell types but only 17400 compatible sites are available in the target device. Please analyze your synthesis results and constraints to ensure the design is mapped to Xilinx primitives as expected. If so, please consider targeting a larger device. Please set tcl parameter "drc.disableLUTOverUtilError" to 1 to change this error to warning.)"

2. 원인
    1) verilog 내에서 사용 가능량을 초과해서 LUT as Distributed RAM를 사용하도록 설계되어있는 문제
    2) (* ram_style = "block" *) reg [DATA_WIDTH-1:0] line_buffer [0:1920*3-1];
    3) BRAM을 사용하도록 수정 필요