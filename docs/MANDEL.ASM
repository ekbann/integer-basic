    .cpu "W65C816S"
    .assume accum:16
    .assume index:16
    .hexfile
    .objfile
    .srecfile
    .listfile

; Constants
;
FPSTACKSIZE .equ 8  ; Fixed-point stack size
INPUTMAXLEN .equ 32 ; Maximum length of input

       .org 0
ZPSTART
ZREAL  .ds 4
ZIMAG  .ds 4
REG1   .ds 4
REG2   .ds 4
SIGN   .ds 2
MULTMP .ds 2
ZPEND

MASK .equ $FF

DPAGE    .equ $6F00
IMAGEBUF .equ $7000
    .org $8000

    JMP MAIN

NX     .word 40
NY     .word 48
ASPECT .string "1.53" ; Aspect ratio
       .string ".."
ASPECTEND

; Mandelbrot application

; Get input parameters, calculate the mandelbrot data, and render it
;
MAIN
    LDA #FPSTACKSIZE
    JSR FPSETSTACKSIZE
    JSR GETPARMS
    JSR START_TIMER
    TXA
    PHA
    LDX #ASPECTEND-ASPECT-1 ; Copy aspect ratio string
M1  LDA ASPECT,X
    STA IBUF,X
    DEX
    BPL M1
    PLA
    TAX
    JSR PARSE               ; Parse it
    LDA #VASP-FPVARS        ; Store it
    JSR FPSTORE
    JSR SAVEINIT
    JSR PRECALC
    JSR IMAGE
    JMP RENDER
;
; Get input: X & Y coordinates, magnification, timeout
; Same functionality as lines 10-30 of Listing 4 (the lo-res BASIC program)
;
GETPARMS
    LDA #MXC-MESSAGES  ; Input X coordinate
    JSR USERINPUT
    LDA #VREAL-FPVARS  ; Store it
    JSR FPSTORE
    LDA #MYC-MESSAGES  ; Input Y coordinate
    JSR USERINPUT
    LDA #VIMAG-FPVARS  ; Store it
    JSR FPSTORE
    LDA #MMAG-MESSAGES ; Input magnification
    JSR USERINPUT
    LDA #VMAG-FPVARS   ; Store it
    JSR FPSTORE
    LDA #MTO-MESSAGES  ; Input timeout
    JSR USERINPUT
    JSR FPPULL
    STA TIMEOUT        ; Store it
    RTS
;
; Preparatory calculations: calculate CREAL, DX, DY, and CIMAG
; Same functionality as lines 100-250
; Note that the formulas are identical (work through the algebra to see this)
;
; NX, NY, the aspect ratio, and the magnification are all positive numbers,
;   so we can get away with using unsigned multiplication and division, since
;   those operations will only be performed on positive numbers.
;
PRECALC
    LDA #VREAL-FPVARS ; CREAL = REAL - (NX-1)/MAG/NX/2
    JSR FPFETCH
    LDA NX
    SEC
    SBC #1
    JSR FPPUSH
    LDA #VMAG-FPVARS
    JSR FPFETCH
    JSR MDIV
    LDA NX
    JSR FPPUSH
    JSR MDIV
    JSR MDIV2
    JSR FPSUB
    LDA #CREAL-MVARS
    JSR MSTORE

    LDA #VIMAG-FPVARS ; Push IMAG onto the stack (it will be used later)
    JSR FPFETCH
    LDA #1            ; DX = 1/MAG/NX
    JSR FPPUSH
    LDA #VMAG-FPVARS
    JSR FPFETCH
    JSR MDIV
    LDA NX
    JSR FPPUSH
    JSR MDIV
    JSR FPDUP
    LDA #DX-MVARS
    JSR MSTORE

    LDA #VASP-FPVARS  ; DY = DX / ASPECT
    JSR FPFETCH
    JSR MDIV
    JSR FPDUP
    LDA #DY-MVARS
    JSR MSTORE
;
; IMAG (which was pushed on the stack earlier) is now at the top of the stack
;
    LDA NY            ; CIMAG = IMAG - (NY-1)*DY/2
    SEC
    SBC #1
    JSR FPPUSH
    JSR FPUMUL
    JSR FPROUNDUP
    JSR MDIV2
    JSR FPSUB
    LDA #CIMAG-MVARS
    JMP MSTORE
;
; Get a line of input, and store it in IBUF
; Returns: length (in characters) of input
; Roughly the same functionaly as the BASIC INPUT command
;
GETLINE
    TYA
    PHA
    LDY #0
GL1 JSR INPUT        ; Get a character
    CMP #$0D         ; Enter?
    BEQ GL3
    CMP #$08         ; Backspace?
    BNE GL2
    CPY #0           ; At the beginning of the line
    BEQ GL1
    DEY
    JSR OUTPUT       ; Output ^H
    JMP GL1
GL2 CMP #$20         ; Ignore characters below space ...
    BCC GL1
    CMP #$7F         ; ... and above ~
    BCS GL1
    CPY #INPUTMAXLEN ; At the end of the line?
    BCS GL1
    STA IBUF,Y       ; Store the character in the buffer
    INY
    JSR OUTPUT       ; Output it
    JMP GL1
GL3 STY MTEMP
    PLA
    TAY
    LDA MTEMP        ; Return length
    JMP OUTCRLF      ; Output CRLF sequence
;
; Divide and round
;
MDIV
    JSR FPUDIV
    JMP FPROUNDUP
;
; Divide by two and round
;
MDIV2
    JSR FPUDIV2
    JMP FPROUNDUP
;
; Output the message indexed by A
;
MESSAGE
    STY MSGTEMP
    TAY
MS1 LDA MESSAGES,Y ; This is a 16-bit load...
    AND #MASK      ; ...so mask the low byte
    BEQ MS2
    JSR OUTPUT
    INY
    JMP MS1
MS2 LDY MSGTEMP
    RTS
;
; Messages
;
MESSAGES:
MERR .string "ERROR!"
     .byte 0
MXC  .string "X COORDINATE: "
     .byte 0
MYC  .string "Y COORDINATE: "
     .byte 0
MMAG .string "MAGNIFICATION: "
     .byte 0
MTO  .string "TIMEOUT: "
     .byte 0
;
; Store an 64-bit FP number in a 32-bit mandelbrot variable
;
; There are more effcient ways of doing this, but this way doesn't depend on
;   knowing the specifics of the FP implementation, and doesn't need a 
;   special FP routine for this application only (i.e. that wouldn't have a
;   general use)
;
; FP bytes 4-1 -> mandelbrot bytes 3-0
;
MSTORE
    STA STORETMP
    TYA
    PHA
    LDY #8
ST1 JSR FPUDIV2    ; Shift the FP number down so it can be rounded
    DEY
    BNE ST1
    LDY STORETMP
    JSR FPROUNDUP  ; Round it
    JSR FPMUL65536 ; Shift the upper 16 bits into the integer portion
    JSR FPDUP
    JSR FPPULL
    STA MVARS+2,Y  ; Store the upper 16 bits
    JSR FPMUL65536 ; Shift the lower 16 bits into the integer portion
    JSR FPPULL
    STA MVARS,Y    ; Store the lower 16 bits
    PLA
    TAY
    RTS
;
; Parse a string to a fixed-point number
; Enter with address of string in A
; To simplify parsing, a decimal point is used as a delimiter, so the string
;   should end with a couple of decimal points, just in case
; Returns with carry set if there was an error
;
PARSE
    LDA #0
    STA PARSEINDEX
    LDA #$8000     ; Set flag to indicate no digits have been parsed
    STA PARSEDIG
    JSR PARSEGET   ; Get a character
    CMP #$2D       ; Is it a minus sign?
    BNE PR1
    JSR PR2        ; Parse the number
    BCS PR5        ; Branch if error
    JMP FPNEG      ; Negate it
PR1 DEC PARSEINDEX ; Not a minus sign, so back up a character
PR2 JSR PARSENUM   ; Get the integer portion
    BCS PR4
    JSR PARSENUM   ; Get the fractional portion (as an integer)
    BCS PR3
    BIT PARSEDIG   ; Was a digit entered?
    BMI PR3
    JSR FPPWR10    ; Turn the fractional portion into a fraction by dividing
    JSR MDIV       ;   by a power of 10
    JSR FPADD      ; Add the integer and fractional portions
    CLC            ; No error
    RTS
PR3 JSR FPPULL     ; Error, so clean up the FP stack
PR4 JSR FPPULL
PR5 SEC
    RTS
;
; Get a character to parse
;
PARSEGET
    STY MTEMP
    LDY PARSEINDEX
PG1 LDA IBUF,Y     ; This is a 16-bit load...
    AND #MASK      ; ...so mask the low byte
    INY
    CMP #$20       ; Ignore spaces
    BEQ PG1
    STY PARSEINDEX
    LDY MTEMP
    RTS
;
; Parse a number
; Return with the number of digits in A
; Return with carry set if there was an error
;
PARSENUM
    LDA #9         ; Allow up to 9 digits
    STA PARSECOUNT
    LDA #0
    JSR FPPUSH
PN1 JSR PARSEGET   ; Get a character
    CMP #$2E       ; Is it a decimal point
    BEQ PN2
    DEC PARSECOUNT ; Too many digits?
    BMI PN3
    EOR #$30       ; Turn ASCII into number 0-9
    CMP #$0A
    BCS PN3
    PHA
    JSR FPMUL10    ; Multiply the number by 10
    PLA
    JSR FPPUSH
    JSR FPADD      ; Add the new digit
    LSR PARSEDIG   ; Clear flag to indicate at least one digit has been
    BPL PN1        ;   entered (always branch)
PN2 LDA #9         ; Return number of digits entered
    SBC PARSECOUNT
    CLC            ; No error
    RTS
PN3 SEC            ; Error
    RTS
;
; Get user input: Display the message (indexed by A) and parse the number
; If an error occurred display an error message and get input again
;
USERINPUT
    STA MTEMP
    TYA
    PHA
    LDA MTEMP
UI1 PHA                ; Save the message index in case we have to try again
    JSR MESSAGE
    JSR GETLINE        ; Get input
    TAY
    CLC
    ADC #IBUF          ; Calculate ending address of buffer
    PHA
    LDA #$2E
    STA IBUF,Y         ; Add a couple of decimal points to the end of the
    STA IBUF+1,Y       ;   string for the parser
    JSR PARSE
    PLA
    BCS UI2
    EOR #$FFFF         ; Equivalent to: STA TEMP
    SEC                ;                LDA PARSEINDEX
    ADC PARSEINDEX     ;                CMP TEMP
    BCC UI3
    JSR FPPULL         ; Clean up the FP stack
UI2 LDA #MERR-MESSAGES ; Display error message
    JSR MESSAGE
    JSR OUTCRLF
    PLA                ; Restore message index
    JMP UI1
UI3 PLA                ; Discard message index
    PLA
    TAY
    RTS

; Mandelbrot generation subroutines

; Generate mandelbrot data
; Same functionality as lines 300-550, except that data is stored, not
;   plotted
;
IMAGE
    TXA
    PHA
    TYA
    PHA
    JSR SAVE0    ; Save zero page
    JSR IMGINIT  ; Init mandelbrot data index
    LDY NY
IM1 LDA CREAL+2  ; Save first column
    PHA
    LDA CREAL
    PHA
    LDX NX
IM2 TXA
    PHA
    TYA
    PHA
    JSR MANDEL1  ; Calculate mandelbrot data
    TYA
    JSR IMGPUT   ; Store it
    PLA
    TAY
    PLA
    TAX
    CLC          ; Advance to next column
    LDA DX
    ADC CREAL
    STA CREAL
    LDA DX+2
    ADC CREAL+2
    STA CREAL+2
    DEX
    BNE IM2
    PLA
    STA CREAL    ; Return to first column
    PLA
    STA CREAL+2
    CLC
    LDA DY       ; Advance to next row
    ADC CIMAG
    STA CIMAG
    LDA DY+2
    ADC CIMAG+2
    STA CIMAG+2
    DEY
    BNE IM1
    JSR RESTORE0 ; Restore zero page
    PLA
    TAY
    PLA
    TAX
    RTS
;
; Calculate mandelbrot data at CREAL, CIMAG
; Return "distance" from mandelbrot set in A
;
MANDEL
    TXA
    PHA
    TYA
    PHA
    JSR SAVE0
    JSR MANDEL1
    STY MTEMP
    JSR RESTORE0
    PLA
    TAY
    PLA
    TAX
    LDA MTEMP
    RTS
MARTS1
    RTS
;
; This is an alternate entry point, which does not save registers or the
;   zero page.  For speed, IMAGE uses this (saving and restoring the zero
;   page once), rather than saving registers at each every point, as the
;   MANDEL entry point (and the original program) does.
;
MANDEL1
    LDA CREAL   ; CREAL -> ZREAL
    STA ZREAL
    LDA CREAL+2
    STA ZREAL+2
    LDA CIMAG   ; CIMAG -> ZIMAG
    STA ZIMAG
    LDA CIMAG+2
    STA ZIMAG+2
    LDY TIMEOUT
MA1 LDA ZREAL+2 ; SIGN = SIGN OF ZREAL * ZIMAG
    EOR ZIMAG+2
    STA SIGN
    LDA ZREAL+2 ; ZREAL = ABS (ZREAL)
    BPL MA2
    SEC
    LDA #0
    SBC ZREAL
    STA ZREAL
    LDA #0
    SBC ZREAL+2
    STA ZREAL+2
MA2 LDA ZIMAG+2 ; ZIMAG = ABS (ZIMAG)
    BPL MA3
    SEC
    LDA #0
    SBC ZIMAG
    STA ZIMAG
    LDA #0
    SBC ZIMAG+2
    STA ZIMAG+2
MA3 LDA ZREAL+2 ; RETURN IF ZREAL >= 2 OR ZIMAG >= 2
    ORA ZIMAG+2
    CMP #$200
    BCS MARTS1

    LDA ZREAL   ; REG1 = ZREAL ^ 2
    SEC
    ROR
    STA MULTMP  ; Do the lowest 16-bits first
    LDA #0
    STA REG1
    STA REG1+2
MR1 BCC MR2     ; Ye olde standard 6502 right shift multiply loop
    CLC
    LDA REG1
    ADC ZREAL
    STA REG1
    LDA REG1+2
    ADC ZREAL+2
    STA REG1+2
MR2 ROR REG1+2
    ROR REG1
    LSR MULTMP
    BNE MR1
    LDA ZREAL+2 ; Now do the rest of the fractional part
    STA MULTMP
    LDX #8
MR3 LSR MULTMP  ; Another standard multiply loop
    BCC MR4
    CLC
    LDA REG1
    ADC ZREAL
    STA REG1
    LDA REG1+2
    ADC ZREAL+2
    STA REG1+2
MR4 ROR REG1+2
    ROR REG1
    DEX
    BNE MR3
;
; At this point, the carry contains the bit we can round with
;
; Because we've already checked that ZREAL < 2 the integer part (which is
;   now positive) can only be 0 or 1, so we either add 0 or ZREAL (and the
;   carry).
;
    LDA MULTMP  ; Round with carry
    AND #1
    TAX
    BEQ MR5
    LDA ZREAL
    LDX ZREAL+2
MR5 ADC REG1
    STA REG1
    TXA
    ADC REG1+2
    STA REG1+2
;
; Exactly the same as the last multiplication, except we use ZIMAG and REG2
;   instead of ZREAL and REG1
;
    LDA ZIMAG   ; REG2 = ZIMAG ^ 2
    SEC
    ROR
    STA MULTMP
    LDA #0
    STA REG2
    STA REG2+2
MI1 BCC MI2     ; Loop for lowest 16 bits
    CLC
    LDA REG2
    ADC ZIMAG
    STA REG2
    LDA REG2+2
    ADC ZIMAG+2
    STA REG2+2
MI2 ROR REG2+2
    ROR REG2
    LSR MULTMP
    BNE MI1
    LDA ZIMAG+2
    STA MULTMP
    LDX #8
MI3 LSR MULTMP  ; Loop for the rest of the fractional part
    BCC MI4
    CLC
    LDA REG2
    ADC ZIMAG
    STA REG2
    LDA REG2+2
    ADC ZIMAG+2
    STA REG2+2
MI4 ROR REG2+2
    ROR REG2
    DEX
    BNE MI3
    LDA MULTMP  ; Round with carry
    AND #1      ; And do the integer part
    TAX
    BEQ MI5
    LDA ZIMAG
    LDX ZIMAG+2
MI5 ADC REG2
    STA REG2
    TXA
    ADC REG2+2
    STA REG2+2

    CLC
    LDA REG1    ; RETURN IF ZREAL ^ 2 + ZIMAG ^ 2 >= 4
    ADC REG2
    LDA REG1+2
    ADC REG2+2
    CMP #$400
    BCC MA4
    RTS
MA4 SEC         ; REG1 -= REG2
    LDA REG1
    SBC REG2
    STA REG1
    LDA REG1+2
    SBC REG2+2
    STA REG1+2
;
; This is largely the same as the ZREAL ^ 2 and ZIMAG ^ 2 calculations, but
;   the last iteration of the second loop was moved outside the loop so that
;   the multiplication by 2 can be done "automatically"
;
    LDA ZREAL   ; REG2 = 2 * ZREAL * ZIMAG
    SEC
    ROR
    STA MULTMP
    LDA #0
    STA REG2
    STA REG2+2
MU1 BCC MU2     ; Lowest 16 bits (so far, the same)
    CLC
    LDA REG2
    ADC ZIMAG
    STA REG2
    LDA REG2+2
    ADC ZIMAG+2
    STA REG2+2
MU2 ROR REG2+2
    ROR REG2
    LSR MULTMP
    BNE MU1
    LDA ZREAL+2
    STA MULTMP
    LDX #7      ; Slightly different here, do all but the last bit of the
MU3 LSR MULTMP  ;   fraction here
    BCC MU4
    CLC
    LDA REG2
    ADC ZIMAG
    STA REG2
    LDA REG2+2
    ADC ZIMAG+2
    STA REG2+2
MU4 ROR REG2+2
    ROR REG2
    DEX
    BNE MU3
;
; We still have to do the last bit of the fractional part and the integer
;   part, but we don't want to shift right any more.  (In the earlier
;   multiplications, we shifted right one more time.)
;
; We also have the rounding bit in the carry here.
;
    LDA MULTMP  ; Round with carry
    AND #1      ; And do the last bit of the fractional part
    TAX
    BEQ MU5
    LDA ZIMAG
    LDX ZIMAG+2
MU5 ADC REG2
    STA REG2
    TXA
    ADC REG2+2
    STA REG2+2
;
; As before, the integer part must be 0 or 1, so add 0 or ZIMAG * 2
;
    LDA MULTMP
    AND #2
    BEQ MU6
    ASL ZIMAG
    ROL ZIMAG+2
;
; ZIMAG must be < 2, so the carry is clear here
;
;    CLC
    LDA REG2
    ADC ZIMAG
    STA REG2
    LDA REG2+2
    ADC ZIMAG+2
    STA REG2+2
MU6:

    CLC         ; ZREAL = CREAL + REG1
    LDA CREAL
    ADC REG1
    STA ZREAL
    LDA CREAL+2
    ADC REG1+2
    STA ZREAL+2
    LDA SIGN    ; BRANCH IF SIGN IS NEGATIVE
    BMI MA5
    CLC         ; ZIMAG = CIMAG + REG2
    LDA CIMAG
    ADC REG2
    STA ZIMAG
    LDA CIMAG+2
    ADC REG2+2
    STA ZIMAG+2
    DEY
    BEQ MARTS2
    JMP MA1
MA5 SEC         ; ZIMAG = CIMAG - REG2
    LDA CIMAG
    SBC REG2
    STA ZIMAG
    LDA CIMAG+2
    SBC REG2+2
    STA ZIMAG+2
    DEY
    BEQ MARTS2
    JMP MA1
MARTS2
    RTS

; Render the mandlebrot data
; Same functionality as lines 3000-3030, except that there is a separate
;   loop for rendering data
;
RENDER
    JSR IMGINIT    ; Initialize mandelbrot data index
    JSR RENDINIT   ; Initalize rendering
    TXA
    PHA
    TYA
    PHA
;
; In math graphs, Y is increasing when you move up (the vertical axis), but
;   on most computer systems, Y is increasing when you move down.  We were
;   increasing Y when we captured data, so we want to start at the bottom of
;   the screen and move up
;
    LDY NY
    DEY
RE1 LDX #0
RE2 JSR IMGGET     ; Get data
    JSR GETCOLOR   ; Get its color
    JSR PLOT       ; Plot it
    INX
    CPX NX
    BCC RE2
    DEY
    BPL RE1
    PLA
    TAY
    PLA
    TAX
    JSR STOP_TIMER
    JMP PLOTEND    ; Perform any plotting clean up
;
; Turn mandelbrot data into a color
;
GETCOLOR6
    STX COLORTMP
    TAX            ; Use color 0 (black) when data is 0
    BEQ GC1
    JSR INTMOD     ; Calculate MOD (line 3010)
    TAX
    LDA COLORTBL,X ; This is a 16-bit load...
    AND #MASK      ; ...so mask the low byte
GC1 LDX COLORTMP
    RTS
;
; As close as lo-res can get to the colors of the rainbow (red, orange,
;   yellow, green, blue, purple)
;
COLORTBL .byte 1,9,13,12,6,3
COLORTBLEND

; Get mandelbrot data
;
IMGGET
    STX IMGTMP
    LDX IMGIDX
    LDA IMAGEBUF,X
    INX            ; Advance the index
    INX
    STX IMGIDX
    LDX IMGTMP
    RTS

; Initialize mandelbrot data index
;
IMGINIT
    PHA
    LDA #0
    STA IMGIDX
    PLA
    RTS

; Store mandelbrot data
;
IMGPUT
    STX IMGTMP
    LDX IMGIDX
    STA IMAGEBUF,X
    INX            ; Advance the index
    INX
    STX IMGIDX
    LDX IMGTMP
    RTS

;
;
INTMOD
    ASL
    STA INTQ   ; Store numerator
    TXA
    PHA
    LDA #0     ; Standard 16-bit / 16-bit 6502 integer division routine
    LDX #16
MO1 ROL
    CMP INTBOT
    BCC MO2
    SBC INTBOT
MO2 ROL INTQ
    DEX
    BNE MO1
    STA INTQ   ; Save the remainder
    PLA
    TAX
    LDA INTQ   ; Restore the remainder
    RTS
;
; Rendering initialization
;
RENDINIT
    PHA
    LDA #COLORTBLEND-COLORTBL ; Prepare denominator for color selection
    STA INTBOT
    PLA
    JMP PLOTBEGIN             ; Initialize plotting

; Save/restore

; Initialize save/restore
;
SAVEINIT
    PHA
    LDA #ZPEND-ZPSTART
    STA SAVESP
    PLA
    RTS

; Save zero page
;
SAVE0
    TXA
    PHA
    TYA
    PHA
    LDX #0
    LDY SAVESP
SV1 LDA ZPSTART,X
    INX
    DEY
    STA ZPBUF,Y
    CPX #ZPEND-ZPSTART
    BCC SV1
    STY SAVESP
    PLA
    TAY
    PLA
    TAX
    RTS

; Restore zero page
;
RESTORE0
    TXA
    PHA
    TYA
    PHA
    LDX #ZPEND-ZPSTART
    LDY SAVESP
RS1 LDA ZPBUF,Y
    INY
    DEX
    STA ZPSTART,X
    BNE RS1
    STY SAVESP
    PLA
    TAY
    PLA
    TAX
    RTS

; Fixed-point routines

; Add top two numbers on stack
; ( a b -- a+b )
;
FPADD
    PHA
    TXA
    PHA
    LDX FPSP
    CLC
    LDA SFL+2,X
    ADC SFL,X
    STA SFL+2,X
    LDA SFH+2,X
    ADC SFH,X
    STA SFH+2,X
    LDA SIL+2,X
    ADC SIL,X
    STA SIL+2,X
    LDA SIH+2,X
    ADC SIH,X
    STA SIH+2,X
    INX
    INX
    STX FPSP
    PLA
    TAX
    PLA
    RTS

; Duplicate top of stack
; ( a -- a a )
;
FPDUP
    PHA
    TXA
    PHA
    LDX FPSP
    DEX
    DEX
    LDA SFL+2,X
    STA SFL,X
    LDA SFH+2,X
    STA SFH,X
    LDA SIL+2,X
    STA SIL,X
    LDA SIH+2,X
    STA SIH,X
    STX FPSP
    PLA
    TAX
    PLA
    RTS

; Push the value of the FP variable (whose index is in A) onto the stack
; ( -- a )
;
FPFETCH
    STA FPTEMP
    PHA
    TXA
    PHA
    TYA
    PHA
    LDX FPSP
    LDY FPTEMP
    DEX
    DEX
    LDA FPVARS,Y
    STA SFL,X
    LDA FPVARS+2,Y
    STA SFH,X
    LDA FPVARS+4,Y
    STA SIL,X
    LDA FPVARS+6,Y
    STA SIH,X
    STX FPSP
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

; Multiply top of stack by ten
; ( a -- a*10 )
;
FPMUL10
    JSR FPDUP
    JSR FPMUL2
    JSR FPMUL2
    JSR FPADD
    JMP FPMUL2

; Multiply top of stack by two
; ( a -- a*2 )
;
FPMUL2
    PHA
    TXA
    PHA
    LDX FPSP
    ASL SFL,X
    ROL SFH,X
    ROL SIL,X
    ROL SIH,X
    PLA
    TAX
    PLA
    RTS

; Multiply top of stack by 65536
; ( a -- a*65536 )
;
FPMUL65536
    PHA
    TXA
    PHA
    LDX FPSP
    LDA SIL,X
    STA SIH,X
    LDA SFH,X
    STA SIL,X
    LDA SFL,X
    STA SFH,X
    LDA #0
    STA SFL,X
    PLA
    TAX
    PLA
    RTS

; Negate top of stack
; ( a -- -a )
;
FPNEG
    PHA
    TXA
    PHA
    LDX FPSP
    SEC
    LDA #0
    SBC SFL,X
    STA SFL,X
    LDA #0
    SBC SFH,X
    STA SFH,X
    LDA #0
    SBC SIL,X
    STA SIL,X
    LDA #0
    SBC SIH,X
    STA SIH,X
    PLA
    TAX
    PLA
    RTS

; Pull low 16-bit of integer portion of top of stack and return in A
; ( a -- )
;
FPPULL
    STX FPTEMP
    LDX FPSP
    LDA SIL,X
    INX
    INX
    STX FPSP
    LDX FPTEMP
    RTS

; Push (unsigned) integer in A onto the stack
; ( -- a )
;
FPPUSH
    PHA
    STX FPTEMP
    LDX FPSP
    DEX
    DEX
    STA SIL,X
    LDA #0
    STA SFL,X
    STA SFH,X
    STA SIH,X
    STX FPSP
    LDX FPTEMP
    PLA
    RTS

; Raise 10 to the power of A
; ( -- 10^A )
;
FPPWR10
    PHA
    LDA #1
    JSR FPPUSH
    PLA
    PHA
    BEQ FP2
FP1 JSR FPMUL10
    SEC
    SBC #1
    BNE FP1
FP2 PLA
    RTS

; If the carry is set, round the top of the stack up
; ( a -- a+carry*2^-32 )
;
FPROUNDUP
    BCC FR2
    PHA
    TXA
    PHA
    LDX FPSP
    INC SFL,X
    BNE FR1
    INC SFH,X
    BNE FR1
    INC SIL,X
    BNE FR1
    INC SIH,X
FR1 PLA
    TAX
    PLA
FR2 RTS

; Set the FP stack size
;
FPSETSTACKSIZE
    ASL
    STA FPSP
    ROR
    RTS

; Store the top of the stack in the FP variable whose index is in A
; ( a -- )
;
FPSTORE
    STA FPTEMP
    PHA
    TXA
    PHA
    TYA
    PHA
    LDX FPSP
    LDY FPTEMP
    LDA SFL,X
    STA FPVARS,Y
    LDA SFH,X
    STA FPVARS+2,Y
    LDA SIL,X
    STA FPVARS+4,Y
    LDA SIH,X
    STA FPVARS+6,Y
    INX
    INX
    STX FPSP
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

; Subtract top two items on the stack
; ( a b -- a-b )
;
FPSUB
    PHA
    TXA
    PHA
    LDX FPSP
    SEC
    LDA SFL+2,X
    SBC SFL,X
    STA SFL+2,X
    LDA SFH+2,X
    SBC SFH,X
    STA SFH+2,X
    LDA SIL+2,X
    SBC SIL,X
    STA SIL+2,X
    LDA SIH+2,X
    SBC SIH,X
    STA SIH+2,X
    INX
    INX
    STX FPSP
    PLA
    TAX
    PLA
    RTS

; Divide (unsigned) top two numbers on stack; return rounding bit in carry
; ( a b -- a/b )
;
FPUDIV
    PHA
    TXA
    PHA
    TYA
    PHA
    LDX FPSP
    LDA SIL+2,X
    STA FPTEMP
    LDA SIH+2,X
    STA FPTEMP+2
    LDA #0
    STA FPTEMP+4
    STA FPTEMP+6
    LDA SFL+2,X
    ASL
    STA SIL+2,X
    LDA SFH+2,X
    ROL
    STA SIH+2,X
    LDY #$40
FD1 ROL FPTEMP   ; FPTEMP holds the remainder
    ROL FPTEMP+2
    ROL FPTEMP+4
    ROL FPTEMP+6
    BCS FD2
    LDA FPTEMP
    CMP SFL,X
    LDA FPTEMP+2
    SBC SFH,X
    LDA FPTEMP+4
    SBC SIL,X
    LDA FPTEMP+6
    SBC SIH,X
    BCC FD3
FD2 LDA FPTEMP
    SBC SFL,X
    STA FPTEMP
    LDA FPTEMP+2
    SBC SFH,X
    STA FPTEMP+2
    LDA FPTEMP+4
    SBC SIL,X
    STA FPTEMP+4
    LDA FPTEMP+6
    SBC SIH,X
    STA FPTEMP+6
    SEC
FD3 ROL SFL+2,X  ; S+2,X holds the quotient
    ROL SFH+2,X
    ROL SIL+2,X
    ROL SIH+2,X
    DEY
    BNE FD1
    ASL FPTEMP   ; If remainder >= bottom / 2 (i.e. 2 * remainder >= b),
    ROL FPTEMP+2 ;   then set carry for rounding
    ROL FPTEMP+4
    ROL FPTEMP+6
    BCS FD4
    LDA FPTEMP
    CMP SFL,X
    LDA FPTEMP+2
    SBC SFH,X
    LDA FPTEMP+4
    SBC SIL,X
    LDA FPTEMP+6
    SBC SIH,X
FD4 INX
    INX
    STX FPSP
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

; Divide (unsigned) the top of the stack by 2; return rounding bit in carry
; ( a -- a/2 )
;
FPUDIV2
    PHA
    TXA
    PHA
    LDX FPSP
    LSR SIH,X
    ROR SIL,X
    ROR SFH,X
    ROR SFL,X
    PLA
    TAX
    PLA
    RTS

; Multiply (unsigned) top two numbers on stack
; ( a b -- a*b )
;
FPUMUL
    PHA
    TXA
    PHA
    TYA
    PHA
    LDX FPSP
    LDA #0       ; Initialize product
    STA FPTEMP
    STA FPTEMP+2
    STA FPTEMP+4
    STA FPTEMP+6
    LDY #$20
FM1 LSR SFH+2,X  ; Multiply fractional portion
    ROR SFL+2,X
    BCC FM2
    CLC
    LDA SFL,X
    ADC FPTEMP
    STA FPTEMP
    LDA SFH,X
    ADC FPTEMP+2
    STA FPTEMP+2
    LDA SIL,X
    ADC FPTEMP+4
    STA FPTEMP+4
    LDA SIH,X
    ADC FPTEMP+6
    STA FPTEMP+6
FM2 ROR FPTEMP+6
    ROR FPTEMP+4
    ROR FPTEMP+2
    ROR FPTEMP
    DEY
    BNE FM1
    PHP
    LDY #$20
FM3 LSR SIH+2,X  ; Multiply integer portion
    ROR SIL+2,X
    BCC FM4
    CLC
    LDA SFL,X
    ADC FPTEMP
    STA FPTEMP
    LDA SFH,X
    ADC FPTEMP+2
    STA FPTEMP+2
    LDA SIL,X
    ADC FPTEMP+4
    STA FPTEMP+4
    LDA SIH,X
    ADC FPTEMP+6
    STA FPTEMP+6
FM4 ASL SFL,X
    ROL SFH,X
    ROL SIL,X
    ROL SIH,X
    DEY
    BNE FM3
    INX
    INX
    LDA FPTEMP   ; Copy product to stack
    STA SFL,X
    LDA FPTEMP+2
    STA SFH,X
    LDA FPTEMP+4
    STA SIL,X
    LDA FPTEMP+6
    STA SIH,X
    PLP
    STX FPSP
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

; Apple II specific routines

; Initialize native mode, and direct register
;
A2MAIN
   CLC
   XCE
   PHP
   REP #$30
   PHD
   PEA #DPAGE
   PLD
   JSR MAIN
   PLD
   PLP
   XCE
   RTS

; Capture start time
;
A2STARTTIMER
   SEP #$40
   .byte $50          ; Skip CLV and fall through
;
; Capture stop time
;
A2STOPTIMER
   CLV
   CLC
   XCE
   PHP
   REP #$30
   PEA #0             ; Push start time buffer address
   PER A2TIMERBUF     ; "
   BVS @A
   PLX                ; Push stop time buffer address instead
   PER A2TIMERBUF+$14
@A LDX #$0F03         ; ReadAsciiTime call (returns 20 byte time string)
   JSL $E10000        ; Call the IIgs toolbox
   PLP
   XCE
   RTS

; Save registers and call the code which follows the JSR CALLE in emulation
;   mode; upon returning from that code, restore registers and native mode
;
CALLE
   CLC
   .byte $B0 ; Skip SEC and fall through
;
; Same as CALLE, but don't preserve A (but clear its high byte)
;
CALLEA
   SEC
   PHA
   LDA 3,S   ; Get the address of the routine
   INC       ; Add 1 since JSR pushes the address minus 1
   STA @B+1  ; Self-modify the JSR below
;
; When we return from CALLE (or CALLEA) we'll be in native mode, and we
;   don't want to return to the code that follows the JSR CALLE (or JSR
;   CALLEA), since that's the code that should be called in emulation mode,
;   so we get a little sneaky here and change the return address on the stack
;   to return not to the code that follows the JSR CALLE but to the RTS at @C
;   instead.  We could move things around on the stack so that the return
;   address is no longer there, but that's even uglier.
;
   LDA #@C-1 ; RTS expects address minus 1
   STA 3,S
   PLA
   BCS @A    ; Don't save A if its CALLEA
   PHA
@A PHD
   PHX
   PHY
   PHP
   PEA #0
   PLD
   SEC
   XCE
@B JSR 0     ; This gets self-modified
   CLC
   XCE
   PLP       ; We get the m and x flags back here but also the carry which
   PLY       ;   tells us whether its CALLE or CALLEA
   PLX
   PLD
   AND #$FF  ; Clear the high bit in case its CALLEA
   BCS @C    ; Don't restore if its CALLEA
   PLA
@C RTS

   .assume accum:8
   .assume index:8

; Input a character, return it in A
;
A2INPUT
   JSR CALLEA
   JSR $FD35  ; Call ROM input routine (allow esc editing sequences)
   EOR #$80   ; Return with bit 7 clear
   RTS

; Output the character in A
;
A2OUTPUT
   JSR CALLE
   EOR #$80  ; Set bit 7
   JMP $FDF0 ; Call ROM output routine

; Output a CRLF sequence (in this case just the CR)
;
A2OUTCRLF
   JSR CALLE
   JMP $FD8E ; Call ROM output CR routine

; Initialize plotting (in this case, switch to the graphics screen; we don't
;   bother to clear it, since we'll be overwriting it anyway)
;
A2PLOTBEGIN
   JSR CALLE
   BIT $C050 ; Graphics screen on
   BIT $C052 ; Full screen
   BIT $C056 ; Lo-res
   RTS

; Plot a point: A = color, X = X coordinate, Y = Y coordinate
;
A2PLOT
   JSR CALLE
   JSR $F864 ; Call set lo-res color ROM routine
   TYA
   TXY
   JMP $F800 ; Call lo-res plot ROM routine

; Plotting clean up (in this case, wait for keypress and switch to the text
;   screen)
;
A2PLOTEND
   JSR CALLE
@A BIT $C061 ; Wait for the (open) apple key to be pressed
   BPL @A
   JMP $FB2F ; Switch to the text screen

; Show the start and stop times.  This should be called from emulation mode.
;
A2TIMEROUT
   PER A2TIMERBUF
   LDY #0
@A LDX #$14
@B LDA (1,S),Y
   JSR $FDF0      ; Call output ROM routine
   INY
   DEX
   BNE @B
   JSR $FD8E      ; Call output CR ROM routine
   CPY #$28
   BCC @A
   PLA            ; Discard buffer address
   PLA
   RTS

; RAM variables and buffers

; Mandelbrot application
;
IBUF       .ds INPUTMAXLEN+2
MSGTEMP    .ds 2
PARSECOUNT .ds 2
PARSEDIG   .ds 2
PARSEINDEX .ds 2
STORETMP   .ds 2

FPVARS:
VREAL .ds 8
VIMAG .ds 8
VMAG  .ds 8
VASP  .ds 8

; Mandelbrot generation
;
MVARS:
CREAL   .ds 4
CIMAG   .ds 4
DX      .ds 4 ; Always positive
DY      .ds 4 ; "
TIMEOUT .ds 2

COLORTMP .ds 2
IMGIDX   .ds 2
IMGTMP   .ds 2
INTBOT   .ds 2
INTQ     .ds 2
MTEMP    .ds 2

; Save/restore
;
SAVESP .ds 2
ZPBUF  .ds ZPEND-ZPSTART

; Fixed-point library
;
FPSP   .ds 2
FPTEMP .ds 8
SFL    .ds FPSTACKSIZE*2
SFH    .ds FPSTACKSIZE*2
SIL    .ds FPSTACKSIZE*2
SIH    .ds FPSTACKSIZE*2

; Apple II specific
;
A2TIMERBUF .ds $28

GETCOLOR    .equ GETCOLOR6
INPUT       .equ A2INPUT
OUTPUT      .equ A2OUTPUT
OUTCRLF     .equ A2OUTCRLF
PLOTBEGIN   .equ A2PLOTBEGIN
PLOT        .equ A2PLOT
PLOTEND     .equ A2PLOTEND
START_TIMER .equ A2STARTTIMER
STOP_TIMER  .equ A2STOPTIMER
