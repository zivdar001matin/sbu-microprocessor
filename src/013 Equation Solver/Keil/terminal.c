#include "stm32f4xx.h"

#define RS 0x100     /* PB5 mask for reg select */
#define RW 0x200     /* PB6 mask for read/write */
#define EN 0x400     /* PB7 mask for enable */

/* LCD */
void delayMs(int n); 
void LCD_command(unsigned char command); 
void LCD_data(char data);
void LCD_init(void);
void PORTS_init(void);
/* Keypad */
void delay(void);
void keypad_init(void);
char keypad_getkey(void);
char keypad_kbhit(void);
/* UART */
// void UART4_init(void);
// void UART4_write(int c);
// char UART4_read(void);

int main(void) {
		unsigned char key;
		// UART4_init();
	
    /* initialize LCD controller */
    LCD_init();
    /* initialize Keypad */
    keypad_init();

    while(1) {
				key = keypad_getkey();  /* read the keypad */
				if (key != 0)
						LCD_data(key);

        delayMs(1000);

        // /* clear LCD display */
        // LCD_command(1);
        // delayMs(500);
    }
}

/* initialize port pins then initialize LCD controller */
void LCD_init(void) {
    PORTS_init();

    delayMs(30);            /* initialization sequence */
    LCD_command(0x30);
    delayMs(10);
    LCD_command(0x30);
    delayMs(1);
    LCD_command(0x30);

    LCD_command(0x38);      /* set 8-bit data, 2-line, 5x7 font */
    LCD_command(0x06);      /* move cursor right after each char */
    LCD_command(0x01);      /* clear screen, move cursor to home */
    LCD_command(0x0F);      /* turn on display, cursor blinking */
}

void PORTS_init(void) {
    /* Initialize needed GPIOs and set ports mode appropriately  */
		RCC->AHB1ENR |=  0x06;          /* enable GPIOB/C clock */

    /* PB5 for LCD R/S */
    /* PB6 for LCD R/W */
    /* PB7 for LCD EN */
    GPIOB->MODER &= ~0x003F0000;    /* clear pin mode */
    GPIOB->MODER |=  0x00150000;    /* set pin output mode */
    GPIOB->BSRR = 0x06000000;       /* turn off EN and R/W */

    /* PB0-PB7 for LCD D0-D7, respectively. */
    GPIOB->MODER &= ~0x0000FFFF;    /* clear pin mode */
    GPIOB->MODER |=  0x00005555;    /* set pin output mode */
}

void LCD_command(unsigned char command) {
    GPIOB->BSRR = (RS | RW) << 16;		/* RS = 0, R/W = 0 */
    GPIOB->ODR = command;							/* put command on data bus */
    GPIOB->BSRR = EN;									/* pulse EN high */
    delayMs(0);
    GPIOB->BSRR = EN << 16;						/* clear EN */

    if (command < 4)
        delayMs(4);         /* command 1 and 2 needs up to 1.64ms */
    else
        delayMs(1);         /* all others 40 us */
}

void LCD_data(char data) {
    GPIOB->BSRR = RS;									/* RS = 1 */
    GPIOB->BSRR = RW << 16;           /* R/W = 0 */
    GPIOB->ODR = data;                /* put data on data bus */
    GPIOB->BSRR = EN;                 /* pulse EN high */
    delayMs(0);              /* Do not change this line! */
    GPIOB->BSRR = EN << 16;						/* clear EN */

    delayMs(1);
}

/* delay n milliseconds (16 MHz CPU clock) */
void delayMs(int n) {
    int i;
    for (; n > 0; n--)
        for (i = 0; i < 3195; i++) ;
}
/* p3_5.c: Matrix keypad scanning
 *
 * This program scans a 4x4 matrix keypad and returns a unique
 * number for each key pressed.
 * LD2 (green LED) is used to blink the returned number.
 *
 * PC0-3 are connected to the columns and PC4-7 are
 * connected to the rows of the keypad.
 *
 * This program was tested with Keil uVision v5.24a with DFP v2.11.0
 */
 /* this function initializes PC0-3 (column) and PC4-7 (row).
 * The column pins need to have the pull-up resistors enabled.
 */
void keypad_init(void) {
    RCC->AHB1ENR |=  0x11;	        /* enable GPIOA clock */
    GPIOA->MODER &= ~0xFF000000;    /* clear pin mode to input */
    GPIOA->PUPDR =   0x00550000;    /* enable pull up resistors for column pins */
}

/*
 * This is a non-blocking function to read the keypad.
 * If a key is pressed, it returns a unique code for the key.
 * Otherwise, a zero is returned.
 * PC6-9 are used as input and connected to the columns. Pull-up resistors are
 * enabled so when the keys are not pressed, these pins are pulled high.
 * PC4-7 are used as output that drives the keypad rows.
 * First, all rows are driven low and the input pins are read. If no key is
 * pressed, they will read as all one because of the pull up resistors.
 * If they are not all one, some key is pressed.
 * If some key is pressed, the program proceeds to drive only one row low at
 * a time and leave the rest of the rows inactive (float) then read the input pins.
 * Knowing which row is active and which column is active, the program can decide
 * which key is pressed.
 *
 * Only one row is driven so that if multiple keys are pressed and row pins are
 * shorted, the microcontroller will not be damaged. When the row is being
 * deactivated, it is driven high first otherwise the stray capacitance may keep
 * the inactive row low for some time.
 */
char keypad_getkey(void) {
    int row, col;
    const int row_mode[] = {0x01000000, 0x04000000, 0x10000000, 0x40000000}; /* one row is output */
    const int row_low[] =  {0x10000000, 0x20000000, 0x40000000, 0x80000000}; /* one row is low */
    const int row_high[] = {0x00001000, 0x00002000, 0x00004000, 0x00008000}; /* one row is high */

    /* check to see any key pressed */
    GPIOA->MODER = 0x55000000;      /* make all row pins output */
    GPIOA->BSRR =  0xF0000000;      /* drive all row pins low */
    delay();                        /* wait for signals to settle */
    col = GPIOA->IDR & 0x0F00;      /* read all column pins */
    GPIOA->MODER &= ~0xFF000000;    /* disable all row pins drive */
    if (col == 0x0F00)              /* if all columns are high */
        return 0;                       /* no key pressed */

    /* If a key is pressed, it gets here to find out which key.
     * It activates one row at a time and read the input to see
     * which column is active. */
    for (row = 0; row < 4; row++) {
        GPIOA->MODER &= ~0xFF000000;    /* disable all row pins drive */
        GPIOA->MODER |= row_mode[row];  /* enable one row at a time */
        GPIOA->BSRR = row_low[row];     /* drive the active row low */
        delay();                        /* wait for signal to settle */
        col = GPIOA->IDR & 0x0F00;      /* read all columns */
        GPIOA->BSRR = row_high[row];    /* drive the active row high */
        if (col != 0x0F00) break;       /* if one of the input is low, some key is pressed. */
    }
    GPIOA->BSRR = 0xF0000000;           /* drive all rows high before disable them */
    GPIOA->MODER &= ~0xFF000000;        /* disable all rows */
    if (row == 4)
        return 0;                       /* if we get here, no key is pressed */

    /* gets here when one of the rows has key pressed, check which column it is */
    if (col == 0x0600) return row * 4 + 1;    /* key in column 0 */
    if (col == 0x0500) return row * 4 + 2;    /* key in column 1 */
    if (col == 0x0300) return row * 4 + 3;    /* key in column 2 */
    // if (col == 0x0700) return row * 4 + 4;    /* key in column 3 */

    return 0;   /* just to be safe */
}

/* make a small delay */
void delay(void) {
    int i;
    for (i = 0; i < 20; i++) ;
}

/* p4_4.c UART4 echo at 9600 Baud
 *
 * This program receives a character from UART4 receiver
 * then sends it back through UART4 transmitter.
 * UART4 is connected to PA0-Tx and PA1-Rx.
 * A 3.3V signal level to USB cable is used to connect PA0/PA1
 * to the host PC COM port.
 * PA0 - UART4 TX (AF8)
 * PA1 - UART4 RX (AF8)
 * Use Tera Term on the host PC to send keystrokes and observe the display
 * of the characters echoed.
 *
 * By default, the clock is running at 16 MHz.
 *
 * This program was tested with Keil uVision v5.24a with DFP v2.11.0
 */

// /* initialize UART4 to transmit at 9600 Baud */
// void UART4_init (void) {
//     RCC->AHB1ENR |= 1;          /* Enable GPIOA clock */
//     RCC->APB1ENR |= 0x80000;    /* Enable UART4 clock */

//     /* Configure PA0, PA1 for UART4 TX, RX */
//     GPIOA->AFR[0] &= ~0x00FF;
//     GPIOA->AFR[0] |=  0x0088;   /* alt8 for UART4 */
//     GPIOA->MODER  &= ~0x000F;
//     GPIOA->MODER  |=  0x000A;   /* enable alternate function for PA0, PA1 */

//     UART4->BRR = 0x0683;        /* 9600 baud @ 16 MHz */
//     UART4->CR1 = 0x000C;        /* enable Tx, Rx, 8-bit data */
//     UART4->CR2 = 0x0000;        /* 1 stop bit */
//     UART4->CR3 = 0x0000;        /* no flow control */
//     UART4->CR1 |= 0x2000;       /* enable UART4 */
// }

// /* Write a character to UART4 */
// void UART4_write (int ch) {
//     while (!(UART4->SR & 0x0080)) {}   // wait until Tx buffer empty
//     UART4->DR = (ch & 0xFF);
// }

// /* Read a character from UART4 */
// char UART4_read(void) {
//     while (!(UART4->SR & 0x0020)) {}   // wait until char arrives
//     return UART4->DR;
// }
