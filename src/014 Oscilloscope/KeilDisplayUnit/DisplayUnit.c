#include <stm32f4xx.h>
// #include <math.h>

void INIT_PORTA(void);
void INIT_PORTB(void);
void INIT_PORTC(void);
void INTI_TIMER(void);

void delay(volatile uint32_t);
void delay10Us(volatile uint32_t num);

uint32_t USART2_read(void);
void USART2_write(uint32_t data);

int main(){
	INIT_PORTA();
	INIT_PORTB();
	INIT_PORTC();
	INTI_TIMER();
	
	// Clear USART data register
	USART2->DR;

	while(1){
		// Receive Packet
		uint32_t packet[8], i;
		for (i = 0; i < 8; i++) {
			packet[i] = USART2_read();
		}

		volatile static uint32_t b_fixed;
		volatile static uint32_t b_floating;
		volatile static uint32_t voltage_unit_fixed;
		volatile static uint32_t voltage_unit_floating;

		uint32_t digital_value_1 = (packet[1] << 8) + packet[0];
		uint32_t digital_value_2 = (packet[3] << 8) + packet[2];
		voltage_unit_fixed = packet[4];
		voltage_unit_floating = packet[5];
		b_fixed = packet[6];
		b_floating = packet[7];

		uint32_t to_glcd = (voltage_unit_fixed + voltage_unit_floating/10) * digital_value_1 + (b_fixed + b_floating/10);

		//TODO show on GLCD

		USART2_write(1); 	// Send finish acknowledgment
	}
}

void USART2_write(uint32_t data) {
    while (!(USART2->SR & USART_SR_TXE)) {}   // wait until Tx buffer empty
    USART2->DR = (data & 0xFF);
}

uint32_t USART2_read(void) {
    while (!(USART2->SR & USART_SR_RXNE)) {}   // wait until char arrives
    return USART2->DR;
}

void INIT_PORTA(){
	// Clock for GPIOA
	RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
	// MODER PORT A
	GPIOA->MODER = 0x55555555;
	
	/* Configure PA2 for USART2_TX */
	/* Configure PA3 for USART2 RX */
	RCC->APB1ENR |= RCC_APB1ENR_USART2EN; /* Enable USART2 clock */
	GPIOA->AFR[0] &= (uint32_t)(~0xFF00);
	GPIOA->AFR[0] |=  0x0700;   					/* Alt7 (USART2) for PA2 */
	GPIOA->AFR[0] |=  0x7000;   					/* Alt7 (USART2) for PA3 */
	GPIOA->MODER  &= (uint32_t)(~0x00F0); /* Clear moder of PA2 and PA3 */
	GPIOA->MODER  |=  0x00A0;   					/* Enable alternate function for PA2 and PA3 (mode = 10) */

	USART2->BRR = 0x0683;       					/* 9600 baud @ 16 MHz */
	USART2->CR1 = 0x000C;       					/* Enable Tx (8-bit data) and Rx (8-bit data) */
	USART2->CR2 = 0x0000;       					/* 1 stop bit */
	USART2->CR3 = 0x0000;       					/* No flow control */
	USART2->CR1 |= 0x2000;      					/* Enable USART2 */
}

void INIT_PORTB(){
	// Clock for GPIOB
	RCC->AHB1ENR |= RCC_AHB1ENR_GPIOBEN;
	// MODER PORT B
	GPIOB->MODER = 0x55555555;
}

void INIT_PORTC(){
	// Clock for GPIOC
	RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;
}

void INTI_TIMER() {
	RCC->APB1ENR |= RCC_APB1ENR_TIM2EN;   /* enable TIM2 clock */
  TIM2->CR1 |= TIM_CR1_OPM; 						/* One pulse mode: Counter stops counting at the next update event (clearing the bit CEN) */
	TIM2->CR1 |= TIM_CR1_ARPE; 						/* Auto-reload preload enable */	
	TIM2->PSC = 16000 - 1;
	
	RCC->APB1ENR |= RCC_APB1ENR_TIM5EN;   /* enable TIM2 clock */
  TIM5->CR1 |= TIM_CR1_OPM; 						/* One pulse mode: Counter stops counting at the next update event (clearing the bit CEN) */
	TIM5->CR1 |= TIM_CR1_ARPE; 						/* Auto-reload preload enable */	
	TIM5->PSC = 160 - 1;
}

/* input between 1 to 65536 */
void delay(volatile uint32_t num) { 
		if (num == 0) {
			return;
		}		
		TIM2->ARR = num;
		TIM2->CNT = 0;          				/* clear timer counter */
		TIM2->CR1 |= TIM_CR1_CEN;        /* enable TIM2 counter */
		// wait until UIF (Update interrupt flag) set
    while(!(TIM2->SR & TIM_SR_UIF)) { }   		
    TIM2->SR &= ~TIM_SR_UIF;
		TIM2->CR1 &= ~TIM_CR1_CEN;      /* disable TIM2 */
}

/* input between 1 to 65536 */
void delay10Us(volatile uint32_t num) {
		if (num == 0) {
			return;
		}
		TIM5->ARR = num;
		TIM5->CNT = 0;          				/* clear timer counter */
		TIM5->CR1 |= TIM_CR1_CEN;       /* enable TIM2 counter */
		// wait until UIF (Update interrupt flag) set
    while(!(TIM5->SR & TIM_SR_UIF)) { }   		
    TIM5->SR &= ~TIM_SR_UIF;
		TIM5->CR1 &= ~TIM_CR1_CEN;   /* disable TIM2 */
}
