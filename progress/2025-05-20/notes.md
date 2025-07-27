[2025-05-20]
1. denoise filter 중 RNLM 구현 목표
    1) 논문명 : "Recursive non-local means filter for video denoising"
    2) 링크 : https://link.springer.com/article/10.1186/s13640-017-0177-2

2. 현재 진행 상황
    1) RNLM Denoise filter를 위해서 이전 프레임과 현재 프레임을 읽는 기능이 필요하므로 AXI_VDMA IP(read) 를 두개 추가한 뒤, 우선적으로 bypass 영상 출력이 정상인 것을 확인