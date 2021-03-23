;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
TITLE   PROG6   (EXE)   PURPOSE: Tetris game
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
BLOCK   DW      ?, ?, ?     ;shows next blocks types
POS     DW      ?           ;show current block head position
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
        DW      ?, ?, ?, ?, ?, ?, ?, ?
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
        CALL PRINT_MAP
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
PRINT_MAP   PROC    NEAR
; ↓↓ implement below logic ↓↓
;   for i in 12:
;	    for j in 8:
;		    if(BLOCKS[i, j] != 0)
;			    print(i, j);

        MOV AX, 25
        MOV BX, 25
        JL  PRINT_BLOCK

PRINT_BLOCK:                ;print block(i, j) where AX->i and BX->j
        MOV CX, AX          ;start line coloumn = i
        MOV DX, BX          ;row = j
        MOV AX, 1919h       ;store 25 at AH and AL
        PUSH AX             ;push to use as a counter
NEXT_COLOUMN:
        MOV AH,0CH          ;AH=OCH FUNCTION TO SET A PIXEL
        MOV AL,12           ;PIXELS= LIGHT RED
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
        RET
NEXT_ROW:
        POP AX              ;reset coloumn counter to 25
        MOV AL, 25
        PUSH AX
        SUB CX, 25          ;reset line coloumn
        ADD DX, 1           ;go to next row
        JMP NEXT_COLOUMN

PRINT_MAP   ENDP
;----------------------------------------------------------
MOV_A  PROC     NEAR
        
MOV_A  ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point