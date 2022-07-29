# Implementation Notes:

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

Integer BASIC, as its name implies, uses signed integers as the basis for its
math package. These were stored internally as a 16-bit number, little-endian (as
is the 6502). This allowed a maximum value for any calculation between -32767
and 32767. No fraction, just QUOTIENT (/) and REMAINDER (MOD).

Only single-dimension arrays were allowed, limited in size only by the available
memory.

Integer BASIC used the parameter in RND(6) which returned an integer from 0 to 5.

The position of the controller could be read using the PDL function, passing
in the controller number, 0 or 1, like A=PDL(0):PRINT A, returning a value
between 0 and 255.

A=SCRN(X,Y) returned the color of the screen at X,Y.

Integer BASIC included a POP command to exit from loops. This popped the
topmost item off the FOR stack. Atari BASIC also supported the same command,
while North Star BASIC used EXIT.

Although Integer BASIC contained its own math routines, the Apple II ROMs
also included a complete floating-point library located in ROM memory between
$F425-F4FB and $F63D-F65D. The source code was included in the Apple II
manual. BASIC programs requiring floating-point calculations could CALL into
these routines.

From Apple 1 BASIC:
https://github.com/jefftranter/6502/blob/master/asm/a1basic/a1basic.s

The noun stack and syntax stack appear to overlap, which is OK since
they apparently are not used simultaneously. The noun stack size appears
to be 32 entries.

        Noun stack usage appears to be:
            integer: value
            string: pointer to string

GOSUB stack, max eight entries, note that the Apple II version has sixteen entries.

FOR stack, max eight entries, note that the Apple II version has sixteen entries.

ASCII  32 ($20) = SPACE
ASCII 160 ($A0) = Non-breaking SPACE (32 + 128, hight bit set). EOL last character is unset.
TAB does horizontal tab by printing ASCII 160

36      | $24         | Horizontal cursor-position (0-39)
37      | $25         | Vertical cursor-position (0-23)

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

Error message strings. Last character has high bit unset:

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

FP routines in ROM at locations $f425-f4fb and $f63d-f65d. Source code in Apple II Manual.

## LO-RES GRAPHICS

COLOR	NAME			PETSCII CODE/CHR$(X)
---
0	Black			144	$90
1	White			5	$05
2	Red			28	$1c
3	Cyan			159	$9f
4	Purple			156	$9c
5	Green			30	$1e
6	Blue			31	$1f
7	Yellow			158	$9e
8	Orange			129	$81
9	Brown			149	$95
A	Light Red		150	$96
B	Dark Grey		151	$97
C	Grey			152	$98
D	Light Green		153	$99
E	Light Blue		154	$9a
F	Light Grey		155	$9b

```
COLOR <color code>
<color code> = $<BG nibble><FG nibble>
```

E.g.	COLOR $14 is BLUE on WHITE
	COLOR $41 is default WHITE on BLUE

You can use PETSCII codes to set both background and foreground color:

```
10 PRINT CHR$($81):REM SET FOREGROUND COLOR TO ORANGE
20 PRINT CHR$($01):REM SWAP FOREGROUND- AND BACKGROUND COLOR
30 PRINT CHR$($1F):REM SET FOREGROUND COLOR TO BLUE
40 PRINT "THIS TEXT IS BLUE ON ORANGE BACKGROUND"
```

Textmode, either 80x60 or 40x30, you can use the screen_set_mode call.

Modes:

The editor's default mode is 80x60 text mode. The following text mode resolutions are supported:

```
Mode	Description
$00	80x60 text
$01	80x30 text
$02	40x60 text
$03	40x30 text
$04	40x15 text
$05	20x30 text
$06	20x15 text
$80	320x200@256c/40x25 text
```

Mode $80 contains two layers: a text layer on top of a graphics screen. In this mode, text color 0 is translucent instead of black.

To switch modes, use the BASIC statement SCREEN or the KERNAL API screen_mode. In BASIC, the F4 key toggles between modes 0 (80x60) and 3 (40x30).

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

EXAMPLE:

```LDA #$80
CLC
JSR screen_mode ; SET 320x200@256C MODE
BCS FAILURE```

---

Function Name: console_put_char
Signature: void console_put_char(byte char: .a, bool wrapping: .c);
Purpose: Print a character to the console.
Call address: $FEDE

Description: This function prints a character to the console. The .C flag specifies whether text should be wrapped at character (.C=0) or word (.C=1) boundaries. In the latter case, characters will be buffered until a SPACE, CR or LF character is sent, so make sure the text that is printed always ends in one of these characters.

Note: If the bottom of the screen is reached, this function will scroll its contents up to make extra room.

## Applesoft Colors

Lo-res mode colors:
---
0 - black
1 - red
2 - dark blue
3 - pink
4 - dark green
5 - dark gray
6 - mid blue
7 - light blue
8 - brown
9 - orange
10 - light gray
11 - apricot
12 - light green
13 - yellow
14 - aqua
15 - white

The numbers in square brackets are the lores color numbers (COLOR= in
Applesoft). The hires colors (HCOLOR= in Applesoft) are marked with an
asterisk.

NTSC Apple II Colors RGB Values in sRGB color space
---
R, G, B [ 0] = 0x000000 * Hires 0, 3
R, G, B [ 1] = 0x8a2140
R, G, B [ 2] = 0x3c22a5
R, G, B [ 3] = 0xc847e4 * Hires 2
R, G, B [ 4] = 0x07653e
R, G, B [ 5] = 0x7b7e80
R, G, B [ 6] = 0x308fe3 * Hires 6
R, G, B [ 7] = 0xb9a9fd
R, G, B [ 8] = 0x3b5107
R, G, B [ 9] = 0xc77028 * Hires 5
R, G, B [10] = 0x7b7e80
R, G, B [11] = 0xf39ac2
R, G, B [12] = 0x2fb81f * Hires 1
R, G, B [13] = 0xb9d060
R, G, B [14] = 0x6ee1c0
R, G, B [15] = 0xf5faff * Hires 4 & 7