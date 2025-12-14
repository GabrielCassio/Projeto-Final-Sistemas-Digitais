## Objetivo:

Evoluir o *SafeCrack FSM* apresentado em sala de aula, com uma nova funcionalidade.

### Requisitos Funcionais:

O sistema SafeCrack Pro deverá utilizar LEDs para fornecer feedback visual ao usuário durante o processo de verificação da senha no modo de operação normal. A senha será composta por três dígitos, e a indicação de progresso será feita exclusivamente pelos LEDs verdes, enquanto os erros serão sinalizados por LEDs vermelhos.

Durante a operação, os LEDs verdes deverão indicar claramente qual dígito o sistema está aguardando:

- 1 LED verde aceso indica que o sistema está aguardando o primeiro dígito;
- 2 LEDs verdes acesos indicam que o sistema aguarda o segundo dígito;
- 3 LEDs verdes acesos indicam que o sistema aguarda o terceiro dígito.

Cada dígito correto digitado faz o sistema avançar para o próximo estado, aumentando a quantidade de LEDs verdes acesos conforme descrito.

Caso o usuário insira um dígito incorreto em qualquer etapa, o sistema deverá acender um LED vermelho por 3 segundos para indicar o erro. Após esse período, todos os LEDs são apagados e o sistema retorna ao estado inicial, com apenas 1 LED verde aceso, aguardando o primeiro dígito.

Quando os três dígitos forem inseridos corretamente, o sistema deverá acionar simultaneamente todos os LEDs verdes da placa por 5 segundos, sinalizando que o cofre foi aberto com sucesso. Ao término desse intervalo, o sistema retorna automaticamente ao estado inicial, reiniciando o processo com 1 LED verde aceso, aguardando um novo primeiro dígito.

### FSM - Diagrama da Máquina de Estados:

![Diagrama de Máquina de Estados](assets/FSM%20-%20Diagrama%20Projeto%20Final%20de%20Sistemas%20Digitais.png "Diagrama de Máquina de Estados")