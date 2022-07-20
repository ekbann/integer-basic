; Loads a 16-bit Word (immediate) to .A (lo-byte) and .X (hi-byte)
;
.macro	LoadWordAX value
	lda #<value
	ldx #>value
.endmacro

; Loads the 16-bit Word (value at address) to .A (lo-byte) and .X (hi-byte)
;
.macro	LoadAX address
	lda address
	ldx address+1
.endmacro

; Moves the 8-bit Byte from source to dest
;
.macro MoveB source, dest
	lda source
	sta dest
.endmacro

; Moves the 16-bit Word from source (lo,hi) to dest (lo,hi)
;
.macro MoveW source, dest
	MoveB source+0, dest+0
	MoveB source+1, dest+1
.endmacro

; Store the 16-bit Word in AX to address (lo,hi)
;
.macro	StoreAX address
	sta address
	stx address+1
.endmacro

; Store a 16-bit Word (immediate) to address (lo,hi)
;
.macro	StoreImm value, address
	LoadWordAX value
	StoreAX address
.endmacro

; Prints a NEWLINE character
;
.macro	PrintNewline
	lda #NEWLINE
	jsr CHROUT
.endmacro

; Push INT to top of stack
;
.macro	PushInt value
	StoreImm value, r0
	jsr PUSH
.endmacro

; Push VAR to top of stack
;
.macro	PushVar variable
	MoveW variable, r0
	jsr PUSH
.endmacro

; Pull top of stack to VAR
;
.macro	PullVar variable
	jsr PULL
	MoveW r0, variable
.endmacro

; Load a 16-bit Address (immediate) to r0
;
.macro	LoadAddress address
	LoadWordAX address
	StoreAX r0
.endmacro