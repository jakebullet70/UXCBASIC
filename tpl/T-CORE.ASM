; T-CORE.ASM -- start and end, loads, stores, the expression stack, POKE and PEEK.
;
; An expression's value is in A (a BYTE), or in A low and Y high (a WORD or an address).
; Assignment is a load then a store: N% = 5 is T_LDW_C then T_STW_V. POKE to a constant
; address is T_STB_V with the address as the slot.

; The BASIC line 10 SYS 2061, for a program at $0801.
T_STUB  .block
        #tpl
        .word $080b, 10
        .text $9e, "2061", 0
        .word 0
        #endtpl
        .endblock

; Startup: keep the stack pointer for END, switch the screen to CP437, and empty the
; expression stack.
T_START .block
        #tpl
        tsx
        stx ZP_SP
        #rec jsr, S_INIT
        ldx #0
        #endtpl
        .endblock

; END, from anywhere, even inside a SUB: back to BASIC.
T_END   .block
        #tpl
        #rec jmp, S_EXIT
        #endtpl
        .endblock

; A = the BYTE constant S0
T_LDB_C .block
        #tpl
        #lo lda, S0
        #endtpl
        .endblock

; A/Y = the WORD constant S0, or the address S0 (@name, a string)
T_LDW_C .block
        #tpl
        #lo lda, S0
        #hi ldy, S0
        #endtpl
        .endblock

; A = the BYTE variable S0
T_LDB_V .block
        #tpl
        #ab lda, S0
        #endtpl
        .endblock

; A/Y = the WORD variable S0
T_LDW_V .block
        #tpl
        #ab lda, S0
        #ab ldy, S0, 1
        #endtpl
        .endblock

; A/Y = the BYTE variable S0, made a WORD
T_LDW_B .block
        #tpl
        #ab lda, S0
        ldy #0
        #endtpl
        .endblock

; The BYTE in A made a WORD in A/Y
T_WIDEN .block
        #tpl
        ldy #0
        #endtpl
        .endblock

; The BYTE variable S0 = A. Also POKE to the constant address S0.
T_STB_V .block
        #tpl
        #ab sta, S0
        #endtpl
        .endblock

; The WORD variable S0 = A/Y
T_STW_V .block
        #tpl
        #ab sta, S0
        #ab sty, S0, 1
        #endtpl
        .endblock

; Push A/Y on the expression stack.
T_PUSH  .block
        #tpl
        sta ESTK,x
        sty ESTK+1,x
        inx
        inx
        #endtpl
        .endblock

; POKE: the address was pushed, the BYTE value is in A. Pops the address.
T_POKE  .block
        #tpl
        dex
        dex
        sta (ESTK,x)
        #endtpl
        .endblock

; PEEK: A = the byte at the address in A/Y. PEEK of a constant address is T_LDB_V.
T_PEEK  .block
        #tpl
        sta ZP_PTR
        sty ZP_PTR+1
        lda (ZP_PTR)
        #endtpl
        .endblock

; JSR to the address S0: a SUB.
T_JSR   .block
        #tpl
        #ab jsr, S0
        #endtpl
        .endblock

; Push the BYTE in A as a WORD. The left side of an operator is pushed before the right
; side's type is known, so a BYTE goes on the stack with a zero high byte.
T_PUSHB .block
        #tpl
        sta ESTK,x
        stz ESTK+1,x
        inx
        inx
        #endtpl
        .endblock

; Return from a SUB.
T_RTS   .block
        #tpl
        rts
        #endtpl
        .endblock

; Pop a word off the expression stack into the BYTE variable S0: its low byte.
T_POPB_V .block
        #tpl
        dex
        dex
        lda ESTK,x
        #ab sta, S0
        #endtpl
        .endblock

; Pop a word off the expression stack into the WORD variable S0.
T_POPW_V .block
        #tpl
        dex
        dex
        lda ESTK,x
        #ab sta, S0
        lda ESTK+1,x
        #ab sta, S0, 1
        #endtpl
        .endblock
