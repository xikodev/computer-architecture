;===========================================================
; FRISC-V
; GPIO2 gate A: bit0=button, bit1=switch
; LCD on GPIO1 gate B (PB_DR at +4, WR strobe bit7)
;===========================================================

START
        ; stack
        lui     sp, %hi(0x10000)
        addi    sp, sp, %lo(0x10000)

        ; s0 = GPIO1 base (0xFFFF0F00)
        lui     s0, %hi(0xFFFF0F00)
        addi    s0, s0, %lo(0xFFFF0F00)

        ; s1 = GPIO2 base (0xFFFF0B00)
        lui     s1, %hi(0xFFFF0B00)
        addi    s1, s1, %lo(0xFFFF0B00)

        ;---------------------------
        ; GPIO2 gate A direction:
        ; bit0, bit1 are inputs
        ;---------------------------
        addi    t0, x0, 0x00
        sw      t0, 8(s1)          ; PA_DDR

        ;---------------------------
        ; GPIO1 gate B direction:
        ; bits 0..7 are outputs
        ;---------------------------
        addi    t0, x0, 0x00
        sw      t0, 12(s0)         ; PB_DDR

        ;---------------------------
        ; state in registers
        ; s2 = counter (0..12)
        ; s3 = prev button (0/1) for rising-edge detect
        ;---------------------------
        addi    s2, x0, 0
        addi    s3, x0, 0

MAIN
        lw      t0, 0(s1)          ; PA_DR

        ; switch = bit1
        andi    t1, t0, 0x2
        beq     t1, x0, SW_OPEN    ; if switch==0 => ignore counting

        ; button = bit0
        andi    t2, t0, 0x1
        beq     t2, x0, BTN_RELEASED

        ; button==1: count only on rising edge (prev==0)
        bne     s3, x0, BTN_HELD

        ; rising edge -> increment
        addi    s2, s2, 1

        ; wrap: if counter==13 -> counter=1
        addi    t3, x0, 13
        bne     s2, t3, DO_DISPLAY
        addi    s2, x0, 1

DO_DISPLAY
        ; required digit extraction routine
        addi    x17, s2, 0
        jal     ra, process        ; x10 tens ASCII, x11 units ASCII

        ; save digits because LCDWR clobbers a0
        addi    t5, x10, 0         ; tens
        addi    t6, x11, 0         ; units

        ; print: CR, (tens if not ' '), units, LF
        addi    a0, x0, 0x0D
        jal     ra, LCDWR

        addi    t4, x0, 0x20       ; ' '
        beq     t5, t4, PRINT_UNITS_ONLY
        addi    a0, t5, 0
        jal     ra, LCDWR

PRINT_UNITS_ONLY
        addi    a0, t6, 0
        jal     ra, LCDWR

        addi    a0, x0, 0x0A
        jal     ra, LCDWR

        ; prev button = 1
        addi    s3, x0, 1
        jal     x0, MAIN

BTN_HELD
        ; still holding button: keep prev=1, no recount
        addi    s3, x0, 1
        jal     x0, MAIN

BTN_RELEASED
        ; released: prev=0
        addi    s3, x0, 0
        jal     x0, MAIN

SW_OPEN
        ; switch open: ignore presses
        ; still track button state to avoid false edge when switch closes
        andi    t2, t0, 0x1
        beq     t2, x0, SW_BTN0
        addi    s3, x0, 1
        jal     x0, MAIN
SW_BTN0
        addi    s3, x0, 0
        jal     x0, MAIN


;===========================================================
; LCDWR
; input: a0 = ASCII char
; uses:  s0 = GPIO1 base
; PB_DR is at +4, strobe is bit7
;===========================================================
LCDWR
        andi    a0, a0, 0x7F
        sb      a0, 4(s0)
        ori     a0, a0, 0x80
        sb      a0, 4(s0)
        andi    a0, a0, 0x7F
        sb      a0, 4(s0)
        jalr    x0, 0(ra)


;===========================================================
; process
; input:  x17 = counter value (1..12)
; output: x10 = tens ASCII, x11 = units ASCII
; single-digit numbers: tens=' ' (space), units='1'..'9'
;===========================================================
process
        addi    t0, x0, 10
        blt     x17, t0, ONE_DIG

        ; 10..12 => tens='1', units=(x17-10)+'0'
        addi    x10, x0, 0x31      ; '1'
        addi    t1, x17, -10
        addi    x11, t1, 0x30
        jalr    x0, 0(ra)

ONE_DIG
        addi    x10, x0, 0x20      ; ' '
        addi    x11, x17, 0x30
        jalr    x0, 0(ra)
