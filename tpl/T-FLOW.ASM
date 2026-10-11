; T-FLOW.ASM -- jumps, branches, truth tests, compares that push nothing, and loop steps.
;
; IF and the loops are built from these small pieces; no template is a whole statement.
;
; A branch's offset is a constant slot. A backward branch to a target in range is a short
; branch; any other is the inverse branch over a JMP. A forward jump to a target not yet
; known is always the long form, and the JMP is patched when the target is reached.
;
; The compares here take the left side in A or A/Y and the right side as an operand, a
; constant or a variable, so nothing goes on the expression stack. Each sets the flags as
; the stack compares do: C = left >= right, Z = left = right. The tails in T-EXPR.ASM turn
; the flag into 0 or 1, or the compiler branches on it.

; JMP to the address S0: a label, code, or a link the compiler patches later.
T_JMP   .block
        #tpl
        #ab jmp, S0
        #endtpl
        .endblock

T_BRA   .block
        #tpl
        #rel bra, S0
        #endtpl
        .endblock

T_BEQ   .block
        #tpl
        #rel beq, S0
        #endtpl
        .endblock

T_BNE   .block
        #tpl
        #rel bne, S0
        #endtpl
        .endblock

T_BCC   .block
        #tpl
        #rel bcc, S0
        #endtpl
        .endblock

T_BCS   .block
        #tpl
        #rel bcs, S0
        #endtpl
        .endblock

; Z = the BYTE in A is 0
T_TSTB  .block
        #tpl
        cmp #0
        #endtpl
        .endblock

; Z = the WORD in A/Y is 0. A is lost.
T_TSTW  .block
        #tpl
        sty ZP_TMP
        ora ZP_TMP
        #endtpl
        .endblock

; Z = the WORD variable S0 is 0. A is lost.
T_TSTW_V .block
        #tpl
        #ab lda, S0
        #ab ora, S0, 1
        #endtpl
        .endblock

; C = A >= S0, Z = A = S0, for the BYTE constant S0
T_CMPB_C .block
        #tpl
        #lo cmp, S0
        #endtpl
        .endblock

; C = A >= S0, Z = A = S0, for the BYTE variable S0
T_CMPB_V .block
        #tpl
        #ab cmp, S0
        #endtpl
        .endblock

; C = A/Y >= S0, for the WORD constant S0. A is lost.
T_CMPW_C .block
        #tpl
        #lo cmp, S0
        tya
        #hi sbc, S0
        #endtpl
        .endblock

; C = A/Y >= S0, for the WORD variable S0. A is lost.
T_CMPW_V .block
        #tpl
        #ab cmp, S0
        tya
        #ab sbc, S0, 1
        #endtpl
        .endblock

; Z = A/Y = S0, for the WORD constant S0
T_CMPW_EQC .block
        #tpl
        #lo cmp, S0
        bne done
        #hi cpy, S0
done
        #endtpl
        .endblock

; Z = A/Y = S0, for the WORD variable S0
T_CMPW_EQV .block
        #tpl
        #ab cmp, S0
        bne done
        #ab cpy, S0, 1
done
        #endtpl
        .endblock

; The BYTE at S0 + 1. Z = the result is 0.
T_INCB_V .block
        #tpl
        #ab inc, S0
        #endtpl
        .endblock

; The BYTE at S0 - 1. Z = the result is 0.
T_DECB_V .block
        #tpl
        #ab dec, S0
        #endtpl
        .endblock

; The WORD variable S0 - 1. A is lost.
T_DECW_V .block
        #tpl
        #ab lda, S0
        bne skip
        #ab dec, S0, 1
skip
        #ab dec, S0
        #endtpl
        .endblock

; A = A + the BYTE constant S0. C = the add carried.
T_ADDB_C .block
        #tpl
        clc
        #lo adc, S0
        #endtpl
        .endblock

; A = A - the BYTE constant S0. C clear = the subtract borrowed.
T_SUBB_C .block
        #tpl
        sec
        #lo sbc, S0
        #endtpl
        .endblock

; A/Y = A/Y + the WORD constant S0. C = the add carried.
T_ADDW_C .block
        #tpl
        clc
        #lo adc, S0
        pha
        tya
        #hi adc, S0
        tay
        pla
        #endtpl
        .endblock

; A/Y = A/Y - the WORD constant S0. C clear = the subtract borrowed.
T_SUBW_C .block
        #tpl
        sec
        #lo sbc, S0
        pha
        tya
        #hi sbc, S0
        tay
        pla
        #endtpl
        .endblock

; REPEAT with a WORD count in A/Y: set the counter S0 so that END REPEAT can count it down a
; byte at a time, as DEC lo / BNE top / DEC hi / BNE top. The high byte is one more when the
; low byte is not 0. Z = the count was 0, and the body is skipped.
T_RPTW_SET .block
        #tpl
        #ab sta, S0
        cmp #1                  ; C = the low byte is not 0
        tya
        adc #0
        #ab sta, S0, 1
        #ab ora, S0
        #endtpl
        .endblock
