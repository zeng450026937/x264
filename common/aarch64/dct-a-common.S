/****************************************************************************
 * dct-a-common.S: aarch64 transform and zigzag
 *****************************************************************************
 * Copyright (C) 2009-2023 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          David Chen   <david.chen@myais.com.cn>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

// This file contains the macros written using NEON instruction set
// that are also used by the SVE/SVE2 functions

#include "asm.S"

const scan4x4_frame, align=4
.byte    0,1,   8,9,   2,3,   4,5
.byte   10,11, 16,17, 24,25, 18,19
.byte   12,13,  6,7,  14,15, 20,21
.byte   26,27, 28,29, 22,23, 30,31
endconst

const scan4x4_field, align=4
.byte    0,1,   2,3,   8,9,   4,5
.byte    6,7,  10,11, 12,13, 14,15
endconst

const sub4x4_frame, align=4
.byte    0,  1,  4,  8
.byte    5,  2,  3,  6
.byte    9, 12, 13, 10
.byte    7, 11, 14, 15
endconst

const sub4x4_field, align=4
.byte    0,  4,  1,  8
.byte   12,  5,  9, 13
.byte    2,  6, 10, 14
.byte    3,  7, 11, 15
endconst

.macro IDCT8_1D type
    SUMSUB_AB   v0.8h,  v1.8h,  v16.8h, v20.8h          // a0/a2
.ifc \type, row
    ld1        {v22.8h,v23.8h}, [x1], #32
.endif
    SUMSUB_SHR  1, v2.8h,  v3.8h,  v18.8h, v22.8h, v16.8h, v20.8h   // a6/a4
    SUMSUB_AB   v16.8h, v18.8h, v21.8h, v19.8h
    SUMSUB_15   v16.8h, v18.8h, v17.8h, v23.8h, v20.8h, v22.8h      // a7/a1
    SUMSUB_AB   v22.8h, v23.8h, v23.8h, v17.8h
    SUMSUB_15   v23.8h, v22.8h, v21.8h, v19.8h, v20.8h, v17.8h      // a5/a3

    SUMSUB_SHR  2, v21.8h, v22.8h, v22.8h, v23.8h, v19.8h, v17.8h   // b3/b5
    SUMSUB_SHR2 2, v20.8h, v23.8h, v16.8h, v18.8h, v19.8h, v17.8h   // b1/b7

    SUMSUB_AB   v18.8h, v2.8h,  v0.8h,  v2.8h           // b0/b6
    SUMSUB_AB   v19.8h, v3.8h,  v1.8h,  v3.8h           // b2/b4

    SUMSUB_AB   v16.8h, v23.8h, v18.8h, v23.8h
    SUMSUB_AB   v17.8h, v22.8h, v19.8h, v22.8h
    SUMSUB_AB   v18.8h, v21.8h, v3.8h,  v21.8h
    SUMSUB_AB   v19.8h, v20.8h, v2.8h,  v20.8h
.endm

.macro DCT_1D v0 v1 v2 v3 v4 v5 v6 v7
    SUMSUB_AB   \v1, \v6, \v5, \v6
    SUMSUB_AB   \v3, \v7, \v4, \v7
    add         \v0, \v3, \v1
    add         \v4, \v7, \v7
    add         \v5, \v6, \v6
    sub         \v2, \v3, \v1
    add         \v1, \v4, \v6
    sub         \v3, \v7, \v5
.endm

// sum = a + (b>>shift)   sub = (a>>shift) - b
.macro SUMSUB_SHR shift sum sub a b t0 t1
    sshr        \t0,  \b, #\shift
    sshr        \t1,  \a, #\shift
    add         \sum, \a, \t0
    sub         \sub, \t1, \b
.endm

// sum = (a>>shift) + b   sub = a - (b>>shift)
.macro SUMSUB_SHR2 shift sum sub a b t0 t1
    sshr        \t0,  \a, #\shift
    sshr        \t1,  \b, #\shift
    add         \sum, \t0, \b
    sub         \sub, \a, \t1
.endm

// a += 1.5*ma   b -= 1.5*mb
.macro SUMSUB_15 a b ma mb t0 t1
    sshr        \t0, \ma, #1
    sshr        \t1, \mb, #1
    add         \t0, \t0, \ma
    add         \t1, \t1, \mb
    add         \a,  \a,  \t0
    sub         \b,  \b,  \t1
.endm

// First part of IDCT (minus final SUMSUB_BA)
.macro IDCT_1D d4 d5 d6 d7 d0 d1 d2 d3
    SUMSUB_AB   \d4, \d5, \d0, \d2
    sshr        \d7, \d1, #1
    sshr        \d6, \d3, #1
    sub         \d7, \d7, \d3
    add         \d6, \d6, \d1
.endm

#define Z(z)   2*(z), 2*(z)+1
#define T(x,y) Z(x*8+y)
const scan8x8_frame, align=5
    .byte T(0,0), T(1,0), T(0,1), T(0,2)
    .byte T(1,1), T(2,0), T(3,0), T(2,1)
    .byte T(1,2), T(0,3), T(0,4), T(1,3)
    .byte T(2,2), T(3,1), T(4,0), T(5,0)
    .byte T(4,1), T(3,2), T(2,3), T(1,4)
    .byte T(0,5), T(0,6), T(1,5), T(2,4)
#undef T
#define T(x,y) Z((x-3)*8+y)
    .byte T(3,3), T(4,2), T(5,1), T(6,0)
    .byte T(7,0), T(6,1), T(5,2), T(4,3)
#undef T
#define T(x,y) Z((x-0)*8+y)
    .byte T(3,4), T(2,5), T(1,6), T(0,7)
    .byte T(1,7), T(2,6), T(3,5), T(4,4)
#undef T
#define T(x,y) Z((x-4)*8+y)
    .byte T(5,3), T(6,2), T(7,1), T(7,2)
    .byte T(6,3), T(5,4), T(4,5), T(3,6)
    .byte T(2,7), T(3,7), T(4,6), T(5,5)
    .byte T(6,4), T(7,3), T(7,4), T(6,5)
    .byte T(5,6), T(4,7), T(5,7), T(6,6)
    .byte T(7,5), T(7,6), T(6,7), T(7,7)
endconst

#undef T
#define T(x,y) Z(x*8+y)
const scan8x8_field, align=5
    .byte T(0,0), T(0,1), T(0,2), T(1,0)
    .byte T(1,1), T(0,3), T(0,4), T(1,2)
    .byte T(2,0), T(1,3), T(0,5), T(0,6)
    .byte T(0,7), T(1,4), T(2,1), T(3,0)
#undef T
#define T(x,y) Z((x-1)*8+y)
    .byte T(2,2), T(1,5), T(1,6), T(1,7)
    .byte T(2,3), T(3,1), T(4,0), T(3,2)
#undef T
#define T(x,y) Z((x-2)*8+y)
    .byte T(2,4), T(2,5), T(2,6), T(2,7)
    .byte T(3,3), T(4,1), T(5,0), T(4,2)
#undef T
#define T(x,y) Z((x-3)*8+y)
    .byte T(3,4), T(3,5), T(3,6), T(3,7)
    .byte T(4,3), T(5,1), T(6,0), T(5,2)
#undef T
#define T(x,y) Z((x-4)*8+y)
    .byte T(4,4), T(4,5), T(4,6), T(4,7)
    .byte T(5,3), T(6,1), T(6,2), T(5,4)
#undef T
#define T(x,y) Z((x-5)*8+y)
    .byte T(5,5), T(5,6), T(5,7), T(6,3)
    .byte T(7,0), T(7,1), T(6,4), T(6,5)
endconst

#undef T
#define T(y,x) x*8+y
const sub8x8_frame, align=5
    .byte T(0,0), T(1,0), T(0,1), T(0,2)
    .byte T(1,1), T(2,0), T(3,0), T(2,1)
    .byte T(1,2), T(0,3), T(0,4), T(1,3)
    .byte T(2,2), T(3,1), T(4,0), T(5,0)
    .byte T(4,1), T(3,2), T(2,3), T(1,4)
    .byte T(0,5), T(0,6), T(1,5), T(2,4)
    .byte T(3,3), T(4,2), T(5,1), T(6,0)
    .byte T(7,0), T(6,1), T(5,2), T(4,3)
    .byte T(3,4), T(2,5), T(1,6), T(0,7)
    .byte T(1,7), T(2,6), T(3,5), T(4,4)
    .byte T(5,3), T(6,2), T(7,1), T(7,2)
    .byte T(6,3), T(5,4), T(4,5), T(3,6)
    .byte T(2,7), T(3,7), T(4,6), T(5,5)
    .byte T(6,4), T(7,3), T(7,4), T(6,5)
    .byte T(5,6), T(4,7), T(5,7), T(6,6)
    .byte T(7,5), T(7,6), T(6,7), T(7,7)
endconst

const sub8x8_field, align=5
    .byte T(0,0), T(0,1), T(0,2), T(1,0)
    .byte T(1,1), T(0,3), T(0,4), T(1,2)
    .byte T(2,0), T(1,3), T(0,5), T(0,6)
    .byte T(0,7), T(1,4), T(2,1), T(3,0)
    .byte T(2,2), T(1,5), T(1,6), T(1,7)
    .byte T(2,3), T(3,1), T(4,0), T(3,2)
    .byte T(2,4), T(2,5), T(2,6), T(2,7)
    .byte T(3,3), T(4,1), T(5,0), T(4,2)
    .byte T(3,4), T(3,5), T(3,6), T(3,7)
    .byte T(4,3), T(5,1), T(6,0), T(5,2)
    .byte T(4,4), T(4,5), T(4,6), T(4,7)
    .byte T(5,3), T(6,1), T(6,2), T(5,4)
    .byte T(5,5), T(5,6), T(5,7), T(6,3)
    .byte T(7,0), T(7,1), T(6,4), T(6,5)
    .byte T(6,6), T(6,7), T(7,2), T(7,3)
    .byte T(7,4), T(7,5), T(7,6), T(7,7)
endconst
