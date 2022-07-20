"""
========================
INT BASIC aka GAME BASIC
========================

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
"""

from lark import Lark, Tree, Token

try:
    input = raw_input   # For Python2 compatibility
except NameError:
    pass

basic_grammar = """
    start: line+

    line: INT statement [(":" statement)*]

    ?statement: ("HOME" | "CLS") -> home
              | "END" -> end
              | "DATA" constant [("," constant)*] -> data
              | "READ" ID [("," ID)*] -> read
              | "CALL" expression -> call
              | "GOTO" expression -> goto
              | "GOSUB" expression -> gosub
              | "RETURN" -> return
              | "POKE" expression "," expression -> poke
              | "TAB" expression -> tab
              | "VTAB" expression -> vtab
              | "DIM" (VAR_ID | STR_ID) "(" expression ")" [("," ID "(" expression ")")*] -> dim
              | "INPUT" [STRING ","] ID [("," ID)*] -> input
              | ("PRINT" | "?") (expression (PRINT_OP expression?)*)? -> print
              | "IF" expression "THEN" (INT | statement) -> if
              | "NEXT" VAR_ID [("," VAR_ID)*] -> next
              | "FOR" VAR_ID "=" expression "TO" expression ("STEP" expression)? -> for
              | "COLOR" "=" expression -> color
              | "LET"? (VAR_ID | STR_ID) "=" expression -> assignment
              | COMMENT -> comment
              | "POP" -> pop
              | "GR" -> gr
              | "TEXT" -> text
              | "PLOT" expression "," expression -> plot
              | "HLIN" expression "," expression "AT" expression -> hlin
              | "VLIN" expression "," expression "AT" expression -> vlin
              | STR_ID "(" INT ")" "=" (STRING | STR_ID) -> concat

    ?expression: or_exp
    
    ?or_exp: [(expression "OR")*] and_exp

    ?and_exp: [(and_exp "AND")*] not_exp

    ?not_exp: "NOT" not_exp -> not
            | compare_exp

    ?compare_exp: [(compare_exp REL_OP)*] add_exp

    ?add_exp: [(add_exp ADD_OP)*] mul_exp

    ?mul_exp: [(mul_exp MUL_OP)*] neg_exp

    ?neg_exp: "-" power_exp -> neg
            | power_exp

    ?power_exp: power_exp "^" sub_exp -> power
              | sub_exp

    ?sub_exp: "(" expression ")"
            | value

    ?value: (VAR_ID | STR_ID)
          | STR_ID "(" INT "," INT ")" -> substring
          | "ABS" "(" expression ")" -> abs
          | "LEN" "(" expression ")" -> len
          | "PEEK" "(" expression ")" -> peek
          | "RND" "(" expression ")" -> rnd
          | "SGN" "(" expression ")" -> sgn
          | "ASC" "(" expression ")" -> asc
          | "PDL" "(" expression ")" -> pdl
          | "SCRN" "(" expression "," expression ")"
          | constant

    ?constant: INT
             | STRING

    PRINT_OP: "," | ";"
    REL_OP: "=" | "#" | "!=" | ">=" | ">" | "<=" | "<>" | "<"
    ADD_OP: "+" | "-"
    MUL_OP: "*" | "/" | "%" | "MOD"
    VAR_ID: (LETTER)(LETTER|INT)*
    STR_ID: VAR_ID "$"
    ID: STR_ID | VAR_ID
    STRING: "\\"" /.*?/ "\\""
    COMMENT: "REM" /[^\\n]/*

    %import common.LETTER
    %import common.INT
    %import common.WS
    %ignore WS
"""

parser = Lark(basic_grammar)

text = '''
10 REM TAB
20 DIM B(16)
25 DIM C(2*8)
28 DIM D(6+10)
30 PRINT "END"
50 END
'''

print(text)
print(parser.parse(text).pretty())

str_count = 0       # counter for string labels L0, L1, ...
str_list = []       # list of strings to use .byte
var_id_list = []    # list of VAR_ID
dim_list = {}       # dictionary of STR_ID with size
dim_ptr_list = []   # list of STR_ID without size, defined at runtime, uses pointer in BUFFER space
#loop_count = 0
loop_list = []

###
### COMPILER FUNCTION
###
def compile(t):
    global str_count
    global str_list     # STRING
    global var_id_list  # VAR_ID
    global dim_list     # STR_ID
    global dim_ptr_list
    #global loop_count
    global loop_list
    
    ###
    ### PROCESS TOKEN OBJECT = <class 'lark.lexer.Token'>
    ###
    if isinstance(t, Token):
        # GAMBLE: will put all INT and VAR into stack HERE. Seems to work well!
        if t.type == 'INT':              # lval is an INT
            print("\t\tPushInt " + t)
        elif t.type == 'VAR_ID':
            print("\t\tPushVar " + t)
        # GAMBLE 2: need to return STR_ID or STRING for other routines??? e.g. PRINT and INPUT
        else:
            return t
    
    ###
    ### PROCESS TREE OBJECT = <class 'lark.tree.Tree'>
    ###
    elif isinstance(t, Tree):
        ###
        ### LINE NUMBER
        ###
        if t.data == 'line':
            line_num = t.children.pop(0)
            print("L" + line_num + ":", end="")
            for cmd in t.children:
                compile(cmd)

        ###
        ### REM
        ###
        elif t.data == 'comment':                       
            print("\t\t; " + t.children[0])

        ###
        ### HOME
        ###
        elif t.data == 'home':                          
            print("\t\tlda #HOME")
            print("\t\tjsr CHROUT")

        ###
        ### END
        ###
        elif t.data == 'end':                           
            print("\t\trts")

        ###
        ### ABS
        ###
        elif t.data == 'abs':                           
            compile(t.children[0])
            print("\t\tjsr ABS")

        ###
        ### DIM
        ###
        elif t.data == 'dim':
            dim_name = t.children[0]
            #print(dim_name)
            if isinstance(t.children[1], Token):
                if t.children[1].type == 'INT':             # INT, no need for stack usage
                    dim_size = t.children[1]
                if dim_name not in dim_list:                # dim_name is new
                    dim_list.update({dim_name:dim_size})    # Add dim_name to dim_list
                else:
                    print('*** DIM ERR')
                    print("Error: DIM redimensioning not implemented")
                    exit()
                print("\t\t; DIM " + dim_name + "(" + dim_size + ")")
            else:
                #print('*** DIM ERR')
                print("\t\t; DIM " + dim_name + "(undefined)")                
                compile(t.children[1])
                #print("Error: DIM size undefined at compile time")
                print("\t\tMoveW BUFP, " + dim_name + "\t\t; VAR_ID = stored at current buffer pointer")
                #print("\t\tPullVar " + dim_name)            # save BUFFER address for this VAR_ID DIM
                # Update BUFP (BUFFER pointer) to next available space
                print("\t\tjsr PULL\t\t; update BUFP += size of VAR_ID")
                print("\t\tclc")
                print("\t\tlda BUFP")
                print("\t\tadc r0L")
                print("\t\tsta BUFP")
                print("\t\tlda BUFP+1")
                print("\t\tadc r0H")
                print("\t\tsta BUFP+1")
                if dim_name not in dim_ptr_list:            # dim_name is new
                    dim_ptr_list.append(dim_name)           # Add dim_name to dim_ptr_list
                else:
                    print('*** DIM ERR')
                    print("Error: DIM redimensioning not implemented")
                    exit()
                #exit()

        ###
        ### ASSIGNMENT
        ###
        elif t.data == 'assignment':
            var_name = t.children[0]
            if var_name.type == 'VAR_ID':
                if var_name not in var_id_list:
                    var_id_list.append(var_name)
                #
                # IMPLEMENT DIRECT ASSIGNMENT AS DONE IN TAB
                #
                compile(t.children[1])
                print("\t\tPullVar " + var_name)                 
            elif var_name.type == 'STR_ID':
                if var_name not in dim_list:
                    print("Error: STR_ID not defined: " + var_name)
                    exit()
                    
        ###
        ### FOR
        ###
        elif t.data == 'for':
            var_name = t.children[0]
            if var_name.type == 'VAR_ID':
                if var_name not in var_id_list:
                    var_id_list.append(var_name)
                if (var_name + "END") not in var_id_list:
                    var_id_list.append(var_name + "END")
                #if len(t.children) == 4:
                if (var_name + "STEP") not in var_id_list:
                    var_id_list.append(var_name + "STEP")
                loop_list.append(var_name)  # keep track for NEXT tokens
                #print(len(t.children))
                loop_label = "LOOP" + str(len(loop_list)-1)
                #loop_count += 1
                #
                # IMPLEMENT DIRECT ASSIGNMENT AS DONE IN TAB
                #
                compile(t.children[1])
                print("\t\tPullVar " + var_name)
                compile(t.children[2])
                print("\t\tPullVar " + var_name + "END")
                if len(t.children) == 4:
                    compile(t.children[3])
                else:
                    print("\t\tPushInt 1")  # If STEP is not used, default is STEP=1
                print("\t\tPullVar " + var_name + "STEP")
                print(loop_label + ":")                     ### LOOP START
                print("\t\tPushVar " + var_name + "END")    ### Exit loop if (I > IEND), same as IF (IEND < I)
                print("\t\tPushVar " + var_name)
                print("\t\tjsr LT")
                print("\t\tjsr PULL")
                print("\t\tlda r0L")
                #
                # BNE below has a range limit of [-128..127], for larger branches, need a JMP hack.
                #
                #print("\t\tbne " + loop_label + "END")     ### Branch if ZERO flag is CLEAR, thus TRUE (non-ZERO)
                print("\t\tbeq " + loop_label + "CONT")
                print("\t\tjmp " + loop_label + "END")
                print(loop_label + "CONT:")

        ###
        ### NEXT
        ###
        elif t.data == 'next':
            if len(t.children) > 1:
                print(t.children)
            print("\t\tPushVar " + loop_list[-1])
            print("\t\tPushVar " + loop_list[-1] + "STEP")
            print("\t\tjsr ADD")
            print("\t\tPullVar " + loop_list[-1])
            print("\t\tjmp LOOP" + str(len(loop_list)-1))
            print("LOOP" + str(len(loop_list)-1) + "END:")
            del loop_list[-1]
            
        ###
        ### TAB
        ###
        elif t.data == 'tab':
            #print(t.children[0])
            if isinstance(t.children[0], Token):            # direct set, does not use STACK
                if t.children[0].type == 'INT':             # INT, no need for stack usage
                    col = int(t.children[0].value) - 1      # PLOT starts from 0 and TAB starts from 1
                    print("\t\tsec")                        # GET cursor position; X=ROW, Y=COL, A preserved
                    print("\t\tjsr PLOT")
                    print("\t\tldy #" + str(col))
                    print("\t\tclc")                        # SET cursor position with new COL
                    print("\t\tjsr PLOT")
                elif t.children[0].type == 'VAR_ID':                                       # not INT, check for VAR_ID
                    print("\t\tsec")                        # GET cursor position; X=ROW, Y=COL, A preserved
                    print("\t\tjsr PLOT")
                    print("\t\tldy " + t.children[0].value) # load low byte of VAR_ID
                    print("\t\tdey")                        # PLOT starts from 0 and TAB starts from 1
                    print("\t\tclc")                        # SET cursor position with new COL
                    print("\t\tjsr PLOT")
                else:
                    print("*** TAB error, encountered: " + t.children[0])
                    exit()
            else:                                           # <expression>, need to get result from stack
                compile(t.children[0])
                print("\t\tjsr PULL")                       # set using STACK value
                print("\t\tsec")
                print("\t\tjsr PLOT")
                print("\t\tldy r0L")                        # uses only low byte, does not check boundary
                print("\t\tclc")
                print("\t\tjsr PLOT")            

        ###
        ### VTAB
        ###
        elif t.data == 'vtab':
            if t.children[0].type == 'INT':
                row = t.children[0].value
            print("\t\tsec")
            print("\t\tjsr PLOT")
            print("\t\tldx #" + row)
            print("\t\tclc")
            print("\t\tjsr PLOT")
            #
            # IMPLEMENT <expression> ASSIGNMENT AS DONE IN TAB
            #            

        ###
        ### PRINT
        ###
        elif t.data == 'print':
            newline = True
            if not t.children:                  # No arguments
                print("\t\tPrintNewline")
            else:                               # Process all PRINT arguments
                for i in range(len(t.children)):
                    #print(t.children[i])
                    if t.children[i].type == 'STRING':
                        str_label = "S" + str(str_count)
                        str_count = str_count + 1                        
                        str_list.append((t.children[i].value).lower())
                        print("\t\tLoadAddress " + str_label + "\t\t; to r0")
                        print("\t\tjsr PrString")                    
                    if t.children[i] == ',':
                        newline = False
                        print("\t\tjsr Tab")        ### BUG: check for last tab position 72 (0-79), add 1 to row
                                                    # and continue on next line at 0. Broken if 40x30 (screen 0)
                                                    # and 40x25 (screen 128)
                    if t.children[i] == ';':
                        newline = False                    
                if newline:
                    print("\t\tPrintNewline")

        ###
        ### MUL/DIV/MOD
        ###
        elif t.data == 'mul_exp':
            compile(t.children[0])  # lval
            compile(t.children[2])  # rval
            if t.children[1] == '*':
                print("\t\tjsr UMUL")
            elif t.children[1] == '/':
                print("\t\tjsr UDIV")
            else:
                print("\t\tjsr UMOD")

        ###
        ### ADD/SUB
        ###
        elif t.data == 'add_exp':
            compile(t.children[0])
            compile(t.children[2])
            if t.children[1] == '+':
                print("\t\tjsr ADD")
            else:
                print("\t\tjsr SUB")
                
        ###
        ### UNKNOWN NODE TYPE
        ###
        else:
            print("\t==>", t.data, t.children)
            
    ###
    ### UNKNOWN OBJECT TYPE
    ###
    else:
        print("Unknown Object: <not TREE nor TOKEN>:", t)

###
### MAIN BODY
###
parse_tree = parser.parse(text)
print(parse_tree)

print('\n.include \"macros.inc\"')
print('.include \"header.inc\"\n')


for inst in parse_tree.children:
    compile(inst)

print()
for idx, val in enumerate(str_list):
    print("S" + str(idx) + ":\t\t.asciiz " + val)
for var in var_id_list:
    print(var + ":\t\t.res 4")
for var in dim_list:
    print("{}:\t\t.res {}".format(var,dim_list[var]))
for var in dim_ptr_list:
    print(var + ":\t\t.res 2")

print("BUFFER:")   # label defining start of runtime DIM buffer address

print('\n.include \"io.asm\"')
print('.include \"math.asm\"')
