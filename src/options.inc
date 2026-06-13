	.ifndef	OPTIONS_INC
OPTIONS_INC = 1
	
	.ifdef	RELEASE
OPT_ENABLE_LOGGING = 0           | DO NOT CHANGE THIS
OPT_ALIGNED_MEMORY = 0
	.else
OPT_ENABLE_LOGGING = 1
OPT_ALIGNED_MEMORY = 1
	.endif
	
* makes random routines return 0
*OPT_FIX_RANDOM = 1

RAM_START = 0xC000
ROM_START = 0x0000
ROM_SIZE = RAM_START
RAM_SIZE = 0x10000-RAM_START

	.ifdef	RELEASE
	.macro	BREAKPOINT comment
	.endm

	.else
	
LOG_BUFFER_SIZE = 0x80000
	* amiga specific
	.macro	BREAKPOINT comment
	move.l	a0,-(a7)
	lea		comment\@(pc),a0
	jbsr	osd_break
	move.l	(a7)+,a0
	jra		next\@
comment\@:
	.asciz	"\comment"
	.align	2
next\@:
	.endm
	.endif
	
	.macro	GET_MEMORY_START_IN_A6
	.ifeq	OPT_ALIGNED_MEMORY
	lea		rom_buffer,a6
	.else
	move.l		rom_start_0000,a6

	.endif
	.endm
	
	.endif
