		.org $0801
    
		.byte $0C, $08
		.byte $0A, $00
		.byte $9E
		.byte $20
		.byte $32, $30, $36, $34
		.byte $00
		.byte $00, $00
		.byte $00, $00              ; Padding so code starts at $0810

CHROUT		= $FFD2
PLOT		= $FFF0
r0L		= $02
r0H		= $03

L10:		lda #147
		jsr CHROUT
		; REM HELLO
L15:		sec
		jsr PLOT
		ldy #10
		clc
		jsr PLOT
		sec
		jsr PLOT
		ldx #10
		clc
		jsr PLOT
L20:		lda #<S0
		sta r0L
		lda #>S0
		sta r0H
		jsr PRINT
L30:		rts
S0:		.byte "hello, world!", 0

PRINT:		ldy #0
PRINT0:		lda (r0L), y
		beq PRINT1
		phy
		jsr CHROUT
		ply
		iny
		jmp PRINT0
PRINT1:		rts