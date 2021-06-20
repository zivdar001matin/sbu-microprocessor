#include <stm32f4xx.h>
// #include <math.h>

void INIT_PORTA(void);
void INIT_PORTB(void);
void INIT_PORTC(void);
void INTI_TIMER(void);

void delay(volatile uint32_t);
void delay10Us(volatile uint32_t num);

void LCD_init(void);
void LCD_command(uint32_t com);
void LCD_data(uint32_t data);
void LCD_ready(void);

uint32_t USART2_read(void);
void USART2_write(uint32_t data);
void show_integer_on_lcd(uint32_t value);
void send_integer_on_usart(uint32_t value);
void show_packet_on_lcd(uint32_t signal_type, uint32_t signal_duration, uint32_t signal_frequency);

void send_to_dac(uint32_t value);

int main(){
	INIT_PORTA();
	INIT_PORTB();
	INIT_PORTC();
	INTI_TIMER();
	
	LCD_init();
	
	// Clear USART data register
	USART2->DR;

	while(1){
		// Receive Packet
		uint32_t packet[5], i;
		for (i = 0; i < 5; i++) {
			packet[i] = USART2_read();
		}
		uint32_t signal_type = packet[0];
		uint32_t signal_duration = (packet[2] << 8) + packet[1];
		uint32_t signal_frequency = (packet[4] << 8) + packet[3];		
		
		double period_ms = 1000.0 / signal_frequency;
		double half_period_ms = period_ms / 2;
		uint32_t period_ms_aprox = (uint32_t)(period_ms);
		uint32_t half_period_ms_aprox = (uint32_t)(half_period_ms);
		
		show_packet_on_lcd(signal_type, signal_duration, signal_frequency);
		
		if (signal_type == 1) { /* Sin */ 			
			//const int lenght = 256;
			//uint32_t sin_wave[lenght];
			//const float M_PI = 3.1415926535897f;
			//float part_radians = 2 * M_PI / length;
			//for (j = 0; j < length; j++) {
        // sin_wave[j] = (uint32_t)((0xFFF / 2) * (sin(part_radians * j) + 1));
				// send_integer_on_usart(sin_wave[j] & 0xFFFF);
				// USART2_write(' ');
			//}
			const static uint32_t sin_wave[] = { 32767, 34824, 36874, 38907, 40916, 42893, 44830, 46719, 48553, 50325, 52027, 53654, 55198, 56653, 58015, 59276, 60434, 61481, 62416, 63233, 63931, 64505, 64954, 65276, 65470, 65535, 65470, 65276, 64954, 64505, 63931, 63233, 62416, 61481, 60434, 59276, 58015, 56653, 55198, 53654, 52027, 50325, 48553, 46719, 44830, 42893, 40916, 38907, 36874, 34824, 32767, 30710, 28660, 26627, 24618, 22641, 20704, 18815, 16981, 15209, 13507, 11880, 10336, 8881, 7519, 6258, 5100, 4053, 3118, 2301, 1603, 1029, 580, 258, 64, 0, 64, 258, 580, 1029, 1603, 2301, 3118, 4053, 5100, 6258, 7519, 8881, 10336, 11880, 13507, 15209, 16981, 18815, 20704, 22641, 24618, 26627, 28660, 30710 };
			uint32_t time = 0, j;
			uint32_t step_10us = period_ms_aprox; // period_ms_aprox * 100 / 100
			while (time < signal_duration) {			
				for (j = 0; j < 100; j++) {
            send_to_dac(sin_wave[j]); /* write value of sinewave to DAC */
            delay10Us(step_10us);
        }
				time += period_ms_aprox;
			}
		} else if (signal_type == 2) { /* Square */ 
			uint32_t time = 0;
			while (time < signal_duration) {
				send_to_dac(0);
				delay(half_period_ms_aprox);
				send_to_dac(0xFFFF);
				delay(half_period_ms_aprox);
				time += 2 * half_period_ms_aprox;
			}
		} else if (signal_type == 3) { /* Triangle */
			uint32_t time = 0, j;
			uint32_t step = 0xFFFF / (half_period_ms_aprox);
			while (time < signal_duration) {
				for (j = 0; j < 2 * 0xFFFF; j += step) {			
					if (j < 0xFFFF) {
						send_to_dac(j);
					} else {
						send_to_dac(0xFFFF * 2 - j);
					}
					delay(1);
				}
				time += period_ms_aprox;
			}
		} else if (signal_type == 4) { /* Abs(Sin) */ 
			const static uint32_t sin_wave[] = { 0, 2058, 4114, 6167, 8213, 10251, 12280, 14296, 16297, 18283, 20251, 22199, 24125, 26027, 27903, 29752, 31571, 33360, 35115, 36836, 38520, 40166, 41773, 43339, 44861, 46340, 47772, 49158, 50495, 51782, 53018, 54202, 55333, 56408, 57428, 58392, 59297, 60145, 60932, 61660, 62327, 62932, 63476, 63956, 64374, 64728, 65018, 65244, 65405, 65502, 65535, 65502, 65405, 65244, 65018, 64728, 64374, 63956, 63476, 62932, 62327, 61660, 60932, 60145, 59297, 58392, 57428, 56408, 55333, 54202, 53018, 51782, 50495, 49158, 47772, 46340, 44861, 43339, 41773, 40166, 38520, 36836, 35115, 33360, 31571, 29752, 27903, 26027, 24125, 22199, 20251, 18283, 16297, 14296, 12280, 10251, 8213, 6167, 4114, 2058 };
			volatile uint32_t time = 0, j;
			volatile uint32_t step_10us = period_ms_aprox; // period_ms_aprox * 100 / 100
			while (time < signal_duration) {			
				for (j = 0; j < 100; j++) {
            send_to_dac(sin_wave[j]); /* write value of sinewave to DAC */
            delay10Us(step_10us);
        }
				time += period_ms_aprox;
			}
		} else if (signal_type == 5) { /* Step */
			uint32_t stairs = 10;
			uint32_t time = 0, j;
			uint32_t step = 0xFFFF / stairs;
			uint32_t step_delay = period_ms_aprox / (stairs * 2);
			while (time < signal_duration) {
				for (j = 0; j < 2 * 0xFFFF; j += step) {			
					if (j < 0xFFFF) {
						send_to_dac(j);
					} else {
						send_to_dac(0xFFFF * 2 - j);
					}
					delay(step_delay);
				}
				time += period_ms_aprox;
			}
		} else if (signal_type == 6) { /* Sawtooth */ 
			uint32_t time = 0, j;
			while (time < signal_duration) {
				for (j = 0; j < 0xFFFF; j += (0xFFFF / (period_ms_aprox))) {
					send_to_dac(j);
					delay(1);
				}
				time += period_ms_aprox;
			}
		}
		
		send_to_dac(0); 	// reset to zero value
		
		LCD_command(1); /* clear display and set cursor at first line */
		LCD_data('F');
		LCD_data('I');
		LCD_data('N');
		LCD_data('I');
		LCD_data('S');
		LCD_data('H');
		LCD_data('E');
		LCD_data('D');
		
		USART2_write(1); 	// Send finish acknowledgment
	}
}

void show_packet_on_lcd(uint32_t signal_type, uint32_t signal_duration, uint32_t signal_frequency) {
	LCD_command(1); /* clear display and set cursor at first line */
	if (signal_type == 1) {
		LCD_data('S');
		LCD_data('I');
		LCD_data('N');
		LCD_data(' ');
		LCD_data('1');
	} else if (signal_type == 2) {
		LCD_data('S');
		LCD_data('Q');
		LCD_data('U');
		LCD_data('A');
		LCD_data('R');
		LCD_data('E');
		LCD_data(' ');
		LCD_data('2');
	} else if (signal_type == 3) {
		LCD_data('T');
		LCD_data('R');
		LCD_data('I');
		LCD_data('A');
		LCD_data('N');
		LCD_data('G');
		LCD_data('L');
		LCD_data('E');
		LCD_data(' ');
		LCD_data('3');
	} else if (signal_type == 4) {
		LCD_data('A');
		LCD_data('B');
		LCD_data('S');
		LCD_data('(');
		LCD_data('S');
		LCD_data('I');
		LCD_data('N');
		LCD_data(')');
		LCD_data(' ');
		LCD_data('4');
	} else if (signal_type == 5) {
		LCD_data('S');
		LCD_data('T');
		LCD_data('E');
		LCD_data('P');
		LCD_data(' ');
		LCD_data('5');
	}	else if (signal_type == 6) {
		LCD_data('S');
		LCD_data('A');
		LCD_data('W');
		LCD_data('T');
		LCD_data('O');
		LCD_data('O');
		LCD_data('T');
		LCD_data('H');
		LCD_data(' ');
		LCD_data('6');
	}
	
	LCD_command(0xC0); 		/* Move cursor to next line */
	
	LCD_data('D');
	LCD_data('U');
	LCD_data('R');
	LCD_data('A');
	LCD_data('T');
	LCD_data('I');
	LCD_data('O');
	LCD_data('N');
	LCD_data(' ');
	show_integer_on_lcd(signal_duration);
	LCD_data(' ');
	
	LCD_data('F');
	LCD_data('R');
	LCD_data('E');
	LCD_data('Q');
	LCD_data('U');
	LCD_data('E');
	LCD_data('N');
	LCD_data('C');
	LCD_data('Y');
	LCD_data(' ');
	show_integer_on_lcd(signal_frequency);
}

void send_to_dac(uint32_t value) {
	GPIOB->ODR &= 0xFFFFFEFF; /* disable DAC */
	uint32_t lower_bit = (value & 0xFF00) >> 8;
	uint32_t upper_bit = (value & 0xFF) << 8;
	GPIOB->ODR = lower_bit;
	GPIOA->ODR = upper_bit;
	GPIOB->ODR |= 0x00000100; /* enable DAC */
}

void send_integer_on_usart(uint32_t value) {
	uint32_t digits[5];
	uint32_t value_copy = value;
	int32_t counter = 0;
	for (counter = 0; counter < 5; counter++) {
			digits[counter] = value_copy % 10;
			value_copy /= 10;
	}
		
	// Show result on LCD
	if (value >= 10000) {
		USART2_write('0' + digits[4]);
	}
	if (value >= 1000) {
		USART2_write('0' + digits[3]);
	}
	if (value >= 100) {
		USART2_write('0' + digits[2]);
	}
	if (value >= 10) {
		USART2_write('0' + digits[1]);
	}
	USART2_write('0' + digits[0]);
}

void show_integer_on_lcd(uint32_t value) {
	uint32_t digits[5];
	uint32_t value_copy = value;
	int32_t counter = 0;
	for (counter = 0; counter < 5; counter++) {
			digits[counter] = value_copy % 10;
			value_copy /= 10;
	}
		
	// Show result on LCD
	if (value >= 10000) {
		LCD_data('0' + digits[4]);
	}
	if (value >= 1000) {
		LCD_data('0' + digits[3]);
	}
	if (value >= 100) {
		LCD_data('0' + digits[2]);
	}
	if (value >= 10) {
		LCD_data('0' + digits[1]);
	}
	LCD_data('0' + digits[0]);
}

void USART2_write(uint32_t data) {
    while (!(USART2->SR & USART_SR_TXE)) {}   // wait until Tx buffer empty
    USART2->DR = (data & 0xFF);
}

uint32_t USART2_read(void) {
    while (!(USART2->SR & USART_SR_RXNE)) {}   // wait until char arrives
    return USART2->DR;
}


void LCD_init() {
	GPIOC->MODER = 0x55555555; 	/* make GPIOC as output pins */
	/* initialization sequence */
	LCD_command(0x38); 					/* set font=5x7 dot, 1-line display, 8-bit data transfer */
	LCD_command(0x01); 					/* clear screen, move cursor to home */
	LCD_command(0x0E); 					/* turn on display, cursor on, no cursor blinking */
}

void LCD_ready(void) {
	volatile uint32_t status;
	GPIOC->MODER = 0x55550000; 	/* make GPIOC as input pins */
	GPIOC->ODR = 0x100 ; 				/* RS = 0, R/W = 1, LCD output*/
	do { 												/* stay in the loop until it is not busy */
		GPIOC->ODR |= 0x400; 			/* pulse E */
		delay(1);
		status = GPIOC->IDR; 			/* read status register */
		GPIOC->ODR &= 0xBFF; 			/* clear pulse E */
		delay(1); 								
	} while (status & 0x80); 		/* check busy bit */
	
	GPIOC->ODR = 0; 						/* R/W = 0, LCD input */
	GPIOC->MODER = 0x55555555; 	/* make GPIOC as output pins */
}

void LCD_command(uint32_t com) {
	LCD_ready();
	GPIOC->ODR = 0x000 | com; 	/* RS = 0, R/W = 0, write command*/
	GPIOC->ODR |= 0x400; 				/* pulse E */
	delay(1);
	GPIOC->ODR &= 0xBFF; 				/* clear pulse E */
}

void LCD_data(uint32_t data) {
	LCD_ready();
	GPIOC->ODR = 0x200 | data; 	/* RS = 1, R/W= 0, set data*/
	GPIOC->ODR |= 0x400; 				/* pulse E */
	delay(1);
	GPIOC->ODR &= 0xBFF; 				/* clear pulse E */
	delay(1);
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
