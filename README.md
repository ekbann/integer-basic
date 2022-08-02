# Game BASIC Compiler (GBC)

Why? When I first heard about the cool project Commander X16, the best 8-bit computer with modern still-available components, I wanted to play with it. Fortunately they had an emulator for users to start developing software. Using the CC65 compiler suite, I did the simple "Hello, World!" test using `printf()` and the result was an enormous executable. I thought that I could do better and more efficiently and that was enough reason and an excuse for me to go back to my first love, compiler design. I chose Woz's Integer BASIC as a model simply because it had a very simple grammar without floating-point complexities.

Why a 6502 compiler? I am a BIG fan of 8-bit computers such as the Commodore 64 and Apple ][ family. The Commander X16 has a boosted 8MHz 65c02 CPU, 2MB of banked RAM along with the main 64K memory, and an advanced audio/graphics called the VERA. This compiler will hopefully generate fast assembly code.

Why BASIC? The BASIC language is a proven and very capable programming language that has a very simple grammar. Woz said that BASIC is "not a real super structured language where you have to learn so much about the structure. It's better to learn structure from the ground up, the basic atoms. Which is what BASIC is. To learn the structure from the ground up, once you've learned it you will apply it in a structured language. Then you're ready for it." Also, it is not  hard to translate into 6502 assembly language because of its similarities like GOTO/JMP and GOSUB/JSR.

Why integers? As Woz famously said, "all you need for games is integers," such that he sometimes refers to it as Game BASIC. While it can run in integer mode only (so I can beat all of the available INT benchmarks), I am adding fixed-point signed Q16.16 capability to render beautiful Mandebrot plots (it will perform better than other BASIC with floating-point math). Adding real number mathematics is the hard part. There are no MUL or DIV on the 6502 instruction set, that means doing bit SHIFTs and ROTATEs manually.

Game BASIC Compiler eventually evolved with the addition of signed fixed-point arithmetics (Q16.16). The 16-bit integer part perfectly integrates with the 16-bit mantissa part without needing any conversion from fixed-point to integer and vice-versa.

### BENCHMARK

In the Byte Sieve (https://en.wikipedia.org/wiki/Byte_Sieve), where math was less important (only integer operations) but array access and looping performance dominated, we obtain the results below (for 1 iteration only):

Platform | Time
--- | ---
Commodore 64 BASIC | 315 s
Applesoft BASIC | 200 s
Apple Integer BASIC | 166 s
Apple IIgs | ? s
Commander X16 BASIC 2.0 | 42.35 s
Game BASIC Compiler (X16) | 4.17 s
cc65 original C program (X16) | 0.75 s
Prog8 C program conversion (X16) | 0.25 s

Game BASIC Compiler will really shine during fixed-point operations.

### FIXED POINT

Signed Fixed-Point Q16.16

Precision: The value of the least significant bit, and therefore the precision of the number, is determined by the number of fractional bits. A fixed-point value can be represented to within half of the precision of its data type and scaling. The term resolution is sometimes used as a synonym for this definition. For example, a fixed-point representation with sixteen bits to the right of the binary point has a precision of $2^{-16}$ or 0.00001526, which is the value of its least significant bit. Any number within the range of this data type and scaling can be represented to within ${2^{-16} \over 2}$ or 0.000007629, which is half the precision. This is an example of representing a number with finite precision.

### IMPORTANT

Do NOT use single letters as variable names because it can crash the compiler:

"Use of identifiers consisting of a single character will not work in all cases, because some of these identifiers are reserved keywords (for example "A" is not a valid identifier for a label, because it is the keyword for the accumulator)."

Debugging can be done by editing the A65 assembly source and add the following instructions:

* `jsr FPSTACK` - prints the entire active stack (4-bytes per level) in the signed Q16.16 format
* `stp` - 6502 SToP instruction which pauses program execution and enter the X16 debugger; needs `-debug` option
* `LoadAddress <label>` - loads the address of `<label>` into the `r0` register; easy to see in the debugger
* `MoveW <var_id>,r0` - loads the **value** from variable `<var_id>` into the `r0` register
* `TIME` - use this BASIC command to print the BASIC timer in jiffies (1/60 s) in 24-bit hexadecimal

Remember not to compile directly from BAS source otherwise that will overwrite the edited A65 assembly source.

### HOW-TO

STEP 1: Compile BASIC program to 6502 assembly code

```./basic.py program.bas```
    -> generates program.a65

STEP 2: Assemble A65 source to 6502 machine code using ca65

```./make.sh program.a65```
    -> generates program.prg
    -> executes x16

Alternatively: Complete compile from BASIC to PRG

```./make.sh -b program.bas```
    -> generates program.a65
    -> generates program.prg
    -> executes x16
