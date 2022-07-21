#!/bin/zsh -i
# interactive shell to expand shell alias
name=`echo $1 | cut -f 1 -d '.'`
prg="${name}.prg"
set -x	# echo on, and expand variables
$CC65_BIN/cl65 -o $prg -t cx16 -u __EXEHDR__ -C $LD65_CFG/cx16-asm.cfg $1
x16 -prg $prg -run

