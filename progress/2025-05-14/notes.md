[2025-05-14]
1. 영상 출력 문제 : 영상이 깨지는 문제

2. 원인 : HW 설계 내 AXI_BayerToRGB IP 에 대한 이해도 부족으로 VDMA 초기 셋팅 오류 발생
    1) 현재 설계는 AXI_BayerToRGB -> AXI_VDMA(write) -> AXI_VDMA(read) -> Denoise filter(custom ip)로 되어있음
    2) AXI_BayerToRGB 셋팅 중 "Input Samples per Clock : 4"로 되어있기에, vitis에서 VDMA 초기화시에 HorisizeInput과 Stride를 7680(1920의 4배)로 설정해야 정상적인 영상을 읽을 수 있다