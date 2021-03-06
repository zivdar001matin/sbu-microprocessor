#include <stm32f4xx.h>

void INIT_PORTA(void);
void INIT_PORTB(void);
void INIT_PORTC(void);
void INIT_TIMER(void);

void delay(volatile uint32_t);

// void show_student_id(void);
// void show_different_signals(void);
void show_on_lcd(void);
void show_integer_on_lcd(uint32_t value);
// void get_signal_type(void);
uint32_t get_analog_value(uint32_t minimum, uint32_t maximum);

uint32_t check_keypad(void);

void LCD_init(void);
void LCD_command(uint32_t com);
void LCD_data(uint32_t data);
void LCD_ready(void);

uint32_t USART2_read(void);
void USART2_write(uint32_t data);

void check_keypad_command(void);

volatile static uint32_t isPressed = 0;
// volatile static uint32_t signal_type;
// volatile static uint32_t signal_duration;
// volatile static uint32_t signal_frequency;

volatile static uint32_t b_fixed = 0;
volatile static uint32_t b_floating = 1;
volatile static uint32_t voltage_unit_fixed = 1;
volatile static uint32_t voltage_unit_floating = 0;
volatile static uint32_t time_unit = 100;

int main(){
	INIT_PORTA();
	INIT_PORTB();
	INIT_PORTC();
	INIT_TIMER();
	
	LCD_init();

	show_on_lcd();

	while(1){
		// Show detail on LCD
		if (isPressed) {
			show_on_lcd();
			isPressed = 0;
		}

		// Get command from keypad
		delay(10);
		check_keypad_command();

		// Read Analog
		uint32_t digital_value_1;
		digital_value_1 = get_analog_value(0, 2);
		uint32_t digital_value_2;
		
		// Send Packet
		delay(10);
		uint32_t packet[8], i;
		packet[0] = (digital_value_1) & 0xFF;
		packet[1] = (digital_value_1 >> 8) & 0xFF;
		packet[2] = (digital_value_2) & 0xFF;
		packet[3] = (digital_value_2 >> 8) & 0xFF;
		packet[4] = voltage_unit_fixed;
		packet[5] = voltage_unit_floating;
		packet[6] = b_fixed;
		packet[7] = b_floating;
		for (i = 0; i < 8; i++) {
			USART2_write(packet[i]);
		}

		
		
		USART2_read(); // wait until display finished
	}
}

void show_on_lcd() {
	LCD_command(1); /* clear display and set cursor at first line */
    LCD_data('B');
    LCD_data('=');
    LCD_data('+');
    show_integer_on_lcd(b_fixed);
    LCD_data('.');
    show_integer_on_lcd(b_floating);
	
	LCD_data(' ');

	LCD_data('U');
	LCD_data('n');
	LCD_data('i');
	LCD_data('t');
	LCD_data('=');
    show_integer_on_lcd(voltage_unit_fixed);
    LCD_data('.');
    show_integer_on_lcd(voltage_unit_floating);
    LCD_data('v');
	LCD_data(' ');


	LCD_command(0xC0); 		/* Move cursor to next line */
	
	
	LCD_data('T');
	LCD_data('i');
	LCD_data('m');
	LCD_data('e');
	LCD_data('U');
	LCD_data('n');
	LCD_data('i');
	LCD_data('t');
	LCD_data(' ');
	LCD_data('=');
	LCD_data(' ');
    show_integer_on_lcd(time_unit);
	LCD_data('m');
	LCD_data('s');
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

void check_keypad_command(void){
	uint32_t key = check_keypad();
	if (key == 1) {
		if (++voltage_unit_floating == 10) {
			voltage_unit_floating = 0;
			voltage_unit_fixed++;
		}
	} else if (key == 2) {
		if (voltage_unit_floating == 0) {
			voltage_unit_floating = 9;
			voltage_unit_fixed--;
		} else {
			voltage_unit_floating--;
		}
	} else if (key == 3) {
		if (++b_floating == 10) {
			b_floating = 0;
			b_fixed++;
		}
	} else if (key == 4) {
		if (b_floating == 0) {
			b_floating = 9;
			b_fixed--;
		} else {
			b_floating--;
		}
	} else if (key == 5) {
		time_unit += 10;	
	} else if (key == 6){
		time_unit -= 10;
	}
}

uint32_t get_analog_value(uint32_t minimum, uint32_t maximum) {
	ADC1->CR2 |= 0x40000000;        				/* start a conversion */
	while(!(ADC1->SR & 2)) {}       				/* wait for conv complete */
	uint32_t converted_value = ADC1->DR;   	/* read conversion result, default 12 bit ADC (others 10 bit, 8 bit) */
	uint32_t result = (uint32_t)((converted_value / (4096.0 - 1)) * (maximum - minimum)) + minimum; /* between minimum to maximum */
		return result;
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
//	RCC->APB1ENR |= RCC_APB1ENR_TIM2EN;   /* enable TIM2 clock */
  //TIM2->CR1 |= TIM_CR1_OPM; 						/* One pulse mode: Counter stops counting at the next update event (clearing the bit CEN) */
//	TIM2->CR1 |= TIM_CR1_ARPE; 						/* Auto-reload preload enable */	
//	TIM2->PSC = 16000 - 1;
//	TIM2->CNT = 0;          
//		TIM2->CR1 |= TIM_CR1_CEN;

  RCC->APB1ENR |= RCC_APB1ENR_TIM2EN;   /* enable TIM2 clock */
  TIM2->PSC = 160 -1;
  TIM2->ARR = 100 - 1;
  TIM2->CNT = 0;
  TIM2->CCMR1 = 0x0060;
  TIM2->CCER = 1;
  TIM2->CCR1 = 50 - 1;
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