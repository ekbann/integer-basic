# Integer BASIC aka Game BASIC Compiler (GBC)

Why write a compiler to 6502 assembly instructions? I am a BIG fan of 8-bit computers such as the Commodore 64 and Apple ][+ or //e. There is a new project to design and build a modern 8-bit computer with modern components and a boosted 8MHz 65c02 CPU called the Commander X16. This compiler is to be used on that platform to generate fast assembly code.

Why Integer BASIC? As Woz famously said, for games all you need is integers, such that he sometimes refers to it as Game BASIC. BASIC has a very simple language grammar and is not too hard to translate to assembly language.

Only integers? Well, actually no. While it can run in interger mode only (so I can beat all of the available INT benchmarks), I am adding fixed-point signed Q16.16 capability to render beautiful Mandebrot plots (initial goal; also to beat all of the available FP benchmarks as well).

### IMPLEMENTATION

Implements Woz's Integer BASIC with a few additional commands from Applesoft
BASIC (AS) or GW-BASIC (GW):

* DATA (AS) : Define inline data; can be literals (unquoted strings), strings or numbers
* READ (AS) : Read the next DATA value
* RESTORE (AS) : Restore the DATA pointer to the first value
* HOME (AS) : Clear text display
* LOCATE r,c (GW) : Move cursor to the specified position
* GET (AS) : Read single key

### IMPORTANT

Do NOT use single letters as variable names because it can crash the compiler:

"Use of identifiers consisting of a single character will not work in all cases, because some of these identifiers are reserved keywords (for example "A" is not a valid identifier for a label, because it is the keyword for the accumulator)."

### HOW-TO

STEP 1: Compile BASIC program to 6502 assembly code

```./basic.py program.bas```
    -> generates program.a65

STEP 2: Assemble A65 source to 6502 machine code using ca65

```./make.sh program.a65```
    -> generates program.prg
    -> executes x16

### TECH NOTES

Signed Fixed-Point Q16.16

Precision: The value of the least significant bit, and therefore the precision of the number, is determined by the number of fractional bits. A fixed-point value can be represented to within half of the precision of its data type and scaling. The term resolution is sometimes used as a synonym for this definition. For example, a fixed-point representation with sixteen bits to the right of the binary point has a precision of $2^{-16}$ or 0.00001526, which is the value of its least significant bit. Any number within the range of this data type and scaling can be represented to within ${2^{-16} \over 2}$ or 0.000007629, which is half the precision. This is an example of representing a number with finite precision.

### OBS

* TAB x where x=1-40 same as HTAB (AS)
* VTAB x where x=1-24
* POP : Convert last GOSUB into a GOTO
