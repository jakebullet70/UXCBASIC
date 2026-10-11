; ZP.ASM -- the zero page of a compiled program.
;
; $02-$21 are the KERNAL's r0-r15. The runtime uses them as scratch between KERNAL calls.
; $50-$7F are free for the user (ASM, POKE).

ZP_PTR  = $22           ; word: a runtime pointer
ZP_TMP  = $24           ; word: a runtime temporary
ZP_SP   = $26           ; byte: the stack pointer at startup, for END
ZP_MODE = $27           ; byte: $0372 at startup, the charset and the ISO bit, for the exit
ZP_DST  = $28           ; word: the destination block of a string routine
ZP_FILE = $2A           ; byte: the handle the input comes from

; The expression stack: 16 words at $30-$4F, low byte first. X is the offset of the next free
; word, so X = 2 x depth. Every runtime routine keeps X.
ESTK    = $30
