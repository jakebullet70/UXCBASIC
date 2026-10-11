# UXCBASIC — design

UXCBASIC is a small compiled BASIC for writing the system programs and utilities of the planned
Unix-style X16. The compiler `UXC.PRG` turns one source file into a native 65C02 PRG. UXCEDIT is the
editor and runs the compiler. v1 of the compiler is written in GPC. When UXCBASIC can do files,
arrays and strings, the compiler is rewritten in UXCBASIC.

Status: approved on 2026-10-09. Steps 1 to 3, the template format, the compiler skeleton and
the test harness, are done.

## 1. The language

**Source.** One file of text from UXCEDIT, ASCII or PETSCII, one statement per line. There
are no line numbers. Keywords and names are not case-sensitive: the lexer folds the case of
ASCII and PETSCII letters. A name has up to 16 characters: letters, digits and `.`, and it
may end in a type mark. A label is `name:` on its own line. Literals are `123`, `$7F`,
`%1010` and `"text"`. There is no character literal: `ASC("A")` with a literal string is
folded to `65` at compile time, so it costs nothing at run time.

**Comments.** A whole-line comment starts with any of `REM`, `'`, `;`, `##` or `//`, after
optional spaces. Only `REM` and `'` may also end a line after a statement:

```
REM the whole line           ' the whole line          ; the whole line
## the whole line            // the whole line
X = 1 ' a trailing comment
X = 1 REM a trailing comment
```

`;` is a comment only at the start of a line, so `PRINT A; B` is unchanged. `##` cannot be
confused with a `#DEFINE`, which has one `#`. Inside a string, none of these start a comment.

**Types.** Every number is unsigned. A type is given by a mark on the name, or by `AS` in the
declaration. A name with neither is a BYTE: `DIM B` is `DIM B AS BYTE`.

| Mark | `AS` form | Type | Size |
|---|---|---|---|
| none | `AS BYTE` | BYTE, 0–255 | 1 byte |
| `%` | `AS WORD` | WORD, 0–65535, low byte first | 2 bytes |
| `$` | `AS STRING` | STRING, Pascal style | max + 2 bytes |

- `WORD` is not the same as `INT`. In most BASICs `INT`, and `%` on Commodore, is signed
  (−32768 to 32767). In UXCBASIC `%` is unsigned. A signed `INT` type comes later, with its
  own mark.
- The mark is part of the name. `A`, `A%` and `A$` are three different names. A name declared
  with `AS` has no mark: after `VAR N AS WORD` the name is `N`.
- A mark and `AS` on one name stop the compile with `A MARK AND AS`.
- `!` is not a mark and not part of a name. `DIM A!` stops the compile with `SYNTAX ERROR`.
- A main program variable is static: it has one fixed address. A `SUB`'s locals are in its
  frame, in the pool of its call-graph level (§5 "Shared temps and locals"). There is no
  stack, so a `SUB` cannot recurse, and two `SUB`s cannot call each other.

**Declarations.** `DIM` and `VAR` mean the same thing. One line can declare several names.

```
DIM A%, B(10), L$ * 80
VAR N AS WORD, T(10) AS BYTE
DIM C = 1, P% = $1000
```

- Every variable must be declared before use. An undeclared name is a compile error, so a
  typo cannot make a new variable. A `SUB` header declares its parameters.
- `B(10)` is a BYTE array of 10 elements, `B(0)` to `B(9)`. `W%(10)` is a WORD array.
  `B(i)` is one element.
- `AddrOf(name)` is the address of any variable, array or string, as a `WORD`. `@name` is
  the same.
- `ContentsAt(a)` is the BYTE at address `a`, and `ContentsAtW(a)` the WORD at `a` and
  `a + 1`, low byte first. Each can be read and assigned:

  ```
  P = AddrOf(X)
  Y = ContentsAt(P)
  ContentsAt(P + 1) = Y
  ContentsAtW(P) = 1000
  ```
- `DIM REG_P AT $030F` puts a BYTE or WORD variable at a fixed address, a constant
  expression. It takes no space, and two such variables may share an address.

**Strings.** A string is a block of `[max][len][data]`. `DIM L$ * 80` reserves 82 bytes:
`max` = 80, `len` = 0 at the start, then 80 bytes of data. A STRING must have a size, 1 to 255:
`DIM L$ * 80` or `DIM L AS STRING * 80`. `(n)` always makes an array.

- `LEN(L$)` reads the length byte, with no scan.
- An assignment or `INPUT` stops at `max`, so a string never overflows.
- A string can hold any byte, zero included.
- A string literal is stored with `max` = `len`, and is read only.
- The compiler copies the bytes of a string literal into the PRG unchanged. UXCEDIT saves
  ASCII. A compiled program starts in ISO mode, so an ASCII literal prints as typed.
- v1 string operations: assignment, `+` (join), the six compares, `LEN`, `MID$`, `CHR$`, `ASC`, `STR$`,
  `VAL` and `INSTR`. `LEFT$`, `RIGHT$`, `UCASE$` and `LCASE$` become built-ins with `R_*`
  routines, as `INSTR` is.

**Expressions (v1).**

| Precedence | Operators |
|---|---|
| highest | `( )`, function calls, `PEEK(a)`, `ContentsAt(a)`, `ContentsAtW(a)`, `name(i)`, `AddrOf(name)`, `@name` |
| | unary `-` |
| | `*` `/` `MOD` |
| | `+` `-` |
| | `<<` `>>` |
| | `=` `<>` `<` `>` `<=` `>=` (unsigned) |
| | `NOT` |
| | `AND` |
| lowest | `OR` `XOR` |

- An operation that mixes `BYTE` and `WORD` is done as `WORD`.
- Assigning a `WORD` value to a `BYTE` keeps the low byte.
- Truth: 0 is false, and any other value is true. `IF X%` tests for nonzero.
- A compare yields 0 or 1. `IF` and the loop tests compile a compare straight to a branch, with no 0/1
  value in between.
- `NOT` binds below the compares, as in MS BASIC and Prog8: `NOT A = B` is `NOT (A = B)`.
- `NOT` is logical: `NOT 0` is 1, and `NOT` of any other value is 0. `NOT` of a compare is
  folded into the opposite compare. For a bit flip, use `XOR $FF` or `XOR $FFFF`.
- `AND`, `OR` and `XOR` are bitwise, as in MS BASIC, so `PEEK(A) AND 15` masks. On compare
  results they work as logic. Inside a condition, `AND` and `OR` between compares compile to
  short-circuit branches. The trap, the same as in MS BASIC: `1 AND 2` is 0, so write
  `IF A% <> 0 AND B% <> 0`, not `IF A% AND B%`.
- Two BYTE operands give a BYTE operation, as in Prog8: `A * 2` with `A` = 200 is 144.
  Widen first for a WORD result: `N% = A` then `N% * 2`.
- A number constant takes the other side's type when
  it fits, so `B + 1` is a BYTE add. An operation on two constants is folded.
- `*`, `/` and `MOD` call runtime routines and work in WORD. Every other operator is inline code.
- Division by zero: a constant 0 divisor is a compile error. At run time the program stops with
  `?DIVISION BY ZERO ERROR AT $xxxx` (the address of the `JSR`; the `.LST` maps it to a line).
- Shifts use only the low byte of the count.
- Not in v1: signed types and signed compares, and floats.

**Run-time errors.** A run-time error prints `?<message> ERROR AT $<address>` and ends the
program as `END` does. `R_ERROR` and the message are linked only into a program that can hit
the error.
- The division-by-zero check is always on: it is 5 bytes in the shared divide routine and
  about 1% of a divide.
- `ERRORS ON` and `ERRORS OFF` are compile-time switches for the source lines after them, like
  Turbo Pascal's `{$R+}` and `{$R-}`. They choose a checked or an unchecked template, so
  `ERRORS OFF` code costs nothing, as in Prog8. They control the inline checks: the array
  index and the string length. The default is `ERRORS ON`, as in MS BASIC. Put `ERRORS OFF`
  around a loop that must be fast.

**Commands.**

| Group | Statements |
|---|---|
| Data | `DIM` / `VAR`, assignment `name = expr`, `name(i) = expr` |
| Control | `IF expr [THEN]` … `ELSEIF expr` … `ELSE` … `ENDIF`, `IF expr THEN statement`, `DO [WHILE\|UNTIL c]` … `LOOP [WHILE\|UNTIL c]`, `FOR v = a TO b [STEP k]` … `NEXT`, `REPEAT [n]` … `END REPEAT`, `EXIT DO\|FOR\|REPEAT`, `CONTINUE`, `GOTO label` |
| Subroutines | `SUB name(X%, Y)` … `ENDSUB`, `[CALL] name(x, y)`, `RETURN [expr]`. `CALL` is optional; the brackets are required, even empty. |
| Console | `PRINT item; item, …` (a trailing `;` drops the newline), `INPUT var`, `LINPUT L$`, `GETKEY` (a function, 0 when no key is waiting) |
| Files | `F% = OPEN(name$, mode)`, `N% = READ(F%, buf, max)`, `WRITE F%, buf, n`, `CLOSE F%`, `PRINT #F%, …`, `INPUT #F%, var`, `LINPUT #F%, L$`, `EOF(F%)`, `DIR "pattern"` |
| Low level | `PEEK(a)`, `POKE a, v`, `ContentsAt(a)`, `ContentsAtW(a)` (read and assigned), `AddrOf(name)`, `SYS a`, `ASM $A9, $41, …` (raw bytes; `AddrOf(name)` or `@name` puts in a variable's address), `ASM` … `END ASM` (a block of byte lines) |

- **Subroutines.** There is one keyword, `SUB`, and its end is `ENDSUB`.
  - `SUB DRAW(X%, Y)` returns no value. `RETURN` leaves it early. A `SUB` name with no mark
    and no `AS` returns no value.
  - `SUB FIRST(S$) AS BYTE` returns a BYTE and `SUB ADD%(A%, B%)` returns a WORD, with
    `RETURN expr`. Such a `SUB` is used inside an expression.
  - `SUB FIRST3$(S$)` or `SUB WRAP(T AS STRING) AS STRING` returns a STRING, as the address of
    the block that holds the result.
  - A parameter with no mark and no `AS` is a BYTE: `SUB SHOW(N)`.
  - Parameters and locals are in the `SUB`'s frame, named `sub.var` inside the compiler. A
    local does not keep its value between calls, and only its `SUB` can name it.
  - A `BYTE` or `WORD` argument is passed by value. A string or an array is passed as a pointer
    to it, so the `SUB` works on the caller's data and no copy is made.
- **IF** (decided 2026-10-09). The block form has any number of `ELSEIF` parts and one `ELSE`;
  `THEN` is optional at the end of the line. The one-line form `IF c THEN statement` has no
  `ELSE`, and a block statement after `THEN` is an error. `IF c THEN GOTO`, `EXIT` or
  `CONTINUE` (and `IF c GOTO label`) compile to one branch to the target.
- **Two-word ends** (decided 2026-10-09): `ENDIF` or `END IF`, `ENDREPEAT` or `END REPEAT`.
- **FOR.** The loop ends when the counter passes `TO`, so a `STEP` that jumps over the `TO`
  value still ends the loop. The test also catches the wrap past 255 or 65535. After the
  loop the variable holds the last value the body saw (option A, decided 2026-10-09), not
  `TO` + `STEP` as in MS BASIC: the test is made before the step.
- **Files, Unix style.** `OPEN` returns a handle. There are no fixed channel numbers.
  - Handles 0, 1 and 2 are stdin (the keyboard), stdout (the screen) and stderr, to allow
    redirection later. `PRINT #1, "HI"` is the same as `PRINT "HI"`.
  - A file is opened for one direction in v1: `O.READ`, `O.WRITE` (replaces the file) or
    `O.APPEND`.
  - The return value carries the status. `READ` returns the count, and 0 at end of file.
    There is no `READST`.
  - `OPEN` returns `NOFILE` ($FFFF) when it fails. 0 cannot mean failure, because 0 is
    stdin.
  - Two forms sit side by side. `READ` and `WRITE` move raw bytes, for binary files and
    copies. `PRINT #`, `INPUT #`, `LINPUT #` and `EOF` work in lines, for text files.
- **Built-in names.** `O.READ`, `O.WRITE`, `O.APPEND` and `NOFILE` are constants the
  compiler knows without an `#INCLUDE`. A constant is folded into the code as an immediate
  operand (`LDA #$FF`). It takes no RAM and no bytes in the PRG beyond the instruction that
  uses it. `CONST` constants work the same way.
- **Line input.** `LINPUT L$` and `LINPUT #F%, L$` read a whole line into a string, commas
  and quotes included. A line ends at CR, at LF, or at CR LF, so files from the X16, from Unix
  and from DOS all read the same. The ending is not stored. After a CR the runtime looks at
  the next byte, and drops it when it is an LF. That byte is held back for the next read
  of the same handle. A line longer than the string's `max` is cut, and the rest of the line
  is skipped.
  - `INPUT` reads one field: it stops at a comma or at the end of a line. For a number
    variable it converts the text.
  - From the keyboard, `INPUT` drops the rest of the line after its last variable. The
    KERNAL drops it anyway when anything is printed before the next read. `INPUT #` keeps
    the rest for the next read.
  - `EOF(F%)` is 1 when the next read would return nothing.
- **Print items.** A `PRINT` item is a number, which prints in decimal, or a string.
  `PRINT` follows MS BASIC, not CBM BASIC, because the X16 screen is 80 columns:
  - A number prints with a space for its sign before it and a space after it.
    `PRINT 1; 2` prints ` 1  2 `.
  - `;` joins two items. Two items with nothing between them are joined the same way.
  - A comma moves to the next 14-column print zone: columns 0, 14, 28, 42 and 56. From
    column 56 on, a comma ends the line instead.
  - A trailing `;` or comma leaves the cursor on the line.
  - The zone comes from the screen cursor (KERNAL PLOT). `PRINT #` will keep its own column.
  - MS BASIC also starts a new line when a number does not fit before the edge. UXCBASIC
    does not, yet.
- **Library procedures.** Copy, fill, compare and sort are library `SUB`s written in UXCBASIC,
  not commands.

**Options and constants.**
- `CONST NAME = value` makes a named constant. Several go on one line, separated by commas,
  as in `DIM`. The value is a constant expression.

  ```
  CONST MAX_LEN = 80
  CONST ROWS = 2 * 30, COLS = MAX_LEN + 1
  CONST BASE% = $9F20
  CONST BIG AS WORD = 1000
  ```

  - The type comes from the mark or `AS`. With neither it is a `BYTE`.
  - The type sets the range. A `BYTE` over 255 stops the compile with `TOO BIG FOR A BYTE: NAME`.
  - A string mark or `AS STRING` stops the compile with `A CONST IS A NUMBER`.
  - A value that is not a constant expression stops the compile with `VALUE NOT A CONSTANT`.
  - The constant belongs to the `SUB` or namespace it is in. A namespace body may hold `CONST`,
    and `BIND` can name a `CONST`.
  - A `CONST` is used like a number. It folds into the code and takes no RAM and no PRG bytes.
  - An assignment to a `CONST` stops the compile with `NOT A VARIABLE: NAME`.
  - `CONST` is a reserved word.

- `#DEFINE` sets compiler options only. Its names start with `UXC.`:
  - `UXC.OBJECT "X.PRG"`: the output file name.
  - `UXC.LIST`: also write a `.LST` file.
  - `UXC.NOSTUB`: leave out the BASIC `SYS` line.
  - `UXC.ORG $xxxx`: the start address.
- `#INCLUDE "FILE"` reads another source file in place (done 2026-10-11: LX.INCLUDE.FIND in
  src/UXC-LEX.BL, tests INCLUDE and ERRINCLUDE). One level: an included file cannot include
  another. An error in it reports the `#INCLUDE` line, with `(FILE n)` after the message.

## 2. The compiled program

**PRG layout** (default origin `$0801`):

```
$0801  BASIC stub "10 SYS 2061"  (left out with UXC.NOSTUB; the code then starts at UXC.ORG)
       startup: set up zero page, JMP to the first statement
       user code
       runtime routines this program uses, and nothing else
       system table: one JMP per KERNAL entry used
       string literals, then variables with their start values
--- end of file ---
       array and string space (not in the file; each string's max byte is set at startup)
```

- Code goes through the system table to reach the KERNAL, and nothing calls `$FFxx` directly.
  A port to the new machine rewrites only that table.
- Code plus data must end below `$9F00`. The array and string space must also end below
  `$9F00`.

**Zero page at run time.**

| Address | Use |
|---|---|
| `$02–$21` | KERNAL `r0–r15`. The runtime uses these as scratch between KERNAL calls |
| `$22–$2F` | runtime pointers and temporaries |
| `$30–$4F` | expression stack: 16 words, indexed by X |
| `$50–$7F` | free for the user (`ASM`, `POKE`) |

**Value passing.** A `BYTE` value goes in A. A `WORD` value, or the address of a string or an
array, goes in A (low byte) and Y (high byte). Arguments are stored into the `SUB`'s own
parameter variables before the `JSR`. A `SUB` returns its result in A, or in A and Y.
A `SUB`'s expressions use the expression stack above its caller's, and the depth is not
checked at run time.

## 3. The compiler

**Input.** UXCEDIT, or `uxc.py` on the host, writes `UXC.INPUT`, which has two or three
lines:
- line 1: the source file name.
- line 2: the result file name, read by UXCEDIT's compile relay. The compiler writes one
  line to it: `OK,<prg>,<bytes>` or `ERROR,<line>,<message>`. The message may hold commas.
- line 3, optional: the program to load next. The compiler loads it after it writes the
  result line. With no line 3 the compiler ENDs.

The PRG is named after the source: `HELLO.UXB` writes `HELLO.PRG`. Either line ending is read in
`UXC.INPUT`, and the source may use CR, LF or CR LF.

Every other option comes from `#DEFINE UXC.*` lines in the source.

**Templates.**
- Code templates and runtime routines are 65C02 source in `tpl/`. `tpl/MKTPL.PY` assembles them
  with 64tass into `UXC.TPL.BIN`. That file is data the compiler loads, so the self-hosted
  compiler uses it too. `tpl/MACROS.ASM` holds the format and the macros that write it.
- There are three kinds of record, all in one table:
  - `T_` templates, copied inline for each use.
  - `R_` runtime routines, placed once at the end of the program.
  - `S_` system table entries, one `JMP` to the KERNAL each.
- A record's id is its place in the table. `tpl/UXC.TPL.IDS` lists them.
- The file is a header (`"UXT"`, version, count, index offset), the records, then an index of
  one word per record.
- A record is its code length, its fixup count, its code, then its fixups. A fixup is three
  bytes: offset, kind, argument.

| Kind | Effect | Argument |
|---|---|---|
| `ABS` | the word at the offset += the slot's value (the code holds the addend, as in `S0+1`) | slot |
| `LO` / `HI` | the byte at the offset = the slot's low or high byte | slot |
| `SELF` | the word += the address the record is placed at | — |
| `REC` | the word += the address of another record, which is linked too | record id |

- A slot is an operand the compiler passes to a template: a variable, a string, a label or a
  constant.
- Linking a record links every record its `REC` fixups name, so a program carries only the
  routines it uses.
- An expression's value is in A (a BYTE), or in A and Y (a WORD or an address). Assignment is
  a load template then a store template.
- `MKTPL.PY --test` links a test program on the host the way the compiler will, runs it in
  the emulator, and checks the output.
- This is asm, so each new template is agreed with the user before it is written.

**One pass, then link.**
1. Each line is tokenised and parsed. The compiler emits code by copying template bytes into the
   code buffer. Each absolute reference becomes a fixup entry: a variable, a string, a label, a
   runtime routine, or a system table entry.
2. Forward jumps from `IF`, the loops and `GOTO` go on a fixup list, which is resolved when their
   target is reached.
3. At the end, the compiler lays out the sections in section 2 and appends the runtime routines
   that were used. It then resolves every fixup, writes the PRG, and optionally writes the
   `.LST`.

**Compiler memory map.**
- `UXC.PRG` and the GPC SHARED runtime use low RAM and bank 1.
- The compiler claims its banks through GPC's `BANKMGR`, which hands out bank 2 and up:

| Banks | Contents |
|---|---|
| 1 bank | the template table, `UXC.TPL.BIN` |
| 1–2 banks | the symbol table: name, type, kind, address or slot, and the owning `SUB` |
| 5 banks | the code buffer, up to 40 KB of output |
| 1–2 banks | fixups, plus the `IF`/`DO`/`FOR`/`REPEAT` nesting stack |

**Errors.**
- The first error stops the compiler. It prints `?<ERROR> IN <line>` and the line of source.
- The error also goes into the result file, so UXCEDIT can jump to that line.

**Source files.** `src/UXC.BASL` is the main file. It includes one file per part:

| File | Part |
|---|---|
| `UXC-DEFS.BL` | the constants, all named `K.*` |
| `UXC-LEX.BL` | the source file and the tokens of a line |
| `UXC-SYM.BL` | the symbol table: 256 hash buckets, then 32-byte records |
| `UXC-CODE.BL` | the template table, the code buffer, the string literals, the fixups, and `EMIT` |
| `UXC-LINK.BL` | the link step and the PRG writer |
| `UXC-STMT.BL` | the statements |
| `UXC.TPL.BL` | the template ids as `#DEFINE`s, written by `tpl/MKTPL.PY` |

- `EMIT` copies a record into the code buffer. A slot that holds a constant goes into the code
  at once. Any other slot becomes a fixup: a code offset, a kind, a section and a value.
- The sections are code, record, string, variable and label.
- A `REC` fixup adds the record to the list of routines.
- At the end of the source, the link step emits each listed routine in turn. Each one can add
  more routines to the list. The strings and the variables follow the routines. Every fixup
  is resolved last, so a forward reference needs nothing special.
- `UXC.TPL.BL` gives the compiler its record ids. The compiler stops when `UXC.TPL.BIN` holds a
  different number of records.

**On the host.** `python uxc.py FILE.UXB [--run]` copies the source onto `build/`, writes
`UXC.INPUT`, runs `UXC.PRG` in the emulator until the result file appears, and prints the
result. With `--run` it then runs the PRG, and prints what the PRG printed.

**Tests.** `python tests.py [NAME ...] [--update]`, or `RUNTESTS.BAT`, runs the tests in
`tests/`. Each test is a source `NAME.UXB` and its expected output `NAME.OUT`.
- A source that compiles is run, and what it printed is compared with `NAME.OUT`. The boot
  banner, the load, and the `READY.` lines around the run are cut.
- A source that does not compile is compared by its result line. An error test's `NAME.OUT`
  is the one line `ERROR,<line>,<message>`.
- `--update` writes `NAME.OUT` from what the test gave. Read it before you keep it.
- A run stops when BASIC prints `READY.` after the program, so a test takes about 2 s, and an
  error test about 1 s.
- A trailing `;` at the end of a program's output cannot be seen: BASIC starts a new line
  before `READY.` either way.

**Listing (`.LST`).** One row per emitted template, in the form `addr  bytes  ; source line`.

**Help.** `UXC.HELP.PRG` is the on-machine reference. It is GPC.HELP from the GPC repo with
the GP.BASIC content taken out: `src/UXC.HELP.BASL` is the viewer. `help/MKHELP.PY` builds
`HELP-TXT/` from `help/UXC-HELP.md`, and each program in `examples/` gets an index row. A
topic is written when its command is built.

## 4. Order of work

Each step ends with a build, a run and a check.

1. **Template format.** Done on 2026-10-09. The 64tass macros, the `UXC.TPL.BIN` layout and a
   first set: start and end, loads and stores, the expression stack, `POKE`, `PEEK`, and
   `PRINT` of a string, a BYTE and a WORD.
2. **Compiler skeleton in GPC.** Done on 2026-10-09.
   - It has every part: `UXC.INPUT`, the line reader and tokeniser, the symbol table in banked
     RAM, the code buffer and fixups, the link step and the PRG writer.
   - It compiles enough to test them: comments, `DIM`/`VAR` of BYTE and WORD names,
     `name = constant`, `PRINT` of strings, numbers and variables, `END`, and labels.
   - `tests/SKEL.UXB` compiles in about 1 s to a 348-byte PRG, which prints the right
     values.
3. **Test harness.** Done on 2026-10-09.
   - `tests.py` and `RUNTESTS.BAT`, as described under **Tests**.
   - 19 tests: the skeleton, `PRINT` forms, names, the three line endings, and one test for
     each compile error the skeleton can give. They all pass in about 25 s.
   - The tests found that a reserved word with a mark, such as `PRINT%`, was taken as a name.
     It is now reserved.
   - Later on 2026-10-09 `PRINT` moved to MS BASIC spacing and print zones. COMMAS is the
     20th test.
4. **Commands**, added in this order:
   1. `DIM`/`VAR` for `BYTE` and `WORD`, expressions, `POKE`/`PEEK`, `PRINT` (done
      2026-10-09: tpl/T-EXPR.ASM, R-MATH.ASM, R-ERROR.ASM, src/UXC-EXPR.BL)
   2. `IF`, `DO`/`LOOP`, `FOR`, `REPEAT`, `EXIT`, `CONTINUE`, `GOTO` (done 2026-10-09:
      tpl/T-FLOW.ASM, src/UXC-COND.BL, src/UXC-FLOW.BL; EXPR and COND run from bank 20, STMT
      and FLOW from bank 21, both in UXC.OVL)
   3. `SUB`/`CALL`/`RETURN` (done 2026-10-09: tpl/T-CORE.ASM T_RTS, T_POPB_V, T_POPW_V,
      src/UXC-SUB.BL in bank 22). The source is read twice: the first pass declares every
      `SUB` from its header, so a call may come before its `SUB`. A body that reaches its end
      returns 0 from a `SUB` with a value. Arguments with a `(` in them are pushed and popped
      into the parameters just before the `JSR`.
   4. arrays, strings, `INPUT`, `GETKEY`, in three parts:
      1. 4.4a: arrays, `GETKEY()`, `ERRORS ON`/`ERRORS OFF` (done 2026-10-09:
         tpl/T-ARRAY.ASM). An array is `DIM B(10)`, elements 0 to 9, BYTE or WORD. The
         arrays sit after the program, outside the file, and the startup code clears them. A
         constant index is checked at compile time. Any other index is checked at run time,
         except under `ERRORS OFF`.
      2. 4.4b: strings (done 2026-10-10: tpl/T-STRING.ASM, tpl/R-STRING.ASM). A string is a
         `[max][len][data]` block in BSS. All six compares, `+`, `LEN`, `ASC`, `CHR$`. A
         STRING parameter is passed by reference. A SUB that returns a STRING is done
         2026-10-10 (test STRRET). Not done: string arrays, a start value.
      3. 4.4c: `INPUT`, `LINPUT` (done 2026-10-10: R_INPUT in tpl/R-STRING.ASM). From the
         keyboard only. `INPUT "prompt"; a, b$` prints "? ", and fields split at commas.
         `LINPUT` takes a whole line. Not done: an array element as the variable.
   5. file commands
      1. 4.5a: `OPEN`, `CLOSE`, `PRINT #`, `NOFILE` (done 2026-10-10: R_FILE in
         tpl/R-FILE.ASM). The mode must be `O.READ`, `O.WRITE` or `O.APPEND`, written as
         the argument. In `PRINT #`, a comma writes ",". Unit 8 only.
      2. 4.5b: `LINPUT #`, `INPUT #`, `EOF` (done 2026-10-10: R_FIN in tpl/R-FILE.ASM, a
         one-byte read-ahead per handle). Handles 0–2 cannot be read in v1.
      3. 4.5c: `READ`, `WRITE` (done 2026-10-10: R_FREAD and R_FWRITE in tpl/R-FILE.ASM).
         The address is any WORD expression. Bytes move as they are.
      4. 4.5d: `DIR` (put off by the user, 2026-10-10: it may become code in a `DIR`
         namespace rather than a statement).
   6. `SYS`, `ASM`, in two parts:
      1. 4.6a: `ASM` (done 2026-10-10: src/UXC-ASM.BL in bank 22). `ASM $A9, 65` puts the
         bytes in on one line. `ASM` alone opens a block that `END ASM` or `ENDASM` closes,
         with a list of items on each line. An item is a constant or `@name`: 0–255 is one
         byte, 256–65535 and `@name` are two, low byte first. `@name ± constant` is folded to
         an address everywhere. The code must keep X.
      2. 4.6b: `SYS` (done 2026-10-10: R_SYS in tpl/SYS.ASM, AS.SYS in bank 22). The
         address is any WORD expression. A, X, Y and P pass through `$030C`–`$030F`, P
         with `AND #$F3`. SYS keeps the program's X.
   7. names for memory, in three parts:
      1. 4.7a: BYTE by default (done 2026-10-10: tests TYPEDEF and ERRBANG). The `!` mark is
         gone. A name, a parameter or an array with no mark and no `AS` is a BYTE. A `SUB`
         name with neither still returns no value. `NO TYPE FOR name` is gone.
      2. 4.7b: `DIM ... AT` (done 2026-10-10: NM.AT in src/UXC-NAME.BL, flag K.SY.FIXED;
         tests DIMAT, ERRATCONST and ERRATKIND). `DIM REG_P AT $030F` puts a BYTE or WORD
         variable at a fixed address. The address is a constant expression. The variable
         takes no space, and each access is an absolute load or store in section
         K.SEC.CONST. Not done: an array or a string at an address, `DIM ... AT ZP`.
      3. 4.7c: pointers by name (user; done 2026-10-10: EX.ADDROF, EX.PEEK and SM.CONTENTS;
         tests POINTER, ERRADDROF and ERRCONTENTS). `AddrOf(name)` is `@name`, and `@name`
         stays. `ContentsAt(a)` reads the BYTE at `a`, as `PEEK(a)` does, and
         `ContentsAt(a) = v` writes it, as `POKE a, v` does. `ContentsAtW(a)` reads and
         writes a WORD with T_PEEKW and T_POKEW. A constant address or `AddrOf(name)` is one
         load or store. `PEEK` and `POKE` stay. This replaces the to-do item `MEM` and
         `MEMW`.
5. **UXCEDIT compile relay** for UXCBASIC (decided by the user, 2026-10-10). Done on
   2026-10-10, in four parts:
   1. 5a: the user disk (done 2026-10-10: `publish` in build.py, `run.py --disk`). The folder
      `disk/` holds what a real user sees. After the builds, `build.py` copies each program
      built there, its PRG and its OVL, with the files it reads at run time: `UXC.TPL.BIN`
      for UXC, `UXCEDIT.KEYS.BIN` for UXCEDIT, `HELP-TXT/` and `EXAMPLES/` for UXC.HELP.
      `GPC.RT.133.BIN`, `GPB.RT.133.BIN` and `GP1.RT.133.BIN` go to `disk/GPC/`. A `.UXB`
      sample in `examples/` or `samples/` is copied only when `disk/` has no file of that
      name. A build deletes nothing in `disk/`. `RUNEDIT.BAT`, `RUNUXC.BAT` and
      `RUNHELP.BAT` run from `disk/` with `run.py NAME --disk --window`. Builds and tests
      still use `build/`. The headless log of `run.py --disk` is `build/RUN.LOG`.
   2. 5b: UXC chains (done 2026-10-10: UI.CHAIN in src/UXC.BASL; test CHAIN, with
      `tests/CHAIN.NEXT`). `UXC.INPUT` gains an optional line 3: the program to load next.
      UXC loads it after it writes the result line, on `OK` and on `ERROR`. With no line 3
      UXC ENDs as before. In `tests/`, a `NAME.NEXT` file names line 3, and the test
      compares the output of the program loaded.
   3. 5c: F5 in the editor compiles the active document (done 2026-10-10: TURBO.BUILD and
      TURBO.BUILD.HOP in src/UXCEDIT/UXCEDIT.BASL; Build, Compile on the menu). It saves the
      modified documents. F5 on an Untitled document asks for a name first. A save that
      does not happen stops the build on its document. It then deletes `UXC.RESULT`, writes
      `UXC.INPUT` (the source, `UXC.RESULT`, `UXCEDIT.PRG`) and `UXCEDIT.RUN`, and loads
      `UXC.PRG`. `UXCEDIT.RUN` holds the number of the active document, 0 to 2, then six
      lines for each document: its name, `ASCII` or `PETSCII`, its cursor line, cursor
      column, top line and left column. An Untitled document has an empty name line.
      - Open question: the hop loads `UXC.PRG` from the current directory. After the file
        picker moves into a subdirectory, the load fails.
   4. 5d: the editor start (done 2026-10-10: TURBO.RESUME and TURBO.RESULT.SHOW in
      src/UXCEDIT/UXCEDIT.BASL; help topic "Compiling from UXCEDIT"). When `UXCEDIT.RUN`
      exists, the editor reopens the documents, reads `UXC.RESULT` and deletes
      `UXCEDIT.RUN`. On `ERROR` it puts the cursor on the line and shows a message box
      titled "Compile error" with `Line N` and the message. On `OK` it shows a message box
      titled "Compiled" with the PRG name and its size in bytes. With no `UXC.RESULT` the
      box says "Compile gave no result". The result line splits at its first two commas
      only. The message may hold commas.
   - The hop: a program clears the screen, prints `LOAD"NAME.PRG",8,1` on the third row,
     and homes the cursor. It puts Return, `RUN:` and Return into the key buffer with
     `kbdbuf_put` through `GP.CALL`, with ROM bank 0, and ends. `READY.` lands on the
     second row, so the first Return runs the LOAD line. `RUN:` is typed after the LOAD's
     `READY.`. It needs no asm.
   - A crash inside UXC writes no result and loads nothing. The user is left at `READY`.
   - Not in v1: running the compiled program. See **Back to the editor** in section 5.
6. **Self-host:** rewrite the compiler in UXCBASIC, and check that it builds itself
   byte-for-byte.
7. **Later:** a small line assembler inside the compiler. It would allow mnemonics in `ASM`
   blocks, and template edits on the X16 with no host.

## 5. Open points

Settled on 2026-10-09:
- `SUB`/`ENDSUB` is the one subroutine keyword. A value-returning `SUB` has a mark or `AS`:
  `SUB FOO%()`, `SUB FOO() AS BYTE`. With neither it returns no value.
- Types by mark (`%` WORD, `$` STRING) or by `AS`. A name with neither is a BYTE (decided
  2026-10-10, step 4.7a). `DIM` and `VAR` are both valid, with several names per line.
- Strings are Pascal style, `[max][len][data]`. Strings and arrays are passed to a `SUB` as
  pointers.
- File I/O uses Unix-style handles. `READST` is gone. Modes and results are built-in constants.
- `FOR` ends when the counter passes `TO`.
- The mark is part of the name. A name declared with `AS` has no mark.
- Every variable must be declared.
- `DIM B(10)` makes 10 elements, 0–9.
- v1 string operations as listed under **Strings**.
- A signed `INT` type comes later, not in v1.
- File modes are the built-in names `O.READ`, `O.WRITE` and `O.APPEND`. `OPEN` returns
  `NOFILE` ($FFFF) on failure.
- The line forms `PRINT #`, `INPUT #`, `LINPUT #` and `EOF` sit beside `READ` and `WRITE`.
- `LINPUT` ends a line at CR, LF or CR LF.
- No character literal. `ASC("A")` is folded at compile time.
- Whole-line comments: `REM`, `'`, `;`, `##`, `//`. Trailing comments: `REM` and `'` only.
- `PRINT` spacing and commas follow MS BASIC (decided 2026-10-09).
- Truth is 0 or nonzero; `NOT` is logical; `AND`/`OR`/`XOR` are bitwise (option C, decided
  2026-10-09).
- Run-time errors: division by zero always stops the program; `ERRORS ON`/`ERRORS OFF` switch
  the inline checks at compile time, default on (decided 2026-10-09).
- Loops (decided 2026-10-09, built in step 4.2):
  - `DO [WHILE|UNTIL c]` ... `LOOP [WHILE|UNTIL c]`. The test can be at the top, at the bottom,
    or absent (a loop that runs until `EXIT DO`). There is no `WHILE` ... `WEND` (dropped
    2026-10-09): it is the same loop as `DO WHILE c` ... `LOOP` with the same code, so it gave
    only a second spelling. A top test is compiled at the bottom (one `JMP` to the test on entry), so a top test and a
    bottom test cost the same per pass.
  - `FOR v = a TO b [STEP k]` ... `NEXT [v]`. `STEP` must be a constant. The body runs zero
    times when the range is empty (as in Prog8, not MS BASIC). The end test is done before the
    step, so `FOR I = 0 TO 255` stops and does not wrap.
  - `REPEAT n` ... `END REPEAT` runs the body n times with a hidden counter that counts down;
    `n` = 0 runs zero times. `REPEAT` with no count runs until `EXIT REPEAT`. `REPEAT` ...
    `UNTIL c` (the BBC BASIC form) is not accepted, so BBC code fails to compile instead of
    meaning something else. There is no
    loop variable, so it is the cheapest counted loop (about 8 cycles of overhead per pass
    against about 15 for a `BYTE` `FOR`). Each nesting level needs its own hidden counter; `X`
    cannot be the counter because it is the expression-stack pointer.
  - `EXIT DO`, `EXIT FOR`, `EXIT REPEAT` leave the named loop. `CONTINUE` jumps to
    the test (or the step) of the innermost loop.
  - No `unroll`.

To do, not designed yet:
- **ASCII, not PETSCII** (user, 2026-10-09). The language, the compiler and the compiled
  programs use ASCII and depend on no PETSCII: source text, string literals, `CHR$` and `ASC`,
  `PRINT` and the key codes `GETKEY()` returns. On the X16 a program runs in CP437:
  - At startup the program sends `$0F` to `CHROUT`, which turns on ISO mode. `CHROUT` then
    writes each byte as its own screen code, and `GETIN` returns ASCII.
  - It then calls `screen_set_charset` (`$FF62`) with A = 7, which loads the CP437 font over
    the ISO font. CP437 needs ROM R47 or later.
  - Before the switch, startup keeps the byte at `$0372`. Its low 6 bits are the active
    charset number, and bit 6 is set in ISO mode. It is not documented, and APPHELP in the
    Blitz compiler relies on it.
  - Every exit puts the screen back: `END`, the end of the program, and a run-time error
    after its message. The exit calls `screen_set_charset` with the kept byte AND 63, then
    stores the whole kept byte to `$0372`. `screen_set_charset` alone leaves bit 6 set.
  - When the kept mode is not ISO, the exit first converts every code on the screen to the
    PETSCII screen code of the same character, for the kept charset, so the text stays
    readable. Upper/graph shows lower case as upper case.
  - This code sits in `tpl/SYS.ASM` and is marked CBM only. The new workstation has no CBM
    mode, and the code is removed there.
  - In ISO mode the codes `$00–$1F` and `$80–$9F` are controls, so `PRINT` cannot show the
    CP437 glyphs at those codes.
  - The tests read the `CHROUT` echo, so `run.py` and `uxc.py` run x16emu with `-echo iso`.
  - Still to decide: whether the compiler and UXCEDIT switch too.
- **Back to the editor.** A key at `READY` that reloads UXCEDIT after the user tests a PRG.
  It is a key not pressed by chance, for example Ctrl+Shift+F5. Not established: whether the
  KERNAL lets a program reprogram such a key.
- **Passing variables between programs.** A built-in, standard way for one UXCBASIC program to
  hand variables to another UXCBASIC program through a banked RAM area, for example when one
  program loads and runs the next. It is part of the language, not a library convention.
  Still to decide: the bank and layout, how a program names what it shares, and how a type or
  size mismatch is caught.
- **Removing unused code** (user, 2026-10-09). By default the compiler leaves out code the
  program never uses: run-time routines nothing calls, `SUB`s and `FUNCTION`s nothing calls,
  and code that can never be reached. A compile-time instruction keeps a named section anyway,
  for example a routine that only another program or a `SYS` call reaches. Still to decide:
  the syntax of the keep instruction, what a section is (a routine, a block of lines, or a
  whole file), and whether the compiler reports what it removed and the bytes saved.
  - It comes before any library of include files (user, 2026-10-10). Without it every `SUB`
    in an included file is compiled into every PRG, called or not.
- **Removing unused variables** (user, 2026-10-09). The compiler gives no address to a
  variable or array that nothing reads or writes. This saves RAM, not PRG bytes, because
  variables sit after the program. The compiler warns `UNUSED VARIABLE name`.
  - A variable is always kept when it is `DIM ... AT`, when `@name` is taken, or when a `BIND`
    in use names it.
  - An address is now set at the `DIM`. Stripping needs the use count first, from a prescan
    pass, or addresses set at the end with fixups.
  - Still to decide: whether a variable that is written and never read loses its stores too.
    Only a plain variable could, because a store to an `AT` variable has a side effect.
- **Debugging** (user, 2026-10-09). Three parts, built in this order.
  - **Map file.** The compiler writes `PROG.MAP`, with the address of each source line and
    each name. It costs nothing at run time. A run-time error such as
    `?BAD SUBSCRIPT ERROR AT $0A3F` is looked up there to find the line. Box16 can load the
    names into its debugger.
  - **`STOP`.** It compiles to `BRK`, which enters the X16 monitor to show the registers and
    memory. It costs 1 byte.
  - **`DEBUG ON` and `DEBUG OFF`.** They work as `ERRORS ON` and `OFF` do: the switch follows
    the source, not the run. Code inside a `DEBUG ON` region stores the line number before
    each statement, about 8 bytes a line, so a run-time error reports `AT LINE n`.
    `ASSERT condition` stops the program when the condition is false. `TRACE` prints each
    line number as it runs. Outside a `DEBUG ON` region, `ASSERT` and `TRACE` compile to
    nothing.

    ```
    DEBUG ON
    FOR I = 0 TO 9
      ASSERT I < 10
      B(I) = I
    NEXT
    DEBUG OFF
    ```

  - Still to decide: the map file format, whether `DEBUG` is a `#DEFINE UXC.*` option as well,
    and the text of an `ASSERT` failure.
- **Code for a set memory address, as in Prog8** (user, 2026-10-09). Prog8 has `%address`,
  `%output raw|prg` and `%launcher none`, and lets a variable sit at a fixed address
  (`&ubyte border = $d020`). Here `UXC.ORG` and `UXC.NOSTUB` already set the start and drop
  the `SYS` line. `DIM BORDER AT $9F2C` puts a BYTE or WORD variable at a fixed address
  (step 4.7b). Still to decide: a raw output with no load address; a separate address for
  the variables (for code in ROM or in a banked window at `$A000`); arrays and strings at a
  fixed address; and how the compiler checks that the program fits below its top.
- **Variables in zero page** (user, 2026-10-09). `DIM I AT ZP` puts a variable in the free
  zero page at `$50–$7F`, for smaller and faster code. The compiler stops with an error when
  that area is full. This replaces Prog8's `%zeropage` modes: the runtime keeps to `$22–$7F`,
  so every program can return to BASIC. Still to decide: whether `@` of a zero-page variable
  is allowed, whether arrays and strings may go there, and how this shares `$50–$7F` with
  `ASM` and `POKE`.
- **Split WORD arrays, as in Prog8** (user, 2026-10-09). Prog8's `splitarrays` keeps a
  `WORD` array as two byte arrays, the low bytes then the high bytes. The index is used as it
  is, with no doubling, so an element is read with `LDA lo,Y` and `LDA hi,Y`. Such an array
  has at most 256 elements. Still to decide: whether it is the default or an option, and what
  `@name` gives for a split array.
- **`ENUM`** (user, 2026-10-09; numbering done 2026-10-11: NM.ENUM in src/UXC-NAME.BL, tests
  ENUM and ERRENUMOPEN). An `ENUM` is a namespace whose lines are constants, numbered from 0.

  ```
  ENUM STATE
    READY            ' 0
    RUNNING          ' 1
    BLOCKED = 10     ' 10, and the count goes on from here
    DONE             ' 11
  END ENUM
  IF S = STATE.BLOCKED THEN PRINT "WAIT"
  ```

  - A member is a constant and folds into the code as an immediate operand. An `ENUM` takes no
    RAM and no bytes in the PRG.
  - A line may hold several members separated by commas: `RED, GREEN, BLUE`.
  - `= value` sets a member's number. The members after it count on from it.
  - The members are `BYTE` when every value fits in 0 to 255. When one passes 255, the `ENUM`
    and every member become `WORD`.
  - Inside the `ENUM` a member is used bare. Outside it is qualified: `STATE.READY`.
  - `ENDENUM` is the same as `END ENUM`.
  - A member is a `CONST` record.
  - Typed enum parameters and variables (user, 2026-10-11): `SUB FOO(N AS ESTATE)` and
    `DIM S AS ESTATE`. The value is a `BYTE` or `WORD`, as for the members. A constant passed
    to it must be a member of that `ENUM`. A member's record owner (+25) names its `ENUM`, and
    the check reads that owner. A member of another `ENUM` is a compile error. A plain variable
    passes unchecked. No check runs in the program, so it costs no bytes.
  - Bare members in an argument (user, 2026-10-11). When an argument expects an `ENUM`, a bare
    name is looked for in that `ENUM` first, then as usual. The compiler gives its built-ins
    their own `ENUM`s the same way: `POS(POS.COL)`, `POS(COL)` and `POS(0)` all work.
    `EX.POS.AXIS` then takes any constant 0 or 1.
  - The order: `CONST`, then `ENUM` numbering, then `AS` enum, then bare members.
- **`CONST`** (user, 2026-10-09; done 2026-10-11: NM.CONST in src/UXC-NAME.BL, tests CONST
  and ERRCONSTBIG). A constant kind in the symbol table, which the expression parser folds as
  it does a number. See "Options and constants" in section 1. `NM.BODY` allows `CONST` in a
  namespace body.
- **`SHL`, `SHR`, `ROL` and `ROR`** (user, 2026-10-09). `<<` and `>>` exist. `SHL` and `SHR`
  are the same operators as words. `ROL` and `ROR` rotate within the left side's type, 8 bits
  for a `BYTE` and 16 for a `WORD`: the bits that leave one end come in at the other. All four
  have the precedence of `<<` and `>>`.

  ```
  B = $81 ROL 1      ' $03
  B = $81 ROR 1      ' $C0
  W% = 1 SHL 15      ' $8000
  ```

- **`ON IRQ CALL name`** (user, 2026-10-09). Runs a `SUB` on each interrupt, such as a
  timer. Still to decide: the whole design. Known problems: the handler shares the runtime zero
  page `$22–$4F` with the main program and must save it, and a `SUB` has no stack frame, so
  the handler and the main program must not use the same `SUB`s. A call from the interrupt is
  not in the call graph, so it breaks the shared temps and locals.
  - XC=BASIC 3 has interrupts; review its code before the design (user, 2026-10-10). It is in
    `C:\dev\XCbasic\xcb-ext\xc-basic3-3.2.0-beta`: the runtime in `lib/irq/irq.asm` and
    `lib/irq/_x16.asm`, the compiler side in `source/statement/irq_stmt.d` and
    `source/statement/on_stmt.d`.

  ```
  SUB TIMERHANDLER()
    TICKS% = TICKS% + 1
  ENDSUB
  ON IRQ CALL TIMERHANDLER
  ```

- **Hardware registers as variables** (user, 2026-10-09; `DIM ... AT` done 2026-10-10, step
  4.7b). `VERA_DATA0 = 65` in place of `POKE $9F23, 65`. A store compiles to `LDA #65`,
  `STA $9F23`.

  ```
  DIM VERA_DATA0 AT $9F23
  VERA_DATA0 = 65
  ```

  - The X16 names live in header files that ship with UXC, not in the compiler: `X16.UXH`,
    split by part if the symbol table needs it. Each holds a `NAMESPACE X16` of `DIM ... AT`
    and `CONST` lines. A program that does not `#INCLUDE` a header pays nothing. The header
    waits for `CONST`; `#INCLUDE` is built.
  - The virtual registers are words: `DIM R0% AT $02` through `DIM R15% AT $20`. A variable
    at a zero-page address is still reached with absolute addressing, 3 bytes an access.
  - Every name takes a 32-byte symbol record at compile time. About 115 fit in bank 22.

- **CPU registers as variables** (user, 2026-10-09; `SYS` done 2026-10-10, test SYS1;
  `DIM ... AT` done 2026-10-10, test DIMAT). `SYS` works as X16 ROM BASIC does. It loads A,
  X, Y and P from `$030C`–`$030F` before the `JSR`, and stores them there after it. A
  program names the four bytes with `DIM ... AT`, and the header is to hold the line:

  ```
  DIM REG_A AT $030C, REG_X AT $030D, REG_Y AT $030E, REG_P AT $030F
  ```

  The carry is bit 0 of `REG_P`. The KERNAL sets it on an error, and some calls read it
  as an input. `PLOT` with the carry set reads the cursor:

  ```
  REG_P = REG_P OR 1
  SYS $FFF0
  PRINT REG_X, REG_Y
  REG_P = REG_P AND $FE
  SYS $FFC0
  IF REG_P AND 1 THEN PRINT "OPEN FAILED"
  ```

  - `SYS` loads P with `AND #$F3`, so a stray D or I bit cannot reach the call.
  - The four bytes are not cleared when the program starts. Set what the call reads.
  - The header is to add `CONST C_FLAG = 1`, `Z_FLAG = 2`, `V_FLAG = 64`, `N_FLAG = 128`.
  - Each `SYS` is 7 bytes: the address in A/Y and `jsr R_SYS`. R_SYS, 43 bytes in
    `tpl/SYS.ASM`, is linked once. It calls through `jmp (ZP_PTR)` and keeps X with
    `phx`/`plx`.
- **Namespaces and `BIND`** (user, 2026-10-09; done 2026-10-09: src/UXC-NAME.BL in bank 22,
  tests NS1, NS2 and five error tests). `NAMESPACE name ... END NAMESPACE` groups
  names. Inside it a name is used bare; outside it is qualified with a dot.

  ```
  NAMESPACE GFX
    DIM COLOR
    SUB PLOT(X%, Y)
      POKE $9F20, COLOR
    ENDSUB
  END NAMESPACE
  GFX.COLOR = 5
  GFX.PLOT(10, 20)
  ```

  - A namespace may hold namespaces. A `SUB` may not hold a `SUB`.
  - A namespace body holds only `DIM`, `VAR`, `CONST`, `SUB` and `BIND`, and no statements
    that run.
  - A `SUB`'s own names are local to it. Outside the `SUB`, `SHOW.N` stops the compile with
    `LOCAL TO A SUB: SHOW.N`.
  - `UXC` is a reserved namespace, for the `#DEFINE UXC.*` options.
  - A name is found in the `SUB`, then in each enclosing namespace, then in the main program.
  - `BIND` gives another name to a variable, a `SUB` or a namespace. It costs nothing at run
    time. The new name carries the same mark as the target. A `BIND` belongs to the scope it
    is written in.

    ```
    BIND G = GFX
    BIND P = GFX.PLOT
    BIND C = GFX.COLOR
    ```

  - In the symbol table a namespace is a new kind, and its owner is its parent. A record keeps
    only the last part of its name, so the 16-character limit is per part. `NM.FIND` splits a
    used name, walks the owners and follows `BIND`s. A declaration checks for a duplicate in
    its own scope only, with `SY.FIND`.
  - The first pass makes the namespace records too, so a `SUB` header is declared in its
    namespace. A `NAMESPACE` that names an existing namespace reopens it.
  - A dot always separates scopes, as in Prog8. A name is a letter, then letters, digits and
    `_`, then an optional mark. `MY_COUNT_2` is one name; `MY.COUNT.2` is three.
  - The first part of a qualified name is found as a bare name is: in the `SUB`, then in each
    enclosing namespace, then in the main program. Inside `GFX`, `PLOT` and `GFX.PLOT` are
    the same.
- **More types, as in XC=BASIC** (user, 2026-10-09). XC=BASIC 3 has `BYTE`, `INT` (signed,
  16 bits), `WORD`, `LONG` (signed, 24 bits), `FLOAT`, `DECIMAL` (BCD, 4 digits) and `STRING`,
  and record types with `TYPE ... END TYPE`. UXCBASIC has `BYTE`, `WORD` and `STRING`. Still to
  decide: which of these types to add, and in what order; their marks and `AS` names; how a
  signed and an unsigned operand mix; whether `FLOAT` uses the X16's ROM math or its own code;
  and whether record types are part of it.
- **A `BOOL` type, as in Prog8** (user, 2026-10-09: is it needed, what does it cost, is it
  worth it). Prog8's `bool` is one byte that holds only 0 or 1; it is not packed into bits.
  What it would give here: `AND`/`OR`/`NOT` on two `BOOL`s are exact logic with no `1 AND 2`
  trap, and `IF F` is `LDA F / BNE`. A BYTE that holds a compare already gives the same code,
  so the gain is safety more than speed. Cost: a type (`AS BOOL`, maybe a mark), and when a
  value that is not a compare is stored in a `BOOL`, about 7 bytes to make it 0 or 1. Bit
  flags packed 8 to a byte save RAM but cost an `AND #mask` or a read-modify-write on every
  use. Dropped (user, 2026-10-09): not worth it.
- **A faster number-to-text routine, as in Prog8** (user, 2026-10-09: review later). Prog8's
  `conv.str_uw` (`internal_uword2decimal` in `compiler/res/prog8lib/`) uses tables and is
  tuned for speed, so it is bigger than `R_PRWORD` and `R_STR`. Still to decide: whether the
  speed is worth the bytes.
- **An immediate `IIF`** (user, 2026-10-10). `IIF(c, a, b)` gives `a` when `c` is true and `b`
  otherwise, as in `PRINT IIF(N% = 1, "ITEM", "ITEMS")`. It compiles inline to a test and two
  branches, with no call, and only the chosen side runs. Still to decide: whether `a` and `b`
  may be strings, and whether a constant `c` is folded at compile time.
- **Overloaded `SUB`s** (user, 2026-10-10). Two `SUB`s may share a name when their parameter
  types differ, as in `SUB PRINT_NUM(V AS WORD)` and `SUB PRINT_NUM(V AS STRING)`. The compiler
  picks one by the argument types at compile time, so a call is the same `JSR` as a call to a
  `SUB` with its own name, and costs nothing at run time. Separate names such as `PRINT_UW` and
  `PRINT_S` give the same code, so this is for the source only. It needs the parameter types in
  the symbol table's name for the `SUB`, and the call must parse an argument before it can
  choose the `SUB`, where today each argument is converted to its parameter's type as it is
  parsed. Rejected: an `AS ANY` parameter with a run-time type tag, which costs about 5 bytes
  and 6 cycles a call and a dispatch on each use.
- **`BIND` to a statement** (user, 2026-10-10). `BIND` gives a name to a statement, and each use
  of the name compiles that statement in its place. It is a macro with no parameters, and it
  costs nothing at run time: `CONSOLE.NL()` is the same code as `PRINT`.

  ```
  NAMESPACE CONSOLE
    BIND NL() PRINT
    BIND SPC() PRINT " ";
  END NAMESPACE
  CONSOLE.NL()
  ```

  - A one-statement wrapper as a `SUB` costs a `JSR` per call, an `RTS` and about 12 cycles a
    call. A `SUB` pays only when its body is bigger than a call.
  - Still to decide: whether a bound statement may take parameters, whether it may hold more
    than one statement, and how an error inside it reports its line.
- **`BIND` to a keyword** (user, 2026-10-10). When the target of `BIND` is a statement keyword,
  the bound name becomes that keyword. The arguments come from the line where the name is used,
  and the rest of the line is parsed as for the keyword. It costs nothing at run time, and the
  editor lists the name with the other members of its namespace.

  ```
  NAMESPACE CONSOLE
    BIND PRINT = PRINT
    BIND INPUT = INPUT
  END NAMESPACE
  CONSOLE.PRINT "HI"; X
  BIND PRT = PRINT
  PRT X
  ```

  - A reserved word as the target makes a keyword alias. No modifier is needed.
  - The statement parser looks up the name and jumps to the keyword's handler.
  - Statements only. A function keyword such as `LEN` is not a target.
  - An error reports the keyword: an error in `CONSOLE.PRINT` reports as in `PRINT`.
  - `BIND NL() PRINT` binds a whole statement. `BIND PRT = PRINT` binds only the keyword.
- **Benchmark suite** (user, 2026-10-10). A fixed set of standard programs, compiled and run
  the same way each time, as Prog8 keeps one. The suite measures the code size of each PRG and
  its run time.

  - It shows whether a change to the compiler or a template makes programs smaller or faster.
  - It compares UXCBASIC with other X16 compilers on the same programs.
  - Candidate programs, not yet chosen: a prime sieve, Mandelbrot in fixed point, N queens, a
    CRC, string building.
  - Still to decide: which programs, how run time is measured (the jiffy clock `TI` in the
    program, or a cycle count from the emulator), and whether the suite runs in `tests.py` or
    in its own script.
- **Banked code that calls banked code** (user, 2026-10-10). A compiled program can put code
  in banked RAM at `$A000`, and code in one bank can call code in another bank.

  - The call saves the current bank, switches to the target bank, calls, and restores the
    bank on return.
  - Review how GPC does this first. The compiler itself already runs from banks 20–22 in
    UXC.OVL through GPC's banked regions.
  - Still to decide: the syntax that puts a `SUB` in a bank, the cost of a cross-bank call in
    bytes and cycles, and whether a call within the same bank skips the switch.
- **`INSTRREV`** (user, 2026-10-10). `INSTRREV(S$, F$)` gives the position of the last `F$`
  in `S$`, or 0 when there is none. It searches from the end, where `INSTR` searches from the
  start.

  - It is a built-in beside `INSTR`, as in §1 "Strings".
  - `INSTR(S$, F$[, START])` is done (2026-10-11): a built-in, SG.INSTR in src/UXC-STR.BL
    and R_INSTR in tpl/R-STRING.ASM, test INSTR. Without a start it searches from 1.
  - Still to decide: whether it takes a start position, as `INSTR` does, and what an empty `F$`
    gives.
- **A compile report** (user, 2026-10-10). A good compile reports more than the PRG name and
  size: the number of variables of each type, and the bytes of each part of memory.

  - Candidate lines: BYTE, WORD and STRING variables and arrays, with their bytes; the
    string temps; the code, the string literals and the runtime routines linked; the array
    and string space, which is the program's only heap; the end address against `$9F00`.
  - It goes in `UXC.RESULT` after the result line, so UXCEDIT can show it, and on the screen
    when UXC runs alone.
  - Still to decide: which lines, and whether the `.LST` carries the same table.
- **Shared temps and locals** (user, 2026-10-10; temps done 2026-10-10: SB.POOLS in
  src/UXC-SUB.BL, test TEMPPOOL; locals done 2026-10-10: SB.PLACE.VARIABLE, SB.PLACE.BLOCK
  and SB.POOLS in src/UXC-SUB.BL, test LOCALPOOL). Two `SUB`s that are never active at once
  can use the same bytes.

  - Temps: the link step gives each `SUB` a level in the call graph, at least 1 and 1 more
    than the level of each `SUB` that calls it. The main program has level 0 and a pool of
    its own. The string temps, 257 bytes each, of all `SUB`s of one level share one pool, as
    big as the most any of them needs. The pools sit after the array space.
  - A call the graph cannot see, through a pointer or `SYS`, breaks the sharing. No such call
    exists today.
  - Locals: a `SUB`'s parameters, its `DIM`s (BYTE and WORD variables, arrays and strings)
    and its hidden words are locals in the `SUB`'s frame. The frames of all `SUB`s of one
    level share that level's pool with the level's temps: the frames below the pool's
    offset, the temps from it up. The main program's variables stay static.
  - A local does not keep its value between calls (the user's choice). A BYTE or WORD local,
    or an array, starts undefined: the program sets it before it reads it. A string local is
    set empty, length 0 with its max set, each time its `DIM` line runs.
  - Only the `SUB` itself can name its locals (the user's choice). `PRINT SHOW.SEEN` in the
    main program stops the compile with `LOCAL TO A SUB: SHOW.SEEN`. Test ERRSUBLOCAL.
  - A frame holds at most 16384 bytes. Past that the compile stops with `LOCALS TOO BIG` at
    the `DIM` line. Test ERRSUBLOCALS.
- **`FRE`** (user, 2026-10-10). A function in the style of `FRE(0)` reports free memory while
  the program runs.

  - A program has no heap, so the free low RAM is fixed at link time: from the end of the
    array and string space to `$9F00`.
  - Still to decide: the arguments, for example `FRE(0)` for low RAM and another value for
    the free banks; whether the value is a constant the linker folds in; and how it fits the
    compile report above.
- **UXCEDIT bug: Caps Lock breaks the Ctrl keys** (user, 2026-10-10). With Caps Lock on, the
  Ctrl key commands in UXCEDIT fail. XFMGR has the fix for the same bug; port it from there.
- **`CONSOLE.LINPUT2`** (user, 2026-10-10). A line input in the `CONSOLE` namespace with more
  editing than `LINPUT L$`, which uses the KERNAL screen editor.
  - It is a library `SUB`, so a program that does not call it does not carry it.
  - Still to decide: the editing keys, whether it takes a starting text and a maximum
    length, and how it handles a line longer than the screen row.
- **Mnemonics in `ASM`** (user, 2026-10-11; done 2026-10-11: src/UXC-ASM.BL in its own region,
  bank 24, tests ASM2 and ERRASMLABEL). An `ASM` block takes 65C02 instructions as well as
  byte items, as GPC's `GP.ASM` does.

  ```
  ASM
      ldy #0
  next: lda (PTR),y
      beq done
      jsr $FFD2
      iny
      bne next
  done:
  END ASM
  ```

  - A line whose first word is a mnemonic is an instruction. Any other line is byte items,
    as now, so the existing programs still compile.
  - All 65C02 mnemonics and addressing modes: `#n`, `n`, `n,X`, `n,Y`, `(n)`, `(n,X)`,
    `(n),Y`, `A` and the branches. An operand is a constant expression, `@name` or
    `AddrOf(name)`.
  - A label is `name:` at the start of a line. Labels belong to their block. A branch to a
    label further down is patched at `END ASM`. A branch out of range stops the compile.
  - A constant below 256 takes the zero-page form when the instruction has one. `@name` is
    resolved at link time, so it always takes the absolute form.
  - `AND`, `ORA`, `EOR` and `ROR` are read as mnemonics, not as operators, inside a block.
  - The code must keep X, which indexes the expression stack.
  - `#<n` and `#>n` are the low and the high byte. `#<@name` and `#>@name` are K.F.LO and
    K.F.HI fixups.
  - JMP and JSR take a label when the operand is a name alone.
  - A block holds 32 labels and 32 uses of a label further down.
  - Cost: about 3.3 KB of compiler in bank 24, and 102 bytes of low memory for the label
    arrays. Nothing at run time.
  - The `@name` of a `DIM ... AT` below 256 takes the zero-page form. Any other `@name` takes
    the absolute form.
  - Still to decide: whether a block may name a `SUB` parameter or local. `@name` of one goes
    through the frame fixup today, untested.
- **`FILE.SEEK`** (user, 2026-10-11). Moves the read or write position of an open file.

  - CMDR-DOS takes `P`, the secondary address, then the position as 4 bytes, low byte
    first, on the command channel. The secondary address of a handle is the handle.
  - R_FIN holds the next byte of each handle in `ahead`. A seek empties it.
  - Still to decide: a built-in or a `SUB` in `lib/DISK_FILEIO.UXI`; the type of the
    position, since a WORD stops at 65,535; and how a seek past the end reports.
