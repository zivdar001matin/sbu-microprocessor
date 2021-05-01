
	EXPORT SystemInit
    EXPORT __main


	AREA MYPROG,CODE,READONLY 

SystemInit FUNCTION
	; initialization code
 ENDFUNC


; add numbers from 1 to 9 
; main logic of code
__main FUNCTION
	MOV R1,#12      ;a = 12
	MOV R2,#8       ;b = 8
	STR R1, [SP,#-4]!		;Caller-Saved register
	STR R2, [SP,#-4]!		;Caller-Saved register
	BL  GCD
	LDR R2, [SP], #4		;Caller-Saved register
	LDR R1, [SP], #4		;Caller-Saved register
	
INFINITE_LOOP
	B   INFINITE_LOOP

GCD
	STR LR, [SP,#-4]!		;save LR on Stack (Callee-saved)
	CMP R1, #0
	BNE ELS
	MOV R0, R2 	;set return register (R0) the return value (R2) [b]
	LDR LR, [SP], #4
	MOV PC, LR
ELS
	CMP R2, R1
	BLT DONE ;!(R2 >= R1)
	SUB R2, R2, R1 ; calculate b % a
	B ELS ; do the while loop
DONE
	STR R1, [SP,#-4]!		; swap R1 , R2
	STR R2, [SP,#-4]!
	LDR R1, [SP], #4
	LDR R2, [SP], #4
	BL GCD
	LDR LR, [SP], #4		;Callee-Saved register
	MOV PC, LR

 ENDFUNC	
 END