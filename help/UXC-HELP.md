# Getting started

## What UXCBASIC is

UXCBASIC is a small compiled BASIC for the system programs and utilities of the
Unix-style X16. The compiler, UXC, turns one source file into a native 65C02 PRG.
UXCEDIT is the editor.

This help is a skeleton. Each topic is written when its command is built.

See [[Using this help]], [[Types]] and [[Compiling from UXCEDIT]].

## Using this help

Up and down move through the index. RETURN opens a topic. ESC goes back one link,
then to the index, then quits.

- / or F finds a word in the index, and N finds the next match.
- L lists a topic's cross references.
- X writes a topic's code lines out as a .UXB file.
- T changes the theme, and ? shows the about box.

The content is built on the PC by help/MKHELP.PY from help/UXC-HELP.md.

# The language

## Types

A name's type comes from its mark or from AS. A name with neither is a BYTE.

```
DIM C, N%, L$ * 80
VAR B AS BYTE, W AS WORD, T AS STRING * 20
```

### The marks

- No mark is BYTE, 0 to 255. AS BYTE is the same.
- % is WORD, 0 to 65535. AS WORD is the same.
- $ is STRING. AS STRING is the same. A STRING needs a size.
- Every number is unsigned.
- A mark and AS on one name stop the compile with A MARK AND AS.
- ! is not a mark. DIM A! stops the compile with SYNTAX ERROR.

### Names

A name is a letter, then letters, digits and _, 16 at most, then its mark, if
it has one. The mark is part of the name: A, A% and A$ are three names. A name
declared with AS has no mark, so after VAR W AS WORD the name is W.
Upper and lower case are the same, so my_count and MY_COUNT are one name. A
dot joins the parts of a qualified name: GFX.COLOR is COLOR in namespace GFX.

See [[Declarations]], [[Strings]], [[Namespaces]].

## Declarations

DIM and VAR mean the same thing. Every variable must be declared.

### DIM ... AT

DIM name AT address puts a BYTE or WORD variable at a fixed address. The type
comes from the mark or AS. The variable takes no space in the program.

```
DIM REG_A AT $030C, REG_P AT $030F
REG_P = 0
REG_A = 65
SYS $FFD2                    ' CHROUT prints A
IF REG_P AND 1 THEN PRINT "CARRY"
```

- The address is a constant expression: DIM H AS BYTE AT $0400 + 1.
- A WORD takes the address and the next byte, low byte first.
- The variable works wherever a variable does: in expressions, as the target
  of =, as a FOR counter, in INPUT and as a BIND target.
- Each read or write is one absolute load or store, 3 bytes, also at a
  zero-page address. REG_P = 5 is LDA #5, STA $030F.
- AddrOf(name) is the address. In ASM it is two bytes.
- Two variables may share an address: DIM P% AT $0400, L AT $0400.
- The address is not checked against the program's own memory.
- An address that is not a constant stops the compile with ADDRESS NOT A
  CONSTANT.
- An array or a string with AT stops the compile with NOT YET: AN ARRAY OR A
  STRING AT AN ADDRESS.

See [[Types]], [[SYS]], [[Pointers]].

## CONST

CONST name = value makes a named constant. Several go on one line, separated
by commas. The value is a constant expression.

```
CONST MAX_LEN = 80
CONST ROWS = 2 * 30, COLS = MAX_LEN + 1
CONST BASE% = $9F20
CONST BIG AS WORD = 1000
PRINT MAX_LEN; ROWS; COLS; BASE%; BIG
```

This prints 80  60  81  40736  1000.

- The type comes from the mark or AS. With neither it is a BYTE.
- A BYTE over 255 stops the compile with TOO BIG FOR A BYTE: name.
- A $ mark or AS STRING stops the compile with A CONST IS A NUMBER.
- A value that is not a constant stops the compile with VALUE NOT A CONSTANT.
- A constant belongs to the SUB or namespace it is in. BIND can name it.
- A constant is used like a number. It takes no RAM and no space in the PRG.
- An assignment to a constant stops the compile with NOT A VARIABLE: name.

See [[Types]], [[Namespaces]], [[BIND]].

## ENUM

ENUM name ... END ENUM makes a set of named constants, the members. ENDENUM is
the same as END ENUM. A line holds one member, or several separated by commas.

```
ENUM STATE
  READY, RUNNING
  BLOCKED = 10
  DONE             ' 11
  LAST = DONE + 5
END ENUM
PRINT STATE.READY; STATE.RUNNING; STATE.BLOCKED; STATE.DONE; STATE.LAST
```

This prints 0  1  10  11  16.

- Members number from 0. NAME = value sets a member's number, and the members
  after it count on by 1. The value is a constant expression, and can use an
  earlier member bare and any CONST.
- Inside the ENUM a member is used bare, in a value only. Outside it is
  qualified: STATE.READY. An ENUM MODE in namespace GFX gives GFX.MODE.TEXT.
- The members are BYTE when every value is 0 to 255. When one passes 255, the
  ENUM and every member are WORD.
- A member is a constant. It takes no RAM and no space in the PRG.
- A member name takes no mark. A % or $ is a syntax error.
- An ENUM may be in a namespace or a SUB.
- Errors: ENUM WITHOUT END ENUM at the ENUM's line when the source ends inside
  it, END ENUM WITHOUT ENUM, TOO BIG FOR A WORD: name for a count past 65535,
  VALUE NOT A CONSTANT.

See [[CONST]], [[Namespaces]], [[Types]].

## Arrays

DIM name(count) makes an array of count elements, numbered 0 to count - 1. An
array is BYTE or WORD, by its mark or by AS. With neither it is BYTE.

```
DIM B(10), W%(5)
VAR T(10) AS BYTE
B(0) = 7
W%(4) = B(0) * 1000
PRINT W%(4)
```

- The count is a constant, 1 or more. It may be a constant expression, such as
  2 * 8.
- Every element of a main program array is 0 when the program starts.
- An index is any BYTE or WORD expression.
- A constant index out of range stops the compile with BAD SUBSCRIPT.
- An index out of range at run time stops the program with ?BAD SUBSCRIPT
  ERROR AT $addr. ERRORS OFF leaves out this check.
- AddrOf(B) is the address of element 0. ContentsAt(AddrOf(B) + 2) reads
  B(2).
- An array DIMed in a SUB is a local of the SUB. Its elements start undefined
  and do not keep their values between calls.
- Arrays sit in memory after the program and take no space in the PRG file.

See [[Declarations]], [[ERRORS ON and OFF]], [[Pointers]], [[Subroutines]].

## Comments

A line is a comment when its first word, after any spaces, is REM, ', ;, ## or
//. The compiler skips the whole line.

```
REM THE WHOLE LINE
' THE WHOLE LINE
; THE WHOLE LINE
## THE WHOLE LINE
// THE WHOLE LINE
```

Only REM and ' can follow a statement. The comment runs to the end of the line.

```
X = 1 ' THE REST OF THE LINE
X = 1 REM THE REST OF THE LINE
```

- ; is a comment only at the start of a line, so PRINT A; B is a PRINT.
- ## is a comment and #DEFINE is not: a directive has one #.
- Inside a string none of these starts a comment.

There is no character literal. Write ASC("A"), and the compiler folds it to 65.

## Strings

DIM name$ * size makes a string of up to size characters, 1 to 255. The form
name AS STRING * size does the same. A string must have a size.

```
DIM L$ * 80, N AS STRING * 20
N = "ADA"
L$ = "HELLO, " + N
PRINT L$; LEN(L$)
IF L$ <> "" THEN PRINT MID$(L$, 1, 5)
```

- A main program string is empty when the program starts. A string DIMed in a
  SUB is set empty each time its DIM line runs.
- An assignment cuts the text at the string's size.
- + joins two strings. A joined string is cut at 255 characters.
- The six compares work on strings. The first character that differs decides,
  by its code. When one string starts with the other, the longer one is
  greater.
- A string and a number in one operator stop the compile with TYPE MISMATCH.
- A string holds any byte, 0 included.
- @L$ is the address of the string's block: the size byte, the length byte,
  then the characters.
- Strings sit in memory after the program, as arrays do, and take no space in
  the PRG file.

The functions:

- LEN(s) is the length, a BYTE.
- ASC(s) is the code of the first character, or 0 when s is empty.
- CHR$(n) is the one character with code n.
- STR$(n) is n in decimal with a space in front: STR$(5) is " 5".
- VAL(s) is the number s starts with. Spaces and a + before it are skipped. A -
  right before the digits gives 65536 minus the number: VAL("-5") is 65531.
  VAL("12AB") is 12, and VAL("ABC") is 0.
- MID$(s, start, count) is count characters of s from position start. The
  first position is 1, and 0 is the same as 1. Without count, it is the rest of
  s. A start past the end gives "".
- STR.name is the same function as name: STR.MID$ is MID$. STRINGS.UXI lists
  them in NAMESPACE STR.
- INSTR(s, find, start) is the position of the first find in s at or after
  position start, a BYTE. It is 0 when there is none, or when find is empty.
  Without start, the search starts at 1, and 0 is the same as 1.

LEN and ASC of a literal, and CHR$ and STR$ of a constant, are worked out by
the compiler.

A SUB takes a STRING parameter with no size: SUB SHOW(T$). The SUB works on the
caller's string, so an assignment to T$ changes it. A literal argument is
copied first, so the SUB cannot change the literal.

Not yet: string arrays, a start value.

See [[Types]], [[Subroutines]], [[Including files]].

## Pointers

AddrOf(name) is the address of a variable, an array or a string, as a WORD.
@name is the same. ContentsAt and ContentsAtW read and write memory at any
address.

```
DIM X, P%, W%
X = 42
P% = AddrOf(X)
PRINT ContentsAt(P%)         ' 42
ContentsAt(P%) = 7           ' X is now 7
ContentsAtW(AddrOf(W%)) = 1000
```

- ContentsAt(a) is the BYTE at address a, as PEEK(a) is.
- ContentsAt(a) = v writes the BYTE v to a, as POKE a, v does.
- ContentsAtW(a) is the WORD at a and a + 1, low byte first.
- ContentsAtW(a) = v writes the WORD v to a and a + 1.
- The address is any WORD expression: ContentsAt(P% + 3) = 33.
- A constant address or AddrOf(name) compiles to one load or store. Any other
  address goes through a pointer at run time.
- In ASM, AddrOf(name) is two bytes, as @name is.
- PEEK and POKE work as well.
- Case does not matter: AddrOf and ADDROF are the same word.
- ADDROF, CONTENTSAT and CONTENTSATW are reserved words.
- AddrOf(X with no closing bracket stops the compile with MISSING ).
- ContentsAt 5 = 1 stops the compile with MISSING ( AFTER CONTENTSAT.

See [[Arrays]], [[Strings]], [[Declarations]], [[ASM]].

# Commands

## Control

IF chooses, and DO, FOR and REPEAT loop. EXIT leaves a loop, CONTINUE starts its
next pass, and GOTO jumps to a label.

A condition is true when it is not 0. A compare is compiled straight to a branch,
with no 0 or 1 in between. AND and OR between compares stop as soon as the answer
is known: in A AND B, B is not tested when A is false.

AND and OR are bitwise, so IF A AND 4 tests bit 2. To test two values for not 0,
write IF A <> 0 AND B <> 0.

See [[IF]], [[DO]], [[FOR]], [[REPEAT]], [[EXIT and CONTINUE]], [[GOTO]].

## IF

A block, with any number of ELSEIF parts and one ELSE. THEN is optional at the
end of the line. ENDIF can be written END IF.

```
IF N% = 0
  PRINT "NONE"
ELSEIF N% < 10 THEN
  PRINT "A FEW"
ELSE
  PRINT "MANY"
ENDIF
```

On one line, with THEN and one statement. A one-line IF has no ELSE.

```
IF K = 27 THEN PRINT "ESC"
IF K = 13 THEN EXIT DO
IF N% > 100 GOTO DONE
```

## DO

DO ... LOOP, with a WHILE or UNTIL test at the top, at the bottom, at both or at
neither. With no test the loop runs until EXIT DO.

```
DO WHILE N% < 10
  N% = N% + 1
LOOP
DO
  N% = N% - 1
LOOP UNTIL N% = 0
```

A test at the top is compiled at the bottom, so it costs no more per pass.

## FOR

FOR v = a TO b [STEP k] ... NEXT [v]. The variable is a BYTE or a WORD, and STEP
is a constant, 1 when it is left out. STEP -1 counts down.

```
FOR I = 0 TO 255
  POKE $0400 + I, I
NEXT
FOR W% = 1000 TO 0 STEP -100
  PRINT W%
NEXT W%
```

- The body runs zero times when the range is empty.
- The test is made before the step, so FOR I = 0 TO 255 ends, and I never wraps.
- After the loop, v holds the last value the body saw: 255 above.
- The TO value is read once, at the start.

## REPEAT

REPEAT n ... END REPEAT runs the body n times. n is read once. REPEAT 0 skips the
body. With no count the loop runs until EXIT REPEAT. ENDREPEAT is the same as
END REPEAT.

```
REPEAT 3
  PRINT "HI"
END REPEAT
```

It has no loop variable, so it is the fastest counted loop.

## EXIT and CONTINUE

EXIT DO, EXIT FOR and EXIT REPEAT leave the innermost loop of that kind. CONTINUE
goes to the test, or the step, of the innermost loop.

```
FOR I = 1 TO 10
  IF I = 3 THEN CONTINUE
  IF I = 8 THEN EXIT FOR
  PRINT I
NEXT
```

## GOTO

GOTO jumps to a label. A label is a name and a colon, alone on its line.

```
GOTO DONE
PRINT "SKIPPED"
DONE:
END
```

## GETKEY

GETKEY() gives the next key from the keyboard buffer as a BYTE, or 0 when no key
is waiting. It does not wait. The brackets are required.

```
DIM K
DO
  K = GETKEY()
LOOP UNTIL K <> 0
PRINT K
```

The value is the key's PETSCII code: 13 is RETURN.

## POS

POS(0) gives the cursor column as a BYTE, as in Commodore BASIC. POS(1) gives
the cursor row as a BYTE. Both count from 0. POS(0) = v moves the cursor to
column v and keeps the row. POS(1) = v moves it to row v and keeps the column.
v is any expression and is used as a BYTE. The number in the brackets must be
written as 0 or 1; anything else is the compile error "POS NEEDS 0 OR 1".

```
PRINT "ABC";
C = POS(0)
PRINT C
POS(0) = C * 3 + 1
PRINT POS(0)
```

This prints 3 after ABC, then 10 starting at column 10.

## INPUT and LINPUT

INPUT reads what the user types into BYTE, WORD and STRING variables. It prints
"? " first. A string and a semicolon after INPUT are printed before the "? ".

```
DIM AGE%, N$ * 20
INPUT "NAME"; N$
INPUT "AGE"; AGE%
PRINT N$; AGE%
```

- Each variable takes one field. A field ends at a comma or at RETURN.
- Several variables take their fields from one line: INPUT A%, B$ takes 5,BOB.
- The rest of the line after the last field is dropped.
- When RETURN comes before the last field, the next field is read from a new
  line, with no prompt.
- A number field is read as VAL reads it.
- A string field is cut at the string's size.
- The variable cannot be an array element.

LINPUT reads a whole line into a STRING variable, commas and quotes included. It
prints no prompt. A line longer than the string is cut.

```
DIM L$ * 80
LINPUT L$
```

## Subroutines

SUB name(parameters) ... ENDSUB. ENDSUB can be written END SUB. A SUB is called
by its name and its brackets. CALL in front is optional. The brackets are not:
they make the name a call, even with no arguments.

```
SUB SHOW(N)
  PRINT N
ENDSUB
SHOW(7)
CALL SHOW(7)
```

A SUB with a value has a type, by its mark or by AS. RETURN gives the value, and
the SUB is used in an expression. A SUB name with no mark and no AS has no
value, so a SUB that returns a BYTE is written SUB F() AS BYTE.

```
SUB MAX%(A%, B%)
  IF A% > B% THEN RETURN A%
  RETURN B%
ENDSUB
SUB HALF(N AS WORD) AS WORD
  RETURN N / 2
ENDSUB
DIM T%
T% = MAX%(3, HALF(100))
```

A SUB that returns a STRING has the $ mark or AS STRING: SUB FIRST3$(S$) or
SUB WRAP(T AS STRING) AS STRING. Its value is assigned, printed, compared and
joined with + as any string is.

```
DIM A$ * 20
SUB FIRST3$(S$)
  RETURN MID$(S$, 1, 3)
ENDSUB
A$ = FIRST3$("HELLO")
PRINT FIRST3$("WORLD") + "!"
```

- A parameter is a BYTE, a WORD or a STRING, by its mark or by AS. With
  neither it is a BYTE: SUB SHOW(N). An argument
  is worked into its parameter's type: a WORD into a BYTE parameter keeps its
  low byte. A STRING parameter has no size, and the SUB works on the caller's
  string. See [[Strings]].
- The number of arguments must match the parameters.
- RETURN leaves the SUB at once. In a SUB with no value, RETURN has nothing
  after it.
- A SUB with a value needs at least one RETURN with a value. Its end, when the
  body reaches it, gives 0, or "" in a STRING SUB.
- A STRING result is at most 255 characters. An assignment cuts it to the
  size of the destination.
- A STRING result passed to a SUB is passed as a copy.
- A SUB may be called before it is written.
- A SUB with a value may be called as a statement. The value is lost.
- The main program jumps over a SUB, so a SUB can sit anywhere outside a block.
- A SUB cannot call itself. A SUB that calls itself stops the compile with
  A SUB CANNOT CALL ITSELF.
- SUBs cannot call each other. A loop of calls between SUBs, A calls B and B
  calls A or a longer loop, stops the compile with SUBS CALL EACH OTHER at the
  line of one of the calls.

### Locals

Parameters, and names DIMed in the SUB, are the SUB's locals. A local with the
same name as a main program variable hides it inside the SUB. Main program
variables DIMed before the SUB can be used in it. Labels belong to the SUB too,
so no GOTO crosses into or out of one.

- A local does not keep its value between calls.
- A BYTE or WORD local, and a local array, starts undefined. Set it before you
  read it.
- A local string is set empty each time its DIM line runs.
- Only the SUB itself can name its locals. Inside SHOW, SHOW.N is N. Outside
  SHOW, PRINT SHOW.N stops the compile with LOCAL TO A SUB: SHOW.N.
- The locals of one SUB take at most 16384 bytes. The DIM that passes it stops
  the compile with LOCALS TOO BIG.
- The SUBs of one level of the call graph share the memory of their locals.
  The compiler does not see a call through a pointer or SYS. A SUB called that
  way may share that memory with a SUB that is running.
- The main program's variables are not locals. Each has its own address and
  keeps its value.

## Namespaces

NAMESPACE name ... END NAMESPACE groups names. Inside it a name is used bare.
Outside it the name is qualified with a dot. ENDNAMESPACE is the same as END
NAMESPACE.

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

- A namespace body holds DIM, VAR, CONST, ENUM, SUB, BIND, ERRORS and other
  namespaces, and nothing that runs.
- A namespace may hold namespaces: OUTER.INNER.B is B in INNER in OUTER.
- A NAMESPACE with the name of one already made opens it again, to add names.
- A name is found in the SUB first, then in each namespace around it, then in
  the main program. Inside OUTER, INNER.B and OUTER.INNER.B are the same.
- A SUB's parameters and DIMs are local to it. Outside the SUB, SHOW.N stops
  the compile with LOCAL TO A SUB: SHOW.N.
- UXC is a reserved name.

See [[BIND]], [[Types]], [[Subroutines]].

## BIND

BIND name = target gives a second name to a variable, an array, a constant, a
SUB or a namespace. It costs nothing at run time.

```
BIND G = GFX
BIND P = GFX.PLOT
BIND C = GFX.COLOR
P(1, 2)
```

- The new name has the same mark as the target: BIND C% = GFX.COLOR stops the
  compile with BIND NEEDS THE SAME MARK.
- A BIND belongs to the scope it is written in. A BIND in a SUB is the SUB's.
- A label cannot be bound.

See [[Namespaces]].

## Files

OPEN opens a file on drive 8 and returns its handle. PRINT # writes to the
handle, INPUT # and LINPUT # read from it, and CLOSE closes it. READ and WRITE
move bytes between the file and memory.

```
DIM F%
F% = OPEN("LOG.TXT", O.WRITE)
IF F% = NOFILE
  PRINT "CANNOT OPEN"
  END
ENDIF
PRINT #F%, "SCORE"; 120
CLOSE F%
```

Close every file before the program ends.

### OPEN

F% = OPEN(name$, mode) returns a handle, a WORD. The name is a literal or any
string expression. The mode is one of three names, written as the argument
itself:

- O.READ reads the file.
- O.WRITE makes the file, and replaces one that is there.
- O.APPEND writes at the end of the file, and makes the file when it is
  missing.

Any other mode stops the compile with MODE MUST BE O.READ, O.WRITE OR O.APPEND.

OPEN returns NOFILE when the file cannot be opened: the file is missing for
O.READ, the drive reports an error, or no handle is free. NOFILE is a built-in
constant, 65535. Up to 12 files can be open at once, as handles 3 to 14.

### PRINT # and CLOSE

PRINT #F%, items works as PRINT does, and writes to the file.

- Each line ends with a CR, 13. A trailing ; leaves out the CR.
- A comma between items writes a "," character, not spaces to a print zone.
- A number has a space before and after it, as on the screen.
  PRINT #F%, "AB"; 5, "CD" writes AB 5 ,CD and a CR.
- Handles 0, 1 and 2 are the screen: PRINT #1, "HI" is PRINT "HI".
- A handle that is not open stops the program with ?FILE NOT OPEN ERROR AT
  $xxxx.

CLOSE F% closes the file. CLOSE of a handle that is not open, NOFILE included,
does nothing.

### INPUT #, LINPUT # and EOF

INPUT #F%, variables reads fields from the file. LINPUT #F%, L$ reads a whole
line, commas and quotes included. EOF(F%) is 1 when the next read would return
nothing, and 0 otherwise.

```
DIM F%, L$ * 80
F% = OPEN("DATA.TXT", O.READ)
IF F% = NOFILE
  PRINT "NO FILE"
  END
ENDIF
DO WHILE NOT EOF(F%)
  LINPUT #F%, L$
  PRINT L$
LOOP
CLOSE F%
```

- A field ends at a comma or at the end of a line. A BYTE or WORD variable gets
  the field's value as VAL reads it.
- The rest of the line stays for the next read. Keyboard INPUT drops it.
- No prompt string is allowed after #F%,.
- A line ends at CR, at LF, or at CR LF, so files from the X16, Unix and DOS
  read the same. The line ending is not stored.
- A field or line longer than the string is cut, and the rest of it is skipped.
- At the end of the file a string gets "" and a number gets 0.
- EOF is 1 right after an empty file is opened. EOF(NOFILE) is 1.
- Handles 0, 1 and 2 are the screen and cannot be read.
- A read from a handle that is not open, 0 to 2 included, stops the program
  with ?FILE NOT OPEN ERROR AT $xxxx.

See [[INPUT and LINPUT]].

### READ and WRITE

N% = READ(F%, address, max) reads up to max bytes from the file into memory
at the address. It returns the count read, a WORD. WRITE F%, address, count
writes count bytes from memory at the address to the file.

```
DIM F%, N%, B(100)
F% = OPEN("DATA.BIN", O.READ)
N% = READ(F%, @B, 100)
CLOSE F%
F% = OPEN("COPY.BIN", O.WRITE)
WRITE F%, @B, N%
CLOSE F%
```

- The address is any WORD expression. @B is the address of an array or a
  variable. @S$ + 2 is the text of a string, after its max and length bytes.
  A number such as $A000 is a fixed address.
- Bytes move as they are, CR, LF and 0 included. No line ending is added or
  dropped.
- READ returns 0 at the end of the file. A max of 0 reads nothing and returns
  0. A count of 0 writes nothing.
- READ, INPUT #, LINPUT # and EOF can be mixed on the same handle. EOF stays
  right after a READ.
- WRITE to handles 0, 1 and 2 goes to the screen. WRITE 1, @S$ + 2, 2 prints
  the first two characters of S$.
- READ from handles 0 to 2, or from a handle that is not open, NOFILE
  included, stops the program with ?FILE NOT OPEN ERROR AT $xxxx. WRITE to a
  handle 3 to 14 that is not open, or to NOFILE, does the same.
- Each byte costs a KERNAL CHRIN and READST to read, or a CHROUT to write.

See [[Arrays]] and [[Strings]] for @name.

## ASM

ASM puts bytes into the code where the statement stands. ASM with items puts
them in on one line. ASM alone opens a block, and END ASM or ENDASM closes it.
When the bytes end, the program goes on with the next statement.

```
DIM N, W%
ASM $A9, 65, $20, $FFD2      ' lda #65 : jsr CHROUT
ASM
    $A9, 66          ' lda #66
    $8D, @N          ' sta N
    $8D, @W% + 1     ' sta the high byte of W%
END ASM
```

- A line of a block is a 65C02 instruction or a list of items split by commas.
- A line may start with a label, name:.
- Empty lines and comments are allowed in a block.
- The code must keep X. X indexes the expression stack.

### Items

An item is a constant expression, @name or AddrOf(name). The compiler folds
it to a value.

- A constant 0 to 255 is one byte.
- A constant 256 to 65535 is two bytes, low byte first.
- A negative constant n is 65536 + n, so -1 is two bytes, $FF, $FF.
- @name and AddrOf(name) are two bytes, the address of the variable or array.
- @name + n and @name - n, with n a constant, are addresses too.

$0050 is one byte, $50. The size follows the value, not the digits written.
Write $50, $00 for a two-byte operand below 256.

### Instructions

A line whose first word is a 65C02 mnemonic is an instruction. Upper and lower
case are the same.

```
DIM M$ * 8
DIM PTR% AT $24
M$ = "HI"
ASM
    lda #<@M$
    sta @PTR%
    lda #>@M$
    sta @PTR% + 1
    ldy #2
next: lda (@PTR%),y
    jsr $FFD2
    iny
    cpy #4
    bne next
END ASM
```

The operands:

- None, or A: implied, or the accumulator.
- #n, #<n, #>n: immediate. n, its low byte, its high byte.
- n, n,X, n,Y: zero page or absolute.
- (n), (n,X), (n),Y: indirect.
- label: a branch, JMP or JSR.
- n, label: BBR0-BBR7 and BBS0-BBS7.

- An operand is a constant expression, @name or AddrOf(name).
- A known value below 256 takes the zero-page form when the instruction has
  one. A constant and the @name of a DIM ... AT are known values.
- Any other @name takes the absolute form. #<@name and #>@name are its bytes.
- An operand that starts with ( is indirect.
- A label belongs to its block. A branch, JMP or JSR may name a label further
  down.
- A block holds 32 labels, and 32 uses of a label further down.

### Errors

- An item that is not a constant or @name stops the compile with ASM TAKES A
  CONSTANT OR @NAME.
- A string item stops the compile with TYPE MISMATCH.
- An instruction without the mode its operand asks for stops the compile with
  NO SUCH ADDRESS MODE.
- An immediate or zero-page operand over 255 stops the compile with NOT A
  BYTE. So does #@name.
- A branch to a name that is not a label stops the compile with BRANCH TAKES
  A LABEL.
- A branch further than 127 bytes stops the compile with BRANCH OUT OF RANGE.
- A label defined twice in a block stops the compile with DUPLICATE LABEL.
- A label that the block does not define stops the compile with LABEL NOT
  FOUND, at the line that uses it.
- A 33rd label, or a 33rd use of a label further down, stops the compile with
  TOO MANY ASM LABELS.
- ASM alone with no END ASM before the end of the source stops the compile
  with ASM WITHOUT END ASM, at the line of the ASM.
- END ASM or ENDASM with no block open stops the compile with END ASM WITHOUT
  ASM.

See [[Arrays]] and [[Strings]] for @name, and [[Pointers]].

## SYS

SYS a calls the machine code at address a. The address is any WORD
expression: a constant, a variable or @name.

```
DIM REG_A AT $030C, REG_X AT $030D, REG_Y AT $030E, REG_P AT $030F
REG_A = 65
SYS $FFD2                    ' CHROUT prints A
```

- Before the call SYS loads A, X, Y and P from $030C, $030D, $030E and $030F.
  After the call it stores the four back there. X16 ROM BASIC does the same.
- DIM ... AT names the four bytes, as in the example.
- SYS ANDs P with $F3, so D and I are clear during the call.
- Carry is bit 0 of REG_P. IF REG_P AND 1 THEN PRINT "FAILED" tests the carry
  a call returns.
- The four bytes are not cleared when the program starts. Set what the call
  reads.
- The called code may change X. SYS keeps the program's X, which indexes the
  expression stack.
- A SYS to a constant address is 7 bytes of code. The routine behind it, 43
  bytes, is in the program once.
- A string address stops the compile with TYPE MISMATCH.

See [[ASM]], [[Declarations]].

# The compiler

## Compiling from UXCEDIT

F5, or Build, Compile on the menu, compiles the document on screen with UXC.

- Every changed document is saved first. The document on screen is saved also
  when it has no name: a save prompt asks for one. If a save does not happen,
  the compile stops on the document it was for.
- The editor closes and loads UXC.PRG. UXC compiles the source and loads
  UXCEDIT.PRG again.
- The PRG is named after the source and goes on the same drive. HELLO.UXB
  writes HELLO.PRG.
- UXCEDIT comes back with the same documents open, up to three, each with its
  cursor and scroll place. The compiled document is on screen.
- A message box shows the result. On success it is titled "Compiled" and
  shows the PRG name and its size in bytes.
- On an error the box is titled "Compile error" and shows "Line N" and the
  error message. The cursor is on that line.
- If UXC writes no result, the box says "Compile gave no result". A crash in
  UXC writes no result and does not load the editor. The X16 is left at READY.
- The editor does not run the program. Load and run it from BASIC.
- The files UXC.INPUT, UXC.RESULT and UXCEDIT.RUN on the drive carry the
  request and the result between the two programs.

See [[Errors]].

## Including files

#INCLUDE "NAME" compiles the file NAME in place of its line. The compiler reads
NAME, then the lines after the #INCLUDE.

```
' TOOLS.UXI holds SUB TWICE(N) AS WORD
#INCLUDE "TOOLS.UXI"
PRINT TWICE(21)
```

- The file is read from the same drive as the source.
- An included file cannot include another file.
- An error in an included file reports the line of the #INCLUDE, with the file
  name and its own line: SYNTAX ERROR (LIB.UXI 2).

See [[Strings]], [[Subroutines]].

## Options

To be written: the #DEFINE UXC.* lines.

## ERRORS ON and OFF

ERRORS OFF leaves out the run-time index checks on arrays in the code after it.
ERRORS ON puts them back. ON is the default.

```
DIM B(10), I
ERRORS OFF
B(I) = 1
ERRORS ON
```

- The switch follows the source, not the run: it applies to the lines below it
  in the file.
- With the checks off, an index out of range reads or writes the memory past
  the array.
- Code under ERRORS OFF is smaller and faster.
- A constant index is checked at compile time in both modes.

See [[Arrays]].

## Errors

To be written.
