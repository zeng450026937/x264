/*****************************************************************************
 * deblock-a-sve.S: aarch64 deblocking
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
#include "deblock-a-common.S"

.arch armv8-a+sve

function deblock_v_luma_sve, export=1
    h264_loop_filter_start

    ptrue           p0.b, vl16
    ld1b            {z0.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z2.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z4.b}, p0/z, [x0]
    sub             x0,  x0,  x1, lsl #2
    sub             x0,  x0,  x1

    ld1b            {z20.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z18.b}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z16.b}, p0/z, [x0]

    // No performance improvememnt if h264_loop_filter_luma is migrated to sve
    // So, keep using its NEON version here
    h264_loop_filter_luma

    sub             x0,  x0,  x1
    st1b            {z17.b}, p0, [x0]
    add             x0, x0, x1
    st1b            {z16.b}, p0, [x0]
    add             x0, x0, x1
    st1b            {z0.b}, p0, [x0]
    add             x0, x0, x1
    st1b            {z19.b}, p0, [x0]

    ret
endfunc

.macro h264_loop_filter_luma_intra_sve
    ptrue           p0.b, vl16

    uabd            v16.16b, v7.16b,  v0.16b        // abs(p0 - q0)
    uabd            v17.16b, v6.16b,  v7.16b        // abs(p1 - p0)
    uabd            v18.16b, v1.16b,  v0.16b        // abs(q1 - q0)
    cmphi           p1.b, p0/z, z30.b, z16.b        // < alpha
    cmphi           p2.b, p0/z, z31.b, z17.b        // < beta
    cmphi           p3.b, p0/z, z31.b, z18.b        // < beta

    movi            v29.16b, #2
    ushr            v30.16b, v30.16b, #2            // alpha >> 2
    add             v30.16b, v30.16b, v29.16b       // (alpha >> 2) + 2
    cmphi           p4.b, p0/z, z30.b, z16.b        // < (alpha >> 2) + 2

    and             p1.b, p0/z, p1.b, p2.b
    ands            p1.b, p0/z, p1.b, p3.b
    b.none          9f

    ushll           v20.8h,  v6.8b,   #1
    ushll           v22.8h,  v1.8b,   #1
    ushll2          v21.8h,  v6.16b,  #1
    ushll2          v23.8h,  v1.16b,  #1
    uaddw           v20.8h,  v20.8h,  v7.8b
    uaddw           v22.8h,  v22.8h,  v0.8b
    uaddw2          v21.8h,  v21.8h,  v7.16b
    uaddw2          v23.8h,  v23.8h,  v0.16b
    uaddw           v20.8h,  v20.8h,  v1.8b
    uaddw           v22.8h,  v22.8h,  v6.8b
    uaddw2          v21.8h,  v21.8h,  v1.16b
    uaddw2          v23.8h,  v23.8h,  v6.16b

    rshrn           v24.8b,  v20.8h,  #2 // p0'_1
    rshrn           v25.8b,  v22.8h,  #2 // q0'_1
    rshrn2          v24.16b, v21.8h,  #2 // p0'_1
    rshrn2          v25.16b, v23.8h,  #2 // q0'_1

    uabd            v17.16b, v5.16b,  v7.16b        // abs(p2 - p0)
    uabd            v18.16b, v2.16b,  v0.16b        // abs(q2 - q0)
    cmphi           p5.b, p0/z, z31.b, z17.b          // < beta
    cmphi           p6.b, p0/z, z31.b, z18.b          // < beta

    and             p5.b, p0/z, p4.b, p5.b       // if_2 && if_3
    and             p6.b, p0/z, p4.b, p6.b       // if_2 && if_4

    nots            p2.b, p0/z, p5.b
    nots            p3.b, p0/z, p6.b

    and             p2.b, p0/z, p2.b, p1.b    // if_1 && !(if_2 && if_3)
    and             p3.b, p0/z, p3.b, p1.b    // if_1 && !(if_2 && if_4)

    and             p5.b, p0/z, p1.b, p5.b    // if_1 && if_2 && if_3
    and             p6.b, p0/z, p1.b, p6.b    // if_1 && if_2 && if_4

    //calc            p, v7, v6, v5, v4, v17, v7, v6, v5, v4
    uaddl           v26.8h,  v5.8b,   v7.8b
    uaddl2          v27.8h,  v5.16b,  v7.16b
    uaddw           v26.8h,  v26.8h,  v0.8b
    uaddw2          v27.8h,  v27.8h,  v0.16b
    add             v20.8h,  v20.8h,  v26.8h
    add             v21.8h,  v21.8h,  v27.8h
    uaddw           v20.8h,  v20.8h,  v0.8b
    uaddw2          v21.8h,  v21.8h,  v0.16b
    rshrn           v20.8b,  v20.8h,  #3 // p0'_2
    rshrn2          v20.16b, v21.8h,  #3 // p0'_2
    uaddw           v26.8h,  v26.8h,  v6.8b
    uaddw2          v27.8h,  v27.8h,  v6.16b
    rshrn           v21.8b,  v26.8h,  #2 // p1'_2
    rshrn2          v21.16b, v27.8h,  #2 // p1'_2
    uaddl           v28.8h,  v4.8b,   v5.8b
    uaddl2          v29.8h,  v4.16b,  v5.16b
    shl             v28.8h,  v28.8h,  #1
    shl             v29.8h,  v29.8h,  #1
    add             v28.8h,  v28.8h,  v26.8h
    add             v29.8h,  v29.8h,  v27.8h
    rshrn           v19.8b,  v28.8h,  #3 // p2'_2
    rshrn2          v19.16b, v29.8h,  #3 // p2'_2

    //calc            q, v0, v1, v2, v3, v18, v0, v1, v2, v3
    uaddl           v26.8h,  v2.8b,   v0.8b
    uaddl2          v27.8h,  v2.16b,  v0.16b
    uaddw           v26.8h,  v26.8h,  v7.8b
    uaddw2          v27.8h,  v27.8h,  v7.16b
    add             v22.8h,  v22.8h,  v26.8h
    add             v23.8h,  v23.8h,  v27.8h
    uaddw           v22.8h,  v22.8h,  v7.8b
    uaddw2          v23.8h,  v23.8h,  v7.16b
    rshrn           v22.8b,  v22.8h,  #3 // q0'_2
    rshrn2          v22.16b, v23.8h,  #3 // q0'_2
    uaddw           v26.8h,  v26.8h,  v1.8b
    uaddw2          v27.8h,  v27.8h,  v1.16b
    rshrn           v23.8b,  v26.8h,  #2 // q1'_2
    rshrn2          v23.16b, v27.8h,  #2 // q1'_2
    uaddl           v28.8h,  v2.8b,   v3.8b
    uaddl2          v29.8h,  v2.16b,  v3.16b
    shl             v28.8h,  v28.8h,  #1
    shl             v29.8h,  v29.8h,  #1
    add             v28.8h,  v28.8h,  v26.8h
    add             v29.8h,  v29.8h,  v27.8h
    rshrn           v26.8b,  v28.8h,  #3 // q2'_2
    rshrn2          v26.16b, v29.8h,  #3 // q2'_2

    mov             z7.b, p2/m, z24.b // p0'_1
    mov             z0.b, p3/m, z25.b // q0'_1
    mov             z7.b, p5/m, z20.b // p0'_2
    mov             z6.b, p5/m, z21.b // p1'_2
    mov             z5.b, p5/m, z19.b // p2'_2
    mov             z0.b, p6/m, z22.b // q0'_2
    mov             z1.b, p6/m, z23.b // q1'_2
    mov             z2.b, p6/m, z26.b // q2'_2
.endm

function deblock_v_luma_intra_sve, export=1
    h264_loop_filter_start_intra

    // No performance improvement if we use sve load here.
    // So, continue using NEON load
    ld1             {v0.16b},  [x0], x1 // q0
    ld1             {v1.16b},  [x0], x1 // q1
    ld1             {v2.16b},  [x0], x1 // q2
    ld1             {v3.16b},  [x0], x1 // q3
    sub             x0,  x0,  x1, lsl #3
    ld1             {v4.16b},  [x0], x1 // p3
    ld1             {v5.16b},  [x0], x1 // p2
    ld1             {v6.16b},  [x0], x1 // p1
    ld1             {v7.16b},  [x0]     // p0

    h264_loop_filter_luma_intra_sve

    // No performance improvement if we use sve store here.
    // So, continue using NEON store
    sub             x0,  x0,  x1, lsl #1
    st1             {v5.16b}, [x0], x1  // p2
    st1             {v6.16b}, [x0], x1  // p1
    st1             {v7.16b}, [x0], x1  // p0
    st1             {v0.16b}, [x0], x1  // q0
    st1             {v1.16b}, [x0], x1  // q1
    st1             {v2.16b}, [x0]      // q2
9:
    ret
endfunc

function deblock_h_luma_intra_sve, export=1
    h264_loop_filter_start_intra

    sub             x0,  x0,  #4
    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v4.8b},  [x0], x1
    ld1             {v5.8b},  [x0], x1
    ld1             {v6.8b},  [x0], x1
    ld1             {v7.8b},  [x0], x1
    ld1             {v0.8b},  [x0], x1
    ld1             {v1.8b},  [x0], x1
    ld1             {v2.8b},  [x0], x1
    ld1             {v3.8b},  [x0], x1
    ld1             {v4.d}[1],  [x0], x1
    ld1             {v5.d}[1],  [x0], x1
    ld1             {v6.d}[1],  [x0], x1
    ld1             {v7.d}[1],  [x0], x1
    ld1             {v0.d}[1],  [x0], x1
    ld1             {v1.d}[1],  [x0], x1
    ld1             {v2.d}[1],  [x0], x1
    ld1             {v3.d}[1],  [x0], x1

    transpose_8x16_sve z4, z5, z6, z7, z0, z1, z2, z3, z21, z23

    h264_loop_filter_luma_intra_sve

    transpose_8x16_sve z4, z5, z6, z7, z0, z1, z2, z3, z21, z23

    sub             x0,  x0,  x1, lsl #4
    // No performance improvement if sve store is used. So, continue using
    // NEON store here
    st1             {v4.8b},  [x0], x1
    st1             {v5.8b},  [x0], x1
    st1             {v6.8b},  [x0], x1
    st1             {v7.8b},  [x0], x1
    st1             {v0.8b},  [x0], x1
    st1             {v1.8b},  [x0], x1
    st1             {v2.8b},  [x0], x1
    st1             {v3.8b},  [x0], x1
    st1             {v4.d}[1],  [x0], x1
    st1             {v5.d}[1],  [x0], x1
    st1             {v6.d}[1],  [x0], x1
    st1             {v7.d}[1],  [x0], x1
    st1             {v0.d}[1],  [x0], x1
    st1             {v1.d}[1],  [x0], x1
    st1             {v2.d}[1],  [x0], x1
    st1             {v3.d}[1],  [x0], x1
9:
    ret
endfunc

.macro h264_loop_filter_chroma_sve
    ptrue           p0.b, vl16

    dup             v22.16b, w2              // alpha
    uxtl            v24.8h,  v24.8b
    uabd            v26.16b, v16.16b, v0.16b   // abs(p0 - q0)
    uxtl            v4.8h,   v0.8b
    uxtl2           v5.8h,   v0.16b
    uabd            v28.16b, v18.16b, v16.16b  // abs(p1 - p0)
    usubw           v4.8h,   v4.8h,   v16.8b
    usubw2          v5.8h,   v5.8h,   v16.16b
    sli             v24.8h,  v24.8h,  #8
    lsl             z4.h, z4.h, #2
    lsl             z5.h, z5.h, #2
    uabd            v30.16b, v2.16b,  v0.16b   // abs(q1 - q0)
    uxtl            v24.4s,  v24.4h
    uaddw           v4.8h,   v4.8h,   v18.8b
    uaddw2          v5.8h,   v5.8h,   v18.16b

    cmphi           p1.b, p0/z, z22.b, z26.b
    usubw           v4.8h,   v4.8h,   v2.8b
    usubw2          v5.8h,   v5.8h,   v2.16b
    sli             v24.4s,  v24.4s,  #16
    dup             v22.16b, w3              // beta
    rshrn           v4.8b,   v4.8h,   #3
    rshrn2          v4.16b,  v5.8h,   #3
    cmphi           p2.b, p0/z, z22.b, z28.b
    cmphi           p3.b, p0/z, z22.b, z30.b
    smin            v4.16b,  v4.16b,  v24.16b
    neg             v25.16b, v24.16b
    and             p1.b, p0/z, p1.b, p2.b
    smax            v4.16b,  v4.16b,  v25.16b
    and             p1.b, p0/z, p1.b, p3.b
    uxtl            v22.8h,  v0.8b
    uxtl2           v23.8h,  v0.16b

    uxtl            v28.8h,  v16.8b
    uxtl2           v29.8h,  v16.16b
    saddw           v28.8h,  v28.8h,  v4.8b
    saddw2          v29.8h,  v29.8h,  v4.16b
    ssubw           v22.8h,  v22.8h,  v4.8b
    ssubw2          v23.8h,  v23.8h,  v4.16b
    sqxtun          v16.8b,  v28.8h
    sqxtun          v0.8b,   v22.8h
    sqxtun2         v16.16b, v29.8h
    sqxtun2         v0.16b,  v23.8h
.endm

function deblock_v_chroma_sve, export=1
    h264_loop_filter_start

    sub             x0,  x0,  x1, lsl #1
    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.16b}, [x0], x1
    ld1             {v16.16b}, [x0], x1
    ld1             {v0.16b},  [x0], x1
    ld1             {v2.16b},  [x0]

    h264_loop_filter_chroma_sve

    sub             x0,  x0,  x1, lsl #1
    st1b            {z16.b}, p1, [x0]
    add             x0, x0, x1
    st1b            {z0.b}, p1, [x0]

    ret
endfunc

function deblock_h_chroma_sve, export=1
    h264_loop_filter_start

    sub             x0,  x0,  #4
    ptrue           p0.d, vl2
    mov             x12, #4
    mul             x11, x1, x12
    index           z17.d, #0, x11
deblock_h_chroma_sve:
    ld1d            {z18.d}, p0/z, [x0, z17.d]
    add              x0, x0, x1
    ld1d            {z16.d}, p0/z, [x0, z17.d]
    add              x0, x0, x1
    ld1d            {z0.d}, p0/z, [x0, z17.d]
    add              x0, x0, x1
    ld1d            {z2.d}, p0/z, [x0, z17.d]
    add              x0, x0, x1

    transpose4x8.h_sve  z18, z16, z0, z2, z28, z29, z30, z31

    // Better use NEON here as it is not convinient to use sve due to
    // the subsequent scatter stores
    h264_loop_filter_chroma_neon

    transpose4x8.h_sve  z18, z16, z0, z2, z28, z29, z30, z31

    sub             x0,  x0,  x1, lsl #2

    st1d            {z18.d}, p0, [x0, z17.d]
    add             x0, x0, x1
    st1d            {z16.d}, p0, [x0, z17.d]
    add             x0, x0, x1
    st1d            {z0.d}, p0, [x0, z17.d]
    add             x0, x0, x1
    st1d            {z2.d}, p0, [x0, z17.d]

    ret
endfunc

function deblock_h_chroma_422_sve, export=1
    add             x5,  x0,  x1
    sub             x0,  x0,  #4
    add             x1,  x1,  x1
    
    ptrue           p0.d, vl2
    mov             x12, #4
    mul             x11, x1, x12
    index           z17.d, #0, x11

    h264_loop_filter_start
    mov             x7,  x30
    bl              deblock_h_chroma_sve
    mov             x30, x7
    sub             x0,  x5,  #4
    mov             v24.s[0], w6
    b               deblock_h_chroma_sve
endfunc

.macro h264_loop_filter_chroma8_sve
    ptrue           p0.b, vl8
    dup             v22.8b,  w2                 // alpha
    uxtl            v24.8h,  v24.8b
    uabd            v26.8b,  v16.8b,  v17.8b    // abs(p0 - q0)
    uxtl            v4.8h,   v17.8b
    uabd            v28.8b,  v18.8b,  v16.8b    // abs(p1 - p0)
    usubw           v4.8h,   v4.8h,   v16.8b
    sli             v24.8h,  v24.8h,  #8
    lsl             z4.h, z4.h, #2
    uabd            v30.8b,  v19.8b,  v17.8b    // abs(q1 - q0)
    uaddw           v4.8h,   v4.8h,   v18.8b
    
    cmphi           p1.b, p0/z, z22.b, z26.b    // < alpha
    usubw           v4.8h,   v4.8h,   v19.8b
    dup             v22.8b,  w3                 // beta
    rshrn           v4.8b,   v4.8h,   #3
    
    cmphi           p2.b, p0/z, z22.b, z28.b    // < beta
    cmphi           p3.b, p0/z, z22.b, z30.b    // < beta
    smin            v4.8b,   v4.8b,   v24.8b
    neg             v25.8b,  v24.8b
    and             p1.b, p0/z, p1.b, p2.b
    smax            v4.8b,   v4.8b,   v25.8b
    and             p1.b, p0/z, p1.b, p3.b
    uxtl            v22.8h,  v17.8b
    movi            v0.2d, #0
    mov             z0.b, p1/m, z4.b
    uxtl            v28.8h,  v16.8b
    saddw           v28.8h,  v28.8h,  v0.8b
    ssubw           v22.8h,  v22.8h,  v0.8b
    sqxtun          v16.8b,  v28.8h
    sqxtun          v17.8b,  v22.8h
.endm

function deblock_h_chroma_mbaff_sve, export=1
    h264_loop_filter_start

    sub             x4,  x0,  #4
    sub             x0,  x0,  #2

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.8b}, [x4], x1
    ld1             {v16.8b}, [x4], x1
    ld1             {v17.8b},  [x4], x1
    ld1             {v19.8b},  [x4]

    transpose4x4.h_sve  z18, z16, z17, z19, z28, z29, z30, z31

    h264_loop_filter_chroma8_sve

    // No performance improvement if sve store is used. So, continue using
    // NEON store here
    st2             {v16.h,v17.h}[0], [x0], x1
    st2             {v16.h,v17.h}[1], [x0], x1
    st2             {v16.h,v17.h}[2], [x0], x1
    st2             {v16.h,v17.h}[3], [x0]

    ret
endfunc

.macro h264_loop_filter_chroma_intra_sve width=16
    ptrue           p0.b, vl16
    uabd            v26.16b, v16.16b, v17.16b  // abs(p0 - q0)
    uabd            v27.16b, v18.16b, v16.16b  // abs(p1 - p0)
    uabd            v28.16b, v19.16b, v17.16b  // abs(q1 - q0)
    
    cmphi           p1.b, p0/z, z30.b, z26.b  // < alpha
    cmphi           p2.b, p0/z, z31.b, z27.b  // < beta
    cmphi           p3.b, p0/z, z31.b, z28.b  // < beta
    and             p1.b, p0/z, p1.b, p2.b
    and             p1.b, p0/z, p1.b, p3.b

    ushll           v4.8h,   v18.8b,  #1
    ushll           v6.8h,   v19.8b,  #1
.ifc \width, 16
    ushll2          v5.8h,   v18.16b, #1
    ushll2          v7.8h,   v19.16b, #1
    uaddl2          v21.8h,  v16.16b, v19.16b
    uaddl2          v23.8h,  v17.16b, v18.16b
.endif
    uaddl           v20.8h,  v16.8b,  v19.8b
    uaddl           v22.8h,  v17.8b,  v18.8b
    add             v20.8h,  v20.8h,  v4.8h     // mlal?
    add             v22.8h,  v22.8h,  v6.8h
.ifc \width, 16
    add             v21.8h,  v21.8h,  v5.8h
    add             v23.8h,  v23.8h,  v7.8h
.endif
    uqrshrn         v24.8b,  v20.8h,  #2
    uqrshrn         v25.8b,  v22.8h,  #2
.ifc \width, 16
    uqrshrn2        v24.16b, v21.8h,  #2
    uqrshrn2        v25.16b, v23.8h,  #2
.endif
    mov             z16.b, p1/m, z24.b
    mov             z17.b, p1/m, z25.b
.endm

function deblock_v_chroma_intra_sve, export=1
    h264_loop_filter_start_intra

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    sub             x0,  x0,  x1, lsl #1
    ld1             {v18.16b}, [x0], x1
    ld1             {v16.16b}, [x0], x1
    ld1             {v17.16b}, [x0], x1
    ld1             {v19.16b}, [x0]

    h264_loop_filter_chroma_intra_sve

    // No performance improvement if sve store is used. So, continue using
    // NEON store here
    sub             x0,  x0,  x1, lsl #1
    st1             {v16.16b}, [x0], x1
    st1             {v17.16b}, [x0], x1

    ret
endfunc

function deblock_h_chroma_intra_mbaff_sve, export=1
    h264_loop_filter_start_intra

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    sub             x4,  x0,  #4
    sub             x0,  x0,  #2
    ld1             {v18.8b}, [x4], x1
    ld1             {v16.8b}, [x4], x1
    ld1             {v17.8b}, [x4], x1
    ld1             {v19.8b}, [x4], x1

    transpose4x4.h_sve  z18, z16, z17, z19, z26, z27, z28, z29

    h264_loop_filter_chroma_intra_sve width=8

    // No performance improvement if sve store is used. So, continue using
    // NEON store here
    st2             {v16.h,v17.h}[0], [x0], x1
    st2             {v16.h,v17.h}[1], [x0], x1
    st2             {v16.h,v17.h}[2], [x0], x1
    st2             {v16.h,v17.h}[3], [x0], x1

    ret
endfunc

function deblock_h_chroma_intra_sve, export=1
    h264_loop_filter_start_intra

    sub             x4,  x0,  #4
    sub             x0,  x0,  #2

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.d}[0], [x4], x1
    ld1             {v16.d}[0], [x4], x1
    ld1             {v17.d}[0], [x4], x1
    ld1             {v19.d}[0], [x4], x1
    ld1             {v18.d}[1], [x4], x1
    ld1             {v16.d}[1], [x4], x1
    ld1             {v17.d}[1], [x4], x1
    ld1             {v19.d}[1], [x4], x1

    transpose4x8.h_sve  z18, z16, z17, z19, z26, z27, z28, z29

    h264_loop_filter_chroma_intra_sve

    // There are not scatter stores in SVE that support more than
    // one vector. So, continue using NEON two-half word store here
    st2             {v16.h,v17.h}[0], [x0], x1
    st2             {v16.h,v17.h}[1], [x0], x1
    st2             {v16.h,v17.h}[2], [x0], x1
    st2             {v16.h,v17.h}[3], [x0], x1
    st2             {v16.h,v17.h}[4], [x0], x1
    st2             {v16.h,v17.h}[5], [x0], x1
    st2             {v16.h,v17.h}[6], [x0], x1
    st2             {v16.h,v17.h}[7], [x0], x1

    ret
endfunc

function deblock_h_chroma_422_intra_sve, export=1
    h264_loop_filter_start_intra

    sub             x4,  x0,  #4
    sub             x0,  x0,  #2

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.d}[0], [x4], x1
    ld1             {v16.d}[0], [x4], x1
    ld1             {v17.d}[0], [x4], x1
    ld1             {v19.d}[0], [x4], x1
    ld1             {v18.d}[1], [x4], x1
    ld1             {v16.d}[1], [x4], x1
    ld1             {v17.d}[1], [x4], x1
    ld1             {v19.d}[1], [x4], x1

    transpose4x8.h_sve  z18, z16, z17, z19, z26, z27, z28, z29

    h264_loop_filter_chroma_intra_sve

    // There are not scatter stores in SVE that support more than
    // one vector. So, continue using NEON two-half word store here
    st2             {v16.h,v17.h}[0], [x0], x1
    st2             {v16.h,v17.h}[1], [x0], x1
    st2             {v16.h,v17.h}[2], [x0], x1
    st2             {v16.h,v17.h}[3], [x0], x1
    st2             {v16.h,v17.h}[4], [x0], x1
    st2             {v16.h,v17.h}[5], [x0], x1
    st2             {v16.h,v17.h}[6], [x0], x1
    st2             {v16.h,v17.h}[7], [x0], x1

    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.d}[0], [x4], x1
    ld1             {v16.d}[0], [x4], x1
    ld1             {v17.d}[0], [x4], x1
    ld1             {v19.d}[0], [x4], x1
    ld1             {v18.d}[1], [x4], x1
    ld1             {v16.d}[1], [x4], x1
    ld1             {v17.d}[1], [x4], x1
    ld1             {v19.d}[1], [x4], x1
    
    transpose4x8.h_sve  z18, z16, z17, z19, z26, z27, z28, z29

    h264_loop_filter_chroma_intra_sve

    // There are not scatter stores in SVE that support more than
    // one vector. So, continue using NEON two-half word store here
    st2             {v16.h,v17.h}[0], [x0], x1
    st2             {v16.h,v17.h}[1], [x0], x1
    st2             {v16.h,v17.h}[2], [x0], x1
    st2             {v16.h,v17.h}[3], [x0], x1
    st2             {v16.h,v17.h}[4], [x0], x1
    st2             {v16.h,v17.h}[5], [x0], x1
    st2             {v16.h,v17.h}[6], [x0], x1
    st2             {v16.h,v17.h}[7], [x0], x1

    ret
endfunc
