[2025-04-20]
1. 문제 : 합성 시간이 3시간씩 걸리는 문제
2. 원인
    1) for문 과도 사용
        - 합성시에 for문을 사용하는 것은 결국 모든 경우의 수를 회로로 그리는 것과 같다
        - 그러므로 최대한 FSM같은 기법을 사용해서 for문을 대체할 수 있도록 해야한다

    2) 잘못된 조합 논리 사용
        - 실수로 순차논리코드에 조합논리코드를 넣었다
        - 즉 always 문에 "always @(posedge aclk) begin" 대신 "always @(*) begin"을 넣었다
        - 이로 인해 아래 구문에서 사용된 변수와 연관된 모든 회로들이 새로 그려져서 합성 시간이 굉장히 증가했다
        EX)
        "always @(*) begin"
        if (!aresetn)
            write_row <= 0;
        else if (pixel_x == H_RES-2) begin
            write_row <= (write_row == 2) ? 0 : write_row + 1;
        end