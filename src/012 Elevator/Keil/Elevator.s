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
	;GPIOB MODER 
	LDR R1 , =GPIOB_MODER
	LDR R0 , [R1]
	LDR R0 , =0x55000055 ;01 01 01 01 -> 00000 
	STR R0 , [R1]
	
 ENDFUNC


; main logic of code
__main FUNCTION

LOOP_3
	BL	ResetCheck
	B	LOOP_3

GET_FIRST
	MOV R9, #0
	BL GetKeyPress
	CMP R0, 0xA
	BGE GET_FIRST
	MOV R12, R0

	;show on 7segments
	LDR R1, =GPIOA_ODR
	LSL R2, R0, #12
	STR R2, [R1]
	;show on LED
	LDR R1, =GPIOB_ODR
	MOV R0, #8
	STR R0, [R1]

GET_HASH
	MOV R9, #8
	BL GetKeyPress
	CMP R0, 0xB
	BNE GET_HASH

GET_SECOND
	BL GetKeyPress
	CMP R0, 0xA
	BGE GET_SECOND
	MOV R11, R0

	MOV R0, R12
	MOV R1, #3			;counter for number showing
	MOV R2, #0			;showing number on LEDs
	CMP R0, R11
	ADD R11, #1
	BEQ END_F
	BLT GO_UP
	SUB R0, #1
	SUB R11, #2
	MOV R1, #0
	BGE GO_DOWN
	B	END_F

GO_UP
	MOV R3, R0			;temp register
	MOV R4, R1
	LSL R4, #2			;multiply R1*4
	LSL R3, R4
	ORR R2, R3
	;show on 7segments
	LDR R3, =GPIOA_ODR
	STR R2, [R3]
	;show on LED
	LDR R3, =GPIOB_ODR
	MOV R4, #1
	MOV R5, R1
POWER
	CMP R5, #0
	BEQ END_POWER
	LSL R4, #1
	SUB R5, #1
	B	POWER
END_POWER

	STR R4, [R3]			;multiply 2^R1
	ADD R0, #1
	SUB R1, #1
	;
	CMP R0, R11
	BEQ END_F
	CMP R1, #-1
	MOVEQ R1, #3
	MOVEQ R2, #0
	BL 	DELAY
	B 	GO_UP

GO_DOWN
	MOV R3, R0			;temp register
	MOV R4, R1
	LSL R4, #2			;multiply R1*4
	LSL R3, R4
	ORR R2, R3
	;show on 7segments
	LDR R3, =GPIOA_ODR
	STR R2, [R3]
	;show on LED
	LDR R3, =GPIOB_ODR
	MOV R4, #1
	MOV R5, R1
POWER_2
	CMP R5, #0
	BEQ END_POWER_2
	LSL R4, #1
	SUB R5, #1
	B	POWER_2
END_POWER_2

	STR R4, [R3]			;multiply 2^R1
	SUB R0, #1
	ADD R1, #1
	;
	CMP R0, R11
	BEQ END_F
	CMP R1, #4
	MOVEQ R1, #0
	MOVEQ R2, #0
	BL 	DELAY
	B 	GO_DOWN


END_F
INF_LOOP
	B INF_LOOP

 ENDFUNC
 

DELAY
;Return key pressed in register R0.
;	used registers:
;		R8
            LDR R8, = 0x4FFFFF
D_LOOP      NOP
            NOP
            SUBS R8, #1
            BNE D_LOOP
            MOV PC, LR
 
GetKeyPress FUNCTION
;Return key pressed in register R0.
;	used registers:
;		R0, R1, R2, R3
; 	input registers:
;		R9 -> ORR with GPIOB output
	;FIRST ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R3 , 0xEFF0
	ORR R3 , R9
	STR R3 , [R2]
	
	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	MOV R1 , R0

	;check if 1 is pressed
	MOV R3 , 0xFEFF ;value for key 1 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R0, R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ ONE_PRESSED
	;check if 2 is pressed
	MOV R3 , 0xFDFF ;value for key 2 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ TWO_PRESSED
	;check if 3 is pressed
	MOV R3 , 0xFBFF ;value for key 3 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ THREE_PRESSED
	
	;SECOND ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R3 , 0xDFF0
	ORR R3 , R9
	STR R3 , [R2]

	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	MOV R1 , R0

	;check if 4 is pressed
	MOV R3 , 0xFEFF ;value for key 4 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R0, R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ FOUR_PRESSED
	;check if 5 is pressed
	MOV R3 , 0xFDFF ;value for key 5 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ FIVE_PRESSED
	;check if 6 is pressed
	MOV R3 , 0xFBFF ;value for key 6 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ SIX_PRESSED
	
	;THIRD ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R3 , 0xBFF0
	ORR R3 , R9
	STR R3 , [R2]

	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	MOV R1 , R0

	;check if 7 is pressed
	MOV R3 , 0xFEFF ;value for key 7 -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R0, R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ SEVEN_PRESSED
	;check if 8 is pressed
	MOV R3 , 0xFDFF ;value for key 8 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ EIGHT_PRESSED
	;check if 9 is pressed
	MOV R3 , 0xFBFF ;value for key 9 -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ NINE_PRESSED
	
	;FOURTH ROW KP ENABLE
	LDR R2 , =GPIOB_ODR
	MOV R3 , 0x7FF0
	ORR R3 , R9
	STR R3 , [R2]

	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	MOV R1 , R0

	;check if 7 is pressed
	MOV R3 , 0xFEFF ;value for key * -> 1111 1110 1111 1111 -> kp1 ->0
	MOV R0, R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ STAR_PRESSED
	;check if 8 is pressed
	MOV R3 , 0xFDFF ;value for key 0 -> 1111 1101 1111 1111 -> kp2 ->0
	MOV R0 , R1
	ORR R0, R0, R3
	CMP R0 , R3
	BEQ ZERO_PRESSED
	;check if 9 is pressed
	MOV R3 , 0xFBFF ;value for key # -> 1111 1011 1111 1111 -> kp3 ->0
	MOV R0 , R1
	ORR R0, R0, R3
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

ResetCheck FUNCTION
;	reset function
	PUSH {R0, R1, R2}
	LDR R2 , =GPIOB_IDR
	LDR R0 , [R2]
	;check if reset is pressed
	MOV R3 , 0xFFEF
	ORR R0, R0, R3
	CMP R0 , R3
	POP {R0, R1, R2}
	BEQ GET_FIRST
	MOV PC, LR
 ENDFUNC

 END