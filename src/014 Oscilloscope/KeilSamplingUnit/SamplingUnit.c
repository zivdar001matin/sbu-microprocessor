#include <stm32f4xx.h>

void INIT_PORTA(void);
void INIT_PORTB(void);
void INIT_PORTC(void);
void INIT_TIMER(void);

void delay(volatile uint32_t);

void show_student_id(void);
void show_different_signals(void);
void show_packet_on_lcd(void);
void show_integer_on_lcd(uint32_t value);
void get_signal_type(void);
uint32_t get_analog_value(uint32_t minimum, uint32_t maximum);

uint32_t check_keypad(void);

void LCD_init(void);
void LCD_command(uint32_t com);
void LCD_data(uint32_t data);
void LCD_ready(void);

uint32_t USART2_read(void);
void USART2_write(uint32_t data);

volatile static uint32_t isPressed = 0;
volatile static uint32_t signal_type;
volatile static uint32_t signal_duration;
volatile static uint32_t signal_frequency;

int main(){
	INIT_PORTA();
	INIT_PORTB();
	INIT_PORTC();
	INIT_TIMER();
	
	LCD_init();
	
	// First show student ID
	show_student_id();
	delay(1000);

	while(1){
		// Get signal type
		get_signal_type();
		// Get signal duration and frequency
		signal_duration = get_analog_value(500, 10000);
		signal_frequency = get_analog_value(1, 1000);
				
		// Show packet on LCD
		show_packet_on_lcd();
		
		// Send Packet
		delay(10);
		uint32_t packet[5], i;
		packet[0] = signal_type;
		packet[1] = (signal_duration) & 0xFF;
		packet[2] = (signal_duration >> 8) & 0xFF;
		packet[3] = (signal_frequency) & 0xFF;
		packet[4] = (signal_frequency >> 8) & 0xFF;
		for (i = 0; i < 5; i++) {
			 USART2_write(packet[i]);
		}
		
		USART2_read(); // wait until display finished
	}
}

void show_packet_on_lcd() {
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
    while (!(USART2->SR & 0x0080)) {}   // wait until Tx buffer empty
    USART2->DR = (data & 0xFF);
}

uint32_t USART2_read(void) {
    while (!(USART2->SR & 0x0020)) {}   // wait until char arrives
    return USART2->DR;
}

uint32_t get_analog_value(uint32_t minimum, uint32_t maximum) {
	LCD_command(1);
	LCD_command(0x0C); /* same configuration, only disable cursor location */
	while (1) {
		ADC1->CR2 |= 0x40000000;        				/* start a conversion */
		while(!(ADC1->SR & 2)) {}       				/* wait for conv complete */
		uint32_t converted_value = ADC1->DR;   	/* read conversion result, default 12 bit ADC (others 10 bit, 8 bit) */
		uint32_t result = (uint32_t)((converted_value / (4096.0 - 1)) * (maximum - minimum)) + minimum; /* between minimum to maximum */
		
		uint32_t digits[5];
		uint32_t result_copy = result;
		int32_t counter = 0;
		for (counter = 0; counter < 5; counter++) {
				digits[counter] = result_copy % 10;
				result_copy /= 10;
		}
		
		// Show result on LCD
		LCD_command(0x80);
		int32_t empty = 0;
		for (counter = 4; counter >= 0; counter--) {
				if (digits[counter] > 0) {
					break;
				} else {
					empty++;
				}
		}
		for (counter = 4 - empty; counter >= 0; counter--) {
				LCD_data('0' + digits[counter]);
		}
		while (empty > 0) {
			LCD_data(' ');
			empty--;
		}
		
		uint32_t key = check_keypad();
		if (key == 10) {
			LCD_command(0x0E); /* reset to init configuration */
			return result;
		}
	}
	
}

void get_signal_type() {
	show_different_signals();
	uint32_t key;
	while (1) {
		key = check_keypad();
		if (key != 100 && key >= 1 && key <= 6) {
			break;
		}
	}
	signal_type = key;
}

void show_student_id() {
	LCD_command(1); /* clear display and set cursor at first line */
	LCD_data('9');
	LCD_data('6');
	LCD_data('2');
	LCD_data('4');
	LCD_data('3');
	LCD_data('0');
	LCD_data('1');
	LCD_data('2');
	delay(100);
}

void show_different_signals() {
	LCD_command(1); 					/* clear display and set cursor at first line */
	// LCD_command(0x80); 		/* Move cursor at first of line */
	LCD_data('S');
	LCD_data('I');
	LCD_data('N');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data('1');
	
	LCD_data(' ');
	
	LCD_data('S');
	LCD_data('Q');
	LCD_data('U');
	LCD_data('A');
	LCD_data('R');
	LCD_data('E');
	LCD_data(' ');
	LCD_data('2');
	
	LCD_data(' ');
	
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
	
	LCD_data(' ');
	LCD_command(0xC0); 		/* Move cursor to next line */
	
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
	
	LCD_data(' ');
	
	LCD_data('S');
	LCD_data('T');
	LCD_data('E');
	LCD_data('P');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data(' ');
	LCD_data('5');
	
	LCD_data(' ');
	
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
	delay(0);
	GPIOC->ODR &= 0xBFF; 				/* clear pulse E */
	delay(1);
}

uint32_t check_keypad() {
	GPIOB->ODR = 0XEFFF;
	volatile uint32_t input = GPIOB->IDR;
	volatile uint32_t digit_pressed = 100;
	switch(input){
		case 0xEEFF: 
			digit_pressed = 1;
			break;
		case 0xEDFF: 
			digit_pressed = 2;
			break;
		case 0xEBFF: 
			digit_pressed = 3;
			break;
	}
	GPIOB->ODR = 0XDFFF;
	input = GPIOB->IDR;
	switch(input){
		case 0xDEFF: 
			digit_pressed = 4;
			break;
		case 0xDDFF: 
			digit_pressed = 5;
			break;
		case 0xDBFF: 
			digit_pressed = 6;
			break;
	}
	GPIOB->ODR = 0XBFFF;
	input = GPIOB->IDR;
	switch(input){
		case 0xBEFF: 
			digit_pressed = 7;
			break;
		case 0xBDFF: 
			digit_pressed = 8;
			break;
		case 0xBBFF: 
			digit_pressed = 9;
			break;
	}
	GPIOB->ODR = 0X7FFF;
	input = GPIOB->IDR;
	switch(input){
		case 0x7DFF: 
			digit_pressed = 0;
			break;
		case 0x7BFF: 
			digit_pressed = 10; /* char # */
			break;
	}
	
	if (digit_pressed != 100) {
		if (isPressed == 0) {
			isPressed = 1;
			return digit_pressed;
		}
		isPressed = 1;	
	} else {
		isPressed = 0;
	}
	return 100; /* mean nothing pressed */
}

void INIT_PORTA(){
	// Clock for GPIOA
	RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
	// MODER PORT A
	GPIOA->MODER = 0x00000003; 						/* analoge input = 11 */
	
	/* Configure PA0 for ADC1 */
	RCC->APB2ENR |= 0x00000100;     			/* Enable ADC1 clock */
	ADC1->CR1 |= 0x00;              			/* Channel PA0 is used */
	ADC1->CR2 = 0;                  			/* SW trigger, Right alignment, Signle conversion mode (after start conversion) */
	ADC1->CR2 |= 1;                 			/* Enable AD converting */
	
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
	GPIOB->MODER = 0x55000000;
}

void INIT_PORTC(){
	// Clock for GPIOC
	RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;
}
void INIT_TIMER() {
	RCC->APB1ENR |= RCC_APB1ENR_TIM2EN;   /* enable TIM2 clock */
  TIM2->CR1 |= TIM_CR1_OPM; 						/* One pulse mode: Counter stops counting at the next update event (clearing the bit CEN) */
	TIM2->CR1 |= TIM_CR1_ARPE; 						/* Auto-reload preload enable */	
	TIM2->PSC = 16000 - 1;
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
