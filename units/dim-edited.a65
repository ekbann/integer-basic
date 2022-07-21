.include "g:\My Drive\Emulators\dev\basic compiler\macros.inc"
.include "g:\My Drive\Emulators\dev\basic compiler\header.inc"
.code

START:
	    	StoreImm SINE, r0
	    	ldy #$00
		ldx #0
sine0:
            	lda (r0), y
            	phy
;            	jsr PrByte
	    	jsr PrHex8
            	lda #' '
	    	jsr CHROUT
		inx
		cpx #8
		bne cont
		PrintNewline
		ldx #0
cont:
	    	ply
            	iny
	    	cpy #0
	    	beq sine1
            	jmp sine0
sine1:		;===================================================================
		PrintNewline
		;===================================================================

;		StoreImm $fb2e, r0
;		jsr PUSH
;		jsr STACK
;		PrintNewline

;		jsr ABS

;		jsr STACK
;		PrintNewline

;		jsr TEMP

		;===================================================================

		LoadAddress BUFFER
		jsr PrHex16
		PrintNewline
		MoveW BUFP, r0
		jsr PrHex16
		PrintNewline

L10:		; REM TAB
L20:		; DIM B(16)
L25:		; DIM C(undefined)
		PushInt 2
		PushInt 8
		jsr UMUL
		MoveW BUFP, C		; VAR_ID = stored at current buffer pointer
		jsr PULL		; update BUFP += size of VAR_ID
		clc
		lda BUFP
		adc r0L
		sta BUFP
		lda BUFP+1
		adc r0H
		sta BUFP+1
L28:		; DIM D(undefined)
		PushInt 6
		PushInt 10
		jsr ADD
		MoveW BUFP, D		; VAR_ID = stored at current buffer pointer
		jsr PULL		; update BUFP += size of VAR_ID
		clc
		lda BUFP
		adc r0L
		sta BUFP
		lda BUFP+1
		adc r0H
		sta BUFP+1

		MoveW BUFP, r0
		jsr PrHex16
		PrintNewline

		MoveW C, r0
		jsr PrHex16
		PrintNewline

		MoveW D, r0
		jsr PrHex16
		PrintNewline

L30:		LoadAddress S0		; to r0
		jsr PrString
		PrintNewline
L50:		rts

S0:		.asciiz "end"
B:		.res 16
C:		.res 2
D:		.res 2
BUFFER:


.include "g:\My Drive\Emulators\dev\basic compiler\io.asm"
.include "g:\My Drive\Emulators\dev\basic compiler\math.asm"
