;THE FORM OF AN ASSEMBLY LANGUAGE PROGRAM 
; USING SIMPLIFIED SEGMENT DEFINITION
        .MODEL 64
        .STACK 64
;----------------------------------------------------------
        .DATA
        ORG     200H

        ;PPI ports
        PORT_A  EQU 00H
        PORT_B  EQU 02H
        PORT_C  EQU 04H
        PORT_CONFIG EQU 06H
        ;Timer ports
        POTR_COUNTER_0  EQU 10H
        POTR_COUNTER_1  EQU 12H
        POTR_COUNTER_2  EQU 14H
        PORT_CONTROL    EQU 16H
        ;Programmable interrupt ports
        PORT_ICW_1  EQU 20H
        PORT_ICW_2  EQU 22H
        PORT_OCW_1  EQU 22H
        PORT_OCW_2  EQU 20H

        MODE        DB  0H
        COUNTER     DB  0H
        ;LED values
        LED_VALUE_0 DB  0H
        LED_VALUE_1 DB  0H
        LED_VALUE_2 DB  0H
        LED_VALUE_3 DB  0H
;----------------------------------------------------------
        .CODE
        ORG     300H
MAIN    PROC    FAR
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        ;Config PPI
        MOV     AL, 10000010B
        MOV     DX, PORT_CONFIG
        OUT     DX, AL
        ;Config timer
        MOV     AL, 00010111B
        MOV     DX, PORT_CONTROL
        OUT     DX, AL
        MOV     AL, 01H
        OUT     POTR_COUNTER_0, AL
        ; Config Programmable interrupt chip (8259A)
        ; ICW1 for 8259A
        MOV     AL, 00010011B
        MOV     DX, PORT_ICW_1
        OUT     DX, AL
        ; ICW2 for 8259A
        MOV     AL, 40H
        MOV     DX, PORT_ICW_2
        OUT     DX, AL
        ; ICW4 for 8259A
        MOV     AL, 00000011B
        MOV     DX, PORT_ICW_2
        OUT     DX, AL
        ;Mask interrupt
        MOV     AL, 00000001B
        MOV     DX, PORT_OCW_1
        OUT     DX, AL
        ;
        ;Config interrupt 40H for handle interrupt of timer
        ;Location of interrupt 40H must be in 40H * 4 = 100H (256 decimal)
        MOV     AX, 0
        MOV     ES, AX
        CLI                 ;Disable interrupts, might not be needed if setting up a software
        MOV     AX, OFFSET INTR40
        MOV     ES:[256], AX
        MOV     ES:[258], CS    ;Segment of handler is current CS
        STI                 ;Re-enable interrupts
        ;
    MAIN_LOOP:
        ;Send led values to 7-segments
        ;first and second led
        MOV     AL, LED_VALUE_1
        SHL     CL, 4
        MOV     AL, CL
        ADD     AL, LED_VALUE_0
        MOV     DX, PORT_A
        OUT     DX, AL
        ;third and fourth led
        MOV     AL, LED_VALUE_3
        SHL     CL, 4
        MOV     AL, CL
        ADD     AL, LED_VALUE_2
        MOV     DX, PORT_B
        OUT     DX, AL
        ;
        JMP     MAIN_LOOP
        ;
        MOV     AH, 4CH     ;set up to
        INT     21H
MAIN    ENDP
;----------------------------------------------------------
; Interrupt of timer
INTR40  PROC    FAR
        PUSH    AX
        PUSH    DS
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        Mov AL,led_value
        cmp AL, 99
        je out_up_proc
        Add AL, 1
        Mov led_value, Al
	out_up_proc:
        ;
        PUSH    DS
        PUSH    AX
        STI
        IRET
INTR40  ENDP
;----------------------------------------------------------
; Interrupt of Din to Inrease counter
INTR40  PROC    FAR
        PUSH    AX
        PUSH    DS
        MOV     AX, @DATA   ;load the data segment address
        MOV     DS, AX      ;assign value to DS
        ;
        INC COUNTER
        ;
        PUSH    DS
        PUSH    AX
        STI
        IRET
INTR40  ENDP
;----------------------------------------------------------
        END MAIN            ;this is the program exit point