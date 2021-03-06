;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG6   (EXE)   PURPOSE: Tetris game
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
; this technology allows to make external add-on devices
; for emu8086, such as led displays, robots, thermometers, stepper-motors, etc...
; c:\emu8086\devices\led_display.exe
#start=led_display.exe#
; connected on port 199
;----------------------------------------------------------
        .DATA
ROWS        EQU     8
COLOUMNS    EQU     12
COLOUMNS2   EQU     24          ;2*COLOUMNS
BLOCK_SIZE  EQU     15
ROW_PRINT_OFFSET    EQU 40     ;(200-BLOCK_SIZE*ROWS)/2

; block type constants
;          (read README):
TYPE_1_1    EQU     0101h
TYPE_1_2    EQU     0102h
TYPE_2_1    EQU     0201h
TYPE_3_1    EQU     0301h
TYPE_3_2    EQU     0302h
TYPE_3_3    EQU     0303h
TYPE_3_4    EQU     0304h
TYPE_4_1    EQU     0401h
TYPE_4_2    EQU     0402h
TYPE_5_1    EQU     0501h
TYPE_5_2    EQU     0502h
TYPE_5_3    EQU     0503h
TYPE_5_4    EQU     0504h

NEXT_TYPE   DW      ?, ?, ?     ;show next blocks types
NEXT_COLOR  DB      ?, ?, ?     ;show next block colors
CURR_POS    DW      ?, ?, ?, ?      ;show current blocks position
CURR_POS_STACK  DW    ?, ?, ?, ?    ;use as memory to save current block colour and number
CURR_DIR    DB      ?           ;show current block move direction
CURR_COLOR  DB      ?           ;show current block color
CURR_TYPE   DW      ?           ;show current block type
BLOCKS  DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
RANDOM_NUM  DW      ?           ;use for RAND macro
MOV_DOWN_STATUS DB  ?           ;use for pressing 'f'
SCORE       DW      ?           ;use for scoring system
NUMBER_MSG  DB      "0"
NUMBER_PRINTED  DB  0
WAIT_TIME   DW      0           ;use for clock ticks
;----------------------------------------------------------
; Return random value between min to max.
;   and save output to RANDOM_NUM.
;   
; ARGUMENTS:
;   MIN: lower bound
;   MAX: upper bound
;   RVAL: return register (16bits)
RAND  MACRO   MIN, MAX, RVAL
        PUSH AX
        PUSH CX
        PUSH DX
        MOV AH,0h           ; interrupts to get system time
        INT 1Ah             ; CX:DX now hold number of clock ticks since midnight
        MOV AX, DX
        xor DX, DX
        XOR CX, CX          ; CX = MAX-MIN
        MOV CX, MAX
        SUB CX, MIN
        DIV CX              ; here dx contains the remainder of the division - from 0 to MAX
        ADD DX, MIN
        MOV RANDOM_NUM, DX
        POP DX
        POP CX
        POP AX
        MOV RVAL, RANDOM_NUM
ENDM
;----------------------------------------------------------
        .CODE
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        MOV AX,0600H        ;SCROLL THE SCREEN
        MOV BH,07           ;NORMALATIRIBUTE
        MOV CX,0000         ;FROM ROW=OO,COLUMN=OO
        MOV DX,184FH        ;TO ROW=18H,COLUMN=4FH
        INT 10H             ;INVOKE INTERRUPT TO CLEAR SCREEN
        MOV AH,00           ;SET MODE
        MOV AL,13H          ;MODE = 13H (CGA Med RESOLUTION)
        INT 10H             ;INVOKE INTERRUPT TO CHANGE MODE
        MOV AX, 2
        CALL SHOW_SCORE
        CALL FIRST_INIT
        CALL INIT_BLOCK
        CALL PRINT_NEXT_BLOCKS
        CALL PRINT_MAP
        CALL PRINT_BORDERS
        JMP GAME_LOOP
        ;CALL MOV_RIGHT
        ;CALL MOV_LEFT
        ;CALL MOV_DOWN
        ;CALL CHECK_ROWS
        ;CALL CLEAR_EMPTY_ROWS
        ;CALL PRINT_MAP
        ;CALL PRINT_BORDERS
        ;JMP STOP_GAME
        ;

    GAME_LOOP:
        MOV MOV_DOWN_STATUS, 0
        ;
        MOV AX,0600H        ;SCROLL THE SCREEN
        MOV BH,07           ;NORMALATIRIBUTE
        MOV CX,0000         ;FROM ROW=OO,COLUMN=OO
        MOV DX,184FH        ;TO ROW=18H,COLUMN=4FH
        INT 10H             ;INVOKE INTERRUPT TO CLEAR SCREEN
        MOV AH,00           ;SET MODE
        MOV AL,13H          ;MODE = 13H (CGA Med RESOLUTION)
        INT 10H             ;INVOKE INTERRUPT TO CHANGE MODE
        ;
        CALL PRINT_MAP
        CALL PRINT_BORDERS
        CALL PRINT_NEXT_BLOCKS
        CALL SHOW_SCORE
    PLAYER_COMMAND:
        ; check for player commands:
        MOV     AH, 01h
        INT     16h
        JZ      NO_KEY
        MOV AH, 00h
        INT 16h
        CMP AL, 1Bh         ; esc - key?
        JE  STOP_GAME       ;
        MOV CURR_DIR, AL
        CALL MOV_BLOCK     ;todo
        JMP AFTER_NO_KEY
    NO_KEY:
        ; === wait a few moments here:
        ; get number of clock ticks
        ; (about 18 per second)
        ; since midnight into cx:dx
        MOV     AH, 00h
        INT     1Ah
        CMP     DX, WAIT_TIME
        JB      PLAYER_COMMAND
        ADD     DX, 18
        MOV     WAIT_TIME, DX
        CALL    MOV_DOWN
    AFTER_NO_KEY:
        ;
        JMP GAME_LOOP
    STOP_GAME:
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
;move block to the current direction
;ALGORITHM : call existing procedures
;PARAMETERS : current direction saved in the CURR_DIR
MOV_BLOCK   PROC    NEAR
        PUSH AX
        MOV AL, CURR_DIR
        CMP AL, 119             ;compare current input with 'w'
        JE  ROTATE_BLOCK
        CMP AL, 97              ;compare current input with 'a'
        JE  MOV_BLOCK_LEFT
        CMP AL, 115             ;compare current input with 's'
        JE  MOV_BLOCK_DOWN
        CMP AL, 100             ;compare current input with 'd'
        JE  MOV_BLOCK_RIGHT
        CMP AL, 102             ;compare current input with 'f'
        JE  MOV_BLOCK_DOWN_F
        JMP MOV_BLOCK_END
    ROTATE_BLOCK:
        CALL ROTATE
        JMP MOV_BLOCK_END
    MOV_BLOCK_LEFT:
        CALL MOV_LEFT
        JMP MOV_BLOCK_END
    MOV_BLOCK_DOWN:
        CALL MOV_DOWN
        JMP MOV_BLOCK_END
    MOV_BLOCK_RIGHT:
        CALL MOV_RIGHT
        JMP MOV_BLOCK_END
    MOV_BLOCK_DOWN_F:
        CALL MOV_DOWN_F
        JMP MOV_BLOCK_END
    MOV_BLOCK_END:
        POP AX
        RET
MOV_BLOCK   ENDP
;----------------------------------------------------------
; Print next blocks.
; ALGORITHM:
;   print first one at (1, coloumns + 1)
;    and the second at (5, coloumns + 1)
;
PRINT_NEXT_BLOCKS   PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ; print next first block
        MOV SI, OFFSET NEXT_COLOR
        MOV AL, [SI]
        MOV CURR_COLOR, AL
        MOV SI, OFFSET NEXT_TYPE
        MOV AX, [SI]
        CMP AX, TYPE_1_1
        JE  NEXT_BLOCK_TYPE_1_1
        CMP AX, TYPE_2_1
        JE  NEXT_BLOCK_TYPE_2_1
        CMP AX, TYPE_3_1
        JE  NEXT_BLOCK_TYPE_3_1
        CMP AX, TYPE_4_1
        JE  NEXT_BLOCK_TYPE_4_1
        CMP AX, TYPE_5_1
        JE  NEXT_BLOCK_TYPE_5_1

    NEXT_BLOCK_TYPE_1_1:
        MOV BX, 1
        MOV AX, COLOUMNS+1
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+4
        CALL PRINT_BLOCK_PROC
        JMP END_NEXT_BLOCK_TYPE
    NEXT_BLOCK_TYPE_2_1:
        MOV BX, 1
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_NEXT_BLOCK_TYPE
    NEXT_BLOCK_TYPE_3_1:
        MOV BX, 1
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 3
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 3
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_NEXT_BLOCK_TYPE
    NEXT_BLOCK_TYPE_4_1:
        MOV BX, 1
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 3
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_NEXT_BLOCK_TYPE
    NEXT_BLOCK_TYPE_5_1:
        MOV BX, 1
        MOV AX, COLOUMNS+1
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 1
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 2
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        JMP END_NEXT_BLOCK_TYPE
    END_NEXT_BLOCK_TYPE:
        ; print second next block
        MOV SI, OFFSET NEXT_COLOR
        MOV AL, [SI+1]
        MOV CURR_COLOR, AL
        MOV SI, OFFSET NEXT_TYPE
        MOV AX, [SI+2]
        CMP AX, TYPE_1_1
        JE  TWO_NEXT_BLOCK_TYPE_1_1
        CMP AX, TYPE_2_1
        JE  TWO_NEXT_BLOCK_TYPE_2_1
        CMP AX, TYPE_3_1
        JE  TWO_NEXT_BLOCK_TYPE_3_1
        CMP AX, TYPE_4_1
        JE  TWO_NEXT_BLOCK_TYPE_4_1
        CMP AX, TYPE_5_1
        JE  TWO_NEXT_BLOCK_TYPE_5_1

    TWO_NEXT_BLOCK_TYPE_1_1:
        MOV BX, 5
        MOV AX, COLOUMNS+1
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+4
        CALL PRINT_BLOCK_PROC
        JMP END_TWO_NEXT_BLOCK_TYPE
    TWO_NEXT_BLOCK_TYPE_2_1:
        MOV BX, 5
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_TWO_NEXT_BLOCK_TYPE
    TWO_NEXT_BLOCK_TYPE_3_1:
        MOV BX, 5
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 7
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 7
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_TWO_NEXT_BLOCK_TYPE
    TWO_NEXT_BLOCK_TYPE_4_1:
        MOV BX, 5
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 7
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        JMP END_TWO_NEXT_BLOCK_TYPE
    TWO_NEXT_BLOCK_TYPE_5_1:
        MOV BX, 5
        MOV AX, COLOUMNS+1
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        MOV BX, 5
        MOV AX, COLOUMNS+3
        CALL PRINT_BLOCK_PROC
        MOV BX, 6
        MOV AX, COLOUMNS+2
        CALL PRINT_BLOCK_PROC
        JMP END_TWO_NEXT_BLOCK_TYPE
    END_TWO_NEXT_BLOCK_TYPE:
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
PRINT_NEXT_BLOCKS   ENDP
;----------------------------------------------------------
;print block(i, j) where AX->i and BX->j
PRINT_BLOCK_PROC    PROC    NEAR
        ;multiply i by 25
        ;MOV AX, AX
        MOV CX, BLOCK_SIZE
        MUL CX
        MOV CX, AX          ;start line coloumn = i
        ;multiply j by 25
        MOV AX, BX
        MOV DX, BLOCK_SIZE
        MUL DX
        MOV DX, AX          ;row = j
        ADD DX, ROW_PRINT_OFFSET
        PUSH CX             ;save first pixel of block
        PUSH DX
        MOV AL, BLOCK_SIZE  ;store 25 at AL
        MOV AH, BLOCK_SIZE  ;store 25 at AH
        PUSH AX             ;push to use as a counter
    NEXT_COLOUMN2:
        MOV AH,0CH          ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL,CURR_COLOR   ;PIXELS= COLOR
        INT 10H             ;INVOKE INTERRUPT TO SET A PIXEL OF LINE
        INC CX              ;INCREMENT HORIZONTAL POSITION
        POP AX
        DEC AL
        PUSH AX
        CMP AL, 0           ;draw line length of 25px
        JNE NEXT_COLOUMN2
        POP AX
        DEC AH
        PUSH AX
        CMP AX, 0           ;draw line width of 25px
        JNE NEXT_ROW2
        POP AX
        JMP PRINT_BORDER_LABEL
    NEXT_ROW2:
        POP AX              ;reset coloumn counter to 25
        MOV AL, BLOCK_SIZE
        PUSH AX
        SUB CX, BLOCK_SIZE  ;reset line coloumn
        ADD DX, 1           ;go to next row
        JMP NEXT_COLOUMN2

    PRINT_BORDER_LABEL:
        POP DX
        POP CX
        MOV AH, 0Ch         ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL, 7           ;light gray
        XOR BX, BX          ;clear BX
    BORDER_FOR1:
        INT 10h
        INC CX              ;next coloumn
        INC BX
        CMP BX, BLOCK_SIZE
        JNZ BORDER_FOR1
        XOR BX, BX          ;clear BX
    BORDER_FOR2:
        INT 10h
        INC DX              ;next row
        INC BX
        CMP BX, BLOCK_SIZE
        JNZ BORDER_FOR2
        XOR BX, BX          ;clear BX
    BORDER_FOR3:
        INT 10h
        DEC CX              ;previous coloumn
        INC BX
        CMP BX, BLOCK_SIZE
        JNZ BORDER_FOR3
        XOR BX, BX          ;clear BX
    BORDER_FOR4:
        INT 10h
        DEC DX              ;previous row
        INC BX
        CMP BX, BLOCK_SIZE
        JNZ BORDER_FOR4
        RET
PRINT_BLOCK_PROC    ENDP
;----------------------------------------------------------
; ARGUMENTS:
;   NONE
;
; ?????? implement below logic ??????
;   for i in 8:
;	    for j in 12:
;		    if(BLOCKS[i, j] != 0)
;			    print(i, j);
PRINT_MAP   PROC    NEAR

        MOV SI, OFFSET BLOCKS
        XOR BX, BX          ;clear BX
    OUTER:
        XOR AX, AX          ;clear AX
    INNER:
        MOV CX, [SI]
        MOV CURR_COLOR, CH
        CMP CL, 0
        JE  BREAK_IF
        PUSH AX
        PUSH BX
        JMP PRINT_BLOCK
    END_PRINT_BLOCK:
        POP BX
        POP AX
    BREAK_IF:
        ADD SI, 2
        INC AX
        CMP AX, COLOUMNS
        JL  INNER
        INC BX
        CMP BX, ROWS
        JL  OUTER
        RET

    PRINT_BLOCK:                ;print block(i, j) where AX->i and BX->j
        ;multiply i by 25
        ;MOV AX, AX
        MOV CX, BLOCK_SIZE
        MUL CX
        MOV CX, AX          ;start line coloumn = i
        ;multiply j by 25
        MOV AX, BX
        MOV DX, BLOCK_SIZE
        MUL DX
        MOV DX, AX          ;row = j
        ADD DX, ROW_PRINT_OFFSET
        MOV AL, BLOCK_SIZE  ;store 25 at AL
        MOV AH, BLOCK_SIZE  ;store 25 at AH
        PUSH AX             ;push to use as a counter
    NEXT_COLOUMN:
        MOV AH,0CH          ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL,CURR_COLOR        ;PIXELS= COLOR
        INT 10H             ;INVOKE INTERRUPT TO SET A PIXEL OF LINE
        INC CX              ;INCREMENT HORIZONTAL POSITION
        POP AX
        DEC AL
        PUSH AX
        CMP AL, 0           ;draw line length of 25px
        JNE NEXT_COLOUMN
        POP AX
        DEC AH
        PUSH AX
        CMP AX, 0           ;draw line width of 25px
        JNE NEXT_ROW
        POP AX
        JMP END_PRINT_BLOCK
    NEXT_ROW:
        POP AX              ;reset coloumn counter to 25
        MOV AL, BLOCK_SIZE
        PUSH AX
        SUB CX, BLOCK_SIZE  ;reset line coloumn
        ADD DX, 1           ;go to next row
        JMP NEXT_COLOUMN

PRINT_MAP   ENDP
;----------------------------------------------------------
;show score on text mode
SHOW_SCORE  PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH ES
        ;show on LED device (port 199)
        MOV AX, SCORE
        OUT 199, AX
        ;
        PUSH DS
        POP ES
        ;
        MOV CX,0 
        MOV DX,0
        MOV NUMBER_PRINTED, 0
    LABEL1: 
        CMP AX,0 
        JE PRINT1       
        MOV BX,10         
        DIV BX                    
        PUSH DX                
        INC CX                 
        XOR DX,DX 
        JMP LABEL1 
    PRINT1:  
        CMP CX,0 
        JE  EXIT
        POP DX 
        ADD DX,48   
        MOV [NUMBER_MSG], DL   

        INC NUMBER_PRINTED

        PUSH AX 
        PUSH BX
        PUSH CX
        PUSH DX   
        ; print message using bios int 10h/13h function
        MOV AL, 0
        MOV BX, 3Fh
        MOV CX, 1
        MOV DL, NUMBER_PRINTED
        MOV DH, 0               ;location on the screen
        ;
        MOV BP, offset  NUMBER_MSG           
        MOV AH, 13h
        INT 10h
        ;
        POP DX
        POP CX
        POP BX
        POP AX  
        ;decrease the count 
        DEC CX 
        JMP PRINT1 
    EXIT: 
        POP ES
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
        ;
SHOW_SCORE  ENDP
;----------------------------------------------------------
; Print Border lines
;
; ARGUMENTS:
;   NONE
;
; ?????? implement below logic ??????
;   for i in 8+1:
;       for j in 12:
;           draw_vertical_line(BLOCKS_SIZE)
;	for j in 12+1:
;       for i in 8:
;           draw_horizontal_line(BLOCKS_SIZE)
PRINT_BORDERS   PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        ;
        XOR AX, AX          ;clear AX
        MOV DX, ROW_PRINT_OFFSET
        XOR CX, CX          ;clear CX
    PRINT_FOR1:
        CMP AX, ROWS
        JG  PRINT_BREAK1
        XOR BX, BX          ;clear BX
        MOV CX, 0
    PRINT_FOR2:
        CMP BX, COLOUMNS
        JGE  PRINT_BREAK2
        ;
        PUSH AX             ;save out loop counter
        MOV AH, 0Ch         ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL, 7           ;light gray
        PUSH BX             ;use as a inner inner loop
        MOV BX, 0
    LINE_LOOP1:
        INT 10H
        INC CX              ;next coloumn
        INC BX              ;increase counter
        CMP BX, BLOCK_SIZE
        JNZ LINE_LOOP1
        POP BX
        POP AX
        ;
        INC BX
        JMP PRINT_FOR2
    PRINT_BREAK2:
        ADD DX, BLOCK_SIZE
        INC AX
        JMP PRINT_FOR1
    PRINT_BREAK1:
        ;now print horizontal lines
        XOR AX, AX          ;clear AX
        XOR CX, CX          ;clear CX
        XOR DX, DX          ;clear DX
    PRINT_FOR3:
        CMP AX, COLOUMNS
        JG  PRINT_BREAK3
        XOR BX, BX          ;clear BX
        MOV DX, ROW_PRINT_OFFSET
    PRINT_FOR4:
        CMP BX, ROWS
        JGE  PRINT_BREAK4
        ;
        PUSH AX             ;save out loop counter
        MOV AH, 0Ch         ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL, 7           ;light gray
        PUSH BX             ;use as a inner inner loop
        MOV BX, 0
    LINE_LOOP2:
        INT 10H
        INC DX              ;next row
        INC BX              ;increase counter
        CMP BX, BLOCK_SIZE
        JNZ LINE_LOOP2
        POP BX
        POP AX
        ;
        INC BX
        JMP PRINT_FOR4
    PRINT_BREAK4:
        ADD CX, BLOCK_SIZE
        INC AX
        JMP PRINT_FOR3
    PRINT_BREAK3:
        ;
        POP DX
        POP CX
        POP BX
        POP AX
        RET
PRINT_BORDERS   ENDP
;----------------------------------------------------------
;Check if any row in the map is full of blocks, then clear it.
;
; ARGUMENTS:
;   NONE
;
; ?????? implement below logic ??????
;   for row in BLOCKS:
;       if all_elements_one(row)==1:
;           clear_row(row)
CHECK_ROWS  PROC    NEAR

        ;save registers
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        MOV CX, 0           ;set CX as a row counter
        MOV SI, OFFSET BLOCKS
    START_CHECK_ROWS:
        CMP CX, ROWS
        JE  END_CHECK_ROWS
        PUSH CX             ;save row counter on stack
        MOV CX, COLOUMNS    ;set CX as a coloumn counter
        MOV AX, 1           ;set AX=1 to use as a flag
    START_CHECK_ROW:
        CMP CX, 0
        JE  END_CHECK_ROW
        MOV BX, [SI]
        AND AX, BX          ;check if all elements in a row are equal to 1
        DEC CX              ;decrease coloumn counter
        ADD SI, 2           ;move SI to the next element in the row
        JMP START_CHECK_ROW
    END_CHECK_ROW:
        CMP AX, 1
        JNE AFTER_CLEAR
        POP CX              ;pop CX to become row counter to pass
        MOV AX, CX          ;as AX for CLEAR_ROW
        CALL CLEAR_ROW
        ; increase score
        ADD SCORE, 10
        ;
        PUSH CX
    AFTER_CLEAR:
        POP CX
        INC CX              ;increase row counter
        JMP START_CHECK_ROWS
    END_CHECK_ROWS:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
CHECK_ROWS  ENDP
;----------------------------------------------------------
;Before clearing, push CURR_POS block to the stack and pop
;   it after clearing row
;
; Arguments:
;   AX: row to clear
;
; ?????? implement for below logic ??????
;   for i in range(row, 1):
;       row(i) = row(i-1)
;   row(0) = OTHERS=>0
CLEAR_ROW   PROC     NEAR

        CALL PUSH_CURR_POS
        ;save registers
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH AX             ;multiply AX by 24
        MOV BX, 2*COLOUMNS
        MUL BX
        MOV SI, OFFSET BLOCKS
        ADD SI, AX          ;set SI to the first element of the row
        POP AX
    START_CLEAR_ROW:
        MOV CX, COLOUMNS    ;CX=12
        CMP AX, 0
        JE  END_CLEAR_ROW 
    RIGHT_COLOUMN:
        CMP CX, 0
        JE  UP_ROW
        MOV BX, [SI-2*COLOUMNS]     ;move [SI-24] to [SI]
        MOV [SI], BX
        ADD SI, 2           ;move SI to the next element in the row
        DEC CX              ;decreament coloumn counter
        JMP RIGHT_COLOUMN
    UP_ROW:
        SUB SI, 2*2*COLOUMNS          ;2*(2*12)
        DEC AX              ;decreament row counter
        JMP START_CLEAR_ROW
    END_CLEAR_ROW:
        MOV SI, OFFSET BLOCKS
        MOV CX, COLOUMNS    ;CX=12
    WHILE_FIRST_ROW:
        CMP CX, 0
        JE  END_WHILE_FIRST_ROW
        MOV [SI], 0
        ADD SI, 2           ;move SI to the next element in the row
        DEC CX              ;decreament coloumn counter
        JMP WHILE_FIRST_ROW
    END_WHILE_FIRST_ROW:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        CALL POP_CURR_POS
        RET

CLEAR_ROW   ENDP
;----------------------------------------------------------
; Arguments:
;   NONE
;
; ?????? implement below logic ??????
;   for row in BLOCKS:              #to avoid infinite loop and simplicity in clearing zero lines at the bottom of blocks
;       for row in BLOCKS:
;           if all_elements_one(i)==1:
;               clear_row(i)
CLEAR_EMPTY_ROWS  PROC     NEAR

        ;save registers
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        MOV CX, 0           ;set CX as a row counter -> first loop
    FIRST_CLEAR_EMPTY_ROWS:
        CMP CX, ROWS
        JE  LAST_CLEAR_EMPTY_ROWS
        PUSH CX
        MOV CX, 0           ;set CX as a row counter -> second loop
        MOV SI, OFFSET BLOCKS
    START_CLEAR_EMPTY_ROWS:
        CMP CX, ROWS
        JE  END_CLEAR_EMPTY_ROWS
        PUSH CX             ;save row counter on stack
        MOV CX, COLOUMNS    ;set CX as a coloumn counter
        MOV AX, 0           ;set AX=0 to use as a flag
    START_CLEAR_EMPTY_ROW:
        CMP CX, 0
        JE  END_CLEAR_EMPTY_ROW
        MOV BX, [SI]
        OR  AX, BX          ;check if all elements in a row are equal to 0
        DEC CX              ;decrease coloumn counter
        ADD SI, 2           ;move SI to the next element in the row
        JMP START_CLEAR_EMPTY_ROW
    END_CLEAR_EMPTY_ROW:
        CMP AL, 0
        JNE AFTER_CLEAR_EMPTY
        POP CX              ;pop CX to become row counter to pass
        MOV AX, CX          ;as AX for CLEAR_ROW
        CALL CLEAR_ROW
        PUSH CX
    AFTER_CLEAR_EMPTY:
        POP CX
        INC CX              ;increase row counter
        JMP START_CLEAR_EMPTY_ROWS
    END_CLEAR_EMPTY_ROWS:
        POP CX
        INC CX
        JMP FIRST_CLEAR_EMPTY_ROWS
    LAST_CLEAR_EMPTY_ROWS:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET

CLEAR_EMPTY_ROWS  ENDP
;----------------------------------------------------------
MOV_DOWN_F  PROC  NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;
    MOV_DOWN_AGAIN:
        CALL MOV_DOWN
        CMP MOV_DOWN_STATUS, 1
        JNZ MOV_DOWN_AGAIN
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
MOV_DOWN_F  ENDP
;----------------------------------------------------------
; to check if BLOCKS[i, j] is 1:
;   [SI] + 24*i + 2*j
MOV_DOWN    PROC     NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;check if it is possible to move block down
        CMP CURR_TYPE, TYPE_1_1
            JE  CHECK_MOV_DOWN_TYPE_1_1
        CMP CURR_TYPE, TYPE_1_2
            JE  CHECK_MOV_DOWN_TYPE_1_2
        CMP CURR_TYPE, TYPE_2_1
            JE  CHECK_MOV_DOWN_TYPE_2_1
        CMP CURR_TYPE, TYPE_3_1
            JE  CHECK_MOV_DOWN_TYPE_3_1
        CMP CURR_TYPE, TYPE_3_2
            JE  CHECK_MOV_DOWN_TYPE_3_2
        CMP CURR_TYPE, TYPE_3_3
            JE  CHECK_MOV_DOWN_TYPE_3_3
        CMP CURR_TYPE, TYPE_3_4
            JE  CHECK_MOV_DOWN_TYPE_3_4
        CMP CURR_TYPE, TYPE_4_1
            JE  CHECK_MOV_DOWN_TYPE_4_1
        CMP CURR_TYPE, TYPE_4_2
            JE  CHECK_MOV_DOWN_TYPE_4_2
        CMP CURR_TYPE, TYPE_5_1
            JE  CHECK_MOV_DOWN_TYPE_5_1
        CMP CURR_TYPE, TYPE_5_2
            JE  CHECK_MOV_DOWN_TYPE_5_2
        CMP CURR_TYPE, TYPE_5_3
            JE  CHECK_MOV_DOWN_TYPE_5_3
        CMP CURR_TYPE, TYPE_5_4
            JE  CHECK_MOV_DOWN_TYPE_5_4

    CHECK_MOV_DOWN_TYPE_1_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN


    CHECK_MOV_DOWN_TYPE_1_2:
        MOV SI, OFFSET CURR_POS ;first block position
        ADD SI, 6               ;last block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access last block position
        ADD SI, COLOUMNS2       ;access block under the last block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_2_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_3_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_3_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-2          ;anort if is in the last row 
        JGE ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the
        ADD SI, COLOUMNS2       ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_3_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the
        SUB SI, 2*COLOUMNS2     ;  fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_3_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN

    CHECK_MOV_DOWN_TYPE_4_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-3          ;anort if is in the last row 
        JGE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2*COLOUMNS2     ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the
        ADD SI, COLOUMNS2       ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_4_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-2          ;anort if is in the last row 
        JGE ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the
        ADD SI, COLOUMNS2       ; third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_5_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-2          ;anort if is in the last row
        JGE ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the
        ADD SI, COLOUMNS2       ; third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the
        SUB SI, COLOUMNS2       ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_5_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the
        SUB SI, COLOUMNS2       ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    CHECK_MOV_DOWN_TYPE_5_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        SUB SI, 2               ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN

    CHECK_MOV_DOWN_TYPE_5_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_DOWN
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        ADD SI, 2               ;access block under the
        SUB SI, COLOUMNS2       ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_DOWN
        JMP DO_MOV_DOWN

    ; move down all of the current positions
    ; for house in CURR_POS:
    ;   BLOCKS[house.y-1, house.x] = BLOCKS[house.y, house.x]
    DO_MOV_DOWN:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV CX, 4               ;CX is a house in block counter
    DO_MOV_DOWN_LOOP:
        CMP CX, 0
        JE  END_MOV_DOWN
        PUSH SI                 ;save SI as a current CURR_POS
        MOV BX, [SI]            ;BH -> i and BL -> j
        PUSH BX                 ;update CURR_POS values
        INC BH
        MOV [SI], BX
        POP BX
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        MOV BX, [SI]            ;move BLOCKS[house.y, house.x]
        DEC BL                  ;   (but before it, we decrease number
        MOV [SI], BL            ;    of the current house)
        MOV [SI+COLOUMNS2+1], BH  ; to BLOCKS[house.y-1, house.x]
        MOV BL, [SI+COLOUMNS2]  ; and increase BLOCKS[house.y, house.x+1] number
        INC BL                  ; of the current houses
        MOV [SI+COLOUMNS2], BL
        DEC CX
        POP SI
        ADD SI, 2
        JMP DO_MOV_DOWN_LOOP

    ABORT_CHECK_DOWN:
        MOV MOV_DOWN_STATUS, 1  ;use for clicking 'f'
        CALL INIT_BLOCK
        CALL PRINT_NEXT_BLOCKS
        CALL CHECK_ROWS
        CALL CLEAR_EMPTY_ROWS

    END_MOV_DOWN:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
MOV_DOWN    ENDP
;----------------------------------------------------------
; to check if BLOCKS[i, j] is 1:
;   [SI] + 24*i + 2*j
MOV_LEFT    PROC     NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;check if it is possible to move block left
        CMP CURR_TYPE, TYPE_1_1
            JE  CHECK_MOV_LEFT_TYPE_1_1
        CMP CURR_TYPE, TYPE_1_2
            JE  CHECK_MOV_LEFT_TYPE_1_2
        CMP CURR_TYPE, TYPE_2_1
            JE  CHECK_MOV_LEFT_TYPE_2_1
        CMP CURR_TYPE, TYPE_3_1
            JE  CHECK_MOV_LEFT_TYPE_3_1
        CMP CURR_TYPE, TYPE_3_2
            JE  CHECK_MOV_LEFT_TYPE_3_2
        CMP CURR_TYPE, TYPE_3_3
            JE  CHECK_MOV_LEFT_TYPE_3_3
        CMP CURR_TYPE, TYPE_3_4
            JE  CHECK_MOV_LEFT_TYPE_3_4
        CMP CURR_TYPE, TYPE_4_1
            JE  CHECK_MOV_LEFT_TYPE_4_1
        CMP CURR_TYPE, TYPE_4_2
            JE  CHECK_MOV_LEFT_TYPE_4_2
        CMP CURR_TYPE, TYPE_5_1
            JE  CHECK_MOV_LEFT_TYPE_5_1
        CMP CURR_TYPE, TYPE_5_2
            JE  CHECK_MOV_LEFT_TYPE_5_2
        CMP CURR_TYPE, TYPE_5_3
            JE  CHECK_MOV_LEFT_TYPE_5_3
        CMP CURR_TYPE, TYPE_5_4
            JE  CHECK_MOV_LEFT_TYPE_5_4

    CHECK_MOV_LEFT_TYPE_1_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn 
        JLE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, -2              ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT


    CHECK_MOV_LEFT_TYPE_1_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn 
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_2_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn 
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_3_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_3_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_3_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+6]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2+2     ;access block left to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_3_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        SUB SI, COLOUMNS2       ;access block left to the
        ADD SI, 4               ; fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_4_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to
        ADD SI, 2               ; the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_4_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+6]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        SUB SI, COLOUMNS2       ;access block left to
        ADD SI, 2               ; the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_5_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, COLOUMNS2       ;access block left to
        ADD SI, 2               ; the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_5_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+6]          ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, -COLOUMNS2+2    ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        ADD SI, 2*COLOUMNS2     ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_5_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j (third block position)
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        SUB SI, COLOUMNS2       ;access block left
        ADD SI, 2               ; to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    CHECK_MOV_LEFT_TYPE_5_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;abort if is in the first coloumn
        JE  ABORT_CHECK_LEFT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        SUB SI, COLOUMNS2       ;access block left to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        SUB SI, COLOUMNS2       ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_LEFT
        JMP DO_MOV_LEFT

    ; move down all of the current positions
    ; for house in CURR_POS:
    ;   BLOCKS[house.y, house.x-1] = BLOCKS[house.y, house.x]
    DO_MOV_LEFT:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV CX, 4               ;CX is a house in block counter
    DO_MOV_LEFT_LOOP:
        CMP CX, 0
        JE  END_MOV_LEFT
        PUSH SI                 ;save SI as a current CURR_POS
        MOV BX, [SI]            ;BH -> i and BL -> j
        PUSH BX                 ;update CURR_POS values
        DEC BL
        MOV [SI], BX
        POP BX
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        MOV BX, [SI]            ;move BLOCKS[house.y, house.x]
        DEC BL                  ;   (but before it, we decrease number
        MOV [SI], BL            ;    of the current house)
        MOV [SI-1], BH          ; to BLOCKS[house.y, house.x-1]
        MOV BL, [SI-2]          ; and increase BLOCKS[house.y, house.x+1] number
        INC BL                  ; of the current houses
        MOV [SI-2], BL
        DEC CX
        POP SI
        ADD SI, 2
        JMP DO_MOV_LEFT_LOOP

    ABORT_CHECK_LEFT:
        ;TODO

    END_MOV_LEFT:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
MOV_LEFT    ENDP
;----------------------------------------------------------
; to check if BLOCKS[i, j] is 1:
;   [SI] + 24*i + 2*j
MOV_RIGHT   PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;check if it is possible to move block right
        CMP CURR_TYPE, TYPE_1_1
            JE  CHECK_MOV_RIGHT_TYPE_1_1
        CMP CURR_TYPE, TYPE_1_2
            JE  CHECK_MOV_RIGHT_TYPE_1_2
        CMP CURR_TYPE, TYPE_2_1
            JE  CHECK_MOV_RIGHT_TYPE_2_1
        CMP CURR_TYPE, TYPE_3_1
            JE  CHECK_MOV_RIGHT_TYPE_3_1
        CMP CURR_TYPE, TYPE_3_2
            JE  CHECK_MOV_RIGHT_TYPE_3_2
        CMP CURR_TYPE, TYPE_3_3
            JE  CHECK_MOV_RIGHT_TYPE_3_3
        CMP CURR_TYPE, TYPE_3_4
            JE  CHECK_MOV_RIGHT_TYPE_3_4
        CMP CURR_TYPE, TYPE_4_1
            JE  CHECK_MOV_RIGHT_TYPE_4_1
        CMP CURR_TYPE, TYPE_4_2
            JE  CHECK_MOV_RIGHT_TYPE_4_2
        CMP CURR_TYPE, TYPE_5_1
            JE  CHECK_MOV_RIGHT_TYPE_5_1
        CMP CURR_TYPE, TYPE_5_2
            JE  CHECK_MOV_RIGHT_TYPE_5_2
        CMP CURR_TYPE, TYPE_5_3
            JE  CHECK_MOV_RIGHT_TYPE_5_3
        CMP CURR_TYPE, TYPE_5_4
            JE  CHECK_MOV_RIGHT_TYPE_5_4

    CHECK_MOV_RIGHT_TYPE_1_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+6]          ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the last block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT


    CHECK_MOV_RIGHT_TYPE_1_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JE  ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_2_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+2]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JE  ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_3_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-2      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2+2     ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_3_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2-4       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_3_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        SUB SI, COLOUMNS2       ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        SUB SI, COLOUMNS2       ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_3_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-3      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 6               ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        SUB SI, COLOUMNS2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_4_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-2      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2+2     ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_4_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2-2     ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_5_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-3      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 6               ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2-2     ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_5_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, COLOUMNS2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_5_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, -COLOUMNS2-2       ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    CHECK_MOV_RIGHT_TYPE_5_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-2      ;abort if is in the last coloumn 
        JGE ABORT_CHECK_RIGHT
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, 2               ;access block right to the first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, -COLOUMNS2+2    ;access block right to the fourth block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        ADD SI, -COLOUMNS2-2    ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_RIGHT
        JMP DO_MOV_RIGHT

    ; move down all of the current positions
    ; for house in CURR_POS:
    ;   BLOCKS[house.y, house.x+1] = BLOCKS[house.y, house.x]
    ;
    ; prevent block self-destruction bug by this new idea:
    ;   when shift block to right, we do not change 1 to 0 or 0 to 1. but we
    ;   increase and decrease so that we can manage moving blocks in any direction.
    ;       (we can have number 2 addition to the 0 and 1 that shows we have 
    ;        overlapping houses of a block)
    ;
    DO_MOV_RIGHT:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV CX, 4               ;CX is a house in block counter
    DO_MOV_RIGHT_LOOP:
        CMP CX, 0
        JE  END_MOV_RIGHT
        PUSH SI                 ;save SI as a current CURR_POS
        MOV BX, [SI]            ;BH -> i and BL -> j
        PUSH BX                 ;update CURR_POS values
        INC BL
        MOV [SI], BX
        POP BX
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        MOV BX, [SI]            ;move color of BLOCKS[house.y, house.x]
        DEC BL                  ;   (but before it, we decrease number
        MOV [SI], BL            ;    of the current house)
        MOV [SI+3], BH          ; to BLOCKS[house.y, house.x+1]
        MOV BL, [SI+2]          ; and increase BLOCKS[house.y, house.x+1] number
        INC BL                  ; of the current houses
        MOV [SI+2], BL
        DEC CX
        POP SI
        ADD SI, 2
        JMP DO_MOV_RIGHT_LOOP

    ABORT_CHECK_RIGHT:
        ;TODO

    END_MOV_RIGHT:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
MOV_RIGHT    ENDP
;----------------------------------------------------------
; Rotate blocks clockwise
;
ROTATE      PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;check if it is possible to move block down
        CMP CURR_TYPE, TYPE_1_1
            JE  CHECK_ROTATE_TYPE_1_1
        CMP CURR_TYPE, TYPE_1_2
            JE  CHECK_ROTATE_TYPE_1_2
        CMP CURR_TYPE, TYPE_2_1
            JE  CHECK_ROTATE_TYPE_2_1
        CMP CURR_TYPE, TYPE_3_1
            JE  CHECK_ROTATE_TYPE_3_1
        CMP CURR_TYPE, TYPE_3_2
            JE  CHECK_ROTATE_TYPE_3_2
        CMP CURR_TYPE, TYPE_3_3
            JE  CHECK_ROTATE_TYPE_3_3
        CMP CURR_TYPE, TYPE_3_4
            JE  CHECK_ROTATE_TYPE_3_4
        CMP CURR_TYPE, TYPE_4_1
            JE  CHECK_ROTATE_TYPE_4_1
        CMP CURR_TYPE, TYPE_4_2
            JE  CHECK_ROTATE_TYPE_4_2
        CMP CURR_TYPE, TYPE_5_1
            JE  CHECK_ROTATE_TYPE_5_1
        CMP CURR_TYPE, TYPE_5_2
            JE  CHECK_ROTATE_TYPE_5_2
        CMP CURR_TYPE, TYPE_5_3
            JE  CHECK_ROTATE_TYPE_5_3
        CMP CURR_TYPE, TYPE_5_4
            JE  CHECK_ROTATE_TYPE_5_4

    CHECK_ROTATE_TYPE_1_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;abort if is in the last rows 
        JE  ABORT_CHECK_ROTATE
        CMP BH, 1
        JLE ABORT_CHECK_ROTATE  ;abort if is in the two first rows
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, -2*COLOUMNS2+4    ;access block 2*above the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, COLOUMNS2       ;access block above the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, COLOUMNS2*2     ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_1_1


    CHECK_ROTATE_TYPE_1_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP AL, 2
        JL  ABORT_CHECK_ROTATE
        CMP AL, COLOUMNS-1
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 4               ;access block left*2 the third block position
        ADD SI, COLOUMNS2*2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 2               ;access block left the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 4               ;access block right the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_1_2

    CHECK_ROTATE_TYPE_2_1:
        ;do nothing
        JMP END_ROTATE

    CHECK_ROTATE_TYPE_3_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 1               ;abort if is in the first coloumn 
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the second block position
        ADD SI, COLOUMNS2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, COLOUMNS2       ;access block left to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 4               ;access block right to the second block position
        SUB SI, COLOUMNS2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_3_1

    CHECK_ROTATE_TYPE_3_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, 1
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the second block position
        SUB SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        SUB SI, COLOUMNS2*2     ;access block above the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        SUB SI, 2               ;access block above the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_3_2

    CHECK_ROTATE_TYPE_3_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;anort if is in the last coloumn 
        JE  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, 2               ;access block left to the second block position
        SUB SI, COLOUMNS
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 4               ;access block right to the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        SUB SI, COLOUMNS2       ;access block right to the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_3_3

    CHECK_ROTATE_TYPE_3_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, COLOUMNS2       ;access block above the second block position
        ADD SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, COLOUMNS2*2     ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 2               ;access block under the third block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_3_4

    CHECK_ROTATE_TYPE_4_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 0               ;anort if is in the first coloumn 
        JE  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2*2     ;access block under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        SUB SI, 2               ;access block left and under the second block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_4_1

    CHECK_ROTATE_TYPE_4_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, 1
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, COLOUMNS2       ;access block above the second block position
        SUB SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        ADD SI, 2               ;access block under the
        ADD SI, COLOUMNS2*2     ; first block position
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_4_2

    CHECK_ROTATE_TYPE_5_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, 1
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, COLOUMNS2       ;access block above the second block position
        ADD SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_5_1

    CHECK_ROTATE_TYPE_5_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, COLOUMNS-1      ;abort if is in the last coloumn 
        JE  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block right to the second block position
        ADD SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_5_2

    CHECK_ROTATE_TYPE_5_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BH, ROWS-1          ;anort if is in the last row 
        JE  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        ADD SI, COLOUMNS2       ;access block under the second block position
        SUB SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_5_3

    CHECK_ROTATE_TYPE_5_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        CMP BL, 1               ;abort if is in the last row 
        JL  ABORT_CHECK_ROTATE
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        SUB SI, COLOUMNS2       ;access block left to the second block position
        SUB SI, 2
        MOV AX, [SI]
        CMP AL, 1
        JE  ABORT_CHECK_ROTATE
        JMP DO_ROTATE_TYPE_5_4

    ; DO_ROTATES

    DO_ROTATE_TYPE_1_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 4
        SUB SI, 2*COLOUMNS2
        MOV [SI], AX
        POP SI
        ADD SI, 2
        PUSH SI                 ;save second element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2
        SUB SI, COLOUMNS2
        MOV [SI], AX
        POP SI
        ADD SI, 4
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        SUB SI, 2
        ADD SI, COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI], 2             ;First element  j
        ADD [SI+1], -2          ;First element  i
        ADD [SI+2], 1           ;Second element j
        ADD [SI+3], -1          ;Second element i
        ADD [SI+4], 0           ;Third element  j
        ADD [SI+5], 0           ;Third element  i
        ADD [SI+6], -1          ;Fourth element j
        ADD [SI+7], 1           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_1_2
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_1_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2*COLOUMNS2-4
        MOV [SI], AX
        POP SI
        ADD SI, COLOUMNS2
        PUSH SI                 ;save second element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, COLOUMNS2-2
        MOV [SI], AX
        POP SI
        ADD SI, 2*COLOUMNS2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -COLOUMNS2+2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI], -2            ;First element  j
        ADD [SI+1], 2           ;First element  i
        ADD [SI+2], -1          ;Second element j
        ADD [SI+3], 1           ;Second element i
        ADD [SI+4], 0           ;Third element  j
        ADD [SI+5], 0           ;Third element  i
        ADD [SI+6], 1           ;Fourth element j
        ADD [SI+7], -1          ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_1_1
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_2_1:
        JMP END_ROTATE
    DO_ROTATE_TYPE_3_1:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, COLOUMNS2+2
        MOV [SI], AX
        POP SI
        ADD SI, 2*COLOUMNS2
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -COLOUMNS2-2
        MOV [SI], AX
        POP SI
        ADD SI, 2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -4
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], -1          ;Third element  j
        ADD [SI+5], -1          ;Third element  i
        ADD [SI+6], -2          ;Fourth element j
        ADD [SI+7], 0           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_3_2
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_3_2:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, COLOUMNS2-2
        MOV [SI], AX
        POP SI
        ADD SI, -4
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -COLOUMNS2+2
        MOV [SI], AX
        POP SI
        ADD SI, COLOUMNS2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -2*COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   -1          ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], 1           ;Third element  j
        ADD [SI+5], -1          ;Third element  i
        ADD [SI+6], 0           ;Fourth element j
        ADD [SI+7], -2          ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_3_3
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_3_3:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -COLOUMNS2-2
        MOV [SI], AX
        POP SI
        ADD SI, -2*COLOUMNS2
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, COLOUMNS2+2
        MOV [SI], AX
        POP SI
        ADD SI, -2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 4
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], 1           ;Third element  j
        ADD [SI+5], 1           ;Third element  i
        ADD [SI+6], 2           ;Fourth element j
        ADD [SI+7], 0           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_3_4
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_3_4:
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -COLOUMNS2+2
        MOV [SI], AX
        POP SI
        ADD SI, 4
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, COLOUMNS2-2
        MOV [SI], AX
        POP SI
        ADD SI, -COLOUMNS2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2*COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], -1          ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], -1          ;Third element  j
        ADD [SI+5], 1           ;Third element  i
        ADD [SI+6], 0           ;Fourth element j
        ADD [SI+7], -2          ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_3_1
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_4_1:
        ;move first block to the rotated_third pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2*COLOUMNS2
        MOV [SI], AX
        POP SI
        ADD SI, 2*COLOUMNS2+2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -4
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], -1          ;Third element  j
        ADD [SI+5], 1           ;Third element  i
        ADD [SI+6], -2          ;Fourth element j
        ADD [SI+7], 0           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_4_2
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_4_2:
        ;move third block to the rotated_first pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        XOR BX, BX              ;clear BX
        ADD SI, COLOUMNS2-2
        PUSH SI                 ;save first element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -2*COLOUMNS2
        MOV [SI], AX
        POP SI
        ADD SI, -2
        PUSH SI                 ;save fourth element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 4
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   -1          ;First element  j
        ADD [SI+1], -1          ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], 1           ;Third element  j
        ADD [SI+5], -1          ;Third element  i
        ADD [SI+6], 2           ;Fourth element j
        ADD [SI+7], 0           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_4_1
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_5_1:
        ;move third block to the rotated_first pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j    (third block position)
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access fourth block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -2-COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], -1          ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], -1          ;Third element  j
        ADD [SI+5], 1           ;Third element  i
        ADD [SI+6], -1          ;Fourth element j
        ADD [SI+7], -1          ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_5_2
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_5_2:
        ;move third block to the rotated_first pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j    (third block position)
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access third block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2-COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   1           ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], -1          ;Third element  j
        ADD [SI+5], -1          ;Third element  i
        ADD [SI+6], 1           ;Fourth element j
        ADD [SI+7], -1          ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_5_3
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_5_3:
        ;move third block to the rotated_first pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j    (third block position)
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access third block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, 2+COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   -1          ;First element  j
        ADD [SI+1], 1           ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], 1           ;Third element  j
        ADD [SI+5], -1          ;Third element  i
        ADD [SI+6], 1           ;Fourth element j
        ADD [SI+7], 1           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_5_4
        ;
        JMP END_ROTATE
    DO_ROTATE_TYPE_5_4:
        ;move third block to the rotated_first pos
        MOV SI, OFFSET CURR_POS ;first block position
        MOV BX, [SI+4]          ;BH -> i and BL -> j    (third block position)
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access third block position
        XOR BX, BX              ;clear BX
        PUSH SI                 ;save third element SI
        MOV AX, [SI]
        MOV [SI], BX            ;clear SI
        ADD SI, -2+COLOUMNS2
        MOV [SI], AX
        POP SI
        ;
        MOV SI, OFFSET CURR_POS
        ADD [SI],   -1          ;First element  j
        ADD [SI+1], -1          ;First element  i
        ADD [SI+2], 0           ;Second element j
        ADD [SI+3], 0           ;Second element i
        ADD [SI+4], 1           ;Third element  j
        ADD [SI+5], 1           ;Third element  i
        ADD [SI+6], -1          ;Fourth element j
        ADD [SI+7], 1           ;Fourth element i
        ;
        MOV CURR_TYPE, TYPE_5_1
        ;
        JMP END_ROTATE

    ABORT_CHECK_ROTATE:
        ;TODO
    END_ROTATE:
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET

ROTATE      ENDP
;----------------------------------------------------------
; Init new block and set current position, location
;   and block type.
;  Call this procedure when MOV_DOWN aborted.
;
;   (Comments are based on 12 coloumn)
;
INIT_BLOCK  PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ; Random Type - shift NEXT_TYPEs
        XOR AX, AX
        RAND 1, 6, AX
        MOV AH, AL
        MOV AL, 01
        MOV SI, OFFSET NEXT_TYPE
        MOV BX, [SI]
        MOV CURR_TYPE, BX               ;MOV CURR_TYPE, [SI]
        MOV BX, [SI+2]
        MOV [SI], BX
        MOV BX, [SI+4]
        MOV [SI+2], BX
        MOV [SI+4], AX
        ; Random Colour - shift NEXT_COLORs
        XOR AX, AX
        RAND 9, 16, AX
        MOV SI, OFFSET NEXT_COLOR
        MOV BL, [SI]                    ;MOV CURR_COLOR, [SI]
        MOV CURR_COLOR, BL
        MOV BL, [SI+1]
        MOV [SI], BL
        MOV BL, [SI+2]
        MOV [SI+1], BL
        MOV [SI+2], AL
        ; First position
        MOV AX, CURR_TYPE
        CMP AH, 1
            JE  INIT_POS_TYPE_1
        CMP AH, 2
            JE  INIT_POS_TYPE_2
        CMP AH, 3
            JE  INIT_POS_TYPE_3
        CMP AH, 4
            JE  INIT_POS_TYPE_4
        CMP AH, 5
            JE  INIT_POS_TYPE_5
    INIT_POS_TYPE_1:
        MOV SI, OFFSET CURR_POS
        MOV [SI],   COLOUMNS/2-2    ;0004h
        MOV [SI+1], 0  
        MOV [SI+2], COLOUMNS/2-1    ;0005h
        MOV [SI+3], 0
        MOV [SI+4], COLOUMNS/2      ;0006h
        MOV [SI+5], 0
        MOV [SI+6], COLOUMNS/2+1    ;0007h
        MOV [SI+7], 0
        ;
        XOR BX, BX
        MOV BH, CURR_COLOR
        MOV BL, 1
        MOV SI, OFFSET BLOCKS
        ; check end_game
        CMP [SI+COLOUMNS-4], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS+2], 1
        JE  STOP_GAME
        ;
        MOV [SI+COLOUMNS-4], BX     ;(COLOUMNS/2-2)*2 + 0
        MOV [SI+COLOUMNS-2], BX     ;(COLOUMNS/2-1)*2 + 0
        MOV [SI+COLOUMNS], BX       ;(COLOUMNS/2)*2   + 0
        MOV [SI+COLOUMNS+2], BX     ;(COLOUMNS/2+1)*2 + 0
        JMP END_INIT
    INIT_POS_TYPE_2:
        MOV SI, OFFSET CURR_POS
        MOV [SI],   COLOUMNS/2-1    ;0005h
        MOV [SI+1], 0  
        MOV [SI+2], COLOUMNS/2      ;0006h
        MOV [SI+3], 0
        MOV [SI+4], COLOUMNS/2-1    ;0105h
        MOV [SI+5], 1
        MOV [SI+6], COLOUMNS/2      ;0106h
        MOV [SI+7], 1
        ;
        XOR BX, BX
        MOV BH, CURR_COLOR
        MOV BL, 1
        MOV SI, OFFSET BLOCKS
        ; check end_game
        CMP [SI+COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS], 1
        JE  STOP_GAME
        ;
        MOV [SI+COLOUMNS-2], BX     ;(COLOUMNS/2-1)*2 + 0 * row
        MOV [SI+COLOUMNS], BX       ;(COLOUMNS/2)*2 + 0 * row
        MOV [SI+3*COLOUMNS-2], BX   ;(COLOUMNS/2-1)*2   + 1 * row
        MOV [SI+3*COLOUMNS], BX     ;(COLOUMNS/2)*2 + 1 * row
        JMP END_INIT
    INIT_POS_TYPE_3:
        MOV SI, OFFSET CURR_POS
        MOV [SI],   COLOUMNS/2-1    ;0005h
        MOV [SI+1], 0  
        MOV [SI+2], COLOUMNS/2-1    ;0105h
        MOV [SI+3], 1
        MOV [SI+4], COLOUMNS/2-1    ;0205h
        MOV [SI+5], 2
        MOV [SI+6], COLOUMNS/2      ;0206h
        MOV [SI+7], 2
        ;
        XOR BX, BX
        MOV BH, CURR_COLOR
        MOV BL, 1
        MOV SI, OFFSET BLOCKS
        ; check end_game
        CMP [SI+COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+5*COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+5*COLOUMNS], 1
        JE  STOP_GAME
        ;
        MOV [SI+COLOUMNS-2], BX     ;(COLOUMNS/2-1)*2 + 0 * row
        MOV [SI+3*COLOUMNS-2], BX   ;(COLOUMNS/2-1)*2 + 1 * row
        MOV [SI+5*COLOUMNS-2], BX   ;(COLOUMNS/2-1)*2 + 2 * row
        MOV [SI+5*COLOUMNS], BX     ;(COLOUMNS/2)*2   + 2 * row
        JMP END_INIT
    INIT_POS_TYPE_4:
        MOV SI, OFFSET CURR_POS
        MOV [SI],   COLOUMNS/2-1    ;0005h
        MOV [SI+1], 0  
        MOV [SI+2], COLOUMNS/2-1    ;0105h
        MOV [SI+3], 1
        MOV [SI+4], COLOUMNS/2      ;0106h
        MOV [SI+5], 1
        MOV [SI+6], COLOUMNS/2      ;0206h
        MOV [SI+7], 2
        ;
        XOR BX, BX
        MOV BH, CURR_COLOR
        MOV BL, 1
        MOV SI, OFFSET BLOCKS
        ; check end_game
        CMP [SI+COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS], 1
        JE  STOP_GAME
        CMP [SI+5*COLOUMNS], 1
        JE  STOP_GAME
        ;
        MOV [SI+COLOUMNS-2], BX     ;(COLOUMNS/2-1)*2 + 0 * row
        MOV [SI+3*COLOUMNS-2], BX   ;(COLOUMNS/2-1)*2 + 1 * row
        MOV [SI+3*COLOUMNS], BX     ;(COLOUMNS/2)*2   + 1 * row
        MOV [SI+5*COLOUMNS], BX     ;(COLOUMNS/2)*2   + 2 * row
        JMP END_INIT
    INIT_POS_TYPE_5:
        MOV SI, OFFSET CURR_POS
        MOV [SI],   COLOUMNS/2-1    ;0005h
        MOV [SI+1], 0  
        MOV [SI+2], COLOUMNS/2      ;0006h
        MOV [SI+3], 0
        MOV [SI+4], COLOUMNS/2+1    ;0007h
        MOV [SI+5], 0
        MOV [SI+6], COLOUMNS/2      ;0106h
        MOV [SI+7], 1
        ;
        XOR BX, BX
        MOV BH, CURR_COLOR
        MOV BL, 1
        MOV SI, OFFSET BLOCKS
        ; check end_game
        CMP [SI+COLOUMNS-2], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS], 1
        JE  STOP_GAME
        CMP [SI+COLOUMNS+2], 1
        JE  STOP_GAME
        CMP [SI+3*COLOUMNS], 1
        JE  STOP_GAME
        ;
        MOV [SI+COLOUMNS-2], BX     ;(COLOUMNS/2-1)*2 + 0 * row
        MOV [SI+COLOUMNS], BX       ;(COLOUMNS/2)*2   + 0 * row
        MOV [SI+COLOUMNS+2], BX     ;(COLOUMNS/2+1)*2 + 0 * row
        MOV [SI+3*COLOUMNS], BX     ;(COLOUMNS/2)*2   + 1 * row
        JMP END_INIT

    END_GAME:
        JMP STOP_GAME
    END_INIT:
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
INIT_BLOCK  ENDP
;----------------------------------------------------------
FIRST_INIT  PROC    NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ; Random Type - shift NEXT_TYPEs
        XOR AX, AX
        RAND 1, 6, AX
        MOV AH, AL
        MOV AL, 01
        MOV SI, OFFSET NEXT_TYPE
        MOV [SI], AX
        ; === wait a few moments here:
        ; get number of clock ticks
        ; (about 18 per second)
        ; since midnight into cx:dx
    WAIT_LOOP1:
        MOV AH, 00h
        INT 1Ah
        CMP DX, WAIT_TIME
        JB  WAIT_LOOP1
        ADD DX, 3
        MOV WAIT_TIME, DX
        RAND 1, 6, AX
        MOV AH, AL
        MOV AL, 01
        MOV [SI+2], AX
        ; === wait a few moments here:
        ; get number of clock ticks
        ; (about 18 per second)
        ; since midnight into cx:dx
    WAIT_LOOP2:
        MOV AH, 00h
        INT 1Ah
        CMP DX, WAIT_TIME
        JB  WAIT_LOOP2
        ADD DX, 3
        MOV WAIT_TIME, DX
        RAND 1, 6, AX
        MOV AH, AL
        MOV AL, 01
        MOV [SI+4], AX
        ; Random Colour - shift NEXT_COLORs
        XOR AX, AX
        ; === wait a few moments here:
        ; get number of clock ticks
        ; (about 18 per second)
        ; since midnight into cx:dx
    WAIT_LOOP3:
        MOV AH, 00h
        INT 1Ah
        CMP DX, WAIT_TIME
        JB  WAIT_LOOP3
        ADD DX, 3
        MOV WAIT_TIME, DX
        RAND 9, 16, AX
        MOV SI, OFFSET NEXT_COLOR
        MOV [SI], AL
        ; === wait a few moments here:
        ; get number of clock ticks
        ; (about 18 per second)
        ; since midnight into cx:dx
    WAIT_LOOP4:
        MOV AH, 00h
        INT 1Ah
        CMP DX, WAIT_TIME
        JB  WAIT_LOOP4
        ADD DX, 3
        MOV WAIT_TIME, DX
        RAND 9, 16, AX
        MOV [SI+1], AL
        RAND 9, 16, AX
        MOV [SI+2], AL
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
FIRST_INIT  ENDP
;----------------------------------------------------------
;Vanish current block from map
;   Read-also: POP_CURR_POS
PUSH_CURR_POS   PROC    NEAR
        ;
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;
        MOV SI, OFFSET CURR_POS ;first block position
        MOV CX, 4               ;CX is a house in block counter
    PUSH_CURR_POS_LOOP:
        CMP CX, 0
        JE  END_PUSH_CURR_POS
        PUSH SI                 ;save SI as a current CURR_POS
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        MOV AX, [SI]
        MOV [SI], 0000h         ;clear block in CURR_POS's map
        MOV SI, OFFSET CURR_POS_STACK
        ADD SI, CX              ;write it twice because it is stored in double word
        ADD SI, CX              ; like SI+2
        SUB SI, 2               ;offset because CX start from 4 and goes to 1
        MOV [SI], AX            ;push to CURR_POS_STACK
        DEC CX
        POP SI
        ADD SI, 2
        JMP PUSH_CURR_POS_LOOP
    END_PUSH_CURR_POS:
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
PUSH_CURR_POS   ENDP
;----------------------------------------------------------
;Retrieve current block from CURR_POS_STACK
;   Read-also: PUSH_CURR_POS
POP_CURR_POS   PROC    NEAR
        ;
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        ;
        MOV SI, OFFSET CURR_POS ;first block position
        MOV CX, 4               ;CX is a house in block counter
    POP_CURR_POS_LOOP:
        CMP CX, 0
        JE  END_POP_CURR_POS
        PUSH SI                 ;save SI as a current CURR_POS
        MOV BX, [SI]            ;BH -> i and BL -> j
        XOR AX, AX              ;clear AX
        MOV AL, COLOUMNS2       ;multiply i*24
        MUL BH
        ADD AL, BL              ;add j twice instead of multiplication
        ADD AL, BL              ;2*j
        MOV SI, OFFSET CURR_POS_STACK
        ADD SI, CX              ;write it twice because it is stored in double word
        ADD SI, CX              ; like SI+2
        SUB SI, 2               ;offset because CX start from 4 and goes to 1
        MOV BX, [SI]            ;pop from CURR_POS_STACK
        MOV SI, OFFSET BLOCKS   ;access blocks array
        ADD SI, AX              ;access first block position
        MOV [SI], BX
        DEC CX
        POP SI
        ADD SI, 2
        JMP POP_CURR_POS_LOOP
    END_POP_CURR_POS:
        ;
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
POP_CURR_POS   ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point