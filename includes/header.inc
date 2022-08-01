.FEATURE dollar_in_identifiers

screen_mode	= $ff5f ; Commodore 128 API Compatibility, C128 name = SWAPPER
RDTIM		= $ffde	; Commodore 64 standard KERNAL function
;clock_get_date_time = $ff50	; New API for the Commander X16 (NOT WORKING)
CHROUT		= $FFD2
PLOT		= $FFF0
NEWLINE		= $0D
UPPERCASE	= $8E
HOME		= $93

	r0	= $02
	r0L	= $02
	r0H	= $03
	r1	= $04
	r1L	= $04
	r1H	= $05
	r2	= $06
	r2L	= $06
	r2H	= $07
	r3	= $08
	r3L	= $08
	r3H	= $09
	r4	= $0a
	r4L	= $0a
	r4H	= $0b
	r5	= $0c
	r5L	= $0c
	r5H	= $0d
	r6	= $0e
	r6L	= $0e
	r6H	= $0f
	r7	= $10
	r7L	= $10
	r7H	= $11
	r8	= $12
	r8L	= $12
	r8H	= $13
	r9	= $14
	r9L	= $14
	r9H	= $15
	r10	= $16
	r10L	= $16
	r10H	= $17
	r11	= $18
	r11L	= $18
	r11H	= $19
	r12	= $1a
	r12L	= $1a
	r12H	= $1b
	r13	= $1c
	r13L	= $1c
	r13H	= $1d
	r14	= $1e
	r14L	= $1e
	r14H	= $1f
	r15	= $20
	r15L	= $20
	r15H	= $21

; Fixed-Point Constants
;
FPSTACKSIZE	= 12  ; Fixed-point stack size, Integer BASIC has maximum 12 nested ()s

; 4-way, 12-element empty ascending stack
; (FYI: The 6502 uses a descending empty stack)
; stack pointer = points to the next free/empty location
;

.zeropage	; MUST USE .CODE AND/OR .ORG FOR CODE

BUFP:		.word 0			; BUFFER pointer = next available space to save space for
							; in-program DIM initialization
FPSP:   	.word 0			; stack pointer = 0 (WORD) in case stack needs to be in higher memory
FPTEMP: 	.res 4			; FP temp;
SFL:    	.res FPSTACKSIZE
SFH:    	.res FPSTACKSIZE
SIL:    	.res FPSTACKSIZE
SIH:    	.res FPSTACKSIZE

.code

		StoreImm BUFFER, BUFP	; initialize BUPF to address of BUFFER (after compiled code)