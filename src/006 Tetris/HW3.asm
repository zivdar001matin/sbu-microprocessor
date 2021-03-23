;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG6   (EXE)   PURPOSE: Tetris game
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
BLOCKS  DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
MOV_A  PROC    NEAR
        
MOV_A  ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point