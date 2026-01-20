        ORG     0
        B       START

        ORG     0x18
        B       IRQHDL

        ORG     0x40

;========================
; START
;========================
START
        ; SVC stack
        MOV     SP, #0x10000

        ; IRQ stack (banked SP_irq)
        MRS     R0, CPSR
        BIC     R0, R0, #0x1F
        ORR     R0, R0, #0x12             ; IRQ mode
        ORR     R0, R0, #0x80             ; disable IRQ while setting SP_irq
        MSR     CPSR_all, R0
        MOV     SP, #0x0F000              ; SP_irq

        ; back to SVC
        MRS     R0, CPSR
        BIC     R0, R0, #0x1F
        ORR     R0, R0, #0x13             ; SVC mode
        ORR     R0, R0, #0x80
        MSR     CPSR_all, R0

        ; stop/clear RTC so it doesn't interfere before button
        BL      RTCOFF

        ; enable IRQ globally
        MRS     R0, CPSR
        BIC     R0, R0, #0x80
        MSR     CPSR_all, R0

        ; GPIO2 Port A DIR: bits 5..7 outputs
        LDR     R0, G2ADR
        MOV     R1, #0xE0
        STR     R1, [R0,#8]

        ; GPIO1 Port B DIR: bits 0..7 outputs
        LDR     R0, G1ADR
        MOV     R1, #0
        STR     R1, [R0,#12]

        ; init
        MOV     R1, #1
        STR     R1, STATE
        MOV     R1, #0
        STR     R1, RUNFG

        BL      ST1

MAIN
        ; wait until cycle not running
        LDR     R0, RUNFG
        CMP     R0, #0
        BNE     MAIN

        ; wait button press
        BL      BTNPRE

        ; start cycle: STATE=2 RUN=1
        MOV     R1, #2
        STR     R1, STATE
        MOV     R1, #1
        STR     R1, RUNFG

        BL      ST2
        BL      RTCARM                   ; schedule first 10s from NOW

        B       MAIN


;========================
; IRQ HANDLER
;========================
IRQHDL
        SUB     LR, LR, #4
        STMFD   SP!, {R0-R3,LR}

        ; clear RTC IRQ
        BL      RTCCLR

        ; if not running -> exit
        LDR     R0, RUNFG
        CMP     R0, #0
        BEQ     IRQEXIT

        ; STATE++
        LDR     R0, STATE
        ADD     R0, R0, #1

        ; if STATE==6 -> stop cycle, back to 1
        CMP     R0, #6
        BNE     NOTEND

        MOV     R0, #1
        STR     R0, STATE
        MOV     R1, #0
        STR     R1, RUNFG
        BL      RTCOFF
        BL      ST1
        B       IRQEXIT

NOTEND
        STR     R0, STATE

        ; call correct state routine
        CMP     R0, #2
        BNE     C3
        BL      ST2
        B       ARMNEXT

C3      CMP     R0, #3
        BNE     C4
        BL      ST3
        B       ARMNEXT

C4      CMP     R0, #4
        BNE     C5
        BL      ST4
        B       ARMNEXT

C5      CMP     R0, #5
        BNE     ARMNEXT
        BL      ST5

ARMNEXT
        ; arm next 10s from NOW
        BL      RTCARM

IRQEXIT
        LDMFD   SP!, {R0-R3,LR}
        SUBS    PC, LR, #0                ; return from IRQ


;========================
; BUTTON wait press (bit0=1)
;========================
BTNPRE
        STMFD   SP!, {R0,R1,LR}
BWAIT
        LDR     R0, G2ADR
        LDR     R1, [R0,#0]
        AND     R1, R1, #1
        CMP     R1, #1
        BNE     BWAIT
        LDMFD   SP!, {R0,R1,LR}
        MOV     PC, LR


;========================
; LEDSET (Port A DATA)
;========================
LEDSET
        STMFD   SP!, {R0,LR}
        LDR     R0, G2ADR
        STR     R1, [R0,#0]
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR


;========================
; LCD PUT8
; R0 = pointer to 8 bytes (ASCII) in memory
;========================
PUT8
        STMFD   SP!, {R1,R2,R3,LR}
        MOV     R2, R0
        MOV     R3, #8
P8NX
        LDRB    R1, [R2]
        MOV     R0, R1
        BL      LCDWR
        ADD     R2, R2, #1
        SUBS    R3, R3, #1
        BNE     P8NX
        LDMFD   SP!, {R1,R2,R3,LR}
        MOV     PC, LR


;========================
; LCDWR
; GPIO1 Port B DATA = +4, WR is bit7
; input: R0 = ASCII char
;========================
LCDWR
        STMFD   SP!, {R1,LR}
        LDR     R1, G1ADR

        AND     R0, R0, #0x7F
        STR     R0, [R1, #4]
        ORR     R0, R0, #0x80
        STR     R0, [R1, #4]
        BIC     R0, R0, #0x80
        STR     R0, [R1, #4]

        LDMFD   SP!, {R1,LR}
        MOV     PC, LR


;========================
; STATES (LED patterns + LCD)
;========================
ST1
        STMFD   SP!, {R0,LR}
        MOV     R1, #0x00
        BL      LEDSET
        LDR     R0, PMS1
        BL      PUT8
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR

ST2
        STMFD   SP!, {R0,LR}
        MOV     R1, #0x20
        BL      LEDSET
        LDR     R0, PMS2
        BL      PUT8
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR

ST3
        STMFD   SP!, {R0,LR}
        MOV     R1, #0x40
        BL      LEDSET
        LDR     R0, PMS3
        BL      PUT8
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR

ST4
        STMFD   SP!, {R0,LR}
        MOV     R1, #0x80
        BL      LEDSET
        LDR     R0, PMS4
        BL      PUT8
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR

ST5
        STMFD   SP!, {R0,LR}
        MOV     R1, #0xE0
        BL      LEDSET
        LDR     R0, PMS5
        BL      PUT8
        LDMFD   SP!, {R0,LR}
        MOV     PC, LR


;========================
; RTCARM: MR = DR + 2650
;========================
RTCARM
        STMFD   SP!, {R0-R2,LR}
        LDR     R0, RTADR

        LDR     R1, [R0,#0]               ; DR (free-running)
        LDR     R2, T2650
        ADD     R1, R1, R2
        STR     R1, [R0,#4]               ; MR

        MOV     R1, #1
        STR     R1, [R0,#16]              ; ICR clear

        MOV     R1, #3
        STR     R1, [R0,#8]               ; CR enable+irq

        LDMFD   SP!, {R0-R2,LR}
        MOV     PC, LR

RTCCLR
        STMFD   SP!, {R0,R1,LR}
        LDR     R0, RTADR
        MOV     R1, #1
        STR     R1, [R0,#16]
        LDMFD   SP!, {R0,R1,LR}
        MOV     PC, LR

RTCOFF
        STMFD   SP!, {R0,R1,LR}
        LDR     R0, RTADR
        MOV     R1, #0
        STR     R1, [R0,#8]               ; CR off
        MOV     R1, #1
        STR     R1, [R0,#16]              ; clear pending
        LDMFD   SP!, {R0,R1,LR}
        MOV     PC, LR


;========================
; DATA (variables + pointers)
;========================
G2ADR   DW      0xFFFF0B00
G1ADR   DW      0xFFFF0F00
RTADR   DW      0xFFFF0E00
T2650   DW      2650

STATE   DW      1
RUNFG   DW      0

;========================
; LCD messages
;========================
        ORG     0x00000500
MS1     DW      0x434C4557,0x20454D4F     ; "WELC" "OME "
MS2     DW      0x54414548,0x20474E49     ; "HEAT" "ING "
MS3     DW      0x46464F43,0x20204545     ; "COFF" "EE  "
MS4     DW      0x4B4C494D,0x20202020     ; "MILK" "    "
MS5     DW      0x454E4F44,0x20202020     ; "DONE" "    "

PMS1    DW      0x00000500
PMS2    DW      0x00000508
PMS3    DW      0x00000510
PMS4    DW      0x00000518
PMS5    DW      0x00000520
