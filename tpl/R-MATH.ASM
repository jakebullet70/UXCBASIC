; R-MATH.ASM -- the runtime routines for *, / and MOD.

; A/Y = the WORD on the stack times A/Y, the low 16 bits. Pops the stack.
R_MULW  .block
        #tpl
        dex
        dex
        sta ZP_TMP              ; the right side, shifted out a bit at a time
        sty ZP_TMP+1
        stz ZP_PTR              ; the product
        stz ZP_PTR+1
loop    lda ZP_TMP
        ora ZP_TMP+1
        beq done                ; no bits left
        lsr ZP_TMP+1
        ror ZP_TMP
        bcc next
        clc
        lda ZP_PTR
        adc ESTK,x
        sta ZP_PTR
        lda ZP_PTR+1
        adc ESTK+1,x
        sta ZP_PTR+1
next    asl ESTK,x              ; the left side, doubled for each bit
        rol ESTK+1,x
        bra loop
done    lda ZP_PTR
        ldy ZP_PTR+1
        rts
        #endtpl
        .endblock

; A/Y = the WORD on the stack divided by A/Y, unsigned, and ZP_PTR = the remainder. Pops the
; stack. A divisor of 0 stops the program with ?DIVISION BY ZERO ERROR.
R_DIVW  .block
        #tpl
        dex
        dex
        sta ZP_TMP              ; the divisor
        sty ZP_TMP+1
        ora ZP_TMP+1
        bne ok
        #rec jmp, R_EDIVZ
ok      stz ZP_PTR              ; the remainder
        stz ZP_PTR+1
        ldy #16
loop    asl ESTK,x              ; the dividend turns into the quotient, a bit at a time
        rol ESTK+1,x
        rol ZP_PTR
        rol ZP_PTR+1
        bcs sub                 ; a 17th bit: the divisor surely goes in
        lda ZP_PTR
        cmp ZP_TMP
        lda ZP_PTR+1
        sbc ZP_TMP+1
        bcc next
sub     lda ZP_PTR              ; C is set on both ways in
        sbc ZP_TMP
        sta ZP_PTR
        lda ZP_PTR+1
        sbc ZP_TMP+1
        sta ZP_PTR+1
        inc ESTK,x              ; this quotient bit is 1
next    dey
        bne loop
        lda ESTK,x
        ldy ESTK+1,x
        rts
        #endtpl
        .endblock
