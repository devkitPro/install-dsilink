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

*/#define	REG_BASE	0x04000000


	.global	_start
_start:

	.word	0x44495347, 0xa505df1b, 0x00000001, 0x1e03e828
	.byte	0x01

	.space	_start + 0x00000023 - . , 0x00	@ 18 bytes

	.ascii "A little hack from WinterMute for 2015. Happy new year, one and all!"

	.space	_start + 0x00000087 - . , 0x20

#if defined(USA)
	.byte	0x64, 0xe3, 0x11, 0x02, 0
#elif defined(EU)
	.byte	0x04, 0xe6, 0x11, 0x02, 0
#else

#error "Currently unrecognised country"

#endif

haxx:
	mov	r0, #REG_BASE
	str	r0, [r0, #0x208]	@ IME = 0;

	mov	r1, #0
	strh	r1, [r0, #0x6c]
	strh	r1, [r0, #0x50]

	mov	r2, #0x1000
	add	r3, r2, r0
	strh	r1, [r3, #0x6c]
	strh	r1, [r3, #0x50]

	mov	r12, r0

	add	r2, r2, r0

	mov	r3, #0x58
	bl	memset

	ldr	r3, dispcnt
	str	r3, [r0]
	str	r3, [r2]

	mov	r5, #0x200
	str	r5, [r0, #0x08]
	str	r5, [r2, #0x08]

	add	r0, r0, #0x240
	str	r1, [r0]
	strh	r1, [r0, #0x04]
	strb	r1, [r0, #0x06]
	strb	r1, [r0, #0x08]

	mov	r1, #0x81
	strb	r1, [r0]
	mov	r1, #0x84
	strb	r1, [r0,#0x02]

	mov	r4, #0x05000000		@ engine A palette

	mov	r1, #0x1f
	str	r1, [r4]
	str	r1, [r4,#0x400]		@ engine B palette

	add	r0, r4, #0x01000000
	add	r2, r0, #0x00200000

	mov	r1, #0
	mov	r3, #0x1800
	bl	memset


	ldr	r0, =0x00002078			@ disable TCM and protection unit
	mcr	p15, 0, r0, c1, c0

	@ Disable caches
	mov	r0, #0
	mcr	p15, 0, r0, c7, c5, 0		@ Instruction cache
	mcr	p15, 0, r0, c7, c6, 0		@ Data cache

	@ Wait for write buffer to empty
	mcr	p15, 0, r0, c7, c10, 4

	mov	r1, #0x3e0
	str	r1, [r4]

	mov	r0, #0x40000
	add	r0, #0xC
	str	r0, [r12, #0x188]

	add	r3, r12, #0x180     @ r3 = 4000180

	ldr	r5,=0x2fffc24

	ldr	r0,=0x4004008
	ldr	r0,[r0]
	ands	r0,r0,#0x8000
	beq	notDSi

	mov	r2, #4
	strh	r2, [r5,#4]
	bl	wait_dsi7
	mov	r2, #3
	strh	r2, [r5,#4]
	bl	wait_dsi7

notDSi:

	mov	r2, #0xffffffff
	str	r2, [r4,#0x400]		@ engine B palette

	mov	r2,#1
	bl	waitsync

	adr	r0,arm7branch
	ldr	r1,=0x02380000
	ldr	r2,[r0],#4
	str	r2,[r1],#4
	ldr	r2,[r0],#4
	str	r2,[r1],#4

	mov	r2, #0x80
	strb	r2, [r12,#0x243]

	adr	r5,arm7_start
	adr	r7,arm7_end
	ldr	r6,=0x6860000
copyloop:
	ldr	r0,[r5],#4
	str	r0,[r6],#4
	cmp	r5,r7
	bne	copyloop

	mov	r2, #0x82
	strb	r2, [r12,#0x243]

	mov	r0, #0x100
	strh	r0, [r3]

	mov	r2,#0
	bl	waitsync

	mov	r0, #0
	strh	r0, [r3]

	mov	r2,#5
	bl	waitsync

	str	r1, [r4,#0x400]		@ engine B palette

	ldr	r10,=0x02FFFE04
	str	r10,[r10,#0x20]
	ldr	r2,=0xE59FF018
	str	r2,[r10]

	bx	r10

	.pool

dispcnt:
	.word	0x10100
arm7branch:
	mov	r0,#0x06000000
	bx	r0

memset:

.clrloop:
	subs	r3, r3, #4
	str	r1, [r0,r3]
	str	r1, [r2,r3]
	bne	.clrloop
	bx	lr

wait_dsi7:
	ldrh	r0,[r5,#2]
.wait7:
	ldrh	r6,[r5,#2]
	cmp	r6,r0
	beq	.wait7

	ldrh	r0,[r5]
	add	r0,r0,#1
	strh	r0,[r5]
	bx	lr

waitsync:
	ldrh	r0, [r3]
	and	r0, r0, #0x000f
	cmp	r0, r2
	bne	waitsync
	bx	lr


arm7_start:
	mov	r12, #REG_BASE
	str	r12, [r12, #0x208]	@ IME = 0;
	add	r3, r12, #0x180
	mov	r0,#0x500
	strh	r0,[r3]
	b	fwload

writeread:
	ldr	r3, =0x4000100
	strh	r0, [r3, #0xc2]
.L2:
	ldrh	r2, [r3, #0xc0]
	tst	r2, #128
	bne	.L2
	ldrh	r0, [r3, #0xc2]
	bx	lr

	.pool


fwload:
	ldr	r5, =0x04000100
	mov	r4, #0
	mov	r6, #0x8900
	strh	r6, [r5, #0xc0]
	mov	r0, #3		@
	bl	writeread
	mov	r0, #1		@ >>16
	bl	writeread
	mov	r0, r4		@ >>8
	bl	writeread
	mov	r0, r4		@ >>0
	bl	writeread
	ldr	r4, =0x06008000
	add	r5, r4, #2048
.load:
	mov	r0, #0
	bl	writeread
	strb	r0, [r4],#1
	cmp	r4, r5
	bne	.load

	ldr	r3, =0x04000100
	mov	r2, #0
	strh	r2, [r3, #0xc0]

	ldr	r4, =0x06008000
	bx	r4

	.pool

arm7_end:


	.space	_start + 0x00002000 - . , 0xff
