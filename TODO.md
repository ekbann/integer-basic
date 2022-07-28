### FINISH VTAB FOR NON-INT CASES (LIKE TAB AND COLOR)
### LOOP vars don't need to be 4 bytes long (32-bit)

### FIXME

DIM: Re-dimension of a pre-existing A$; memory problems

### OPTIMIZE

Any `PushVar XYZ` followed by `jsr PULL` to access `r0` can be optimized as such:

```
ldx XYZ     ; loads .X with lo-byte of XYZ
ldy XYZ+1   ; loads .Y with hi-byte of XYZ
```

### CREATE NEW BASIC AUTORUN HEADER WITH TIMER

Create new basic_header.a65 that runs a TIMER:
```
    10 PRINT INITIAL TIME
    20 CALL 2064
    30 PRINT FINAL TIME
    40 PRINT ELAPSED TIME
    <6502 CODE>
```
### CREATE NEW BASIC COMMAND

SETCOLOR: New BASIC command to change the 16-color palette

### OPTIMIZE U32DIV16

U32DIV16: .Y is used for temporary byte storage.
    use a memory location instead and use .Y (or .X) for FPSP index == smaller code
    optimize U32DIV16: avoid copying TOS to FPTEMP and back

### OPTIMIZE PrFP32 TO PULL FROM STACK

PrFP32: maybe convert it to print from r0/r1 like PrDec16 prints from r0 (but copies to r11)

### FIX BASIC PRINT COMMAND

UNIT: loop1
    PRINT does not terminate with LF/CR when using ',' separator.

### MAKE SURE USER DOESN'T USE SINGLE CHARACTER VARIABLES

UNIT: assignment
    variable "A" crashes ca65 assembler, conflict with cc65 macros
    cc65 treats "A" as accumulator, need to rename variables as "var_A"
    "Use of identifiers consisting of a single character will not work in all cases, because some of these identifiers are reserved keywords (for example "A" is not a valid identifier for a label, because it is the keyword for the accumulator)."

### CREATE FUNCTION LIBRARY

Learn to compile a library and only add used functions to the final code.

### NOT SURE IF THIS IS NEEDED

FPMUL32
FP (32-bit) x FP (32-bit) = 64-bit FPTEMP ==> 8 bytes (really need 8 bytes?)
iiii.ffff x iiii.ffff = aaaa.bbbb:cccc.cccc
result = bbbb:cccc

### CHECK IF I FINISHED THE FUNCTIONS BELOW:

```
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

Add Zero Page variables
Add r0-r15 16-bit registers
Add .B suffix for unsigned byte (normal VAR is 16-bit)
Add ADD8(), SUB8(), MUL8() and DIV8() for .B
Add support for hexadecimals $ff5c
BASIC V2 commands: CHR$,GET,TIME,ASC
Add FP command to run BASIC in SIGNED Q16.16 FIXED-POINT MODE otherwise runs in SIGNED 16-bit INTEGER MODE
```

### DONE

DONE: URGENT: PrDec16 pads with 5 '0' which breaks PrFP32 because it needs '0000' and '0000'
        and PrDec16Lp1 does NOT work as it should... ldy #6 ==> 4 digits
        call PrDec16 but changing line 3 to:
```
                LDY #6			; Offset to powers of ten
```

works!!! prints decimal with 4 places padding with '0'. WHY?

DONE: PUSH needs to zero SFL/SFH to avoid FPSTACK garbage.

DONE: CONVERT MANTISSA Q16.16 ==> .16 part to INTEGER ==> PrDec16
		PUSH mantissa (16-bit) as an integer
		decimal 10,000 ($2710); largest that fits in 16-bit
        jsr UMUL	; (mantissa * 10000) / (2^16) <-- just the MSW of FP
        mantissa is always UNSIGNED
        REPEAT to extend 4 decimals '9999' to 8 decimals '99999999'

DONE:   CONVERT ASCII MANTISSA ==> to .16 part
        ASCII to UNSIGNED INTEGER (normal ATOI)
        Copy mantissa INT to SIL/SIH, zero SFL/SFH == ffff:0000 (32-bit) use FPTEMP
        UDIV by $2710
        Copy LSW (least significant WORD) to SFL/SFH
        therefore... NEED 32-bit DIV 16-bit == 16-bit RESULT

DONE: ATOFP is buggy because it can only process 4 digits in the mantissa at a time!
    3.14159 => "14,159" overflows the "9,999" limit
    PrFP32 works by printing "xxxx" twice (two UMUL $2710)
    but ATOFP needs work... reverse PrFP32 and undo twice with mantissa text processed:
    0-4 chars = pad to 8 char string; "aaaa0000"
    5-8 chars = pad to 8 char string; "aaaabbbb"; e.g. "14159000"
    start undoing "bbbb" = "9000":
        9000:0000 / 10000 = "0000:xxxx" where xxxx is the LSW for the next round
    start undoing "aaaa" = "1415":
        1415:xxxx / 10000 = "0000:yyyy" where yyyy is the ORIGINAL mantissa for .14159000

DONE:   Need to print FPTEMP from 4 bytes to 8 bytes(?). NO, algo doesnt need
        Verify if Q16.16 needs 64-bit temp storage. NO

DONE: ### COLOR = XX

PushVar XX ==> Load contents at address XX into TOS
jsr PULL ==> Removes TOS into register r0

We can optimize by Loading the XX value (two bytes) directly into r0
Even better, inside the COLOR compile section, LDA XX should do the trick

```
L30:		PushVar XX
		jsr PULL
		ldx r0L
		lda GRCOLORS,x		; SET FOREGROUND COLOR
		jsr CHROUT
		lda #$01		; SWAP FOREGROUND AND BACKGROUND COLOR
		jsr CHROUT
```
