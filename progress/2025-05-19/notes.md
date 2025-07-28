[2025-05-19]
1. 데이터 정렬 오류 발생
    1) 영상 가운데 세로선 생김
    2) 픽셀들이 뭉쳐 중간중간에 작은 스트라이프 패턴이 보임

2. 원인
    1) m_axis_tvalid 출력이 적합하게 한 클럭만 유지되는 것이 아니라 여러 클럭동안 유지되어서 출력
    2) RNLM 알고리즘에 따라 과거 프레임과 현재 프레임을 읽어야하고, 이에 VDMA READ IP를 2개로 늘리면서 VDMA IP로부터 TVALID 신호를 못받는 주기가 길어지는 현상 발생

3. 해결방안
    1) M_AXIS_TLAST, M_AXIS_TUSER 신호는 적합한 조건일 경우일 때만 출력하도록 적용
        - "if (!m_axis_tvalid || m_axis_tready) begin" 조건 추가

    2) 결국 VDMA와 DDR Memory를 연결하는 PS의 arbitrator(S_HP)를 추가해서 해결
        - 즉 VDMA IP가 다른 라인을 통해 Memory에 접근하도록 arbitrator를 추가