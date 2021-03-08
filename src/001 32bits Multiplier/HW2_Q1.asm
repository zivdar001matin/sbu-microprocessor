;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG1   (EXE)   PURPOSE: MULTIPLY TWO 32BITS NUMBERS
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
NUMS    DD      00000052H, 00000029H     
RES     DD      2 DUP(?)
;----------------------------------------------------------     
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        MOV     SI, OFFSET NUMS
        MOV     AX, [SI]
        MOV     BX, [SI+4]
        MUL     BX
        MOV     RES, AX
        MOV     RES+2, DX
        ;
        MOV     AX, [SI+2]
        MOV     BX, [SI+4]
        MUL     BX
        ADD     [RES+2], AX
        ADC     [RES+4], DX
        ADC     [RES+6], 0
        ;
        MOV     AX, [SI]
        MOV     BX, [SI+6]
        MUL     BX
        ADD     [RES+2], AX
        ADC     [RES+4], DX
        ADC     [RES+6], 0
        ;
        MOV     AX, [SI+2]
        MOV     BX, [SI+6]
        MUL     BX
        ADD     [RES+2], AX
        ADC     [RES+4], DX
        ADC     [RES+6], 0
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
        END MAIN            ;this is the program exit point