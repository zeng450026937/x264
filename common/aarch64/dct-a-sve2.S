/****************************************************************************
 * dct-a-sve2.S: aarch64 transform and zigzag
 *****************************************************************************
 * Copyright (C) 2009-2023 x264 project
 *
 * Authors: David Chen <david.chen@myais.com.cn>
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

#include "asm-sve.S"
#include "dct-a-common.S"

.arch armv8-a+sve2

function add4x4_idct_sve2, export=1
    mov         x2, #FDEC_STRIDE
    mov         x11, x0
    ptrue       p0.h, vl8
    ptrue       p1.h, vl4
    ld1h       {z0.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z2.h}, p0/z, [x1]

    SUMSUB_AB   z4.h, z5.h, z0.h, z2.h
    // mov and asr introduce more latency. So, keep using NEON
    // sshr here
    sshr        v7.8h, v0.8h, #1
    sshr        v6.8h, v2.8h, #1
    sub         z7.h, z7.h, z2.h
    add         z6.h, z6.h, z0.h
    mov         v7.d[0], v7.d[1]
    mov         v6.d[0], v6.d[1]
    ld1b       {z28.h}, p0/z, [x11]
    add         x11, x11, x2
    SUMSUB_AB   z0.h, z2.h, z4.h, z6.h
    SUMSUB_AB   z1.h, z3.h, z5.h, z7.h

    transpose4x4.h_sve z0, z1, z3, z2, z16, z17, z18, z19

    SUMSUB_AB   z4.h, z5.h, z0.h, z3.h
    // mov and asr introduce more latency. So, keep using NEON
    // sshr here
    sshr        v7.8h, v1.8h, #1
    sshr        v6.8h, v2.8h, #1
    sub         z7.h, z7.h, z2.h
    add         z6.h, z6.h, z1.h
    ld1b       {z29.h}, p0/z, [x11]
    add         x11, x11, x2
    SUMSUB_AB   z0.h, z2.h, z4.h, z6.h
    SUMSUB_AB   z1.h, z3.h, z5.h, z7.h

    srshr       z0.h, p0/m, z0.h, #6
    srshr       z1.h, p0/m, z1.h, #6
    ld1b       {z31.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z2.h, p0/m, z2.h, #6
    srshr       z3.h, p0/m, z3.h, #6
    ld1b       {z30.h}, p0/z, [x11]

    add         z0.h, z0.h, z28.h
    add         z1.h, z1.h, z29.h
    add         z2.h, z2.h, z30.h
    add         z3.h, z3.h, z31.h
    sqxtunb     z0.b, z0.h
    sqxtunb     z1.b, z1.h
    sqxtunb     z2.b, z2.h
    sqxtunb     z3.b, z3.h

    st1b       {z0.h}, p1, [x0]
    add         x0, x0, x2
    st1b       {z1.h}, p1, [x0]
    add         x0, x0, x2
    st1b       {z3.h}, p1, [x0]
    add         x0, x0, x2
    st1b       {z2.h}, p1, [x0]
    ret
endfunc

function add8x4_idct_sve2, export=1
    mov         x11, x0
    ptrue       p0.h, vl8
    ld1h       {z0.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z1.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z2.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z3.h}, p0/z, [x1]
    add         x1, x1, #16

    transpose   z20.d, z21.d, z0.d, z2.d
    transpose   z22.d, z23.d, z1.d, z3.d
    IDCT_1D     v16.8h, v17.8h, v18.8h, v19.8h, v20.8h, v21.8h, v22.8h, v23.8h
    SUMSUB_AB   z0.h,  z3.h,  z16.h, z18.h
    SUMSUB_AB   z1.h,  z2.h,  z17.h, z19.h

    transpose4x8.h_sve z0, z1, z2, z3, z4, z5, z6, z7

    IDCT_1D     v16.8h, v17.8h, v18.8h, v19.8h, v0.8h, v1.8h, v2.8h, v3.8h
    SUMSUB_AB   z0.h,  z3.h,  z16.h, z18.h
    SUMSUB_AB   z1.h,  z2.h,  z17.h, z19.h

    srshr       z0.h, p0/m, z0.h, #6
    ld1b       {z28.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z1.h, p0/m, z1.h, #6
    ld1b       {z29.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z2.h, p0/m, z2.h, #6
    ld1b       {z30.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z3.h, p0/m, z3.h, #6
    ld1b       {z31.h}, p0/z, [x11]

    add         z0.h, z0.h, z28.h
    add         z1.h, z1.h, z29.h
    add         z2.h, z2.h, z30.h
    add         z3.h, z3.h, z31.h

    sqxtunb     z0.b, z0.h
    sqxtunb     z1.b, z1.h
    sqxtunb     z2.b, z2.h
    sqxtunb     z3.b, z3.h
    st1b       {z0.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z1.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z2.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z3.h}, p0, [x0]
    add         x0, x0, x2
    ret
endfunc

function add8x8_idct_sve2, export=1
    mov             x2, #FDEC_STRIDE
    mov             x5,  x30
    bl              X(add8x4_idct_sve2)
    mov             x30, x5
    b               X(add8x4_idct_sve2)
endfunc

function add16x16_idct_sve2, export=1
    mov             x2, #FDEC_STRIDE
    mov             x5,  x30
    bl              X(add8x4_idct_sve2)
    bl              X(add8x4_idct_sve2)
    sub             x0, x0, #8*FDEC_STRIDE-8
    bl              X(add8x4_idct_sve2)
    bl              X(add8x4_idct_sve2)
    sub             x0, x0, #8
    bl              X(add8x4_idct_sve2)
    bl              X(add8x4_idct_sve2)
    sub             x0, x0, #8*FDEC_STRIDE-8
    bl              X(add8x4_idct_sve2)
    mov             x30, x5
    b               X(add8x4_idct_sve2)
endfunc

function add8x8_idct8_sve2, export=1
    mov         x2,  #FDEC_STRIDE
    mov         x11, x0
    ptrue       p0.h, vl8
    ld1h       {z16.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z17.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z18.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z19.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z20.h}, p0/z, [x1]
    add         x1, x1, #16
    ld1h       {z21.h}, p0/z, [x1]
    add         x1, x1, #16

    // Keep using NEON sshr here
    IDCT8_1D    row

    transpose8x8.h_sve z16, z17, z18, z19, z20, z21, z22, z23, z30, z31

    // Keep using NEON sshr here
    IDCT8_1D    col

    ld1b       {z0.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z16.h, p0/m, z16.h, #6
    ld1b       {z1.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z17.h, p0/m, z17.h, #6
    ld1b       {z2.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z18.h, p0/m, z18.h, #6
    ld1b       {z3.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z19.h, p0/m, z19.h, #6
    ld1b       {z4.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z20.h, p0/m, z20.h, #6
    ld1b       {z5.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z21.h, p0/m, z21.h, #6
    ld1b       {z6.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z22.h, p0/m, z22.h, #6
    ld1b       {z7.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z23.h, p0/m, z23.h, #6
    
    add         z16.h, z16.h, z0.h
    add         z17.h, z17.h, z1.h
    add         z18.h, z18.h, z2.h
    add         z19.h, z19.h, z3.h
    add         z20.h, z20.h, z4.h
    add         z21.h, z21.h, z5.h
    add         z22.h, z22.h, z6.h
    add         z23.h, z23.h, z7.h

    sqxtunb     z0.b, z16.h
    sqxtunb     z1.b, z17.h
    sqxtunb     z2.b, z18.h
    sqxtunb     z3.b, z19.h
    sqxtunb     z4.b, z20.h
    sqxtunb     z5.b, z21.h
    sqxtunb     z6.b, z22.h
    sqxtunb     z7.b, z23.h

    st1b       {z0.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z1.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z2.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z3.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z4.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z5.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z6.h}, p0, [x0]
    add         x0, x0, x2
    st1b       {z7.h}, p0, [x0]
    add         x0, x0, x2
    ret
endfunc

function add16x16_idct8_sve2, export=1
    mov             x7,  x30
    bl              X(add8x8_idct8_sve2)
    sub             x0,  x0,  #8*FDEC_STRIDE-8
    bl              X(add8x8_idct8_sve2)
    sub             x0,  x0,  #8
    bl              X(add8x8_idct8_sve2)
    sub             x0,  x0,  #8*FDEC_STRIDE-8
    mov             x30, x7
    b               X(add8x8_idct8_sve2)
endfunc

function dct4x4dc_sve2, export=1
    // We cannot take advantage of vector sizes greater than 128 bits
    // here so we cannot use VL
    mov         x11, #4
    mov         x12, #8
    mov         x13, #12
    ptrue       p0.h, vl8
    ld1h        {z0.h}, p0/z, [x0]
    ld1h        {z1.h}, p0/z, [x0, x12, lsl #1]
    uunpklo     z2.s, z0.h
    uunpkhi     z3.s, z0.h
    uunpklo     z4.s, z1.h
    uunpkhi     z5.s, z1.h
    mov         z31.h, #1
    SUMSUB_AB   z27.h, z28.h, z2.h, z3.h
    SUMSUB_AB   z29.h, z30.h, z4.h, z5.h
    SUMSUB_AB   z0.h, z2.h, z27.h, z29.h
    SUMSUB_AB   z3.h, z1.h, z28.h, z30.h
    transpose   z4.s, z6.s, z0.s, z2.s
    transpose   z5.s, z7.s, z1.s, z3.s
    SUMSUB_AB   z0.h, z2.h, z4.h, z6.h
    SUMSUB_AB   z1.h, z3.h, z5.h, z7.h
    transpose   z4.d, z5.d, z0.d, z1.d
    transpose   z6.d, z7.d, z2.d, z3.d
    add         z16.h, z4.h, z31.h
    add         z17.h, z6.h, z31.h
    srhadd      z4.h, p0/m, z4.h, z5.h
    shsub       z16.h, p0/m, z16.h, z5.h
    shsub       z17.h, p0/m, z17.h, z7.h
    srhadd      z6.h, p0/m, z6.h, z7.h
    st1h       {z4.s}, p0, [x0]
    st1h       {z16.s}, p0, [x0, x11, lsl #1]
    st1h       {z17.s}, p0, [x0, x12, lsl #1]
    st1h       {z6.s}, p0, [x0, x13, lsl #1]
    ret
endfunc
