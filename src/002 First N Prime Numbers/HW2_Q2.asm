;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG2   (EXE)   PURPOSE: PRINT FIRST N PRIME NUMBERS
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
N       DW      10          ; N = 10 //TODO user input
COUNT   DW      0
NUM     DW      2
FLAG    DW      1
NUMSTR  DB      '$$$$'      ;converted NUM to string for 4 digits
;----------------------------------------------------------     
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
WHILE:  
        MOV     AX, COUNT   ;check to see if the appropriate
        MOV     BX, N       ;number of primes has been found
        CMP     AX, BX
        JGE     EWHILE
        ;
        MOV     FLAG, 1     ;flag = 1
        ;
        MOV     CX, 2
FOR:    
        CMP     NUM, CX
        JLE     ENDFOR
        ;NUM % CX
        MOV     AX, NUM     ;AX holds numerator
        XOR     DX, DX      ;DX must be cleared
        DIV     CX
        CMP     DX, 0       ;remainder == 0
        JNE     ENDIF
        MOV     FLAG, 0     ;flag = 0
        JMP     ENDFOR
ENDIF:  
        INC     CX
        JMP     FOR        
ENDFOR: 
        MOV     AX, FLAG
        CMP     AX, 1
        JNE     ENDIF1
        ADD     COUNT, 1
        ;print prime NUM
        JMP     PRINT
ENDIF1: 
        ADD     NUM, 1      ;see if next number is prime
        JMP     WHILE 
EWHILE: 
        MOV     AH, 4CH     ;set up to
        INT     21H
PRINT:  
        MOV     SI, OFFSET NUMSTR
        MOV     AX, NUM
        CALL    NUMBER2STRING   ;retruns numstr
        ;display string
        MOV     AH, 9
        MOV     DX, OFFSET NUMSTR
        INT     21h
        ;display line break
        MOV     DX, 13
        MOV     AH, 2
        INT     21h
        MOV     DX, 10
        MOV     AH, 2
        INT     21h
        JMP     ENDIF1

MAIN    ENDP
;----------------------------------------------------------
;SOURCE: https://stackoverflow.com/questions/37605815/how-can-i-print-0-to-100-in-assembly-language-in-emu-8086
;----------------------------------------------------------
;CONVERT A NUMBER IN STRING.
;ALGORITHM : EXTRACT DIGITS ONE BY ONE, STORE
;THEM IN STACK, THEN EXTRACT THEM IN REVERSE
;ORDER TO CONSTRUCT STRING (STR).
;PARAMETERS : AX = NUMBER TO CONVERT.
;             SI = POINTING WHERE TO STORE STRING.

number2string proc 
  call dollars ;FILL STRING WITH $.
  mov  bx, 10  ;DIGITS ARE EXTRACTED DIVIDING BY 10.
  mov  cx, 0   ;COUNTER FOR EXTRACTED DIGITS.
cycle1:       
  mov  dx, 0   ;NECESSARY TO DIVIDE BY BX.
  div  bx      ;DX:AX / 10 = AX:QUOTIENT DX:REMAINDER.
  push dx      ;PRESERVE DIGIT EXTRACTED FOR LATER.
  inc  cx      ;INCREASE COUNTER FOR EVERY DIGIT EXTRACTED.
  cmp  ax, 0   ;IF NUMBER IS
  jne  cycle1  ;NOT ZERO, LOOP. 
;NOW RETRIEVE PUSHED DIGITS.
cycle2:  
  pop  dx        
  add  dl, 48  ;CONVERT DIGIT TO CHARACTER.
  mov  [ si ], dl
  inc  si
  loop cycle2  

  ret
number2string endp       

;------------------------------------------
;FILLS VARIABLE WITH '$'.
;USED BEFORE CONVERT NUMBERS TO STRING, BECAUSE
;THE STRING WILL BE DISPLAYED.
;PARAMETER : SI = POINTING TO STRING TO FILL.

proc dollars                 
  mov  cx, 5
  mov  di, offset numstr
dollars_loop:      
  mov  bl, '$'
  mov  [ di ], bl
  inc  di
  loop dollars_loop

  ret
endp  

;------------------------------------------
        END MAIN            ;this is the program exit point