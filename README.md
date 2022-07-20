INT BASIC aka GAME BASIC

Why INTEGER BASIC? Woz explains: "I wrote down a complete syntax chart of the
commands that were in the H-P BASIC manual, and I included floating point
arithmetic, decimal points, numbers and everything. Then I started thinking
it was going to take me a month longer - I could save a month if I left out
the floating point."

Wozniak was confident that a good mathematician can work around the
limitation of integers: "We made the first handheld scientific calculators at
H-P, that's what I was designing, and they would work with transcendental
numbers, like SIN and COSIN. And was everything floating point? No! We did
all the calculations inside our calculators digitally, for higher accuracy
and higher speed, with integers. I said, basically integers can solve
anything. I was a mathematician of the type that wanted to solve things with
integers. You could always have dollars and cents as separate integer numbers
- all you need for games is integers. So I thought, I'll save a month writing
my BASIC, and I'll have a chance to be known as the first one to write a
BASIC for the 6502 processor. I said: I'll become famous like Bill Gates if I
write it the fastest I could. So I stripped out the floating point."

Lastly, Woz reminisces I liked Integer BASIC. There's a lot of things you
could do to save time, but you have to think mathematically. And most people
would rather just have the easy world - so it wasn't good for most people.
But for my type of person, Integer was great. I would want to do things with
integers."

Given that it's been 50 years since BASIC was formed, does he believe it
still has a place in the world? "I think it does. I still recommend it
frequently, as the right way to start programming classes. Or at least a
simpler language like BASIC - it's probably pretty hard to find the exact,
plain old original BASIC in this day of graphics on computers. But yes, I do.

"But as far as the introduction to computing... To me BASIC and FORTRAN are
the same. Either one of those, that's the right way to start, and not a real
super structured language where you have to learn so much about the
structure. It's better to learn structure from the ground up, the basic
atoms. Which is what BASIC is. To learn the structure from the ground up,
once you've learned it you will apply it in a structured language. Then
you're ready for it.

~~~~~~

Implements Woz's Integer BASIC with a few additional commands from Applesoft
BASIC (AS) or GW-BASIC (GW):

DATA (AS) : Define inline data; can be literals (unquoted strings), strings or numbers
READ (AS) : Read the next DATA value
RESTORE (AS) : Restore the DATA pointer to the first value
HOME (AS) : Clear text display
LOCATE r,c (GW) : Move cursor to the specified position
GET (AS) : Read single key

OBS:
TAB x where x=1-40 same as HTAB (AS)
VTAB x where x=1-24
POP : Convert last GOSUB into a GOTO

Todo:
=====
MUL8(): 8-bit integer multiplication, result is 2-bytes
DIV8(): 8-bit integer division, result is 2-bytes
MOD8(): 8-bit integer modulo, result is 2-bytes
MUL() : 32-bit fixed-point multiplication (Woz's) 4-bytes, 16-bit:16-bit
DIV() : 32-bit fixed-point division (Woz's) 4-bytes, 16-bit:16-bit
FMUL(): 32-bit floating-point multiplication (Woz's) 4-bytes
FDIV(): 32-bit floating-point division (Woz's) 4-bytes
LOG,LN,ATN,COS,SIN,SQR,TAN,PI
        (add all these to a math library on 8K HIGH RAM)
>>  : bitwise operator right shift 
<<  : bitwise operator left shift
&   : bitwise operator AND
|   : bitwise operator OR
^   : bitwise operator XOR
~   : bitwise operator NOT
!   : ??
#   : NOT EQUAL
!=  : NOT EQUAL
++
--
Add Zero Page variables
Add r0-r15 16-bit registers
Add .B suffix for unsigned byte (normal VAR is 16-bit)
Add ADD8(), SUB8(), MUL8() and DIV8() for .B
Add support for hexadecimals $ff5c
BASIC V2 commands: CHR$,GET,TIME,ASC

Fixme:
======
DIM: Re-dimension of a pre-existing A$; memory problems

Notes:
====== 

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

Error message strings. Last character has high bit unset:
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

FP routines in ROM at locations $f425-f4fb and $f63d-f65d. Source code in Apple II Manual.