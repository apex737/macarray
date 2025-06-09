// 파일명: ControlUnit.v
module ControlUnit (
    input               CLK,
    input               RSTN,
    input               ext_start,
    input               row_done_from_output,
    output reg          LOAD_EN,
    output reg          START_CALC,
    output reg          W_LOAD,
    output reg  [1:0]   WROW,
    output reg  [1:0]   IDST,
    output reg  [3:0]   ODST,
    output reg          System_Done
);
    localparam S_IDLE=0, S_LOAD_W=1, S_LOAD_A=2, S_START_C=3, S_WAIT=4, S_DONE=5;
    reg [2:0] current_state, next_state;
    reg [1:0] row_counter;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) current_state <= S_IDLE;
        else current_state <= next_state;
    end

    always @(*) begin
        next_state=current_state;
        LOAD_EN=0; START_CALC=0; W_LOAD=0;
        WROW=0; IDST=0; ODST=0; System_Done=0;

        case(current_state)
            S_IDLE: if (ext_start) next_state = S_LOAD_W;
            S_LOAD_W: begin
                W_LOAD = 1; WROW = row_counter;
                if (row_counter == 2'd3) next_state = S_LOAD_A;
            end
            S_LOAD_A: begin
                LOAD_EN = 1; IDST = row_counter; ODST = row_counter;
                if (row_counter == 2'd3) next_state = S_START_C;
            end
            S_START_C: begin
                START_CALC = 1; next_state = S_WAIT;
            end
            S_WAIT: begin
                if (row_done_from_output) begin
                    if (row_counter == 2'd3) next_state = S_DONE;
                    else next_state = S_LOAD_A;
                end
            end
            S_DONE: begin
                System_Done = 1; next_state = S_DONE;
            end
        endcase
    end
    
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) row_counter <= 0;
        else if(next_state == S_IDLE) row_counter <= 0;
        else if(current_state != next_state) begin // 상태가 바뀔 때
            if(next_state == S_LOAD_A) row_counter <= 0;
            else if(next_state == S_WAIT && current_state == S_LOAD_A) row_counter <= 0;
            else if(current_state == S_WAIT && next_state == S_LOAD_A) row_counter <= row_counter + 1;
            else row_counter <= row_counter + 1;
        end
    end
endmodule