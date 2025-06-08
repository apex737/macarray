// IB
module ControlUnit (
    input               CLK,
    input               RSTN,
    
    // 외부에서 들어오는 제어 신호
    input               Start,  // 전체 연산을 시작하라는 외부 명령
    input       [3:0]   mac_OVALID, // MAC4x4의 OVALID 출력

    // IBuffer4로 나가는 제어 신호
    output reg          LOAD_EN,
    output reg          START_CALC,

    // 최종 시스템 출력 신호
    output reg          system_Done // 모든 연산이 끝났음을 알림
);

    // FSM 상태 정의
    localparam S_IDLE = 3'd0;
    localparam S_LOAD = 3'd1;
    localparam S_START = 3'd2;
    localparam S_WAIT_DONE = 3'd3;
    localparam S_DONE = 3'd4;

    // FSM 상태 레지스터
    reg [2:0] current_state, next_state;
    // 4사이클 로드를 위한 카운터
    reg [1:0] load_counter;
    // 4개 행의 출력을 확인하기 위한 카운터
    reg [3:0] done_checker;

    // FSM State Transition Logic (Sequential Block)
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM Output & Next State Logic (Combinational Block)
    always @(*) begin
        // 기본 출력값 설정 (Latch 방지)
        next_state = current_state;
        LOAD_EN = 1'b0;
        START_CALC = 1'b0;
        system_Done = 1'b0;

        case (current_state)
            S_IDLE: begin
                // 외부 시작 신호를 기다림
                if (Start) begin
                    next_state = S_LOAD;
                end
            end
            S_LOAD: begin
                // 4 사이클 동안 LOAD_EN=1 유지
                LOAD_EN = 1'b1;
                // 카운터가 3이 되면 (즉, 4 사이클이 지나면) 다음 상태로
                if (load_counter == 2'd3) begin
                    next_state = S_START;
                end
            end
            S_START: begin
                // 1 사이클 동안 START_CALC=1 펄스 발생
                START_CALC = 1'b1;
                next_state = S_WAIT_DONE;
            end
            S_WAIT_DONE: begin
                // 모든 행의 OVALID 신호가 한 번씩 다 들어왔는지 확인
                // done_checker가 1111이 되면 연산 완료
                if (done_checker == 4'b1111) begin
                    next_state = S_DONE;
                end
            end
            S_DONE: begin
                // 최종 완료 신호 출력
                system_Done = 1'b1;
                next_state = S_DONE; // 상태 유지
            end
        endcase
    end
    
    // Counter Logics
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            load_counter <= 0;
            done_checker <= 0;
        end else begin
            // Load Counter: S_LOAD 상태일 때만 1씩 증가
            if (current_state == S_LOAD) begin
                load_counter <= load_counter + 1;
            end else begin
                load_counter <= 0; // 다른 상태에서는 초기화
            end

            // Done Checker: OVALID 신호를 누적하여 저장
            // OVALID는 one-hot 이므로 OR 연산으로 누적 가능
            done_checker <= done_checker | mac_OVALID; 
        end
    end

endmodule
