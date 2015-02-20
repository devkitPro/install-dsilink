/*-----------------------------------------------------------------

 Copyright (C) 2010  Dave "WinterMute" Murphy

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
	.global	_start
//-----------------------------------------------------------------
_start:
//-----------------------------------------------------------------
	b	_copystub

_size:	.word	0
_stubsize:	.word _loader - _bootstub

_copystub:
	mov	r0, #0x03000000
	sub	r0, r0, #0xc000
	adr	r1, _bootstub
	ldr	r2, [r1,#8]
	add	r2, r2, r0
	str	r2, [r1,#8]
	ldr	r2, [r1,#12]
	add	r2, r2, r0
	str	r2, [r1,#12]

	ldr	r2, _size
	adr	r3, _loader_size
	str	r2, [r3]
	add	r2, r0, r2
	ldr	r3, _stubsize
	add	r2, r2, r3

1:	ldr	r3, [r1],#4
	str	r3, [r0],#4
	cmp	r2, r0
	bne	1b

	adr	r0, _loader
	ldr	r2, _loader_size
	mov	r1, #0x06000000
	add	r2, r0, r2
2:
	ldr	r4, [r0], #4
	str	r4, [r1], #4
	cmp	r0, r2
	bne	2b

	mov	r1, #0x06000000
	bx	r1

_bootstub:
	.ascii	"bootstub"
	.word	hook7from9 - _bootstub
	.word	hook9from7 - _bootstub
_loader_size:
	.word	0

//-----------------------------------------------------------------
hook9from7:
//-----------------------------------------------------------------
	ldr	r0, arm9bootaddr
	adr	r1, hook7from9
	str	r1, [r0]

	adr	r0, waitcode_start
	ldr	r1, arm7base
	adr	r2, waitcode_end
1:	ldr	r4, [r0],#4
	str	r4, [r1],#4
	cmp	r2, r0
	bne	1b

	mov	r3, #0x04000000
	ldr	r0, resetcode
	str	r0, [r3, #0x188]
	add	r3, r3, #0x180
	ldr	r1, arm7base
	bx	r1

//-----------------------------------------------------------------
waitcode_start:
//-----------------------------------------------------------------
	push	{lr}
	mov	r2, #1
	bl	waitsync

	mov	r0, #0x100
	strh	r0, [r3]

	mov	r2, #0
	bl	waitsync

	mov	r0, #0
	strh	r0, [r3]
	pop	{lr}

	bx	lr

waitsync:
	ldrh	r0, [r3]
	and	r0, r0, #0x000f
	cmp	r0, r2
	bne	waitsync
	bx	lr
waitcode_end:

arm7base:
	.word	0x037f8000
arm7bootaddr:
	.word	0x02FFFE34
arm9bootaddr:
	.word	0x02FFFE24
tcmpudisable:
	.word	0x2078

resetcode:
	.word	0x0c04000c
hook7from9:
	mov	r12, #0x04000000
	str	r12, [r12,#0x208]

	.arch	armv5te
	.cpu	arm946e-s

	ldr	r1, tcmpudisable		@ disable TCM and protection unit
	mcr	p15, 0, r1, c1, c0

	@ Disable cache
	mov	r0, #0
	mcr	p15, 0, r0, c7, c5, 0		@ Instruction cache
	mcr	p15, 0, r0, c7, c6, 0		@ Data cache
	mcr	p15, 0, r0, c3, c0, 0		@ write buffer

	@ Wait for write buffer to empty
	mcr	p15, 0, r0, c7, c10, 4

	add	r3, r12, #0x180		@ r3 = 4000180

	mov	r0,#0x80
	strb	r0,[r3,#0x242-0x180]

	adr	r0, _loader
	ldr	r2, _loader_size
	mov	r1, #0x06800000
	add	r1, r1, #0x40000
	add	r2, r0, r2
_copyloader:
	ldr	r4, [r0], #4
	str	r4, [r1], #4
	cmp	r0, r2
	blt	_copyloader

	mov	r0,#0x82
	strb	r0,[r3,#0x242-0x180]

// set up passme loop

	ldr	r0,arm9branchaddr
	ldr	r1,branchinst
	str	r1,[r0]
	str	r0,[r0,#0x20]

	ldr	r0, arm7bootaddr
	mov	r1, #0x06000000
	str	r1, [r0]

	ldr	r0, resetcode
	str	r0, [r12, #0x188]

	mov	r2, #1
	bl	waitsync

	mov	r0, #0x100
	strh	r0, [r3]

	mov	r2, #0
	bl	waitsync

	mov	r0, #0
	strh	r0, [r3]

	ldr	r0,arm9branchaddr
	bx	r0

branchinst:
	.word 0xE59FF018

arm9branchaddr:
	.word 0x02fffe04


_loader:
