;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG1   (EXE)   PURPOSE: MOD OF A BCD NUMBER ON 16 NIT BINARY
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
DATA1   DD      ?           ;BCD number
DATA2   DD      ?           ;binary number          
RESULT  DD      ?
NUMSTR  DB      '$$$$'      ;converted RESULT to string for 4 digits
MSG1    DB      'Enter the BCD number: $' 
MSG2    DB      0Dh,0Ah, 'Enter the Binary number: $'
MSG3    DB      0Dh,0Ah, 'Modulo result is: $'
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        MOV     SI, OFFSET DATA1
        ;get first number
        MOV     DX, OFFSET MSG1
        MOV     AH, 9
        INT     21h
        CALL    SCAN_NUM    ;return 16bit BCD number in CX1
        MOV     DATA1, CX
        ;get second number
        MOV     DX, OFFSET MSG2
        MOV     AH, 9
        INT     21h
        CALL    SCAN_BNUM   ;return 16bit binary number in CX
        MOV     [SI+2], CX
        ;calculate modulo
        XOR     DX, DX      ;clear DX
        MOV     AX, [SI]
        MOV     BX, [SI+2]
        DIV     BX
        MOV     [SI+4], DX
        ;print result
        MOV     DX, OFFSET MSG3
        MOV     AH, 9
        INT     21h
        ;TODO
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; these functions are copied from emu8086.inc ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;----------------------------------------------------------
; this macro prints a char in AL and advances
; the current cursor position:
putc    macro   char
        push    ax
        mov     al, char
        mov     ah, 0eh
        int     10h     
        pop     ax
endm
; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
PUSH    DX
PUSH    AX
PUSH    SI

MOV     CX, 0

; reset flag:
MOV     CS:make_minus, 0

next_digit:

; get char from keyboard
; into AL:
MOV     AH, 00h
INT     16h
; and print it:
MOV     AH, 0Eh
INT     10h

; check for MINUS:
CMP     AL, '-'
JE      set_minus

; check for ENTER key:
CMP     AL, 0Dh  ; carriage return?
JNE     not_cr
JMP     stop_input
not_cr:


CMP     AL, 8                   ; 'BACKSPACE' pressed?
JNE     backspace_checked
MOV     DX, 0                   ; remove last digit by
MOV     AX, CX                  ; division:
DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
MOV     CX, AX
PUTC    ' '                     ; clear position.
PUTC    8                       ; backspace again.
JMP     next_digit
backspace_checked:


; allow only digits:
CMP     AL, '0'
JAE     ok_AE_0
JMP     remove_not_digit
ok_AE_0:
CMP     AL, '9'
JBE     ok_digit
remove_not_digit:
PUTC    8       ; backspace.
PUTC    ' '     ; clear last entered not digit.
PUTC    8       ; backspace again.
JMP     next_digit ; wait for next input.
ok_digit:


; multiply CX by 10 (first time the result is zero)
PUSH    AX
MOV     AX, CX
MUL     CS:ten                  ; DX:AX = AX*10
MOV     CX, AX
POP     AX

; check if the number is too big
; (result should be 16 bits)
CMP     DX, 0
JNE     too_big

; convert from ASCII code:
SUB     AL, 30h

; add AL to CX:
MOV     AH, 0
MOV     DX, CX      ; backup, in case the result will be too big.
ADD     CX, AX
JC      too_big2    ; jump if the number is too big.

JMP     next_digit

set_minus:
MOV     CS:make_minus, 1
JMP     next_digit

too_big2:
MOV     CX, DX      ; restore the backuped value before add.
MOV     DX, 0       ; DX was zero before backup!
too_big:
MOV     AX, CX
DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
MOV     CX, AX
PUTC    8       ; backspace.
PUTC    ' '     ; clear last entered digit.
PUTC    8       ; backspace again.
JMP     next_digit ; wait for Enter/Backspace.


stop_input:
; check flag:
CMP     CS:make_minus, 0
JE      not_minus
NEG     CX
not_minus:

POP     SI
POP     AX
POP     DX
RET
make_minus      DB      ?       ; used as a flag.
ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
SCAN_NUM        ENDP
;----------------------------------------------------------
; gets the multi-digit BINARY number from the keyboard,
; and stores the result in CX register:
SCAN_BNUM       PROC    NEAR
PUSH    DX
PUSH    AX
PUSH    SI

MOV     CX, 0

; reset flag:
MOV     CS:make_minus_b, 0

next_digit_b:

; get char from keyboard
; into AL:
MOV     AH, 00h
INT     16h
; and print it:
MOV     AH, 0Eh
INT     10h

; check for MINUS:
CMP     AL, '-'
JE      set_minus_b

; check for ENTER key:
CMP     AL, 0Dh  ; carriage return?
JNE     not_cr_b
JMP     stop_input_b
not_cr_b:


CMP     AL, 8                   ; 'BACKSPACE' pressed?
JNE     backspace_checked_b
MOV     DX, 0                   ; remove last digit by
MOV     AX, CX                  ; division:
DIV     CS:two                  ; AX = DX:AX / 2 (DX-rem).
MOV     CX, AX
PUTC    ' '                     ; clear position.
PUTC    8                       ; backspace again.
JMP     next_digit_b
backspace_checked_b:


; allow only digits:
CMP     AL, '0'
JAE     ok_AE_0_b
JMP     remove_not_digit_b
ok_AE_0_b:
CMP     AL, '1'
JBE     ok_digit_b
remove_not_digit_b:
PUTC    8       ; backspace.
PUTC    ' '     ; clear last entered not digit.
PUTC    8       ; backspace again.
JMP     next_digit_b ; wait for next input.
ok_digit_b:


; multiply CX by 2 (first time the result is zero)
PUSH    AX
MOV     AX, CX
MUL     CS:two                  ; DX:AX = AX*2
MOV     CX, AX
POP     AX

; check if the number is too big
; (result should be 16 bits)
CMP     DX, 0
JNE     too_big_b

; convert from ASCII code:
SUB     AL, 30h

; add AL to CX:
MOV     AH, 0
MOV     DX, CX      ; backup, in case the result will be too big.
ADD     CX, AX
JC      too_big2_b    ; jump if the number is too big.

JMP     next_digit_b

set_minus_b:
MOV     CS:make_minus_b, 1
JMP     next_digit_b

too_big2_b:
MOV     CX, DX      ; restore the backuped value before add.
MOV     DX, 0       ; DX was zero before backup!
too_big_b:
MOV     AX, CX
DIV     CS:two  ; reverse last DX:AX = AX*2, make AX = DX:AX / 2
MOV     CX, AX
PUTC    8       ; backspace.
PUTC    ' '     ; clear last entered digit.
PUTC    8       ; backspace again.
JMP     next_digit_b ; wait for Enter/Backspace.


stop_input_b:
; check flag:
CMP     CS:make_minus_b, 0
JE      not_minus_b
NEG     CX
not_minus_b:

POP     SI
POP     AX
POP     DX
RET
make_minus_b    DB      ?       ; used as a flag.
two             DW      2      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
SCAN_BNUM       ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point         