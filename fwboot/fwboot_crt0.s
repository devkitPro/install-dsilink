@---------------------------------------------------------------------------------
	.section ".init"
	.global _start
@---------------------------------------------------------------------------------
	.align	2
	.arm
@---------------------------------------------------------------------------------
_start:
@---------------------------------------------------------------------------------
	b	start
fwheader:
	.word	0	@ arm7 fw address
	.word	0	@ arm7 load address
arm7execute:
	.word	0	@ arm7 execute
	.word	0	@ arm7 size
	
	.word	0	@ arm9 fw address
	.word	0	@ arm9 load address
	.word	0	@ arm9 execute
	.word	0	@ arm9 size
	
start:
	ldr	r3, =boot
	adr	r0, fwheader
	adr	lr, ret
	bx	r3
ret:
	ldr	r0,arm7execute
	bx	r0

	.pool


