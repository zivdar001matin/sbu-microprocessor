;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROGX   (EXE)   PURPOSE: XXXX
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
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

;----------------------------------------------------------
        END MAIN            ;this is the program exit point