; "Breakout", Atari XL/XE Intro 256B
; code by tr1x / Agenda
; requirements: original Atari XL/XE 64KB PAL
; version: 1.0
; release date: 2021-07-10

scrptr	equ $0058
pmgaddr	equ $5400
dispadr	equ $be70

sdmctl	equ $022f
pcolr0	equ $02c0
m0pf	equ $d000
hposp0	equ $d000
hposm0	equ $d004
m0pl	equ $d008
sizep0	equ $d008
colpf0	equ $d016
gractl	equ $d01d
hitclr	equ $d01e
consol	equ $d01f
pmbase	equ $d407
wsync	equ $d40a
vcount	equ $d40b
osgraph	equ $ef9c


	org $0080

	bvc start

ballshp	.byte 0, %01100000, %00001001, 0	; ball's shape
dirstep	.byte $ff, $ff, $01, $01
brckofs	.byte $7a, $86, $92, $9e, $aa, $b6, $c2	; bricks' lines offsets
ballofs	.byte 1, 0, 0, 1, 1	; horizontal: 1, 0, 0, 1, vertical: 0, 0, 1, 1
dirh	.byte $01		; horizontal step (1 => +1, $ff => -1)
dirv	.byte $ff 		; vertical step (1 => +1, $ff => -1)

start	lda #$03
	jsr osgraph
posx	*
	; PMG setup
	;ldx #3			; not necessary, since X=3 after "jsr osgraph"
	stx gractl
	;ldy #$01		; not necessary, since Y=1 after "jsr osgraph"
	sty sizep0
	lda #$2f
	sta sdmctl
	ldx #>pmgaddr
	stx pmbase

	; draw top horizontal bar and bricks
	;ldx #$54		; not necessary; $54=12*7
loopa1	lda #%10101010
	sta dispadr,x		; top horizontal bar
posy	*
	lsr			; lda #%01010101
	sta dispadr+12,x	; bricks
	dex
	bne loopa1

	; draw left and right vertical bars
	ldx #$17
loopb1	lda #%10000010
	ldy #$00
	sta (scrptr),y
	ldy #$0b
	sta (scrptr),y
	lda scrptr
	clc
	adc #$0c
	sta scrptr
	bcc skipa1
	inc scrptr+1
skipa1	dex
	bne loopb1

main	lda vcount
	tax

	; rainbow on bricks
	sec
	sbc #$14
	lsr
	ora #%10000000
	sta colpf0
	sta wsync

	txa
	bne main

	; the ball consists of four missiles (m0..m3)
	;  +----+----+
	;  | m1 | m0 |
	;  +----+----+   <- the ball
	;  | m2 | m3 |
	;  +----+----+
	; I use missiles to playfield collisions in order to detect
	; which side a hit came from
	; e.g. if both m0 and m1 detected an obstacle it means the ball
	; hit an object from the bottom
	; e.g. if both m0 and m3 detected an obstacle it means the ball
	; hit an object from the left
	ldx #$03
	tay			; ldy #$00
loopc1	lda #$0f
	sta pcolr0,y		; colors of the racket and the ball
	lda m0pf,y
	iny
	pha
	tya
	and #$03
	tay
	pla
	and m0pf,y
	beq skipc1
	sta consol		; sound
	txa
	pha
	lda dirstep,x
	pha
	txa
	and #$01
	tax
	pla
	sta dirh,x
	lda m0pf,y		; if m0pf=1 (bricks)
	lsr
	bne skipc2
	lda posx
	clc
	adc ballofs,y
	lsr
	lsr
	lsr
	lsr
	pha
	lda posy
	clc
	adc ballofs+1,y
	sec
	sbc #$13
	lsr
	lsr
	tax
	lda brckofs,x
	sta opcodc1+1
	pla
	tax
	lda #$00
opcodc1	sta dispadr+12*6-2,x
skipc2	pla
	tax
skipc1	dex
	bpl loopc1

	; I use missile to player collision in order to detect that the ball
	; hit the racket
	lda m0pl+2
	beq skipd1
	sta consol		; sound
	lda #$ff
	sta dirv
skipd1

	sta hitclr		; clear collisions register

	; move the ball and the racket horizontally
	lda dirh
	;clc			; not necessary
	adc posx	
	sta posx

	; set ball's horizontal positions
	ldy #$03
loope1	sta hposm0,y
	dey
	bpl loope1

	; set racket's horizontal positions
	;clc			; do not uncomment
	adc #$ff-7
	sta hposp0

	; move the ball and the racket vertically
	lda dirv
	clc
	adc posy
	sta posy

	; draw ball's shape
	ldx #$03
	ldy posy
loopf1	lda ballshp,x
	sta pmgaddr+384,y
	iny
	dex
	bpl loopf1

	jmp main


	org pmgaddr+512+128-20

	; racket's shape
racket	.byte $ff, $ff