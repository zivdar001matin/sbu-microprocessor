#define RS 0x20     /* Pin mask for reg select (e.g. here is pin 5) */
#define RW 0x40     /* Pin mask for read/write (e.g. here is pin 6) */
#define EN 0x80     /* Pin mask for enable     (e.g. here is pin 7) */
 
void delayMs(int n); 
void LCD_command(unsigned char command); 
void LCD_data(char data);
void LCD_init(void);
void PORTS_init(void);

int main(void) {
    /* initialize LCD controller */
    LCD_init();

    while(1) {
        /* Write "hello" on LCD */
        LCD_data('h');
        LCD_data('e');
        LCD_data('l');
        LCD_data('l');
        LCD_data('o');
        delayMs(1000);

        /* clear LCD display */
        LCD_command(1);
        delayMs(500);
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

    //TODO      /* set 8-bit data, 2-line, 5x7 font */
    //TODO      /* move cursor right after each char */
    //TODO      /* clear screen, move cursor to home */
    //TODO      /* turn on display, cursor blinking */
}

void PORTS_init(void) {
    //TODO                /* Initialize needed GPIOs and set ports mode appropriately  */
}

void LCD_command(unsigned char command) {
    //TODO                           /* RS = 0, R/W = 0 */
    //TODO                           /* put command on data bus */
    //TODO                           /* pulse EN high */
    delayMs(0);
    //TODO                           /* clear EN */

    if (command < 4)
        delayMs(2);         /* command 1 and 2 needs up to 1.64ms */
    else
        delayMs(1);         /* all others 40 us */
}

void LCD_data(char data) {
    //TODO                   /* RS = 1 */
    //TODO                   /* R/W = 0 */
    //TODO                   /* put data on data bus */
    //TODO                   /* pulse EN high */
    delayMs(0);              /* Do not change this line! */
    //TODO                   /* clear EN */

    delayMs(1);
}

/* delay n milliseconds (16 MHz CPU clock) */
void delayMs(int n) {
    int i;
    for (; n > 0; n--)
        for (i = 0; i < 3195; i++) ;
}

