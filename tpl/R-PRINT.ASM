; R-PRINT.ASM -- the runtime routines for PRINT.

; Print the string at A/Y: [max][len][data].
R_PRSTR .block
        #tpl
        sta ZP_PTR
        sty ZP_PTR+1
        ldy #1
        lda (ZP_PTR),y
        beq done
        sta ZP_TMP              ; the length
        inc ZP_PTR              ; (ZP_PTR),y with y = 1 is the first character
        bne loop
        inc ZP_PTR+1
loop    lda (ZP_PTR),y
        #rec jsr, S_CHROUT      ; CHROUT keeps Y
        cpy ZP_TMP
        iny
        bcc loop
done    rts
        #endtpl
        .endblock

; Print the WORD in A/Y in decimal, as MS BASIC does: a space for the sign, the digits with
; no leading zeros, then a space. PRINT 1; 2 prints " 1  2 ".
R_PRWORD .block
        #tpl
        phx
        sta ZP_TMP
        sty ZP_TMP+1
        lda #" "                ; the sign: a WORD is never negative
        #rec jsr, S_CHROUT
        stz ZP_PTR              ; not 0 once a digit is printed
        ldx #0
digit   ldy #"0"
sub     lda ZP_TMP              ; count how many times the power of ten goes
        sec
        #selfx sbc, tens_lo
        pha
        lda ZP_TMP+1
        #selfx sbc, tens_hi
        bcc out
        sta ZP_TMP+1
        pla
        sta ZP_TMP
        iny
        bra sub
out     pla
        tya
        cmp #"0"
        bne show
        ldy ZP_PTR
        beq next                ; a leading zero
show    sta ZP_PTR
        #rec jsr, S_CHROUT
next    inx
        cpx #4
        bne digit
        lda ZP_TMP              ; the ones, always printed
        ora #"0"
        #rec jsr, S_CHROUT
        lda #" "
        plx
        #rec jmp, S_CHROUT
tens_lo .byte <10000, <1000, <100, <10
tens_hi .byte >10000, >1000, >100, >10
        #endtpl
        .endblock

; End the line.
R_PRNL  .block
        #tpl
        lda #13
        #rec jmp, S_CHROUT
        #endtpl
        .endblock

; Move to the next 14-column print zone, as MS BASIC does on an 80-column screen: the zones
; start at columns 0, 14, 28, 42 and 56. From column 56 on, end the line instead.
R_PRCOMMA .block
        #tpl
        phx
        sec
        #rec jsr, S_PLOT        ; Y = the cursor column
        cpy #56
        bcs newline
        tya
mod     sec                     ; A = the column mod 14, minus 14
        sbc #14
        bcs mod
        eor #$ff                ; = the spaces to print, minus 1
        tax
space   lda #" "
        #rec jsr, S_CHROUT      ; CHROUT keeps X
        dex
        bpl space
        plx
        rts
newline plx
        lda #13
        #rec jmp, S_CHROUT
        #endtpl
        .endblock

; Move the cursor to the column in A, on the same row.
R_POSSETCOL .block
        #tpl
        phx
        pha
        sec
        #rec jsr, S_PLOT        ; X = the row
        ply
        clc
        #rec jsr, S_PLOT
        plx
        rts
        #endtpl
        .endblock

; Move the cursor to the row in A, in the same column.
R_POSSETROW .block
        #tpl
        phx
        pha
        sec
        #rec jsr, S_PLOT        ; Y = the column
        plx
        clc
        #rec jsr, S_PLOT
        plx
        rts
        #endtpl
        .endblock
