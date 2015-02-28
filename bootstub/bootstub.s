/*-----------------------------------------------------------------

 Copyright (C) 2010 - 2015 Dave "WinterMute" Murphy

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

------------------------------------------------------------------*/

#define REG_BASE 0x04000000

	.global	_start
@-----------------------------------------------------------------
_start:
@-----------------------------------------------------------------
	b 	_boot
fwheader:
	.word	0	@ arm7 fw address
	.word	0	@ arm7 load address
	.word	0	@ arm7 size
	.word	0	@ arm7 execute
	
	.word	0	@ arm9 fw address
	.word	0	@ arm9 load address
	.word	0	@ arm9 size
	.word	0	@ arm9 execute

@-----------------------------------------------------------------
_boot:
@-----------------------------------------------------------------
	bl	copystub

	adr	r12, fwheader

	ldr	r1, [r12], #4
	ldr	r0, [r12], #4
	ldr	r2, [r12], #4
	ldr	r3, [r12], #4

	ldr	r4, =0x02FFFE34
	str	r3, [r4]

	bl	fwread

	ldr	r1, [r12], #4
	ldr	r0, [r12], #4
	ldr	r2, [r12], #4

	bl	fwread

	ldr	r3, [r12], #4
	ldr	r4, =0x02FFFE24
	str	r3, [r4]

	ldr	r4, =0x02FFFE34
	ldr	r4, [r4]
	bx	r4

@-----------------------------------------------------------------
copystub:
@-----------------------------------------------------------------
	mov	r0, #0x03000000
	sub	r0, r0, #0xc000
	adr	r1, _bootstub

@-----------------------------------------------------------------
@ adjust arm9 code address
@-----------------------------------------------------------------
	ldr	r2, [r1,#8]
	add	r2, r2, r0
	str	r2, [r1,#8]

@-----------------------------------------------------------------
@ adjust arm7 code address
@-----------------------------------------------------------------
	ldr	r2, [r1,#12]
	add	r2, r2, r0
	str	r2, [r1,#12]

	adr	r2, arm7_end

1:	ldr	r3, [r1],#4
	str	r3, [r0],#4
	cmp	r1, r2
	bne	1b

	bx	lr

@-----------------------------------------------------------------
_bootstub:
@-----------------------------------------------------------------
	.ascii	"bootstub"
	.word	hook7from9 - _bootstub
	.word	hook9from7 - _bootstub

//-----------------------------------------------------------------
hook9from7:
//-----------------------------------------------------------------
	mov	r12, #REG_BASE
	mov	r0, #0
	str	r0, [r12, #0x208]


	mov	r0, #0xc200              @ enable FIFO, clear error, enable irq
	orr	r0, #8                   @ flush send FIFO
	str	r0, [r12, #0x184]

	adr	r0, waitcode_start
	mov	r1, #0x03800000
	adr	r2, waitcode_end
1:	ldr	r4, [r0],#4
	str	r4, [r1],#4
	cmp	r2, r0
	bne	1b

	adr	r11, enter_passme_loop
	ldr	r0, resetcode
	mov	r1, #0x03800000
	bx	r1

	.pool

@-----------------------------------------------------------------
waitcode_start:
@-----------------------------------------------------------------
	mov	r3, #0x04000000
	str	r0, [r3, #0x188]
	add	r3, r3, #0x180

	mov	r2, #1
	bl	waitsync

	ldr	r0, =0x02FFFE24
	str	r11, [r0]

	mov	r0, #0x100
	strh	r0, [r3]

	mov	r2, #0
	bl	waitsync

	mov	r0, #0
	strh	r0, [r3]

	mov	r2, #5
	bl	waitsync

	ldr	lr, =0x02380000
	bx	lr

	.pool

waitsync:
	ldrh	r0, [r3]
	and	r0, r0, #0x000f
	cmp	r0, r2
	bne	waitsync
	bx	lr
waitcode_end:

arm9bootaddr:
	.word	0x02FFFE24

resetcode:
	.word	0x0c04000c

	.arch	armv5te
	.cpu	arm946e-s

@-----------------------------------------------------------------
copy_arm7_code:
@-----------------------------------------------------------------

	ldr	r1, =0x02380000
	ldr	r0, =0x02FFFE34
	str	r1, [r0]

	adr	r0, arm7_start
	adr	r2, arm7_end
_copyloader:
	ldr	r4, [r0], #4
	str	r4, [r1], #4
	cmp	r0, r2
	blt	_copyloader


	ldr	r0, =0x02380000
	ldr	r1, arm7size
	add 	r1, r1, r0
.flush:
	mcr	p15, 0, r0, c7, c14, 1		@ clean and flush address
	add	r0, r0, #32
	cmp	r0, r1
	blt	.flush

	mov     r0, #0
	mcr     p15, 0, r0, c7, c10, 4		@ drain write buffer

	bx	lr

arm7size:
	.word	arm7_end - arm7_start
	.pool

@-----------------------------------------------------------------
hook7from9:
@-----------------------------------------------------------------
	mov	r12, #REG_BASE
	mov	r0, #0
	str	r0, [r12, #0x208]

	mov	r0, #0xc200             @ enable FIFO, clear error, enable irq
	orr	r0, #8                  @ flush send FIFO
	str	r0, [r12, #0x184]

	add	r3, r12, #0x180		@ r3 = 4000180 (REG_IPCSYNC)

	mov	r0, #0
	strh	r0, [r3]

	ldr	r0, resetcode
	str	r0, [r12, #0x188]

	mov	r2, #1
	bl	waitsync

	bl	copy_arm7_code

	mov	r0, #0x100
	strh	r0, [r3]

	mov	r2, #5
	bl	waitsync

	mov	r0,#0x82
	strb	r0,[r3,#0x242-0x180]

	b	passme_loop

@-----------------------------------------------------------------
enter_passme_loop:
@-----------------------------------------------------------------
	mov	r12, #REG_BASE
	str	r12, [r12,#0x208]

	add	r3, r12, #0x180		@ r3 = 4000180 (REG_IPCSYNC)

	mov	r0,#0x82
	strb	r0,[r3,#0x242-0x180]

	bl	copy_arm7_code

@-----------------------------------------------------------------
passme_loop:
@-----------------------------------------------------------------
	ldr	r1, tcmpudisable		@ disable TCM and protection unit
	mcr	p15, 0, r1, c1, c0

	@ Disable cache
	mov	r0, #0
	mcr	p15, 0, r0, c7, c5, 0		@ Instruction cache
	mcr	p15, 0, r0, c7, c6, 0		@ Data cache
	mcr	p15, 0, r0, c3, c0, 0		@ write buffer

	@ Wait for write buffer to empty
	mcr	p15, 0, r0, c7, c10, 4

@-----------------------------------------------------------------
@ set up and enter passme loop
@-----------------------------------------------------------------

	ldr	r0,arm9branchaddr
	ldr	r1,branchinst
	str	r1,[r0]
	str	r0,[r0,#0x20]

	mov	r1, #0x500
	strh	r1, [r3]

	bx	r0

branchinst:
	.word 0xE59FF018

arm9branchaddr:
	.word 0x02fffe04

tcmpudisable:
	.word	0x2078
/*
	Copyright 2015 Dave Murphy (WinterMute)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/
	.arch	armv4t
	.cpu	arm7tdmi

@-----------------------------------------------------------------
arm7_start:
@-----------------------------------------------------------------
	mov	r12, #REG_BASE
	str	r12, [r12, #0x208]	@ IME = 0;

	adr	r1,arm7_boot
	adr	r3,arm7_end
	ldr	r2,=0x03800000
	mov	r4, r2
1:
	ldr	r0,[r1],#4
	str	r0,[r2],#4
	cmp	r1,r3
	bne	1b

	bx	r4

	.pool

@-----------------------------------------------------------------
arm7_boot:
@-----------------------------------------------------------------
	add	r3, r12, #0x180
	mov	r0,#0x500
	strh	r0,[r3]

waitfor9:
	ldrh	r0, [r3]
	and	r0, r0, #0x000f
	cmp	r0, #5
	bne	waitfor9

	b	fwload

@-----------------------------------------------------------------
writeread:
@-----------------------------------------------------------------
	and 	r0, r0, #0xff
	strh	r0, [r3, #0xc2]
.L2:
	ldrh	r2, [r3, #0xc0]
	tst	r2, #128
	bne	.L2
	ldrh	r0, [r3, #0xc2]
	bx	lr

	.pool

@-----------------------------------------------------------------
fwread:
@-----------------------------------------------------------------
@ r0 - destination
@ r1 - firmware address
@ r2 - size
@-----------------------------------------------------------------
	push 	{lr}
	mov	r5, r0
	mov	r6, r2
	ldr	r3, =0x04000100
	mov	r4, #0x8900
	strh	r4, [r3, #0xc0]
	mov	r0, #3
	bl	writeread
	mov	r0, r1,	lsr #16
	bl	writeread
	mov	r0, r1,	lsr #8
	bl	writeread
	mov	r0, r1
	bl	writeread

	add	r4, r5, r6
.load:
	mov	r0, #0
	bl	writeread
	strb	r0, [r5],#1
	cmp	r4, r5
	bne	.load

	mov	r2, #0
	strh	r2, [r3, #0xc0]

	pop	{pc}

	.pool

@-----------------------------------------------------------------
fwload:
@-----------------------------------------------------------------
	ldr	r0, =0x06008000
	mov	r1, #0x10000
	mov	r2, #2048
	bl 	fwread

	ldr	r4, =0x06008000
	bx	r4

	.pool

arm7_end:
