;
; cl65 -o hw.prg -t cx16 -C cx16-asm.cfg hw.asm
;
; Run with x16emu.exe -prg hello2.prg -run -scale 2
;
; hw.s: example using BASIC ROM routine to output a string


    .org $0801                  ; Assembled code should start at $0801
                                ; (where BASIC programs start)
                                ; The real program starts at $0810 = 2064

; 10 SYS 2064
    .byte $0C, $08              ; $080C - pointer to next line of BASIC code
    .byte $0A, $00              ; 2-byte line number ($000A = 10)
    .byte $9E                   ; SYS BASIC token
    .byte $20                   ; [space]
    .byte $32, $30, $36, $34	; $32="2",$30="0",$36="6",$34="4"
    .byte $00                   ; End of Line
    .byte $00, $00              ; This is address $080C containing
                      		; 2-byte pointer to next line of BASIC code
                      		; ($0000 = end of program)
    .byte $00, $00              ; Padding so code starts at $0810

LOWERCASE       = $0E
CLRSCR          = $93
WHITE           = $05
LTBLUE          = $9A
STROUT          = $CD52		; BASIC in ROM BANK #4
VIA1		= $9F60		; PB0-2 = 0-7

	LDA #4
	STA VIA1
        LDA #<msg
        LDY #>msg
        JMP STROUT
	LDA #0
	STA VIA1
	RTS

msg:
.byte "hello world! ", 0

; LOWERCASE, CLRSCR, WHITE, "Hello World!", LTBLUE, 0