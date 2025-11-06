; R0 - result array
; R1 - result array address
; R9 - data array address
; R4 - data array end flag
; R5 - result array end flag

; R2 - operation
; R6 - 1st operand
; R7 - 2nd operand
; R8 - temporary result


START
        MOV R1, #0x2000         ; result array
        MOV R3, #0x600          ; termination flags
        MOV R9, #0x700          ; data array
        MOV SP, #0x10000        ; stack
        
        LDR R4, [R3], #4
        LDR R5, [R3], #4


LOOP
        LDR R2, [R9], #4        ; operation
        CMP R2, R4
        BEQ END                 ; check for termination flag

        LDR R6, [R9], #4        ; 1st operand
        LDR R7, [R9], #4        ; 2nd operand

        CMP R2, #0x0            ; addition
        ADDEQ R8, R6, R7
        STREQ R8, [R1], #4

        CMP R2, #0x1            ; subtraction
        SUBEQ R8, R6, R7
        STREQ R8, [R1], #4

        CMP R2, #0x2            ; multiplication
        MULEQ R8, R6, R7
        STREQ R8, [R1], #4

        CMP R2, #0x3            ; division
        STMEQFD SP!, {R6-R7}
        BLEQ DIVIDE

        CMP R2, #0x3
        ADDEQ SP, SP, #8
        STREQ R0, [R1], #4
        MOVEQ R0, #0

        BAL LOOP


DIVIDE
        STMFD SP!, {R1-R4}

        LDR R1, [SP, #16]       ; 1st operand
        LDR R2, [SP, #20]       ; 2nd operand

        CMP R1, #0              ; check if 1st operand is negative
        RSBMI R1, R1, #0
        MOVMI R3, #1
        MOVPL R3, #0

        CMP R2, #0              ; check if 2nd operand is negative
        MOVEQ R0, #0
        BEQ RETURN
        RSBMI R2, R2, #0
        MOVMI R4, #1
        MOVPL R4, #0
        
        EOR R3, R3, R4          ; check if the result will be negative


REC_SUB
        SUBS R1, R1, R2
        ADDGE R0, R0, #1
        BHI REC_SUB
        CMP R3, #1
        RSBEQ R0, R0, #0


RETURN
        LDMFD SP!, {R1-R4}
        MOV PC, LR
        

END
        ; store termination flag in the result array and quit
        STR R5, [R1]
        SWI 0x123456


        ; termination flags
        ORG 0x600
        DW 0x80808080
        DW 0xffffffff
        
        ; data array
        ORG 0x700
        DW 0x3, 0xfffffeff, 0x10
        DW 0x1, 0x1f4, 0xfffffd44
        DW 0x2, 0xfffffffe, 0xa
        DW 0x3, 0xfffff000, 0xffffffc0
        DW 0x80808080
        
        ; result array
        ORG 0x2000
        DS 20
