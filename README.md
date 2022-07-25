============================
Integer BASIC aka Game BASIC
============================

Why Integer BASIC? As Woz famously said, for games all you need is integers, such that he sometimes refers to it as Game BASIC.

Why then write a compiler to 6502 assembly instructions?

==============
IMPLEMENTATION
==============

Implements Woz's Integer BASIC with a few additional commands from Applesoft
BASIC (AS) or GW-BASIC (GW):

DATA (AS) : Define inline data; can be literals (unquoted strings), strings or numbers
READ (AS) : Read the next DATA value
RESTORE (AS) : Restore the DATA pointer to the first value
HOME (AS) : Clear text display
LOCATE r,c (GW) : Move cursor to the specified position
GET (AS) : Read single key

=========
IMPORTANT
=========

Do NOT use single letters as variable names because it can crash the compiler:

"Use of identifiers consisting of a single character will not work in all cases, because some of these identifiers are reserved keywords (for example "A" is not a valid identifier for a label, because it is the keyword for the accumulator)."

==========
TECH NOTES
==========

Signed Fixed-Point Q16.16

Precision: The value of the least significant bit, and therefore the precision of the number, is determined by the number of fractional bits. A fixed-point value can be represented to within half of the precision of its data type and scaling. The term resolution is sometimes used as a synonym for this definition. For example, a fixed-point representation with sixteen bits to the right of the binary point has a precision of $2^{-16}$ or 0.00001526, which is the value of its least significant bit. Any number within the range of this data type and scaling can be represented to within ${2^{-16} \over 2}$ or 0.000007629, which is half the precision. This is an example of representing a number with finite precision.

===
OBS
===

TAB x where x=1-40 same as HTAB (AS)
VTAB x where x=1-24
POP : Convert last GOSUB into a GOTO
