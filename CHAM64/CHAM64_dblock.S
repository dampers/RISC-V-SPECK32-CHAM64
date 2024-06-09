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

t1 : rc
t2 : 0xfffefffe
t4 : 0x00ff00ff
t5 : 0x00010000
t6 : 0x00010001

t0
t3

s0
s1
s2
s3
s4
s5
s6
s7
s8
s9
s10
s11

ra(x1)
a2



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


.macro INIT_EVEN_ROUND A, B, RK
	// a0 = ROL16(B, 1)
	ROL1 \B, a0, a7, a0

	// rk
	xor		a0, a0 ,\RK		// a0 = a0 ^ t3

	ADDITION \A, a0, a7, \A
.endm

.macro INIT_ODD_ROUND A, B, RK
	// a0 = ROL16(B, 8)
	ROL8 \B, a0, a7, a0

	// rk
	xor		a0, a0, \RK		// a0 = a0 ^ t3

	// xor rc
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
	// A = rol16(A, 1)
	ROL1	\A, a0, a7, \A
.endm

.macro SECOND_ROUND A, B, RK
	// a0 = ROL16(B, 1)
	ROL1 \B, a0, a7, a0

	// rk
	xor		a0, a0, \RK		// a0 = a0 ^ t3

	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
.endm


.macro EVEN_ROUND A, B, RK

	// A = ROL16(A, 8)
	ROL8	\A, a0, a7, \A
	// a0 = ROL16(B, 1)
	ROL1	\B, a0, a7, a0

	// rk
	xor		a0, a0, \RK		// a0 = a0 ^ t3
	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc


	ADDITION \A, a0, a7, \A
.endm

.macro ODD_ROUND A, B, RK

	// rk
	xor		a0, \B, \RK		// a0 = B ^ t3

	// xor rc
	add		t1, t1, t6		// rc += 0x00010001
	xor		\A, \A, t1		// A ^= rc

	ADDITION \A, a0, a7, \A
	// A = rol16(A, 1)
	ROL1	\A, a0, a7, \A
.endm

.macro LOAD_RK
	lw		t0, 0(a2)
	lw		t3, 4(a2)
	lw		x1, 8(a2)
	lw		s0, 12(a2)
	lw		s1, 16(a2)
	lw		s2, 20(a2)
	lw		s3, 24(a2)
	lw		s4, 28(a2)

	lw		s5, 32(a2)
	lw		s6, 36(a2)
	lw		s7, 40(a2)
	lw		s8, 44(a2)
	lw		s9, 48(a2)
	lw		s10,52(a2)
	lw		s11,56(a2)
	lw		a2, 60(a2)
.endm

.macro INIT_8ROUNDS A, B, C, D
	INIT_EVEN_ROUND \A, \B, t0		// round 0   0
	INIT_ODD_ROUND	\B, \C, t3		// round 1   1
	SECOND_ROUND	\C, \D, x1	 	// round 2   0
	ODD_ROUND		\D, \A, s0		// round 3   0

	EVEN_ROUND		\A, \B, s1	 	// round 4   1
	ODD_ROUND		\B, \C, s2		// round 5   0
	EVEN_ROUND		\C, \D, s3	 	// round 6   1
	ODD_ROUND		\D, \A, s4		// round 7   0
.endm

.macro FIRST_8ROUNDS A, B, C, D
	EVEN_ROUND 		\A, \B, t0		// round 0   0
	ODD_ROUND		\B, \C, t3		// round 1   1
	EVEN_ROUND		\C, \D, x1	 	// round 2   0
	ODD_ROUND		\D, \A, s0		// round 3   0

	EVEN_ROUND		\A, \B, s1	 	// round 4   1
	ODD_ROUND		\B, \C, s2		// round 5   0
	EVEN_ROUND		\C, \D, s3	 	// round 6   1
	ODD_ROUND		\D, \A, s4		// round 7   0
.endm

.macro EIGHT_ROUNDS A, B, C, D
	EVEN_ROUND		\A, \B, s5	 	// round 8
	ODD_ROUND		\B, \C, s6		// round 9
	EVEN_ROUND		\C, \D, s7	 	// round 10
	ODD_ROUND		\D, \A, s8		// round 11

	EVEN_ROUND		\A, \B, s9	 	// round 12
	ODD_ROUND		\B, \C, s10		// round 13
	EVEN_ROUND		\C, \D, s11	 	// round 14
	ODD_ROUND		\D, \A, a2		// round 15
.endm


CHAM64_dblock:


	lhu		a3, 0(a0)
	lhu		a4, 2(a0)
	lhu		a5, 4(a0)
	lhu		a6, 6(a0)

	slli	a3, a3, 16
	slli	a4, a4, 16
	slli	a5, a5, 16
	slli 	a6, a6, 16

	lhu		t1,	8(a0)
	lhu		t2, 10(a0)
	lhu		t3, 12(a0)
	lhu		t4, 14(a0)

	xor		a3, a3, t1
	xor		a4, a4, t2
	xor		a5, a5, t3
	xor		a6, a6, t4

	addi	sp,	sp, -52
	sw		x1, 48(sp)
	sw		s0, 44(sp)
	sw		s1, 40(sp)
	sw		s2, 36(sp)
	sw		s3, 32(sp)
	sw		s4,	28(sp)
	sw		s5,	24(sp)
	sw		s6,	20(sp)
	sw		s7,	16(sp)
	sw		s8,	12(sp)
	sw		s9,	8(sp)
	sw		s10,4(sp)
	sw		s11,0(sp)

	li		t5, 0x00010000		// for add
	li		t1, 0x00010001		// rc for round 1
	li		t2, 0xfffefffe		// for ROL 1
	li		t4, 0x00ff00ff		// for ROL 8
	addi	t6, t5, 1			// for add rc and ROL 1

	LOAD_RK

	INIT_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6

	FIRST_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6

	FIRST_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6

	FIRST_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6

	FIRST_8ROUNDS	a3, a4, a5, a6
	EIGHT_ROUNDS	a3, a4, a5, a6

	FIRST_8ROUNDS	a3, a4, a5, a6


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

	lw		ra, 48(sp)
	lw		s0, 44(sp)
	lw		s1, 40(sp)
	lw		s2, 36(sp)
	lw		s3, 32(sp)
	lw		s4,	28(sp)
	lw		s5,	24(sp)
	lw		s6,	20(sp)
	lw		s7,	16(sp)
	lw		s8,	12(sp)
	lw		s9,	8(sp)
	lw		s10,4(sp)
	lw		s11,0(sp)
	addi	sp,	sp, 52


	ret