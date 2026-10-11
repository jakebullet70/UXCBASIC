# UXCBASIC handoff, 2026-10-11

The current state, for the next agent. The standing orders and the commands are in `CLAUDE.md`.
The design and the to-do list are in `docs/UXCBASIC.PLAN.md`: the order of work is section 4,
and the to-do items are section 5. The old notes are in `docs/HISTORY.md`; do not read it unless
you need to trace a past decision.

## Where the work stands

Steps 4.1 to 4.7b are done: expressions, control flow, `SUB`, arrays, `GETKEY()`,
`ERRORS ON`/`OFF`, namespaces, `BIND`, CP437 on exit, strings, `INPUT`/`LINPUT`, the file
commands (4.5a to 4.5c), `ASM` and `SYS` (4.6), BYTE by default (4.7a), `DIM ... AT`
(4.7b) and pointers by name (4.7c: `AddrOf`, `ContentsAt`, `ContentsAtW`). Step 4.5d, `DIR`,
is put off by the user: it may become code in a `DIR` namespace.

Plan section 4 item 5, the UXCEDIT compile relay, is done: the user disk (5a), UXC chains
(5b), F5 in the editor (5c) and the editor start with the result in a message box (5d).

A `SUB` returns a STRING: `SUB FIRST3$(S$)` or `SUB WRAP(T AS STRING) AS STRING`.

Shared temps and locals are done: plan section 5, "Shared temps and locals". The string
temps and the locals of all `SUB`s of one call-graph level share one pool. A local does not
keep its value between calls, and only its `SUB` can name it. Tests LOCALPOOL (4.3 s),
ERRSUBLOCAL (1.5 s) and ERRSUBLOCALS (1.3 s) pass. NS2 lost its SHOW.N/SHOW.SEEN print. All
`SUB`, string, namespace, array, FOR, `INPUT` and file tests pass, 1.3–6.7 s: STRRET 6.7 s,
FLOWFOR 6.1 s and FILER 6.3 s on a loaded machine.

`#INCLUDE "FILE"` is done: LX.INCLUDE.FIND, LX.INCLUDE.START and LX.INCLUDE.END in
src/UXC-LEX.BL. One level only. At the end of the included file the source is opened again
and read up to the line after the `#INCLUDE`.
An include file has the extension `.UXI`. `build.py` copies `lib/` to `disk/`, and `tests.py` copies `lib/*.UXI` and `tests/*.UXI` to
`build/`. Tests INCLUDE (5.8 s) and ERRINCLUDE (2.8 s) pass. The help has a topic "Including
files"; UXC.HELP is rebuilt (2026-10-11, 10070 bytes, 55 s).

`INSTR(S$, F$[, START])` is a built-in: SG.INSTR in src/UXC-STR.BL, T_INSTR and R_INSTR in
the templates. Without a start it searches from 1. SG.INSTR and SG.MID share SG.LAST.WORD,
the optional last argument. R_INSTR is 123 bytes and takes 25 cycles a position tried, when
the first character differs. `INSTR` is a reserved word. Tests INSTR (3.5 s, was 9.0 s as a
`SUB`) and STR2 (4.9 s) pass. The help topic Strings lists `INSTR`; UXC.HELP is rebuilt.

BIND to a word of the language is done. `BIND name [=] word`, where the word is in the list of
NM.WORD (src/UXC-NAME.BL), makes an alias: `BIND INSTR INSTR` in `NAMESPACE STR` makes
`STR.INSTR`, and `BIND FIND = INSTR` outside a namespace makes `FIND`. The `=` is optional in
every BIND. NM.BIND.SCAN adds each alias in the first pass, to NM.ALIAS.NAME$() and
NM.ALIAS.TARGET$() (K.ALIASES = 64), so an alias works on every line, before its `#INCLUDE`
too. LX.WORD.END in src/UXC-LEX.BL reads an alias as its word. NM.BIND passes over a BIND to a
word. A BIND to a SUB declared above it, outside a SUB body, is made in the first pass by
NM.BIND.SCAN.SUB, with the flag K.SY.SCANNED; NM.BIND.SCANNED clears the flag in the second
pass, so a second BIND of the name is a duplicate. NM.FIND.QUIET makes NM.FIND give SY.R = 0
for a name not found. SB.SCAN.IN.SUB is set from SUB to ENDSUB or END SUB. A BIND to a
variable, an array or a namespace is still made in the second pass.
NM.RESERVED calls NM.WORD. An alias in a namespace is found only by its qualified name.
`lib/STRINGS.UXI` is `NAMESPACE STR` with one `BIND` for each string function. Test STRNS
(4.1 s) passes, with the `#INCLUDE` at the end. UXC.PRG is 7907 bytes, built in 61 s.

`LEFT$(S$, N)` and `RIGHT$(S$, N)` are global SUBs in `lib/STRINGS.UXI`, with ASM bodies,
before `NAMESPACE STR`. `BIND LEFT$ LEFT$` and `BIND RIGHT$ RIGHT$` in it make `STR.LEFT$`
and `STR.RIGHT$`.
Each copies into a local `R$ * 255` and returns it. `P% = @S$` takes the block address,
because `@S$` of a STRING parameter is not a constant and ASM refuses it. The ASM uses r0
($02-$03) as the pointer, and RIGHT$ uses $04. Test STRLR, with the `#INCLUDE` at the end,
passes in 6.5 s, over the 5 s limit, and was not rerun. UXC.PRG is 7907 bytes, built in 62 s.

Mnemonics in `ASM` are done: plan section 5, "Mnemonics in `ASM`". src/UXC-ASM.BL moved to
its own region, `K.BANK.ASM` (24). The opcode table is six string literals in AS.TABLE.CHUNK,
written by a generator script: `/`, the mnemonic, then a mode letter and two hex digits per
opcode. The mode letters are in the header comment of UXC-ASM.BL. Tests ASM2 (3.7 s) and
ERRASMLABEL (1.5 s) pass, and ASM1, ERRASMITEM, ERRASMOPEN and SYS1 still pass. The help
topic ASM has the instructions; UXC.HELP is rebuilt.

- Build: about 31 s on a quiet machine, 57–89 s loaded; 83 s for `#INCLUDE`.
  The last build: 60 s loaded. UXC.PRG 7830 bytes, UXC.OVL 31243 bytes (bank 24 has 15
  pages). Templates: 156 records, 3773 bytes.
  `MKTPL.PY --test` passes.
- Suite: 105 tests. The last full run, after step 5c: 94 tests, 0 failed, 240 s loaded. Steps
  since the last full suite: 15 (5d, STRING results, shared temps, shared locals, `#INCLUDE`,
  `ASM` mnemonics, `INSTR`, `STR.name`, BIND to a word, LEFT$ and RIGHT$, BIND to a SUB in
  the first pass, `.UXI` includes, `POS`, `CONST`, ENUM numbering). STRNS passes in 5.7 s after the rename, not rerun.
  `POS(0)` gives the cursor column and `POS(1)` the row, as a BYTE, by T_POSCOL and T_POSROW
  inline. `POS(0) = v` and `POS(1) = v` are SM.POS, by R_POSSETCOL and R_POSSETROW.
  EX.POS.AXIS takes only the number 0 or 1. Test POS passes in 3.1 s. UXC.PRG is 7907 bytes,
  built in 65 s. The help topic is in `help/UXC-HELP.md`; UXC.HELP is rebuilt.
  `CONST NAME = value` is NM.CONST in `src/UXC-NAME.BL`, a record of kind K.SK.CONST that
  EX.OPERAND folds as a number. It is in the SUB bank because the STMT and FLOW bank passed
  8K. NM.AS.TYPE in `src/UXC-NAME.BL` reads `AS type` for DIM and CONST. Test CONST passes in
  3.7 s; ERRCONSTBIG is written and not run.
  `ENUM name` ... `END ENUM` is NM.ENUM in `src/UXC-NAME.BL`, a record of kind K.SK.ENUM. Its
  members are K.SK.CONST records owned by it, the records after it. NM.ENUM.RECORD is set from
  ENUM to END ENUM, and SM.LINE then sends each line to NM.ENUM.MEMBERS. A member past 255
  makes the ENUM and every member WORD at END ENUM. Test ENUM passes in 3.5 s; ERRENUMOPEN is
  written and not run. UXC.PRG is 7910 bytes, built in 64 s. The help topic is in
  `help/UXC-HELP.md`; UXC.HELP is rebuilt. Next in the plan: `AS` enum, then bare members.
  `lib/CONSOLE.UXI` and `lib/DISK_FILEIO.UXI` are the user's work in progress; review them
  only when asked.
  The full suite is due. Until 2026-10-13 the user is short of tokens: run only the new tests
  and one or two old ones, and the user runs the full suite.
- A single test takes 1.1–5.5 s on a quiet machine; STR*, FLOWFOR, FLOWIF, FILEW and FILER
  are the slowest. On the slow machine every test takes about twice its quiet time.
- The help topics for every done step are written. All but "Including files" and the ASM
  instructions are built:
  UXC.HELP.PRG 10,070 bytes,
  27 topics, 58 s.

**Next:** the user runs the full suite (`RUNTESTS.BAT`) first. Then, in this order (user,
2026-10-11). The user approved asm for both steps; ask again only for asm outside them.

1. **The string library as asm runtime.** The user wants as much of the core in asm as
   possible. `INSTR` is done. Make `LEFT$`, `RIGHT$`, `UCASE$` and `LCASE$` built-in
   functions, like `MID$` and `INSTR` (SG.FUNCTION in src/UXC-STR.BL), with `R_*` routines in
   tpl/R-STRING.ASM, linked only when used. A new name goes in SG.FUNCTION, SG.SCAN.KNOWN,
   NM.WORD (src/UXC-NAME.BL) and a `BIND` line in `lib/STRINGS.UXI`.

**Proposed, not approved: DIM in the first pass.** SB.SCAN declares each DIM, so a BIND to a
variable and a use before the DIM work on any line. The second pass then only emits the
storage.

Plan section 5 also holds the new items "A compile report" and "`FRE`".

## Editor

The UXCEDIT notes are in `docs/HISTORY.md`, under "Notes moved from HANDOFF.md on 2026-10-10".
The user drives the editor tests by hand. Do not run a headless drive of UXCEDIT.

## Compiler map

| Region | Bank | Modules |
|---|---|---|
| low RAM | | `UXC.BASL` (main, all DIMs at the top), `-DEFS`, `-LEX`, `-SYM`, `-CODE`, `-LINK` |
| `K.BANK.EXPR` | 20 | `UXC-EXPR.BL` (EX.*), `UXC-COND.BL` (JP.*, CN.*) |
| `K.BANK.FLOW` | 21 | `UXC-STMT.BL` (SM.*), `UXC-FLOW.BL` (NS.*, CT.*, FR.*, RP.*) |
| `K.BANK.SUB` | 22 | `UXC-SUB.BL` (SB.*), `UXC-NAME.BL` (NM.*) |
| `K.BANK.STR` | 23 | `UXC-STR.BL` (SG.*); its header comment has the string design |
| `K.BANK.ASM` | 24 | `UXC-ASM.BL` (AS.*): `ASM`, `SYS`, the 65C02 assembler |

- UXC.MAIN claims banks 20–24 right after BANKMGR.INIT. The regions are written to `UXC.OVL`.
- A GOTO from one region to another, or from a region to low code, is written
  `GOSUB x : RETURN`.
- The source is read twice. `SB.SCAN` declares every `SUB` and calls `NM.SCAN`; the second pass
  compiles.
- Templates: `tpl/*.ASM`, built by `tpl/MKTPL.PY`. Ids are `T.NAME.ID` in `UXC.TPL.BL`;
  inserting a template moves every id after it.
- Error tests: the `.OUT` is the `ERROR,<line>,<msg>` line. RUNDIV0.OUT and RUNSUB.OUT hold code
  addresses, which move when the start code changes.

## Code notes

- The string design is in the header comment of `UXC-STR.BL`. A string variable is a
  `[max][len][data]` block in BSS, and its value is the block address in A/Y.
- STRING results: SG.RESULT, SG.IS.RESULT and SG.RETURN.EMPTY in `UXC-STR.BL` (bank 23),
  called from SB.FUNCTION, SB.RETURN and SB.FALL.OUT in `UXC-SUB.BL`. No new templates.
  The `SUB` returns in A/Y the address of the block that holds the result: a literal, one of
  its temps, a parameter's block or another variable. `RETURN` makes no copy. The caller
  reads the block and never writes it, and keeps its address in a hidden WORD (`%P 1` and
  on). The caller copies the result into a temp of its own when it passes the result to a
  `SUB`, or when another call comes later in the same statement: a temp of the `SUB` holds
  the result only until the `SUB` runs again. A body that ends without a `RETURN` gives "".
  A result has no size of its own and is at most 255 characters.
- Files: R_FILE, R_FIN, R_FREAD and R_FWRITE are in `tpl/R-FILE.ASM`; SG.OPEN, SG.READ and
  SG.WRITE are in `UXC-STR.BL`. A handle is the KERNAL logical file number 3–14 on unit 8.
  File 15 is the command channel; the first `OPEN` opens it and it stays open.
- R_FIN holds each handle's next byte in `ahead`, so `READ`, `INPUT #`, `LINPUT #` and `EOF`
  can be mixed on one handle.
- The chain: `UXC.INPUT` line 3 names the program UI.CHAIN (`src/UXC.BASL`) loads after
  the result line. The hop is in plan section 4 item 5. A test with `tests/NAME.NEXT`
  chains to the PRG it names.
- `ASM` and `SYS`: AS.* in `src/UXC-ASM.BL` (bank 24), R_SYS in `tpl/SYS.ASM`.
- `ASM` labels: AS.LABEL.* and AS.REFERENCE.* arrays, DIMed in `UXC.BASL`. A use of a label
  further down is kept and patched at END ASM by AS.RESOLVE. JMP and JSR to a label take a
  K.F.ABS fixup in K.SEC.CODE.
- Pointers: `AddrOf(name)` is EX.ADDROF, `@name` with brackets (EX.AT.NAME). A read of
  `ContentsAt` or `ContentsAtW` is EX.PEEK, by the operator K.EO.PEEK or K.EO.WORDPEEK. A
  write is SM.CONTENTS, which shares SM.POKE.ADDRESS with `POKE`; a computed address goes
  through SM.STORE.THROUGH, the tail of the array store. Tests POINTER, ERRADDROF and
  ERRCONTENTS.
- Fixed addresses: NM.AT (`src/UXC-NAME.BL`) adds a variable record with flag K.SY.FIXED (2)
  and the address as its value. Its loads and stores use section K.SEC.CONST, an absolute
  address with no fixup. The FOR stack keeps the counter's section in NS.VS%. AS.ADDRESS
  writes a K.SEC.CONST `@name` as it is. Checklist: a new reader of a variable record checks
  K.SY.FIXED, as EX.OPERAND, EX.AT, SM.LET, CT.FOR and SG.INPUT.NEXT do.
- Temp pools: SB.POOLS (`UXC-SUB.BL`, bank 22) places the pools at link, after the array
  space. SB.EDGE adds a hidden K.SK.CALL record, `%C n`, for each `SUB` a `SUB` calls. It is
  owned by the caller; its value is the `SUB` called and its count is the line of the first
  such call. A call from the main program adds none. These records and the temps count
  toward the 496 names of TOO MANY NAMES.
- A temp record has flag K.SY.TEMP (4), and its value is its offset in its owner's pool. A
  K.SEC.TEMP fixup holds its owner, SB.CURRENT, in bytes +6/+7. LK.FIX adds the owner's pool
  offset from SB.POOL.OF. A `SUB` record holds its level at +28 (K.SY.LEVEL, a byte), its
  temp count at +29 (K.SY.TEMPS, a byte), and at +30 (K.SY.POOL, a word) its frame bytes,
  then its pool offset.
- Locals: SB.PLACE.VARIABLE and SB.PLACE.BLOCK (`UXC-SUB.BL`) place a variable or a block in
  the frame of the `SUB` being compiled, or in the main program's space. Inside a `SUB`, a
  K.SEC.VAR or K.SEC.BSS value from K.FRAME.BASE (49152) up is 65536 less the local's
  distance below its pool's offset. LK.FIX resolves it through the fixup's owner. SB.CALL.STORE
  and SB.CALL.POP set SB.CURRENT to the `SUB` called while they emit: the parameter is in the
  callee's frame.
- Temps are not cleared at startup. The startup code sets the max byte, 255, of each temp.
- A KERNAL probe is plain BASIC typed with `x16emu -bas FILE -run` and `-fsroot` a scratch
  folder.
- The detail of steps 4.4c to 4.6b is in `docs/HISTORY.md`, under "Notes moved from
  HANDOFF.md at step 4.7a".

## Traps

- There is no `!` mark: a name with no mark is a BYTE. A SUB with no mark and no AS returns
  nothing.
- KERNAL `CHRIN` from the screen leaves the prompt out of the line, and leaves the cursor on
  the typed line: R_INPUT prints the CR. Any output before the next `CHRIN` drops the rest of
  a typed line.
- The KERNAL `OPEN` never fails on a missing file. `OPEN` reads the command channel, and a
  status that does not start with "0" closes the file and returns NOFILE ($FFFF).
- Emulator DOS (ROM R49, `-fsroot`): the last byte of a file comes with ST 64. A read past
  the end gives 0 with ST 66, and so does the first read of an empty file.
- Handles 0–2 cannot be read: KERNAL CHKIN gives FILE NOT OPEN.
- Bank 21 (`K.BANK.FLOW`, STMT and FLOW) is nearly full; its free bytes are not measured. Past 8K the
  build stops with `GP.BANKED REGION OVER 8K @ line`; the line is the region's own
  `GP.BANKED` in `build/UXC.SRC.PRG`. New statement code goes in another region, with one
  `GOSUB` line in SM.STMT.
- Git Bash `sed -i` turns CRLF into LF. Edit the CRLF files (UXC-STR, UXC-EXPR, UXC-STMT,
  UXC-FLOW, UXC-ASM, UXC.BASL, HISTORY.md, UXC-HELP.md) with a Python script that keeps the
  endings.
- A label and a variable with the same name give DUPLICATE SYMBOL.
- EX.PREC ranks every operator id from K.EO.LOR up as AND or OR. A new K.EO id goes below
  K.EO.LOR, and LOR and LAND move up.
- BASLOAD `#DEFINE` names may not contain digits, and no name may begin another name.
- GPC allows only 32 arrays used before their DIM, so every DIM sits at the top of `UXC.BASL`.
- A string literal in GPC source passes 255 characters as OUT OF RANGE. NM.R$ and NM.Q$ in
  NM.RESERVED split the reserved words for this reason.
- `?RTB133` at boot means `build/` lost the runtime file. A build during a test run causes it.
  Rebuild.
- A test with `tests/NAME.IN` gets its lines typed on the keyboard. The harness types `LOAD`
  and `RUN` through `-bas`, because `-bas` loses keys while `-prg` loads. Typed text is not
  in the output; the CR R_INPUT prints is.
- `-echo` logs every CHROUT, so what `PRINT #` writes to a file shows in a test's output.
- `-echo` also logs every byte `WRITE` sends, and tests.py prints the log as cp1252, which
  fails on some bytes. Keep a binary-file test's data printable apart from the bytes under
  test.
- `PRINT CHR$(147)` clears the screen and then prints its own Return, so the next PRINT
  lands on the second row.
- The tests do not see the screen. Check the CP437 conversion on exit by eye in the emulator.
- A new built-in function in EX.OPERAND goes in SG.SCAN.KNOWN too, or SG.SCAN reports it as
  UNDECLARED NAME.
- GPC's banking rules are in `tools/gpc/GPC-BASIC/BANKED-OR-NOT.md`.
- BASLOAD stops a source line of 230 characters with LINE TOO LONG. A line of 190 passes.
- The Write tool strips the trailing spaces of a line. A PRINT of numbers ends in a space, so
  write a test's `.OUT` from Python.
- The emulator prints a warning into the test output at the first RMB, SMB, BBR or BBS
  it runs. A test that runs one fails on the warning.
