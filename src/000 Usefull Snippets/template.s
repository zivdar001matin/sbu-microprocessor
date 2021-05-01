
	EXPORT SystemInit
    EXPORT __main

	AREA RESET,CODE,READONLY 

SystemInit FUNCTION
	; initialization code
 ENDFUNC


; main logic of code
__main FUNCTION
	;Implement your code here

INFINITE_LOOP
	B INFINITE_LOOP

 ENDFUNC	
 END