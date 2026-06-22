	.ifndef	UTILITY_MACROS_INC
UTILITY_MACROS_INC = 1
	
	
	.macro	PUSH_INTERRUPT_STATE
	move.w	_custom+intenar,-(a7)
	.endm
	
	.macro	PULL_INTERRUPT_STATE
	move.w	d0,-(a7)
	move.w	(2,a7),d0
	bset	#15,d0
	move.w	d0,_custom+intena
	move.w	(a7)+,d0
	addq	#2,a7
	.endm
	
	.macro	DISABLE_INTERRUPTS
	move.w	#0x4000,_custom+intena
	.endm

	.macro	DISABLE_INTERRUPTS_BUT_NOT_LEVEL_6
	move.w	#0x1FFF,_custom+intena
	.endm



	.macro MUL_TABLE value,len
mul\value\()_table:
	.set    mulv,0
	.rept	\len
	dc.w	mulv
	.set	mulv,mulv+\value
	.endr
	.endm


* debug macro that colors the screen until LMB pressed
	.macro 	blitz_bypass
	move.w	d0,-(a7)
	clr.w	d0
loop\@:
	move.w	d0,_custom+color
	btst	#6,0xbfe001
	beq.b	out\@
	addq.w	#1,d0
	bra.b	loop\@
out\@:
	move.w	(a7)+,d0
	nop
.endm

* same thing but if LMB is pressed when entering, macro waits for release)
	.macro blitz
w\@:
	btst	#6,0xbfe001
	beq.b	w\@
	blitz_bypass
.endm

	.endif
