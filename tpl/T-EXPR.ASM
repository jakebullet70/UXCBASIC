; T-EXPR.ASM -- the operators.
;
; A binary operator is compiled as: the left side, then T_PUSH or T_PUSHB, then the right side,
; then the operator's template. The template pops the left side and leaves the result in A (a
; BYTE) or A/Y (a WORD). The B form works on two BYTEs; the W form on two WORDs, a BYTE side
; being widened first. *, / and MOD are always WORD.

; A = left + A
T_ADDB  .block
        #tpl
        dex
        dex
        clc
        adc ESTK,x
        #endtpl
        .endblock

; A/Y = left + A/Y
T_ADDW  .block
        #tpl
        dex
        dex
        clc
        adc ESTK,x
        pha
        tya
        adc ESTK+1,x
        tay
        pla
        #endtpl
        .endblock

; A = left - A, worked as left + ~A + 1
T_SUBB  .block
        #tpl
        dex
        dex
        eor #$ff
        sec
        adc ESTK,x
        #endtpl
        .endblock

; A/Y = left - A/Y
T_SUBW  .block
        #tpl
        dex
        dex
        eor #$ff
        sec
        adc ESTK,x
        pha
        tya
        eor #$ff
        adc ESTK+1,x
        tay
        pla
        #endtpl
        .endblock

; A = left AND A
T_ANDB  .block
        #tpl
        dex
        dex
        and ESTK,x
        #endtpl
        .endblock

; A/Y = left AND A/Y
T_ANDW  .block
        #tpl
        dex
        dex
        and ESTK,x
        pha
        tya
        and ESTK+1,x
        tay
        pla
        #endtpl
        .endblock

; A = left OR A
T_ORB   .block
        #tpl
        dex
        dex
        ora ESTK,x
        #endtpl
        .endblock

; A/Y = left OR A/Y
T_ORW   .block
        #tpl
        dex
        dex
        ora ESTK,x
        pha
        tya
        ora ESTK+1,x
        tay
        pla
        #endtpl
        .endblock

; A = left XOR A
T_XORB  .block
        #tpl
        dex
        dex
        eor ESTK,x
        #endtpl
        .endblock

; A/Y = left XOR A/Y
T_XORW  .block
        #tpl
        dex
        dex
        eor ESTK,x
        pha
        tya
        eor ESTK+1,x
        tay
        pla
        #endtpl
        .endblock

; A = left << A
T_SHLB  .block
        #tpl
        dex
        dex
        tay
        beq done
loop    asl ESTK,x
        dey
        bne loop
done    lda ESTK,x
        #endtpl
        .endblock

; A/Y = left << A. Only the low byte of the count is used.
T_SHLW  .block
        #tpl
        dex
        dex
        tay
        beq done
loop    asl ESTK,x
        rol ESTK+1,x
        dey
        bne loop
done    lda ESTK,x
        ldy ESTK+1,x
        #endtpl
        .endblock

; A = left >> A
T_SHRB  .block
        #tpl
        dex
        dex
        tay
        beq done
loop    lsr ESTK,x
        dey
        bne loop
done    lda ESTK,x
        #endtpl
        .endblock

; A/Y = left >> A. Only the low byte of the count is used.
T_SHRW  .block
        #tpl
        dex
        dex
        tay
        beq done
loop    lsr ESTK+1,x
        ror ESTK,x
        dey
        bne loop
done    lda ESTK,x
        ldy ESTK+1,x
        #endtpl
        .endblock

; A/Y = left * A/Y
T_MUL   .block
        #tpl
        #rec jsr, R_MULW
        #endtpl
        .endblock

; A/Y = left / A/Y
T_DIV   .block
        #tpl
        #rec jsr, R_DIVW
        #endtpl
        .endblock

; A/Y = left MOD A/Y
T_MOD   .block
        #tpl
        #rec jsr, R_DIVW
        lda ZP_PTR
        ldy ZP_PTR+1
        #endtpl
        .endblock

; A = -A
T_NEGB  .block
        #tpl
        eor #$ff
        inc a
        #endtpl
        .endblock

; A/Y = -A/Y
T_NEGW  .block
        #tpl
        eor #$ff
        clc
        adc #1
        pha
        tya
        eor #$ff
        adc #0
        tay
        pla
        #endtpl
        .endblock

; A = NOT A: 1 when A is 0, else 0.
T_NOTB  .block
        #tpl
        cmp #1                  ; C = A is not 0
        lda #0
        rol a
        eor #1
        #endtpl
        .endblock

; A = NOT A/Y: 1 when A/Y is 0, else 0. The result is a BYTE.
T_NOTW  .block
        #tpl
        sty ZP_TMP
        ora ZP_TMP
        cmp #1
        lda #0
        rol a
        eor #1
        #endtpl
        .endblock

; The compares. A compare is a core, which sets a flag, then a tail, which turns the flag into
; a BYTE 0 or 1. IF and the loops follow the same cores with a branch instead of a tail.
;
;   op    BYTE               WORD
;   =     CMPB_RL, ZTRUE     CMPW_EQ, ZTRUE
;   <>    CMPB_RL, ZFALSE    CMPW_EQ, ZFALSE
;   >=    CMPB_LR, CTRUE     CMPW_LR, CTRUE
;   <     CMPB_LR, CFALSE    CMPW_LR, CFALSE
;   <=    CMPB_RL, CTRUE     CMPW_RL, CTRUE
;   >     CMPB_RL, CFALSE    CMPW_RL, CFALSE

; C = left >= A, Z = left = A
T_CMPB_LR .block
        #tpl
        dex
        dex
        eor #$ff
        sec
        adc ESTK,x
        #endtpl
        .endblock

; C = A >= left, Z = left = A
T_CMPB_RL .block
        #tpl
        dex
        dex
        cmp ESTK,x
        #endtpl
        .endblock

; C = left >= A/Y
T_CMPW_LR .block
        #tpl
        dex
        dex
        eor #$ff
        sec
        adc ESTK,x
        tya
        eor #$ff
        adc ESTK+1,x
        #endtpl
        .endblock

; C = A/Y >= left
T_CMPW_RL .block
        #tpl
        dex
        dex
        cmp ESTK,x
        tya
        sbc ESTK+1,x
        #endtpl
        .endblock

; Z = left = A/Y
T_CMPW_EQ .block
        #tpl
        dex
        dex
        cmp ESTK,x
        bne done
        tya
        cmp ESTK+1,x
done
        #endtpl
        .endblock

; A = C
T_CTRUE .block
        #tpl
        lda #0
        rol a
        #endtpl
        .endblock

; A = not C
T_CFALSE .block
        #tpl
        lda #0
        rol a
        eor #1
        #endtpl
        .endblock

; A = Z, which is bit 1 of P
T_ZTRUE .block
        #tpl
        php
        pla
        lsr a
        and #1
        #endtpl
        .endblock

; A = not Z
T_ZFALSE .block
        #tpl
        php
        pla
        lsr a
        and #1
        eor #1
        #endtpl
        .endblock
