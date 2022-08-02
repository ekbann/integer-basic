# IMPLEMENTATION NOTES

### INTEGER BASIC COMMANDS

Implements Woz's Integer BASIC (IB) with a few additional commands from Applesoft
BASIC (AS), GW-BASIC (GW), and my very own additions to GAME BASIC (GB):

* DATA (AS) : Define inline data; can be literals (unquoted strings), strings or numbers
* READ (AS) : Read the next DATA value
* RESTORE (AS) : Restore the DATA pointer to the first value
* HOME (AS) : Clear text display
* LOCATE r,c (GW) : Move cursor to the specified position
* GET (AS) : Read single key
* STACK (GB): Print the current STACK; May not be very useful
* TIME (GB): Print the current time from boot-up in jiffies (1/60 sec); from C64
* `DIM ARY(X)` : Creates an array with X+1 elementes; ARY(0)..ARY(X)
* `A=SCRN(X,Y)` : Returns the color of the screen at X,Y
* TAB x (IB) : Where x=1-40 same as HTAB (AS)
* VTAB x (IB) : Where x=1-24, but X16 has a 40x30 mode meaning x=1-30
* POP (IB) : Convert last GOSUB into a GOTO

### STACK

Game BASIC has a 12 element 4-byte stack.

SIH | SIL | SFH | SFL | LEVEL
--- | --- | --- | --- | ---
. | . | . | . | 3
. | . | . | . | 2
. | . | . | . | 1
. | . | . | . | 0 <- FPSP

From Apple 1 BASIC:
https://github.com/jefftranter/6502/blob/master/asm/a1basic/a1basic.s

The noun stack and syntax stack appear to overlap, which is OK since
they apparently are not used simultaneously. The noun stack size appears
to be 32 entries.

```
Noun stack usage appears to be:
        integer: value
        string: pointer to string
```

`GOSUB` stack, max eight entries, note that the Apple II version has sixteen entries. `FOR` stack, max eight entries, note that the Apple II version has sixteen entries.

### STRINGS

Integer BASIC's string handling was based on the system in HP BASIC. This
treated string variables as arrays of characters which had to be DIMed prior
to use. This is similar to the model in C or Fortran 77. This is in contrast
to MS-like BASICs where strings are an intrinsic variable-length type. Before
MS-derived BASICs became the de facto standard, this style was not uncommon;
North Star BASIC and Atari BASIC used the same concept, as did others.

Strings in Integer Basic used a fixed amount of memory regardless of the
number of characters used within them, up to a maximum of 255 characters.
This had the advantage of avoiding the need for the garbage collection of the
heap that was notoriously slow in MS BASIC but meant that strings that
were shorter than the declared length was wasted.

String output uses the C64 standard KERNAL function: `CHROUT` ($FFD2)

```
The CHROUT kernal routine is located at $FFD2 (65490).

This routine will translate the value on the Accumulator register to a character code, and output to the default output device. This is generally the screen unless the OPEN and then CHKOUT routines were previously called to change the default output device.

Real address of Kernal routine: $F1CA.
```

### INTEGER NUMBERS

Integer BASIC, as its name implies, uses signed integers as the basis for its
math package. These were stored internally as a 16-bit number, little-endian (as
is the 6502). This allowed a maximum value for any calculation between -32767
and 32767. No fraction, just QUOTIENT (/) and REMAINDER (MOD).

### FLOATING/FIXED POINT

Although Integer BASIC contained its own math routines, the Apple II ROMs
also included a complete floating-point library located in ROM memory between
$F425-F4FB and $F63D-F65D. The source code was included in the Apple II
manual. BASIC programs requiring floating-point calculations could CALL into
these routines.

### DIM ARRAYS

Only single-dimension arrays were allowed, limited in size only by the available
memory.

### RANDOM NUMBERS

Integer BASIC used the parameter in RND(6) which returned an integer from 0 to 5.

### PADDLE CONTROLLERS

The position of the controller could be read using the PDL function, passing
in the controller number, 0 or 1, like `A=PDL(0):PRINT A`, returning a value
between 0 and 255.

### CONTROL FLOW

* `GOTO` (IB) : `GOTO <INT>` and `GOTO <expr>` except `GOTO 10+10`
* `GOTO` (AS) : Only allows `GOTO <INT>`; Same behavior seen in C64 BASIC

To implement `GOTO <expr>` (IB) is complicated. The `<expr>` will result in an `<INT>` value during execution and we must somehow convert that integer into a physical memory address of the equivalent line label `L<INT>`.

One way to solve this problem is to implement a `line_lookup_table` during compile-time:

INT | ADDRESS | LABEL
--- | --- | ---
10 | $091c | L10
20 | $093f | L20
etc. | etc. | etc.

And write a function `line_lookup` which scans this table using the INT as the index to obtain the `JMP` address.

The easiest way is to implement the `ON <expr> GOTO <linenum> [, linenum ...]` (AS) and `ON <expr> GOSUB <linenum> [, linenum ...]` (AS) which branches based on index `<expr>`.

Integer BASIC included a POP command to exit from loops. This popped the
topmost item off the FOR stack. Atari BASIC also supported the same command,
while North Star BASIC used EXIT.

### ERROR MESSAGES

```
        ">32767"
        "TOO LONG"
        "SYNTAX"
        "MEM FULL"
        "TOO MANY PARENS"
        "STRING"
        "NO END"
        "BAD BRANCH"
        ">8 GOSUBS"
        "BAD RETURN"
        ">8 FORS"
        "BAD NEXT"
        "STOPPED AT "
        "*** "
        " ERR.\n"
        ">255"
        "RANGE"
        "DIM"
        "STR OVFL"
        "\\\n"
        "RETYPE LINE\n"
        "?"
```

### LO-RES GRAPHICS (80x60) and (40x30)

COLOR |NAME	| PETSCII CODE | CHR$(X)
--- | --- | --- | ---
0 | Black | 144 | $90
1 | White | 5 | $05
2 | Red | 28 | $1c
3 | Cyan | 159 | $9f
4 | Purple | 156 | $9c
5 | Green | 30 | $1e
6 | Blue | 31 | $1f
7 | Yellow | 158 | $9e
8 | Orange | 129 | $81
9 | Brown | 149 | $95
A | Light Red | 150 | $96
B | Dark Grey | 151 | $97
C | Grey | 152 | $98
D | Light Green | 153 | $99
E | Light Blue | 154 | $9a
F | Light Grey | 155 | $9b

```
COLOR <color code>
<color code> = $<BG nibble><FG nibble>
```

E.g. `COLOR $14` is BLUE on WHITE
    `COLOR $41` is default WHITE on BLUE

You can use PETSCII codes to set both background and foreground color:

```
10 PRINT CHR$($81):REM SET FOREGROUND COLOR TO ORANGE
20 PRINT CHR$($01):REM SWAP FOREGROUND- AND BACKGROUND COLOR
30 PRINT CHR$($1F):REM SET FOREGROUND COLOR TO BLUE
40 PRINT "THIS TEXT IS BLUE ON ORANGE BACKGROUND"
```

Textmode, either 80x60 or 40x30, you can use the `screen_set_mode` call.

Modes:

The editor's default mode is 80x60 text mode. The following text mode resolutions are supported:

Mode | Description
--- | ---
$00 | 80x60 text
$01 | 80x30 text
$02 | 40x60 text
$03 | 40x30 text
$04 | 40x15 text
$05 | 20x30 text
$06 | 20x15 text
$80 | 40x25 text, or
$80 | 320x200x256

Mode $80 contains two layers, a text layer on top of a graphics screen. In this mode, text color 0 is translucent instead of black:

```
^  Z=3 sprites
|  Layer 1
|  Z=2 sprites
|  Layer 0
|  Z=1 sprites
|  Background color (palette entry #0)
```

To switch modes, use the BASIC statement SCREEN or the KERNAL API screen_mode. In BASIC, the F4 key toggles between modes 0 (80x60) and 3 (40x30).

```
$FF5F: screen_mode - get/set screen mode

Function Name: screen_mode
Purpose: Get/Set the screen mode
Call address: $FF5F
Communication registers: .A, .X, .Y, .C
Preparatory routines: None
Error returns: .C = 1 in case of error
Stack requirements: 4
Registers affected: .A, .X, .Y

Description: If .C is set, a call to this routine gets the current screen mode in .A, the width (in tiles) of the screen in .X, and the height (in tiles) of the screen in .Y. If .C is clear, it sets the current screen mode to the value in .A. For a list of possible values, see the basic statement SCREEN. If the mode is unsupported, .C will be set, otherwise cleared.
```

Example:

```
LDA #$80
CLC
JSR screen_mode ; SET 320x200@256C MODE
BCS FAILURE
```

NTSC Apple II Lo-Res Colors RGB Values in sRGB color space:

Lo-res mode colors:

COLOR | NAME | RGB
--- | --- | ---
0 | black | 0x000000
1 | red | 0x8a2140
2 | dark blue | 0x3c22a5
3 | pink | 0xc847e4
4 | dark green | 0x07653e
5 | dark gray | 0x7b7e80
6 | mid blue | 0x308fe3
7 | light blue | 0xb9a9fd
8 | brown | 0x3b5107
9 | orange | 0xc77028
10 | light gray | 0x7b7e80
11 | apricot | 0xf39ac2
12 | light green | 0x2fb81f
13 | yellow | 0xb9d060
14 | aqua | 0x6ee1c0
15 | white | 0xf5faff

### HORIZONTAL TAB DETAILS (APPLE)

* ASCII  32 ($20) = SPACE
* ASCII 160 ($A0) = Non-breaking SPACE (32 + 128, hight bit set). EOL last character is unset.
* TAB does horizontal tab by printing ASCII 160

DEC | HEX | DESCRIPTION
--- | --- | ---
36 | $24 | Horizontal cursor-position (0-39)
37 | $25 | Vertical cursor-position (0-23)

 ```
        ch      =       $24     ; horizontal cursor location
        ; horizontal tab
        tabout: LDA     ch
                ORA     #$07
                TAY
                INY
        Le7b7:  LDA     #$A0
                JSR     cout
        Le7bc:  CPY     ch
                BCS     Le7b7
                RTS

;******* Hardware Variables ************
DSP   = $D012	; Video I/O
DSPCR = $D013
KBD   = $D010	; Keyboard I/O
KBDCR = $D011
;******** $200-$27F Text Buffer *********
IN = $0200
;********
CR        = #$8D
BACKSPACE = #$DF
ESC       = #$9B
;********

        DSP     =       $D012
        cout:   CMP     #$8D
                BNE     Le3d3
        
        crout:  LDA     #$00            ; character output
                STA     ch
                LDA     #$8D
        Le3d3:  INC     ch
        
        ; Send character to display. Char is in A.
        Le3d5:  BIT     DSP          ; See if display ready
                BMI     Le3d5        ; Loop if not
                STA     DSP          ; Write display data
                RTS                  ; and return
```