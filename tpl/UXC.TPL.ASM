; UXC.TPL.ASM -- the template table of the UXCBASIC compiler.
;
; Built by tpl/MKTPL.PY with 64tass into UXC.TPL.BIN. MACROS.ASM describes the format.
; A record's id is its place in this file, so add new records at the end of a file, and
; rebuild the compiler after any change here.

        .cpu "65c02"
        .include "MACROS.ASM"
        .include "ZP.ASM"

        .text "UXT"
        .byte 1                 ; the format version
        .word tpl_count
        .word index

        .include "T-CORE.ASM"
        .include "T-PRINT.ASM"
        .include "R-PRINT.ASM"
        .include "SYS.ASM"
        .include "T-EXPR.ASM"
        .include "R-MATH.ASM"
        .include "R-ERROR.ASM"
        .include "T-FLOW.ASM"
        .include "T-ARRAY.ASM"
        .include "T-STRING.ASM"
        .include "R-STRING.ASM"
        .include "T-FILE.ASM"
        .include "R-FILE.ASM"

tpl_count = len(tpl_all)
index   .word tpl_all
