#!/usr/bin/python3
"""
========================
INT BASIC aka GAME BASIC
========================

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
"""

from pickle import FALSE, TRUE
import sys
from lark import Lark, Tree, Token

#try:
#    input = raw_input   # For Python2 compatibility
#except NameError:
#    pass

# Process command line arguments
print_program = False
print_tree = False
print_parse = False
compile_program = True
has_basic_program = False
if len(sys.argv) == 1:
    print("Usage: " + sys.argv[0] + " [options] filename.bas")
    print("Integer BASIC compiler for 6502\n")
    print("-b\tprint BASIC program")
    print("-t\tprint BASIC tree")
    print("-p\tprint Lark parse tree")
    print("-n\tdo not compile BASIC program")
else:
    for arg in sys.argv[1:]:
        if arg[0] == '-':
            if arg[1] == 'b':
                print_program = True
                #print("print BASIC program")
            elif arg[1] == 't':
                print_tree = True
                #print("print BASIC tree")
            elif arg[1] == 'p':
                print_parse = True
                #print("print parse tree")
            elif arg[1] == 'n':
                compile_program = False
                #print("do not compile")
            else:
                print(arg + " :invalid option")
                exit(1)
        else:
            has_basic_program = True
            bas_program = arg
            a65_program = bas_program.split(".")[0]+".a65"
            #print(bas_program + " :BAS source")
            #print(a65_program + " :A65 code")
if not has_basic_program:
    print("\nError: no .bas file provided")
    exit(1)

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

text_file = open(bas_program, "r")
text = text_file.read()
text_file.close()

if print_program:
    print(text)
if print_tree:
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
        ### GR
        ###
        elif t.data == 'gr':
            # Set 40x30 mode
            print("\t\tlda #$03\t\t; SCREEN MODE 3, 40x30")
            print("\t\tclc")
            print("\t\tjsr screen_mode")
            #print("BCS FAILURE") ==> No check for failures
            # Set black background color
            print("\t\tlda #$90\t\t; SET FOREGROUND COLOR TO BLACK")
            print("\t\tjsr CHROUT")
            print("\t\tlda #$01\t\t; SWAP FOREGROUND AND BACKGROUND COLOR")
            print("\t\tjsr CHROUT")
            # Clear screen to black
            print("\t\tlda #HOME")
            print("\t\tjsr CHROUT")

        ###
        ### COLOR
        ###
        elif t.data == 'color':
            if t.children[0].type == 'INT':
                grcol = t.children[0].value
            # Set black background color
            #
            # check valid color [0-15]; if fail, JSR ERROR with message on .A
            #
            print("\t\tldx #" + grcol)
            print("\t\tlda GRCOLORS,x\t\t; SET FOREGROUND COLOR")
            print("\t\tjsr CHROUT")
            print("\t\tlda #$01\t\t; SWAP FOREGROUND AND BACKGROUND COLOR")
            print("\t\tjsr CHROUT")
            #
            # IMPLEMENT <expression> ASSIGNMENT AS DONE IN TAB
            #            

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
if print_parse:
    print(parse_tree)
    print("\n")

if compile_program:
    # Redirect to A65 file output
    original_stdout = sys.stdout    # Save a reference to the original standard output
    f = open(a65_program, 'w')
    sys.stdout = f                  # Change the standard output to the file we created.

    print('.include \"./includes/macros.inc\"')
    print('.include \"./includes/header.inc\"\n')

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

    print('\n.include \"./includes/io.a65\"')
    print('.include \"./includes/math.a65\"')
    print('.include \"./includes/mathfp.a65\"')
    print('.include \"./includes/graphics.a65\"')

    sys.stdout = original_stdout    # Reset the standard output to its original value
    f.close()
    print(sys.argv[0] + ": compiled successfully")
else:
    print(sys.argv[0] + ": no compilation performed")
exit(0)