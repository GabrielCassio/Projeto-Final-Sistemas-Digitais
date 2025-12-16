module safecrack_fsm (
    input  logic         clk,
    input  logic         rstn,
    input  logic [2:0] btn,       // button inputs (BTN[2:0])
    output logic [7:0] leds_green,  // Green LEDs (progress/success)
    output logic       led_red     // Red LED (error)
);
    
    typedef enum logic [4:0] { 
        S0        = 5'b00001,  // Awaiting first digit (1 Green LED)
        S1        = 5'b00010,  // Awaiting second digit (2 Green LEDs)
        S2        = 5'b00100,  // Awaiting third digit (3 Green LEDs)
        ERROR     = 5'b01000,  // Error state (1 Red LED for 3s)
        SUCCESS   = 5'b10000   // Success state (3 Green LEDs for 5s)
    } state_t;
    
    state_t state, next_state;
    logic [2:0] btn_prev, btn_edge, btn_pos;
    logic       any_btn_edge;

    // Constants for Timing
    localparam int CLK_FREQ_HZ = 50_000_000;
    localparam int DELAY_1S = CLK_FREQ_HZ;
    localparam int DELAY_ERROR = 3 * DELAY_1S;  // 3 seconds delay
    localparam int DELAY_SUCCESS = 5 * DELAY_1S; // 5 seconds delay
    
    logic [$clog2(DELAY_SUCCESS)-1:0] delay_cnt, next_delay_cnt; 
    
    // Combinational logic for button edge detection
    always_comb begin
        btn_pos = ~btn; 
        btn_edge = btn_pos & ~btn_prev;
        any_btn_edge = (|btn_edge);
    end 
    
    // Sequential logic (State and Delay Counter registers)
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_prev    <= 3'b000;
            delay_cnt   <= 0;
            state       <= S0;
        end
        else begin
            btn_prev    <= btn_pos;
            delay_cnt   <= next_delay_cnt;
            state       <= next_state;
        end
    end

    // Transition logic (Next State and Next Counter)
    always_comb begin
        next_state     = state;
        next_delay_cnt = delay_cnt;

        unique case (state)
            S0: begin
                if (any_btn_edge) begin
                    if (btn_edge == 3'b001) begin // Correct: BTN[0]
                        next_state = S1;
                    end else begin // Error: BTN[1] or BTN[2]
                        next_state     = ERROR;
                        next_delay_cnt = DELAY_ERROR; 
                    end
                end
            end

            S1: begin
                if (any_btn_edge) begin
                    if (btn_edge == 3'b010) begin // Correct: BTN[1]
                        next_state = S2;
                    end else begin // Error: BTN[0] or BTN[2]
                        next_state     = ERROR;
                        next_delay_cnt = DELAY_ERROR; 
                    end
                end
            end

            S2: begin
                if (any_btn_edge) begin
                    if (btn_edge == 3'b100) begin // Correct: BTN[2]
                        next_state     = SUCCESS;
                        next_delay_cnt = DELAY_SUCCESS; 
                    end else begin // Error: BTN[0] or BTN[1]
                        next_state     = ERROR;
                        next_delay_cnt = DELAY_ERROR; 
                    end
                end
            end
            
            ERROR: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0; 
                    next_delay_cnt = 0;
                end
            end

            SUCCESS: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0; 
                    next_delay_cnt = 0;
                end
            end

            default: next_state = S0;
        endcase
    end

    // Output logic (LED control)
    always_comb begin
        leds_green = 8'b0000000; 
        led_red    = 1'b0;   

        case (state)
            S0:      leds_green = 8'b0000001; // 1 Green LED
            S1:      leds_green = 8'b0000011; // 2 Green LEDs
            S2:      leds_green = 8'b0000111; // 3 Green LEDs
            
            ERROR: begin
                led_red    = 1'b1;   // 1 Red LED ON
                leds_green = 8'b0000000; 
            end

            SUCCESS: begin
                leds_green = 8'b1111111; // 3 Green LEDs ON
                led_red    = 1'b0;   
            end
            
            default: ;
        endcase
    end

endmodule