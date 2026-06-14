* Converted with z80to68k v2.1 by JOTD
*
* make sure you call "cpu_init" first so all bits of data registers
* are zeroed out so we can use add.l dy,ax with dy > 0x7FFF
* without systematic masking
*
* WARNING: you also have to call "cpu_init"
* at start of any interrupt you could hook
*
* the GET_ADDRESS macro can just call get_address or it can also use
* conditional compilation to select the proper memory banks at compile time
* (see my burger time 6502 conversion which does that in RELEASE mode)


	.include	"options.inc"
	
	.global	cpu_init


	.macro	ERROR	arg
	.warning	"\arg"     | comment out or replace by ".warning" to disable errors
	.endm

	.macro	VIDEO_BYTE_DIRTY
	| called when a byte write was done in a0
	.endm

	.macro	VIDEO_WORD_DIRTY
	| called when a word write was done in a0
	.endm

* the function that accesses all memory (except banks)
* without any check
	.macro	GET_UNCHECKED_ADDRESS_FUNC	dest
	lea	(a6,\dest\().l),\dest
	.endm

	.macro	WRITE_ADDRESS	src,dest
	move.l	\src,d7
	sub.l	a6,d7
	MOVE_W_FROM_REG	d7,\dest
	.endm

	.macro	READ_ADDRESS	src,dest
	MOVE_W_TO_REG	a0,d7
	GET_ADDRESS_FUNC	d7
	move.l	d7,\dest
	.endm

* only in dev mode, else call GET_UNCHECKED_ADDRESS_FUNC
	.macro	GET_ADDRESS_FUNC	dest
	.if \dest!=a0
	exg	a0,\dest
	.endif
	jbsr	get_address
	.if \dest!=a0
	exg	a0,\dest
	.endif
	.endm

	.macro	CHECK_MAX	reg,arg
	ERROR  "insert check max table function index here"
	.endm

	.macro	MAKE_AR_FROM_HL	dest
	GET_REG_ADDRESS	0,d6,\dest
	.endm
	.macro	MAKE_AR_FROM_DE	dest
	GET_REG_ADDRESS	0,d4,\dest
	.endm
	.macro	MAKE_AR_FROM_BC	dest
	GET_REG_ADDRESS	0,d2,\dest
	.endm
	
	.macro	MAKE_AR_UNCHECKED_FROM_HL	dest
	GET_REG_UNCHECKED_ADDRESS	0,d6,\dest
	.endm
	.macro	MAKE_AR_UNCHECKED_FROM_DE	dest
	GET_REG_UNCHECKED_ADDRESS	0,d4,\dest
	.endm
	.macro	MAKE_AR_UNCHECKED_FROM_BC	dest
	GET_REG_UNCHECKED_ADDRESS	0,d2,\dest
	.endm

	.macro	MAKE_HL_NO_AR
* add d5 as MSB of d6 so d6.W = HL, load target reg
	rol.w	#8,d6
	move.b	d5,d6
	rol.w	#8,d6
	.endm

	.macro	MAKE_HL	dest
	MAKE_HL_NO_AR
	MAKE_AR_FROM_HL	\dest
	.endm

	.macro	MAKE_H
* update d5 from d6.W = HL
	rol.w	#8,d6
	move.b	d6,d5
	rol.w	#8,d6
	.endm

	.macro	MAKE_BC_NO_AR
* add d1 as MSB of d2 so d2.W = BC
	rol.w	#8,d2
	move.b	d1,d2
	rol.w	#8,d2
	.endm

	.macro	MAKE_BC	dest
	MAKE_BC_NO_AR
	MAKE_AR_FROM_BC	\dest
	.endm

	.macro	MAKE_B
* update d1 from d2.W = HL
	rol.w	#8,d2
	move.b	d2,d1
	rol.w	#8,d2
	.endm

	.macro	MAKE_DE_NO_AR
* add d3 as MSB of d4 so d4.W = DE
	rol.w	#8,d4
	move.b	d3,d4
	rol.w	#8,d4
	.endm

	.macro	MAKE_DE	dest
	MAKE_DE_NO_AR
	MAKE_AR_FROM_DE	\dest
	.endm

	.macro	MAKE_D
* update d3 from d4.W = HL
	rol.w	#8,d4
	move.b	d4,d3
	rol.w	#8,d4
	.endm

	.macro	LOAD_HL	argument
	move.w	\argument,d6
	MAKE_H
	.endm

	.macro	LOAD_BC	argument
	move.w	\argument,d2
	MAKE_B
	.endm

	.macro	LOAD_DE	argument
	move.w	\argument,d4
	MAKE_D
	.endm

	.macro CLR_XC_FLAGS
	and.b	#0xEE,ccr	| bit 4 = X, bit 0 = C
	.endm

	.macro SET_XC_FLAGS
	or.b	#0x11,ccr	| bit 4 = X, bit 0 = C
	.endm


	.macro INVERT_XC_FLAGS
	eor.b	#0x11,ccr
	.endm

* useful to recall C from X (add then move then bcx)
	.macro	SET_C_FROM_X
	PUSH_SR
	move.w	(sp),d7
	bset	#0,d7   | set C
	btst	#4,d7
	jne	0f
	bclr	#0,d7   | X is clear: clear C
0:
	move.w	d7,(sp)
	POP_SR
	.endm

* useful to store X from C (store cmp result)
	.macro	SET_X_FROM_C
	PUSH_SR
	move.w	(sp),d7
	bset	#4,d7   | set X
	btst	#0,d7
	bne.b	0f
	bclr	#4,d7   | C is clear: clear X
0:
	move.w	d7,(sp)
	POP_SR
	.endm

	.macro	SET_X_FROM_CLEARED_C
	PUSH_SR
	move.w	(sp),d7
	bset	#4,d7   | set X
	btst	#0,d7
	jeq	0f
	bclr	#4,d7   | C is set: clear X
0:
	move.w	d7,(sp)
	POP_SR
	.endm


	.macro SET_I_FLAG
	jbsr	osd_disable_interrupts
	.endm
	.macro CLR_I_FLAG
	jbsr	osd_enable_interrupts
	.endm

	.ifdef	MC68020


* 68020 compliant & optimized

    .macro    JXX_X_INDEXED    inst,reg,nb_cases,ab
    moveq    #0,d7
    move.b    \ab,d7  | mask 8 bits
    CHECK_MAX    d7,\nb_cases
    \inst    ([\reg,d7.W*2])
    .endm


	.macro DO_EXTB	reg
	extb.l	\reg
	.endm

	.macro PUSH_SR
	move.w	ccr,-(sp)
	.endm





	.else

* 68000 compliant

	.macro    JXX_X_INDEXED    inst,reg,nb_cases,ab
	moveq    #0,d7   | scratch register
	move.b   \ab,d7  | mask 8 bits
	CHECK_MAX    d7,\nb_cases
	* original register is not changed (could cause issues)
	add.w    d6,d6    | *2 (16 -> 32 bits)
	move.l    (\reg,d7.w),\reg
	\inst    (\reg)
	.endm



	.macro DO_EXTB	reg
	ext	\reg
	ext.l	\reg
	.endm

	.macro PUSH_SR
	move.w	sr,-(sp)
	.endm



	.endif

* same for 68000 and 68020+
	.macro POP_SR
	move.w	(sp)+,ccr
	.endm

	.macro    MOVE_W_TO_REG    src,dest
	move.b	(\src),\dest
	rol.w	#8,\dest
	move.b	(1,\src),\dest
	.endm

	.macro	MOVE_W_FROM_REG    src,dest
	move.b	\src,(\dest)
	rol.w	#8,\src
	move.b	\src,(1,\dest)
	rol.w	#8,\src
	.endm


    .macro    JXX_A_INDEXED    inst,reg,nb_cases
    JXX_X_INDEXED    \inst,\reg,\nb_cases,d0
    .endm

    .macro    JXX_B_INDEXED    inst,reg,nb_cases
    JXX_X_INDEXED    \inst,\reg,\nb_cases,d1
    .endm

    .macro    JSR_A_INDEXED    reg,nb_cases
    JXX_A_INDEXED	jsr,\reg,\nb_cases
    .endm
    .macro    JMP_A_INDEXED    reg,nb_cases
    JXX_A_INDEXED	jmp,\reg,\nb_cases
    .endm
    .macro    JSR_B_INDEXED    reg,nb_cases
    JXX_B_INDEXED	jsr,\reg,\nb_cases
    .endm
    .macro    JMP_B_INDEXED    reg,nb_cases
    JXX_B_INDEXED	jmp,\reg,\nb_cases
    .endm

	.macro	EXG_A_A_PRIME
	move.b	aprime,d7       | retrieve A'
	move.b	d0,aprime            | save A
	move.b	d7,d0           | A <= A'
	.endm

	.macro	EXG_AF_AF_PRIME
	PUSH_SR                       | push ccr
	EXG_A_A_PRIME
	move.w	fprime,d7       | retrieve F'
	move.w	(sp),fprime           | save F
	move.w	d7,(sp)         | F' <= F
	POP_SR                        | pop ccr
	.endm
	.macro GET_REG_ADDRESS	offset,reg,dest
	.ifeq	\offset
	move.l	\reg,\dest
	.else
	lea	\offset,\dest
	lea	(\dest,\reg\().l),\dest
	.endif
	GET_ADDRESS_FUNC	\dest
	.endm



	.macro GET_ADDRESS	offset,dest
	.if \offset==a2
    move.l    \offset,\dest
    .else
    .if \offset==a3
       move.l  \offset,\dest
    .else
    lea    \offset,\dest
    .endif
    .endif
	GET_ADDRESS_FUNC	\dest
	.endm

	.macro GET_INDIRECT_ADDRESS	offset,dest
	GET_ADDRESS	\offset,\dest
	READ_BE_WORD	\dest
	GET_ADDRESS_FUNC	\dest
	.endm
	.macro GET_REG_UNCHECKED_ADDRESS	offset,reg,dest
	.ifeq	\offset
	move.l	\reg,\dest
	.else
	lea	\offset,\dest
	lea	(\dest,\reg\().l),\dest
	.endif
	GET_UNCHECKED_ADDRESS_FUNC	\dest
	.endm



	.macro GET_UNCHECKED_ADDRESS	offset,dest
	.if \offset==a2
    move.l    \offset,\dest
    .else
    .if \offset==a3
       move.l  \offset,\dest
    .else
    lea    \offset,\dest
    .endif
    .endif
	GET_UNCHECKED_ADDRESS_FUNC	\dest
	.endm

	.macro GET_INDIRECT_UNCHECKED_ADDRESS	offset,dest
	GET_ADDRESS	\offset,\dest
	READ_BE_WORD	\dest
	GET_UNCHECKED_ADDRESS_FUNC	\dest
	.endm

* < A0: source (HL)
* < A1: destination (DE)
* < D1: length (16 bit)
ldir_video:
    MAKE_BC_NO_AR
    MAKE_HL_NO_AR
    MAKE_DE_NO_AR
    MAKE_AR_UNCHECKED_FROM_HL	a1
    MAKE_AR_UNCHECKED_FROM_DE	a0
    add.w	d2,d6
    add.w	d2,d4
    MAKE_HL_NO_AR
    MAKE_DE_NO_AR
    subq.w    #1,d2
0:
    move.b    (a1)+,(a0)
	VIDEO_BYTE_DIRTY
	addq	#1,a0
    dbf        d2,0b
    moveq	#0,d2
	moveq	#0,d1
    rts


get_address:
	.ifndef	RELEASE
	cmp.l	#0xC000,a0
	jcs		0f		| in ROM: okay!
	cmp.l	#0xC800,a0
	jcc		1f
	jbsr	osd_get_last_known_pc
	BREAKPOINT	"accessing unmapped memory between 0xC000 and 0xC7FF, PC in D7"
	jra 	0f
1:
	* > 0xC800
	cmp.l 	#0xD000,a0
	jcc		1f
	* I/O: needs unchecked
	jbsr	osd_get_last_known_pc
	BREAKPOINT	"accessing I/O memory between 0xC800 and 0xCFFF"
	jra 	0f
1:
	cmp.l	#0xE000,a0
	jcc		0f		| RAM: ok
	jbsr	osd_get_last_known_pc
	BREAKPOINT	"accessing video memory between 0xD000 and 0xDFFF"
0:
	.endif

	GET_UNCHECKED_ADDRESS_FUNC	a0
	rts


	.ifne	OPT_ENABLE_LOGGING
	.macro	LOG_REGS	z80pc
	move.w	sr,-(a7)
	move.w	#0x\z80pc,-(a7)
	move.w	#0,-(a7)  | cpu 0
	jbsr	osd_log_cpu
	addq.w	#4,a7
	move.w	(a7)+,sr
	.endm
	
	.macro	ENABLE_LOG_REGS
	moveq	#1,d7		| enable
	jbsr	osd_cpu_logging_control	
	.endm
	.macro	DISABLE_LOG_REGS
	moveq	#0,d7		| disable
	jbsr	osd_cpu_logging_control	
	.endm	

	.endif
	
