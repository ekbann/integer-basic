rm test.prg
cl65 -o test.prg -t cx16 -u __EXEHDR__ -C cx16-asm.cfg test.asm
\x16-r38\x16emu.exe -prg test.prg -run
