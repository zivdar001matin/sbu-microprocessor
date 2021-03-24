;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG6   (EXE)   PURPOSE: Tetris game
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
ROWS    EQU     8
COLOUMNS EQU     12
BLOCK_SIZE  EQU 25

BLOCK   DW      ?, ?, ?     ;shows next blocks types
POS     DW      ?           ;show current block head position
COLOR   DB      ?           ;show current block color
BLOCKS  DW      0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h, 0C01h
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h, 0201h
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        DW      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
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
        CALL CLEAR_ROW
        CALL PRINT_MAP
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
PRINT_MAP   PROC    NEAR
; ↓↓ implement below logic ↓↓
;   for i in 8:
;	    for j in 12:
;		    if(BLOCKS[i, j] != 0)
;			    print(i, j);

        MOV SI, OFFSET BLOCKS
        XOR BX, BX          ;clear BX
OUTER:
        XOR AX, AX          ;clear AX
INNER:
        MOV CX, [SI]
        MOV COLOR, CH
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
;       MOV AX, AX
        MOV CX, BLOCK_SIZE
        MUL CX
        MOV CX, AX          ;start line coloumn = i
        ;multiply j by 25
        MOV AX, BX
        MOV DX, BLOCK_SIZE
        MUL DX
        MOV DX, AX          ;row = j
        MOV AL, BLOCK_SIZE  ;store 25 at AL
        MOV AH, BLOCK_SIZE  ;store 25 at AH
        PUSH AX             ;push to use as a counter
NEXT_COLOUMN:
        MOV AH,0CH          ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL,COLOR        ;PIXELS= COLOR
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
CHECK_ROWS  PROC    NEAR
; ↓↓ implement below logic ↓↓
;   for row in BLOCKS:
;       if all_elements_one(row)==1:
;           clear_row(row)

CHECK_ROWS  ENDP
;----------------------------------------------------------
CLEAR_ROW   PROC     NEAR
; Arguments:
;   AX: row to clear
;
; ↓↓ implement for below logic ↓↓
;   for i in range(row, 1):
;       row(i) = row(i-1)
;   row(0) = OTHERS=>0

        ;save registers
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH AX             ;multiply AX by 24
        MOV BX, 24
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
        MOV BX, [SI-24]     ;move [SI-24] to [SI]
        MOV [SI], BX
        ADD SI, 2           ;move SI to the next element in the row
        DEC CX              ;decreament coloumn counter
        JMP RIGHT_COLOUMN
UP_ROW:
        SUB SI, 48          ;2*(2*12)
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
        POP DX
        POP CX
        POP BX
        POP AX
        RET

CLEAR_ROW   ENDP
;----------------------------------------------------------
MOV_A  PROC     NEAR
        
MOV_A  ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point