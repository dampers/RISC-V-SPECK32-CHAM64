/*
 * CHAM64_dblock.S
 *
 *  Created on: 2024. 5. 17.
 *      Author: MYOUNGSU
 */



/* double block encryption */

.section .text

.globl CHAM64_dblock
.type CHAM64_dblock, %function

.align 2

/*
REGIStER
a0 pt -> tmp
a1 ct pointer
a2 rk pointer
a3 x0
a4 x1
a5 x2
a6 x3
a7 : tmp

t0 : 64
t1 : rc
t2 : 0xfffefffe
t3 : rk
t4 : 0x00ff00ff
t5 : 0x00010000
t6 : 0x00010001

*/


.macro ADDITION A, B, T, D
	xor		\T, \A, \B		// T = A ^ B
	add		\D, \A, \B		// D = A + B
	xor		\T, \T, \D		// T = T ^ D
	and		\T, \T, t5		// T = T & 0x00010000
	sub		\D, \D, \T		// D = D - T
.endm

.macro ROL1 A, T1, T2, D
	slli	\T1, \A, 1		// T1 = A << 1
	and		\T1, \T1, t2	// T1 = T1 & 0xfffefffe
	srli	\T2, \A, 15		// T2 = A >> 15
	and		\T2, \T2, t6	// T2 = T2 & 0x00010001
	or		\D, \T1, \T2	// D = a0 | a7
.endm

.macro ROL8 A, T1, T2, D
	and		\T1, \A, t4		// a0 = A & 0x00ff00ff
	srli	\T2, \A, 8		// a7 = A >> 8
	slli	\T1, \T1, 8		// a0 = a0 << 8
	and		\T2, \T2, t4	// a7 = a7 & 0x00ff00ff
	or		\D, \T1, \T2	// D = a0 | a7
.endm


.macro INIT_EVEN_ROUND A, B
	// a0 = ROL16(B, 1)
	ROL1 \B, a0, a7, a0

	// rk
	lw		t3, 0(a2)		// t3 = rk[0]
	xor		a0, a0 ,t3		// a0 = a0 ^ t3
	addi	a2, a2, 4		// a2 += 4

	ADDITION \A, a0, a7, \A
.endm

.macro INIT_ODD_ROUND A, B
	// a0 = ROL16(B, 8)
	ROL8 \B, a0, a7, a0

	// rk
	lw		t3, 0(a2)		// s1 = rk[0]
	xor		a0, a0 ,t3		// a0 = a0 ^ t3
	addi	a2, a2, 4		// a2 += 4
	// xor rc
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
	// A = rol16(A, 1)
	ROL1	\A, a0, a7, \A
.endm

.macro SECOND_ROUND A, B
	// a0 = ROL16(B, 1)
	ROL1 \B, a0, a7, a0

	// rk
	lw		t3, 0(a2)		// t3 = rk[0]
	xor		a0, a0 ,t3		// a0 = a0 ^ t3
	addi	a2, a2, 4		// a2 += 4
	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
.endm


.macro EVEN_ROUND A, B

	// A = ROL16(A, 8)
	ROL8	\A, a0, a7, \A
	// a0 = ROL16(B, 1)
	ROL1	\B, a0, a7, a0

	// rk
	lw		t3, 0(a2)		// t3 = rk[0]
	xor		a0, a0 ,t3		// a0 = a0 ^ t3
	addi	a2, a2, 4		// a2 += 4
	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc


	ADDITION \A, a0, a7, \A
.endm

.macro ODD_ROUND A, B

	// rk
	lw		t3, 0(a2)		// t3 = rk[0]
	xor		a0, \B, t3		// a0 = B ^ t3
	addi	a2, a2, 4		// a2 += 4
	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
	// A = rol16(A, 1)
	ROL1	\A, a0, a7, \A
.endm



.macro INIT_8ROUNDS A, B, C, D
	INIT_EVEN_ROUND \A, \B		// round 0
	INIT_ODD_ROUND	\B, \C		// round 1
	SECOND_ROUND	\C, \D	 	// round 2
	ODD_ROUND		\D, \A		// round 3

	EVEN_ROUND		\A, \B	 	// round 4
	ODD_ROUND		\B, \C		// round 5
	EVEN_ROUND		\C, \D	 	// round 6
	ODD_ROUND		\D, \A		// round 7
.endm

.macro EIGHT_ROUNDS A, B, C, D
	EVEN_ROUND		\A, \B	 	// round 8
	ODD_ROUND		\B, \C		// round 9
	EVEN_ROUND		\C, \D	 	// round 10
	ODD_ROUND		\D, \A		// round 11

	EVEN_ROUND		\A, \B	 	// round 12
	ODD_ROUND		\B, \C		// round 13
	EVEN_ROUND		\C, \D	 	// round 14
	ODD_ROUND		\D, \A		// round 15
.endm


CHAM64_dblock:


	lh		a3, 0(a0)
	lh		a4, 2(a0)
	lh		a5, 4(a0)
	lh		a6, 6(a0)

	slli	a3, a3, 16
	slli	a4, a4, 16
	slli	a5, a5, 16
	slli 	a6, a6, 16

	lh		t1,	8(a0)
	lh		t2, 10(a0)
	lh		t3, 12(a0)
	lh		t4, 14(a0)

	xor		a3, a3, t1
	xor		a4, a4, t2
	xor		a5, a5, t3
	xor		a6, a6, t4

	li		t5, 0x00010000		// for add
	li		t1, 0x00010001		// rc for round 1
	li		t2, 0xfffefffe		// for ROL 1
	li		t4, 0x00ff00ff		// for ROL 8
	addi	t6, t5, 1			// for add rc and ROL 1
	li		t0, 64				// for rk back

	INIT_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6
	sub		a2, a2, t0
	EIGHT_ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6
	sub		a2, a2, t0
	EIGHT_ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6
	sub		a2, a2, t0
	EIGHT_ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6
	sub		a2, a2, t0
	EIGHT_ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6
	sub		a2, a2, t0
	EIGHT_ROUNDS	a3, a4, a5, a6


	ROL8	a3, a0, a7, a3
	ROL8	a5, a0, a7, a5

	sh		a3, 8(a1)
	sh		a4, 10(a1)
	sh		a5, 12(a1)
	sh		a6, 14(a1)

	srli	a3, a3, 16
	srli	a4, a4, 16
	srli	a5, a5, 16
	srli	a6, a6, 16

	sh		a3, 0(a1)
	sh		a4, 2(a1)
	sh		a5, 4(a1)
	sh		a6, 6(a1)


	ret



