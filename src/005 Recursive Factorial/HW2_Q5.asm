;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG5   (EXE)   PURPOSE: CALCULATE FACTORIAL OF A NUMBER USING RECURSIVE FUNCTION
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
N       DW      ?           ;number
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        ; enter your code here
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
;CALCULATE FACTORIAL OF A NUMBER
;ALGORITHM : RECURSIVE CALL UNTIL BASE CONDITION
;N=1, SAVE REGISTER ON THE STACK.
;PARAMETERS : AX = NUMBER TO CONVERT.
FACTORIAL   PROC
        CMP     AX, 1       ;if(AX==1)
        JNE     RETURN      ;return 1
        PUSH    AX
        DEC     AX
        CALL    FACTORIAL
        MOV     BX, AX      ;AX = factorial(n-1)
        POP     AX          ;AX = n
        MUL     BX          ;AX = AX * BX
RETURN:
        RET
FACTORIAL   ENDP      
;----------------------------------------------------------
        END MAIN            ;this is the program exit point