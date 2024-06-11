/*
 * SPECK32_dblock.S
 *
 *  Created on: 2024. 5. 20.
 *      Author: MYOUNGSU
 */



/* double block encryption */

.section .text

.globl SPECK32_dblock
.type SPECK32_dblock, %function

.align 2

/*
REGIStER
a0 pt pointer
a1 ct pointer
a2 rk pointer
a3 x1
a4 x0
a5 : rk
a6 : tmp
a7 : tmp

t1 : tmp
t2 : 0x3fff3fff		// for ROL 2
t3 : 0xc000c000		// for ROL 2
t4 : 0x007f007f		// for ROR 7
t5 : 0xff80ff80		// for ROR 7
t6 : 0x00010000		// for addition

*/

.macro ADDITION A, B, T, D
	xor		\T, \A, \B		// T = A ^ B
	add		\D, \A, \B		// D = A + B
	xor		\T, \T, \D		// T = T ^ D
	and		\T, \T, t6		// T = T & 0x00010000
	sub		\D, \D, \T		// D = D - T
.endm

.macro ROL2 A, T1, T2, D
	and		\T1, \A, t2		// T1 = A & 0x3fff3fff
	and		\T2, \A, t3		// T2 = A & 0xc000c000
	slli	\T1, \T1, 2		// T1 = T1 << 2
	srli	\T2, \T2, 14	// T2 = T2 >> 14
	or		\D, \T1, \T2	// D = T1 | T2
.endm

.macro ROR7 A, T1, T2, D
	and		\T1, \A, t4		// T1 = A & 0x007f007f
	and		\T2, \A, t5		// T2 = A & 0xff80ff80
	slli	\T1, \T1, 9		// T1 = T1 << 9
	srli	\T2, \T2, 7		// T2 = T2 >> 7
	or		\D, \T1, \T2	// D = T1 | T2
.endm


.macro SPECK_ROUND A, B
	ROR7		\A, a6, a7, \A		// A = ror16(A, 7)
	ADDITION	\A, \B, a6, \A		// A = A + B
	ROL2		\B, a6, a7, \B		// B = rol16(B, 2)

	xor			\A, \A, a5			// A = A ^ rk[0]

	xor			\B, \B, \A			// B = B ^ A

.endm


SPECK32_dblock:


	lhu		a3, 0(a0)
	lhu		a4, 2(a0)

	slli	a3, a3, 16
	slli	a4, a4, 16

	lhu		t1,	4(a0)
	lhu		t2, 6(a0)

	xor		a3, a3, t1
	xor		a4, a4, t2


	li		t2, 0x3fff3fff		// for ROL 2
	li		t3, 0xc000c000		// for ROL 2

	li		t4, 0x007f007f		// for ROR 7
	li		t5, 0xff80ff80		// for ROR 7

	li		t6, 0x00010000		// for addition


	lw		a5, 0(a2)
	SPECK_ROUND a4, a3
	lw		a5, 4(a2)
	SPECK_ROUND a4, a3
	lw		a5, 8(a2)
	SPECK_ROUND a4, a3
	lw		a5, 12(a2)
	SPECK_ROUND a4, a3
	lw		a5, 16(a2)
	SPECK_ROUND a4, a3
	lw		a5, 20(a2)
	SPECK_ROUND a4, a3
	lw		a5, 24(a2)
	SPECK_ROUND a4, a3
	lw		a5, 28(a2)
	SPECK_ROUND a4, a3
	lw		a5, 32(a2)
	SPECK_ROUND a4, a3
	lw		a5, 36(a2)
	SPECK_ROUND a4, a3

	lw		a5, 40(a2)
	SPECK_ROUND a4, a3
	lw		a5, 44(a2)
	SPECK_ROUND a4, a3
	lw		a5, 48(a2)
	SPECK_ROUND a4, a3
	lw		a5, 52(a2)
	SPECK_ROUND a4, a3
	lw		a5, 56(a2)
	SPECK_ROUND a4, a3
	lw		a5, 60(a2)
	SPECK_ROUND a4, a3
	lw		a5, 64(a2)
	SPECK_ROUND a4, a3
	lw		a5, 68(a2)
	SPECK_ROUND a4, a3
	lw		a5, 72(a2)
	SPECK_ROUND a4, a3
	lw		a5, 76(a2)
	SPECK_ROUND a4, a3

	lw		a5, 80(a2)
	SPECK_ROUND a4, a3
	lw		a5, 84(a2)
	SPECK_ROUND a4, a3


	sh		a3, 4(a1)
	sh		a4, 6(a1)

	srli	a3, a3, 16
	srli	a4, a4, 16

	sh		a3, 0(a1)
	sh		a4, 2(a1)


	ret
