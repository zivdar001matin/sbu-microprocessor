;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG4   (EXE)   PURPOSE: CALCULATE SUM OF ODD ARRAY NUMBERS
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
N       DW      ?
SUM     DW      ?
NUMSTR  DB      '$$$$$'      ;converted NUM to string for 5 digits
MSG1    DB      'enter array length: $'
MSG2    DB      0Dh, 0Ah, 'sum of odd array nums is: $'
MSG3    DB      0Dh, 0Ah, 19h, 19h, ' enter array elements below ', 19h, 19h, 0Dh, 0Ah, 0Ah, '$'
NUMBERS DW      100 DUP(?)
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
START:  ;clear screen
        MOV     AX,0600H        ;06 TO SCROLL & 00 FOR FULLJ SCREEN
        MOV     BH,71H          ;ATTRIBUTE 7 FOR BACKGROUND AND 1 FOR FOREGROUND
        MOV     CX,0000H        ;STARTING COORDINATES
        MOV     DX,184FH        ;ENDING COORDINATES
        INT     10H             ;FOR VIDEO DISPLAY
        ;get N
        MOV     DX, OFFSET MSG1
        MOV     AH, 9
        INT     21h
        CALL    SCAN_NUM    ;return number in CX
        MOV     N, CX
        ;
        MOV     DX, OFFSET MSG3
        MOV     AH, 9
        INT     21h
        ;
        MOV     SI, OFFSET NUMBERS
GET_ARRAY:
        CMP     CX, 0
        JE      END_ARRAY
        PUSH    CX
        CALL    SCAN_NUM
        MOV     [SI], CX
        POP     CX
        DEC     CX
        ADD     SI, 2
        ;display line break
        MOV     DX, 13
        MOV     AH, 2
        INT     21h
        MOV     DX, 10
        MOV     AH, 2
        INT     21h
        ;
        JMP     GET_ARRAY
END_ARRAY:
        XOR     AX, AX          ;clear AX
        XOR     CX, CX          ;clear CX
        MOV     SI, OFFSET NUMBERS
CALCULATE_SUM:
        CMP     CX, N
        JGE     END_CALCULATE
        PUSH    AX
        ;
        XOR     DX, DX
        MOV     AX, [SI]
        MOV     BX, 2
        DIV     BX
        ;
        POP     AX
        CMP     DX, 0
        JE      BACK
        MOV     BX, [SI]
        ADD     AX, BX
BACK: 
        INC     CX
        ADD     SI, 2
        JMP     CALCULATE_SUM
END_CALCULATE:
        MOV     SUM, AX
PRNIT_SUM:
        MOV     DX, OFFSET MSG2
        MOV     AH, 9
        INT     21h
        MOV     SI, OFFSET NUMSTR
        MOV     AX, SUM
        CALL    NUMBER2STRING   ;retruns numstr
        MOV     DX, OFFSET NUMSTR
        MOV     AH, 9
        INT     21h
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
  mov  cx, 6
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