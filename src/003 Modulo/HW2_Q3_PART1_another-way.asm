;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG_1_2   (EXE)   PURPOSE: MOD OF A BCD NUMBER ON 16 BITS BINARY NUMBER
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
bcd_num         DW      0123h
bcd_hex         DW      ?
binary_num      DW      1001h, 1000h, 0100h, 0010h
binary_hex      DW      ?
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        MOV     AX, bcd_num
        MOV     CX, 0
bcd_digits:
        CMP     AX, 0
        JZ      bcd_end

        PUSH    AX
        AND     AX, 0F000h              ; mask last digit
        SHR     AX, 12                  ; bring it to first digit

        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ADD     CX, AX

        POP     AX
        SHL     AX, 4

        JMP     bcd_digits
bcd_end:
        MOV     bcd_hex, CX
        ;

        MOV     CX, 0

        MOV     SI, OFFSET binary_num
        ADD     SI, 6

        MOV     BX, 4
loop_start:                     ;loop for 4 of 4 digits
        CMP     BX, 0
        JZ      loop_end
        PUSH    BX

        MOV     AX, [SI]
        ADD     SI, -2
        
        MOV     BX, 4
binary_digits:
        CMP     BX, 0
        JZ      binary_end

        PUSH    AX
        AND     AX, 0F000h              ; mask last digit
        SHR     AX, 12                  ; bring it to first digit

        PUSH    AX
        MOV     AX, CX
        MUL     CS:two                  ; DX:AX = AX*2
        MOV     CX, AX
        POP     AX

        ADD     CX, AX

        POP     AX
        SHL     AX, 4
        
        DEC     BX
        JMP     binary_digits

binary_end:
        MOV     binary_hex, CX
        ;
        POP     BX
        DEC     BX
        JMP     loop_start
loop_end:
        ;calculate modulo
        XOR     DX, DX      ;clear DX
        MOV     AX, bcd_hex
        MOV     BX, binary_hex
        DIV     BX
        MOV     RESULT, DX
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
ten             DW      10
two             DW      2
MAIN    ENDP
        END MAIN            ;this is the program exit point