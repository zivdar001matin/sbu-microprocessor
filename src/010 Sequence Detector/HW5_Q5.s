
	EXPORT SystemInit
    EXPORT __main

	AREA MYPROG,CODE,READONLY 

SystemInit FUNCTION
	; initialization code
 ENDFUNC


; main logic of code
__main FUNCTION
	; R10 = 0x05CBCF9D
	MOV R10, #0x5000000
	ORR R10, #0xCB0000
	ORR R10, #0xCF00
	ORR R10, #0x9D
	
	STR R10, [SP,#-4]!
	
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
LOOP
	MOVS R10, R10, LSR #1
	MOV R0, R0, LSL #1
	AND R0, #7
	ADC	R0, #0
	CMP R0, #5			;(101)b = 5
	BNE	NO_SEQUENCE
	ADD R1, #1			;increase sequence counter
NO_SEQUENCE
	ADD R2, #1
	CMP R2, #32
	BNE LOOP
	
	LDR R10, [SP], #4

	B END_F


END_F

 ENDFUNC	
 END