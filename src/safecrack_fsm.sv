/*
O sistema do SafeCrack não possui leds piscando

### Requisitos Funcionais:

O sistema SafeCrack Pro deverá utilizar LEDs para fornecer feedback visual ao usuário durante o processo de verificação da senha no modo de operação normal. A senha será composta por três dígitos, e a indicação de progresso será feita exclusivamente pelos LEDs verdes, enquanto os erros serão sinalizados por LEDs vermelhos.

Durante a operação, os LEDs verdes deverão indicar claramente qual dígito o sistema está aguardando:

- 1 LED verde aceso indica que o sistema está aguardando o primeiro dígito;
- 2 LEDs verdes acesos indicam que o sistema aguarda o segundo dígito;
- 3 LEDs verdes acesos indicam que o sistema aguarda o terceiro dígito.

Cada dígito correto digitado faz o sistema avançar para o próximo estado, aumentando a quantidade de LEDs verdes acesos conforme descrito.

Caso o usuário insira um dígito incorreto em qualquer etapa, o sistema deverá acender um LED vermelho por 3 segundos para indicar o erro. Após esse período, todos os LEDs são apagados e o sistema retorna ao estado inicial, com apenas 1 LED verde aceso, aguardando o primeiro dígito.

Quando os três dígitos forem inseridos corretamente, o sistema deverá acionar simultaneamente todos os LEDs verdes da placa por 5 segundos, sinalizando que o cofre foi aberto com sucesso. Ao término desse intervalo, o sistema retorna automaticamente ao estado inicial, reiniciando o processo com 1 LED verde aceso, aguardando um novo primeiro dígito.

LEDR[0] PIN_G19 LED Red[0] 2.5V
LEDR[1] PIN_F19 LED Red[1] 2.5V
LEDR[2] PIN_E19 LED Red[2] 2.5V
LEDR[3] PIN_F21 LED Red[3] 2.5V
LEDR[4] PIN_F18 LED Red[4] 2.5V
LEDR[5] PIN_E18 LED Red[5] 2.5V
LEDR[6] PIN_J19 LED Red[6] 2.5V
LEDR[7] PIN_H19 LED Red[7] 2.5V
LEDR[8] PIN_J17 LED Red[8] 2.5V
LEDR[9] PIN_G17 LED Red[9] 2.5V
LEDR[10] PIN_J15 LED Red[10] 2.5V
LEDR[11] PIN_H16 LED Red[11] 2.5V
LEDR[12] PIN_J16 LED Red[12] 2.5V
LEDR[13] PIN_H17 LED Red[13] 2.5V
LEDR[14] PIN_F15 LED Red[14] 2.5V
LEDR[15] PIN_G15 LED Red[15] 2.5V
LEDR[16] PIN_G16 LED Red[16] 2.5V
LEDR[17] PIN_H15 LED Red[17] 2.5V
LEDG[0] PIN_E21 LED Green[0] 2.5V
LEDG[1] PIN_E22 LED Green[1] 2.5V
LEDG[2] PIN_E25 LED Green[2] 2.5V
LEDG[3] PIN_E24 LED Green[3] 2.5V
LEDG[4] PIN_H21 LED Green[4] 2.5V
LEDG[5] PIN_G20 LED Green[5] 2.5V
LEDG[6] PIN_G22 LED Green[6] 2.5V
LEDG[7] PIN_G21 LED Green[7] 2.5V
LEDG[8] PIN_F17 LED Green[8] 2.5V
*/

module safecrack_fsm (
    input  logic       clk,
    input  logic       rstn,
    input  logic [2:0] btn,        // buttons inputs (BTN[2:0])
    output logic [7:0] leds_green,       // leds outputs (LEDSG[7:0])
    output logic [17:0] leds_red,       // leds outputs (LEDSG[7:0])
    output logic       unlocked    // output: 1 when the safe is unlocked
);

    // one-hot encoding
    typedef enum logic [4:0] { 
        S0      = 5'b00001,  // initial state
        S1      = 5'b00010,  // BTN = 1 right
        S2      = 5'b00100,  // BTN = 2 right
        UNLOCKED_ON   = 5'b01000,  // BTN = 3 right -> unlock ON
        //UNLOCKED_OFF  = 5'b10000,   // unlock OFF
        INCORRECT_DIGIT_STATE = 5'b10000
    } state_t;

    state_t state, next_state;
    logic [2:0] btn_prev, btn_edge, btn_pos;
    logic       any_btn_edge;

    //localparam int BLINK_DELAY = 50_000_000;    // 1 second delay at 50MHz clock
    localparam int INCORRET_DIGIT_DELAY = 150_000_000;    // 3 second delay at 50MHz clock
    localparam int UNLOCKED_DELAY = 500_000_000;    // 5 second delay at 50MHz clock
    logic [$clog2(BLINK_DELAY)-1:0] delay_cnt, next_delay_cnt;
     
     always_comb begin
        btn_pos	= ~btn; // invert buttons to active high
        btn_edge = btn_pos & ~btn_prev; // get 0 -> 1 edges
        any_btn_edge = (|btn_edge); // any button edge detected
     end 
     
    // sequential logic
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_prev    <= 3'b000;
            delay_cnt   <= BLINK_DELAY;
            state       <= S0;
        end
        else begin
            btn_prev    <= btn_pos;
            delay_cnt   <= next_delay_cnt;
            state       <= next_state;
        end
    end

    // transition logic
    always_comb begin
        // default assignments
        next_state     = state;
        next_delay_cnt = delay_cnt;

        unique case (state)
            S0: begin
                    if (btn_edge == 3'b001) next_state = S1;	// button 0 pressed -> correct input
                    else if (any_btn_edge) next_state = INCORRECT_DIGIT_STATE; 	// any other invalid input -> restart
                    else next_state = S0;					    // no button pressed -> stay
                end
            S1: begin
                    if (btn_edge == 3'b010) next_state = S2; 		// button 1 pressed -> correct input
                    else if (any_btn_edge) next_state = INCORRECT_DIGIT_STATE; 	// any other invalid input -> restart
                    else next_state = S1;				// no button pressed -> stay
                end
            S2: begin
                    if (btn_edge == 3'b100) next_state = UNLOCKED_ON;		// button 2 pressed -> correct input
                    else if (any_btn_edge) next_state = INCORRECT_DIGIT_STATE; 	// any other invalid input -> restart	
                    else next_state = S2;				// no button pressed -> stay
                end
                
            UNLOCKED_ON: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0;
                    next_delay_cnt = UNLOCKED_DELAY;       // reset delay counter
                end
            end

            INCORRECT_DIGIT_STATE: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = S0;
                    next_delay_cnt = INCORRET_DIGIT_DELAY;       // reset delay counter
                end
            end

            default: next_state = S0;
        endcase
    end


    // output logic
    always_comb begin
        // Visual indication by the first three leds in the FPGA
        leds_green[0] = (|state_t);
        leds_green[1] = (state == S1 | state == S2 | state == UNLOCKED_ON);
        leds_green[2] = (state == S2 | state == UNLOCKED_ON);

        // Switch to on the remaing leds
        leds_green[3] = (state == UNLOCKED_ON)
        leds_green[4] = (state == UNLOCKED_ON)
        leds_green[5] = (state == UNLOCKED_ON)
        leds_green[6] = (state == UNLOCKED_ON)

        // Error led indicator
        leds_red[0] = (state == INCORRECT_DIGIT_STATE)

        unlocked = (state == UNLOCKED_ON);
    end

endmodule
