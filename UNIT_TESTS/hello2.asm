;
; cl65 -o hello2.prg -t cx16 -C cx16-asm.cfg hello2.asm
;
; Also, you should count on CHROUT modifying X, so you should flank that jsr with phx and plx.
; Run with x16emu.exe -prg hello2.prg -run -scale 2

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

    CHROUT = $FFD2

    ldx #0
again:
    lda hello, x
    cmp #0
    beq done
    stx SaveX
    jsr CHROUT
    ldx SaveX
    inx
    jmp again
done:
    rts
SaveX: .byte 0
hello:
    .byte   "hello world! ", $00
