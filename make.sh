#!/bin/zsh -i
# -i interactive shell to expand shell alias

if [ $# -eq 0 ] ; then
    echo "Usage: $0 [-b] filename.[bas|a65]"
    echo "Script to compile and assemble BAS and A65 source"
    echo
    echo "-b       compile BASIC program first"
    exit 1
fi

if [[ $1 == "-b" ]] ; then
    source=$2
else
    source=$1
fi

name=`echo $source | cut -f 1 -d '.'`
bas="${name}.bas"
a65="${name}.a65"
prg="${name}.prg"

# compile BASIC source
if [[ $1 == "-b" ]] ; then
    ./basic.py $bas
fi

# echo on, and expand variables
#set -x

# assemble A65 source
$CC65_BIN/cl65 -o $prg -t cx16 -u __EXEHDR__ -C $LD65_CFG/cx16-asm.cfg $a65
echo '$CC65_BIN/cl65: assembled successfully'

# run PRG program inside X16 with debug option
echo "x16: running emulator..."
x16 -prg $prg -run -debug

