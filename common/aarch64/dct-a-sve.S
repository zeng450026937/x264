/****************************************************************************
 * dct-a-sve.S: aarch64 transform and zigzag
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

.arch armv8-a+sve

function idct4x4dc_sve, export=1
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
    SUMSUB_AB   z0.h, z1.h, z4.h, z5.h
    SUMSUB_AB   z3.h, z2.h, z6.h, z7.h
    st1h       {z0.s}, p0, [x0]
    st1h       {z1.s}, p0, [x0, x11, lsl #1]
    st1h       {z2.s}, p0, [x0, x12, lsl #1]
    st1h       {z3.s}, p0, [x0, x13, lsl #1]
    ret
endfunc

function sub4x4_dct_sve, export=1
    mov         x3, #FENC_STRIDE
    mov         x4, #FDEC_STRIDE
    ptrue       p0.h, vl4
    ld1b       {z0.h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b       {z1.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b       {z2.h}, p0/z, [x1]
    add         x1, x1, x3
    sub         z16.h, z0.h, z1.h
    ld1b       {z3.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b       {z4.h}, p0/z, [x1]
    add         x1, x1, x3
    sub         z17.h, z2.h, z3.h
    ld1b       {z5.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b       {z6.h}, p0/z, [x1]
    add         x1, x1, x3
    sub         z18.h, z4.h, z5.h
    ld1b       {z7.h}, p0/z, [x2]
    add         x2, x2, x4
    sub         z19.h, z6.h, z7.h

    DCT_1D      z0.h, z1.h, z2.h, z3.h, z16.h, z17.h, z18.h, z19.h
    transpose4x4.h_sve z0, z1, z2, z3, z4, z5, z6, z7
    DCT_1D      z4.h, z5.h, z6.h, z7.h, z0.h, z1.h, z2.h, z3.h
    // Use NEON st1 here for improving performance
    st1        {v4.4h,v5.4h,v6.4h,v7.4h}, [x0]
    ret
endfunc

function sub8x4_dct_sve
    ptrue       p0.h, vl8
    ld1b       {z0.h}, p0/z, [x1]
    ld1b       {z1.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z16.h, z0.h, z1.h
    ld1b       {z2.h}, p0/z, [x1]
    ld1b       {z3.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z17.h, z2.h, z3.h
    ld1b       {z4.h}, p0/z, [x1]
    ld1b       {z5.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z18.h, z4.h, z5.h
    ld1b       {z6.h}, p0/z, [x1]
    ld1b       {z7.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z19.h, z6.h, z7.h

    DCT_1D      z0.h, z1.h, z2.h, z3.h, z16.h, z17.h, z18.h, z19.h
    transpose4x8.h_sve z0, z1, z2, z3, z4, z5, z6, z7

    SUMSUB_AB   z16.h, z19.h, z0.h, z3.h
    SUMSUB_AB   z17.h, z18.h, z1.h, z2.h
    add         z22.h, z19.h, z19.h
    add         z21.h, z18.h, z18.h
    add         z0.h, z16.h, z17.h
    sub         z1.h, z16.h, z17.h

    add         z2.h, z22.h, z18.h
    sub         z3.h, z19.h, z21.h

    zip1        z4.d, z0.d, z2.d
    zip2        z6.d, z0.d, z2.d
    zip1        z5.d, z1.d, z3.d
    zip2        z7.d, z1.d, z3.d

    // Use NEON st1 here for improving performance
    st1        {v4.8h}, [x0], #16
    st1        {v5.8h}, [x0], #16
    st1        {v6.8h}, [x0], #16
    st1        {v7.8h}, [x0], #16
    ret
endfunc

function sub8x8_dct_sve, export=1
    mov         x5,  x30
    mov         x3, #FENC_STRIDE
    mov         x4, #FDEC_STRIDE
    bl          sub8x4_dct_sve
    mov         x30, x5
    b           sub8x4_dct_sve
endfunc

function sub16x16_dct_sve, export=1
    mov         x5,  x30
    mov         x3, #FENC_STRIDE
    mov         x4, #FDEC_STRIDE
    bl          sub8x4_dct_sve
    bl          sub8x4_dct_sve
    sub         x1, x1, #8*FENC_STRIDE-8
    sub         x2, x2, #8*FDEC_STRIDE-8
    bl          sub8x4_dct_sve
    bl          sub8x4_dct_sve
    sub         x1, x1, #8
    sub         x2, x2, #8
    bl          sub8x4_dct_sve
    bl          sub8x4_dct_sve
    sub         x1, x1, #8*FENC_STRIDE-8
    sub         x2, x2, #8*FDEC_STRIDE-8
    bl          sub8x4_dct_sve
    mov         x30, x5
    b           sub8x4_dct_sve
endfunc

.macro DCT8_1D_SVE type
    SUMSUB_AB   z18.h, z17.h, z3.h, z4.h   // s34/d34
    SUMSUB_AB   z19.h, z16.h, z2.h, z5.h   // s25/d25
    SUMSUB_AB   z22.h, z21.h, z1.h, z6.h   // s16/d16
    SUMSUB_AB   z23.h, z20.h, z0.h, z7.h   // s07/d07

    SUMSUB_AB   z24.h, z26.h, z23.h, z18.h  // a0/a2
    SUMSUB_AB   z25.h, z27.h, z22.h, z19.h  // a1/a3

    SUMSUB_AB   z30.h, z29.h, z20.h, z17.h  // a6/a5
    // mov and asr introduce more latency. So, keep using NEON
    // sshr here
    sshr        v23.8h, v21.8h, #1
    sshr        v18.8h, v16.8h, #1
    add         z23.h, z23.h, z21.h
    add         z18.h, z18.h, z16.h
    sub         z30.h, z30.h, z23.h
    sub         z29.h, z29.h, z18.h

    SUMSUB_AB   z28.h, z31.h, z21.h, z16.h   // a4/a7
    // mov and asr introduce more latency. So, keep using NEON
    // sshr here
    sshr        v22.8h, v20.8h, #1
    sshr        v19.8h, v17.8h, #1
    add         z22.h, z22.h, z20.h
    add         z19.h, z19.h, z17.h
    add         z22.h, z28.h, z22.h
    add         z31.h, z31.h, z19.h

    SUMSUB_AB      z0.h,  z4.h,  z24.h, z25.h
    // mov and asr introduce more latency. So, keep using NEON
    // sshr here
    SUMSUB_SHR  2, v1.8h,  v7.8h,  v22.8h, v31.8h, v16.8h, v17.8h
    SUMSUB_SHR  1, v2.8h,  v6.8h,  v26.8h, v27.8h, v18.8h, v19.8h
    SUMSUB_SHR2 2, v3.8h,  v5.8h,  v30.8h, v29.8h, v20.8h, v21.8h
.endm

function sub8x8_dct8_sve, export=1
    mov         x3, #FENC_STRIDE
    mov         x4, #FDEC_STRIDE
    ptrue       p0.h, vl8
    ld1b       {z16.h}, p0/z, [x1]
    ld1b       {z17.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    ld1b       {z18.h}, p0/z, [x1]
    ld1b       {z19.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z0.h, z16.h, z17.h
    ld1b       {z20.h}, p0/z, [x1]
    ld1b       {z21.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z1.h, z18.h, z19.h
    ld1b       {z22.h}, p0/z, [x1]
    ld1b       {z23.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z2.h, z20.h, z21.h
    ld1b       {z24.h}, p0/z, [x1]
    ld1b       {z25.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z3.h, z22.h, z23.h
    ld1b       {z26.h}, p0/z, [x1]
    ld1b       {z27.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z4.h, z24.h, z25.h
    ld1b       {z28.h}, p0/z, [x1]
    ld1b       {z29.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z5.h, z26.h, z27.h
    ld1b       {z30.h}, p0/z, [x1]
    ld1b       {z31.h}, p0/z, [x2]
    add         x1, x1, x3
    add         x2, x2, x4
    sub         z6.h, z28.h, z29.h
    sub         z7.h, z30.h, z31.h

    DCT8_1D_SVE row
    transpose8x8.h_sve z0, z1, z2, z3, z4, z5, z6, z7, z30, z31
    DCT8_1D_SVE col

    // Keep NEON st1 here
    st1        {v0.8h,v1.8h,v2.8h,v3.8h}, [x0], #64
    st1        {v4.8h,v5.8h,v6.8h,v7.8h}, [x0], #64
    ret
endfunc

function sub16x16_dct8_sve, export=1
    mov         x7,  x30
    bl          X(sub8x8_dct8_sve)
    sub         x1,  x1,  #FENC_STRIDE*8 - 8
    sub         x2,  x2,  #FDEC_STRIDE*8 - 8
    bl          X(sub8x8_dct8_sve)
    sub         x1,  x1,  #8
    sub         x2,  x2,  #8
    bl          X(sub8x8_dct8_sve)
    mov         x30, x7
    sub         x1,  x1,  #FENC_STRIDE*8 - 8
    sub         x2,  x2,  #FDEC_STRIDE*8 - 8
    b           X(sub8x8_dct8_sve)
endfunc

.macro sub4x4x2_dct_dc_sve, dst, t0, t1, t2, t3, t4, t5, t6, t7
    ld1b       {\t0\().h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b       {\t1\().h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b       {\t2\().h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b       {\t3\().h}, p0/z, [x2]
    add         x2, x2, x4
    sub         \t0\().h, \t0\().h, \t1\().h
    ld1b       {\t4\().h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b       {\t5\().h}, p0/z, [x2]
    add         x2, x2, x4
    sub         \t1\().h, \t2\().h, \t3\().h
    ld1b       {\t6\().h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b       {\t7\().h}, p0/z, [x2]
    add         x2, x2, x4
    add         \dst\().h, \t0\().h,  \t1\().h
    sub         \t2\().h, \t4\().h, \t5\().h
    sub         \t3\().h, \t6\().h, \t7\().h
    add         \dst\().h, \dst\().h, \t2\().h
    add         \dst\().h, \dst\().h, \t3\().h
.endm

function sub8x8_dct_dc_sve, export=1
    mov             x3,  #FENC_STRIDE
    mov             x4,  #FDEC_STRIDE
    ptrue           p0.h, vl8

    sub4x4x2_dct_dc_sve  z0, z16, z17, z18, z19, z20, z21, z22, z23
    sub4x4x2_dct_dc_sve  z1, z24, z25, z26, z27, z28, z29, z30, z31

    transpose   z2.d, z3.d, z0.d, z1.d
    SUMSUB_AB   z0.h, z1.h, z2.h, z3.h
    transpose   z2.d, z3.d, z0.d, z1.d
    SUMSUB_AB   z0.h, z1.h, z2.h, z3.h
    transpose   z2.d, z3.d, z0.d, z1.d

    addp        v0.8h,  v2.8h,  v3.8h
    addp        v0.8h,  v0.8h,  v0.8h

    st1        {v0.4h}, [x0]
    ret
endfunc

function sub8x16_dct_dc_sve, export=1
    mov             x3,  #FENC_STRIDE
    mov             x4,  #FDEC_STRIDE
    ptrue           p0.h, vl8
    sub4x4x2_dct_dc_sve  z0, z16, z17, z18, z19, z20, z21, z22, z23
    sub4x4x2_dct_dc_sve  z1, z24, z25, z26, z27, z28, z29, z30, z31
    sub4x4x2_dct_dc_sve  z2, z16, z17, z18, z19, z20, z21, z22, z23
    sub4x4x2_dct_dc_sve  z3, z24, z25, z26, z27, z28, z29, z30, z31

    addp             v4.8h,  v0.8h,  v2.8h
    addp             v5.8h,  v1.8h,  v3.8h

    transpose   z2.s,  z3.s,  z4.s, z5.s
    SUMSUB_AB   z0.h,  z1.h,  z2.h, z3.h

    transpose   z2.s,  z3.s, z0.s, z1.s
    SUMSUB_AB   z0.h,  z1.h, z2.h, z3.h

    transpose   z2.d, z3.d, z0.d, z1.d
    SUMSUB_AB   z0.h, z1.h, z2.h, z3.h

    trn1        z2.d, z0.d, z1.d
    trn2        z3.d, z1.d, z0.d

    addp        v0.8h,  v2.8h,  v3.8h

    st1h       {z0.h}, p0, [x0]
    ret
endfunc

function zigzag_interleave_8x8_cavlc_sve, export=1
    mov        x3,  #7
    mov        z31.s, #1
    ptrue      p2.s, vl2
    ld4        {v0.8h,v1.8h,v2.8h,v3.8h}, [x1],  #64
    ld4        {v4.8h,v5.8h,v6.8h,v7.8h}, [x1],  #64
    umax       v16.8h, v0.8h,  v4.8h
    umax       v17.8h, v1.8h,  v5.8h
    umax       v18.8h, v2.8h,  v6.8h
    umax       v19.8h, v3.8h,  v7.8h
    st1        {v0.8h}, [x0],  #16
    st1        {v4.8h}, [x0],  #16
    umaxp      v16.8h, v16.8h, v17.8h
    umaxp      v18.8h, v18.8h, v19.8h
    st1        {v1.8h}, [x0],  #16
    st1        {v5.8h}, [x0],  #16
    umaxp      v16.8h, v16.8h, v18.8h
    st1        {v2.8h}, [x0],  #16
    st1        {v6.8h}, [x0],  #16
    cmhs       v16.4s, v16.4s, v31.4s
    st1        {v3.8h}, [x0],  #16
    and        v16.16b, v16.16b, v31.16b
    st1        {v7.8h}, [x0],  #16
    st1b       {z16.s}, p2, [x2]
    add         x2, x2, #1
    add         x2, x2, x3
    mov        v16.d[0], v16.d[1]
    st1b       {z16.s}, p2, [x2]
    ret
endfunc
