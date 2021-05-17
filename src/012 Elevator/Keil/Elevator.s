;AHB1ENR
RCC_AHB1ENR	EQU	0x40023830
;GPIOA
GPIOA_MODER	EQU 0x40020000
GPIOA_IDR	EQU 0x40020010
GPIOA_ODR	EQU 0x40020014
;GPIOB
GPIOB_MODER	EQU 0x40020400
GPIOB_IDR	EQU 0x40020410
GPIOB_ODR	EQU 0x40020414

	EXPORT SystemInit
    EXPORT __main

	AREA MYPROG,CODE,READONLY 

SystemInit FUNCTION
	; initialization code
	; GPIOA and GPIOB clock enable
	LDR R1, =RCC_AHB1ENR
	MOV R0, 0x03
	STR R0, [R1]
	;GPIOA config
	LDR R1, =GPIOA_MODER
	MOV R0, 0x55555555
	STR R0, [R1]
	
 ENDFUNC


; main logic of code
__main FUNCTION
	;Implement your code here

END_F

 ENDFUNC
 
GetKeyPress FUNCTION
;Return key pressed in register R0.
;	used registers:
;		R0, R1, R2, R3
	;FIRST ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R0 , 0xEFFF
	STR R0 , [R2]
	
	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	MOV R1 , R0

	;check if 1 is pressed
	MOV R3 , 0xFEFF ;value for key 1 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R1, R0
	CMP R0 , R3
	BEQ ONE_PRESSED
	;check if 2 is pressed
	MOV R3 , 0xFDFF ;value for key 2 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ TWO_PRESSED
	;check if 3 is pressed
	MOV R3 , 0xFBFF ;value for key 3 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ THREE_PRESSED
	
	;SECOND ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R0 , 0xDFFF
	STR R0 , [R2]

	;check if 4 is pressed
	MOV R3 , 0xFEFF ;value for key 4 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R1, R0
	CMP R0 , R3
	BEQ FOUR_PRESSED
	;check if 5 is pressed
	MOV R3 , 0xFDFF ;value for key 5 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ FIVE_PRESSED
	;check if 6 is pressed
	MOV R3 , 0xFBFF ;value for key 6 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ SIX_PRESSED
	
	;THIRD ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R0 , 0xBFFF
	STR R0 , [R2]

	;check if 7 is pressed
	MOV R3 , 0xFEFF ;value for key 7 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R1, R0
	CMP R0 , R3
	BEQ SEVEN_PRESSED
	;check if 8 is pressed
	MOV R3 , 0xFDFF ;value for key 8 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ EIGHT_PRESSED
	;check if 9 is pressed
	MOV R3 , 0xFBFF ;value for key 9 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ NINE_PRESSED
	
	;FOURTH ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R0 , 0x7FFF
	STR R0 , [R2]

	;check if 7 is pressed
	MOV R3 , 0xFEFF ;value for key * -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R1, R0
	CMP R0 , R3
	BEQ STAR_PRESSED
	;check if 8 is pressed
	MOV R3 , 0xFDFF ;value for key 0 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ ZERO_PRESSED
	;check if 9 is pressed
	MOV R3 , 0xFBFF ;value for key # -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	CMP R0 , R3
	BEQ HASH_PRESSED

	MOV R0, #0xF
	B TO_RETURN

ONE_PRESSED
	MOV  R0 , #1
	B TO_RETURN

TWO_PRESSED
	MOV  R0 , #2
	B TO_RETURN

THREE_PRESSED
	MOV  R0 , #3
	B TO_RETURN

FOUR_PRESSED
	MOV  R0 , #4
	B TO_RETURN

FIVE_PRESSED
	MOV  R0 , #5
	B TO_RETURN

SIX_PRESSED
	MOV  R0 , #6
	B TO_RETURN

SEVEN_PRESSED
	MOV  R0 , #7
	B TO_RETURN

EIGHT_PRESSED
	MOV  R0 , #8
	B TO_RETURN

NINE_PRESSED
	MOV  R0 , #9
	B TO_RETURN

STAR_PRESSED
	MOV  R0 , #10
	B TO_RETURN

ZERO_PRESSED
	MOV  R0 , #0
	B TO_RETURN

HASH_PRESSED
	MOV  R0 , #11
	B TO_RETURN

TO_RETURN
	MOV PC, LR

 ENDFUNC
 END