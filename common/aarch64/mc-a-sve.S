/*****************************************************************************
 * mc.S: aarch64 motion compensation
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
#include "mc-a-common.S"

.arch armv8-a+sve

// void pixel_avg( uint8_t *dst,  intptr_t dst_stride,
//                 uint8_t *src1, intptr_t src1_stride,
//                 uint8_t *src2, intptr_t src2_stride, int weight );
.macro AVGH_SVE w h
function pixel_avg_\w\()x\h\()_sve, export=1
    mov         w10, #64
    cmp         w6,  #32
    mov         w9, #\h
    b.eq        pixel_avg_w\w\()_neon
    subs        w7,  w10,  w6
    b.lt        pixel_avg_weight_w\w\()_add_sub_sve     // weight > 64
    cmp         w6,  #0
    b.ge        pixel_avg_weight_w\w\()_add_add_sve
    b           pixel_avg_weight_w\w\()_sub_add_sve     // weight < 0
endfunc
.endm

AVGH_SVE  4, 2
AVGH_SVE  4, 4
AVGH_SVE  4, 8
AVGH_SVE  4, 16
AVGH_SVE  8, 4
AVGH_SVE  8, 8
AVGH_SVE  8, 16
AVGH_SVE 16, 8
AVGH_SVE 16, 16

.macro weight_add_add_sve dst, s1, s2, h=
    mul         \dst, \s1, v30.8h
    mla         \dst, \s2, v31.8h
.endm

.macro weight_add_sub_sve dst, s1, s2, h=
    mul         \dst, \s1, v30.8h
    mls         \dst, \s2, v31.8h
.endm

.macro weight_sub_add_sve dst, s1, s2, h=
    mul         \dst, \s2, v31.8h
    mls         \dst, \s1, v30.8h
.endm

.macro AVG_WEIGHT_SVE ext
function pixel_avg_weight_w4_\ext\()_sve
    load_weights_\ext
    ptrue       p0.b, vl8
    mov         z30.h, w6
    mov         z31.h, w7
1:  // height loop
    subs        w9,  w9,  #2
    ld1b       {z0.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z1.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v4.8h,  v0.8h,  v1.8h
    ld1b       {z2.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z3.h}, p0/z, [x4]
    add         x4, x4, x5
    sqrshrun    v0.8b,  v4.8h,  #6
    weight_\ext\()_sve v5.8h,  v2.8h,  v3.8h
    st1        {v0.s}[0], [x0], x1
    sqrshrun    v1.8b,  v5.8h,  #6
    st1        {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w8_\ext\()_sve
    load_weights_\ext
    ptrue       p0.b, vl16
    mov         z30.h, w6
    mov         z31.h, w7
1:  // height loop
    subs        w9,  w9,  #4
    ld1b       {z0.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z1.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v16.8h, v0.8h,  v1.8h
    ld1b       {z2.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z3.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v17.8h, v2.8h,  v3.8h
    ld1b       {z4.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z5.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v18.8h, v4.8h,  v5.8h
    ld1b       {z6.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z7.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v19.8h, v6.8h,  v7.8h
    sqrshrun    v0.8b,  v16.8h, #6
    sqrshrun    v1.8b,  v17.8h, #6
    sqrshrun    v2.8b,  v18.8h, #6
    sqrshrun    v3.8b,  v19.8h, #6
    st1        {v0.8b}, [x0], x1
    st1        {v1.8b}, [x0], x1
    st1        {v2.8b}, [x0], x1
    st1        {v3.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w16_\ext\()_sve
    load_weights_\ext
    dup         v30.16b, w6
    dup         v31.16b, w7
1:  // height loop
    subs        w9,  w9,  #2
    ld1        {v0.16b}, [x2], x3
    ld1        {v1.16b}, [x4], x5
    weight_\ext v16.8h, v0.8b,  v1.8b
    weight_\ext v17.8h, v0.16b, v1.16b, 2
    ld1        {v2.16b}, [x2], x3
    ld1        {v3.16b}, [x4], x5
    weight_\ext v18.8h, v2.8b,  v3.8b
    weight_\ext v19.8h, v2.16b, v3.16b, 2
    sqrshrun    v0.8b,  v16.8h, #6
    sqrshrun    v1.8b,  v18.8h, #6
    sqrshrun2   v0.16b, v17.8h, #6
    sqrshrun2   v1.16b, v19.8h, #6
    st1        {v0.16b}, [x0], x1
    st1        {v1.16b}, [x0], x1
    b.gt        1b
    ret
endfunc
.endm

AVG_WEIGHT_SVE add_add
AVG_WEIGHT_SVE add_sub
AVG_WEIGHT_SVE sub_add

.macro weight_prologue_sve type
    mov         w9,  w5                 // height
.ifc \type, full
    ldr         w12, [x4, #32]          // denom
.endif
    ldp         w4,  w5,  [x4, #32+4]   // scale, offset
    mov         z0.h, w4
    mov         z1.h, w5
.ifc \type, full
    neg         w12, w12
    mov         z2.h, w12
.endif
.endm

// void mc_weight( uint8_t *src, intptr_t src_stride, uint8_t *dst,
//                 intptr_t dst_stride, const x264_weight_t *weight, int h )
function mc_weight_w20_sve, export=1
    weight_prologue_sve full
    sub         x1,  x1,  #16
    // We cannot take advantage of vector sizes greater than 128 bits
    // here so we cannot use VL
    mov         x11, #8
    mov         x12, #16
    ptrue       p0.b, vl16
1:
    subs        w9,  w9,  #2
    ld1b       {z16.h}, p0/z, [x2]
    ld1b       {z17.h}, p0/z, [x2, x11]
    ld1b       {z18.h}, p0/z, [x2, x12]
    add         x2, x2, x3
    ld1b       {z19.h}, p0/z, [x2]
    ld1b       {z20.h}, p0/z, [x2, x11]
    ld1b       {z21.h}, p0/z, [x2, x12]
    add         x2, x2, x3
    mul         v22.8h, v16.8h, v0.8h
    mul         v23.8h, v17.8h, v0.8h
    zip1        v18.2d, v18.2d, v21.2d
    mul         v25.8h, v19.8h, v0.8h
    mul         v26.8h, v20.8h, v0.8h
    mul         v24.8h, v18.8h, v0.8h
    srshl       v22.8h, v22.8h, v2.8h
    srshl       v23.8h, v23.8h, v2.8h
    srshl       v24.8h, v24.8h, v2.8h
    srshl       v25.8h, v25.8h, v2.8h
    srshl       v26.8h, v26.8h, v2.8h
    add         v22.8h, v22.8h, v1.8h
    add         v23.8h, v23.8h, v1.8h
    add         v24.8h, v24.8h, v1.8h
    add         v25.8h, v25.8h, v1.8h
    add         v26.8h, v26.8h, v1.8h
    sqxtun      v4.8b,  v22.8h
    sqxtun2     v4.16b, v23.8h
    sqxtun      v6.8b,  v24.8h
    sqxtun      v5.8b,  v25.8h
    sqxtun2     v5.16b, v26.8h
    st1        {v4.16b},  [x0], #16
    st1        {v6.s}[0], [x0], x1
    st1        {v5.16b},  [x0], #16
    st1        {v6.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_sve, export=1
    weight_prologue_sve full
    ptrue       p0.b, vl16
1:
    subs        w9,  w9,  #2
    ld1b       {z16.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b       {z17.h}, p0/z, [x2]
    add         x2, x2, x3
    mul         v4.8h,  v16.8h, v0.8h
    mul         v5.8h,  v17.8h, v0.8h
    srshl       v4.8h,  v4.8h,  v2.8h
    srshl       v5.8h,  v5.8h,  v2.8h
    add         v4.8h,  v4.8h,  v1.8h
    add         v5.8h,  v5.8h,  v1.8h
    sqxtun      v16.8b, v4.8h
    sqxtun      v17.8b, v5.8h
    st1        {v16.8b}, [x0], x1
    st1        {v17.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w20_nodenom_sve, export=1
    weight_prologue_sve nodenom
    sub         x1,  x1,  #16
    ptrue       p0.b, vl16
    // We cannot take advantage of vector sizes greater than 128 bits
    // here so we cannot use VL
    mov         x11, #8
    mov         x12, #16
1:
    subs        w9,  w9,  #2
    ld1b       {z16.h}, p0/z, [x2]
    ld1b       {z17.h}, p0/z, [x2, x11]
    ld1b       {z18.h}, p0/z, [x2, x12]
    add         x2, x2, x3
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    ld1b       {z19.h}, p0/z, [x2]
    ld1b       {z20.h}, p0/z, [x2, x11]
    ld1b       {z21.h}, p0/z, [x2, x12]
    add         x2, x2, x3
    mov         v31.16b, v1.16b
    mov         v29.16b, v1.16b
    mov         v30.16b, v1.16b
    zip1        v18.2d, v18.2d, v21.2d
    mla         v27.8h, v16.8h, v0.8h
    mla         v28.8h, v17.8h, v0.8h
    mla         v31.8h, v18.8h, v0.8h
    mla         v29.8h, v19.8h, v0.8h
    mla         v30.8h, v20.8h, v0.8h
    sqxtun      v4.8b,  v27.8h
    sqxtun2     v4.16b, v28.8h
    sqxtun      v5.8b,  v29.8h
    sqxtun2     v5.16b, v30.8h
    sqxtun      v6.8b,  v31.8h
    st1        {v4.16b},  [x0], #16
    st1        {v6.s}[0], [x0], x1
    st1        {v5.16b},  [x0], #16
    st1        {v6.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_nodenom_sve, export=1
    weight_prologue_sve nodenom
    ptrue       p0.b, vl16
1:
    subs        w9,  w9,  #2
    ld1b       {z16.h}, p0/z, [x2]
    add         x2, x2, x3
    mov         v27.16b, v1.16b
    ld1b       {z17.h}, p0/z, [x2]
    add         x2, x2, x3
    mov         v29.16b, v1.16b
    mla         v27.8h, v16.8h, v0.8h
    mla         v29.8h, v17.8h, v0.8h
    sqxtun      v4.8b,  v27.8h
    sqxtun      v5.8b,  v29.8h
    st1        {v4.8b},  [x0], x1
    st1        {v5.8b},  [x0], x1
    b.gt        1b
    ret
endfunc

// void mc_copy( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride, int height )
function mc_copy_w4_sve, export=1
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_mc_copy_w4_sve
1:
    subs        w4,  w4,  #4
    ld1        {v0.s}[0],  [x2],  x3
    ld1        {v1.s}[0],  [x2],  x3
    ld1        {v2.s}[0],  [x2],  x3
    ld1        {v3.s}[0],  [x2],  x3
    st1        {v0.s}[0],  [x0],  x1
    st1        {v1.s}[0],  [x0],  x1
    st1        {v2.s}[0],  [x0],  x1
    st1        {v3.s}[0],  [x0],  x1
    b.gt        1b
    ret
.vl_gt_16_mc_copy_w4_sve:
    ptrue      p0.d, vl4
    index      z31.d, #0, x3
    index      z30.d, #0, x1
2:
    subs        w4,  w4,  #4
    ld1w       {z0.d}, p0/z, [x2, z31.d]
    add         x2, x2, x3, lsl #2
    st1w       {z0.d}, p0, [x0, z30.d]
    add         x0, x0, x1, lsl #2
    b.gt        2b
    ret
endfunc

function mc_copy_w8_sve, export=1
    rdvl            x9, #1
    cmp             x9, #16
    bgt             .vl_gt_16_mc_copy_w8_sve
1:  subs        w4,  w4,  #4
    ld1        {v0.8b},  [x2],  x3
    ld1        {v1.8b},  [x2],  x3
    ld1        {v2.8b},  [x2],  x3
    ld1        {v3.8b},  [x2],  x3
    st1        {v0.8b},  [x0],  x1
    st1        {v1.8b},  [x0],  x1
    st1        {v2.8b},  [x0],  x1
    st1        {v3.8b},  [x0],  x1
    b.gt        1b
    ret
.vl_gt_16_mc_copy_w8_sve:
    ptrue      p0.d, vl4
    index      z31.d, #0, x3
    index      z30.d, #0, x1
2:  subs        w4,  w4,  #4
    ld1d       {z0.d}, p0/z, [x2, z31.d]
    add         x2, x2, x3, lsl #2
    st1d       {z0.d}, p0, [x0, z30.d]
    add         x0, x0, x1, lsl #2
    b.gt        2b
    ret
endfunc

.macro integral4h_sve p1, p2
    ext         v1.16b,  \p1\().16b,  \p2\().16b,  #2
    ext         v2.16b,  \p1\().16b,  \p2\().16b,  #4
    ext         v3.16b,  \p1\().16b,  \p2\().16b,  #6
    add         v0.8h,  \p1\().8h,  v1.8h
    add         v4.8h,  v2.8h,  v3.8h
    add         v0.8h,  v0.8h,  v4.8h
    add         v0.8h,  v0.8h,  v5.8h
.endm

function integral_init4h_sve, export=1
    sub         x3,  x0,  x2, lsl #1
    ptrue       p0.h, vl8
    ld1b        {z6.h}, p0/z, [x1]
    add         x1, x1, #8
    ld1b        {z7.h}, p0/z, [x1]
    add         x1, x1, #8
1:
    subs        x2,  x2,  #16
    ld1        {v5.8h},  [x3], #16
    integral4h_sve  v6, v7
    ld1b        {z6.h}, p0/z, [x1]
    add         x1, x1, #8
    ld1        {v5.8h},  [x3], #16
    st1        {v0.8h},  [x0], #16
    integral4h_sve  v7, v6
    ld1b        {z7.h}, p0/z, [x1]
    add         x1, x1, #8
    st1        {v0.8h},  [x0], #16
    b.gt        1b
    ret
endfunc

.macro integral8h_sve p1, p2, s
    ext         v1.16b,  \p1\().16b,  \p2\().16b,  #2
    ext         v2.16b,  \p1\().16b,  \p2\().16b,  #4
    ext         v3.16b,  \p1\().16b,  \p2\().16b,  #6
    ext         v4.16b,  \p1\().16b,  \p2\().16b,  #8
    ext         v5.16b,  \p1\().16b,  \p2\().16b,  #10
    ext         v6.16b,  \p1\().16b,  \p2\().16b,  #12
    ext         v7.16b,  \p1\().16b,  \p2\().16b,  #14
    add         v0.8h,  \p1\().8h,  v1.8h
    add         v2.8h,  v2.8h,  v3.8h
    add         v4.8h,  v4.8h,  v5.8h
    add         v6.8h,  v6.8h,  v7.8h
    add         v0.8h,  v0.8h,  v2.8h
    add         v4.8h,  v4.8h,  v6.8h
    add         v0.8h,  v0.8h,  v4.8h
    add         v0.8h,  v0.8h,  \s\().8h
.endm

function integral_init8h_sve, export=1
    sub         x3,  x0,  x2, lsl #1
    ptrue       p0.h, vl8
    ld1b        {z16.h}, p0/z, [x1]
    add         x1, x1, #8
    ld1b        {z17.h}, p0/z, [x1]
    add         x1, x1, #8
    //ld1        {v16.8b,v17.8b}, [x1], #16
1:
    subs        x2,  x2,  #16
    ld1        {v18.8h}, [x3], #16
    integral8h_sve  v16, v17, v18
    ld1b        {z16.h}, p0/z, [x1]
    add         x1, x1, #8
    //ld1        {v16.8b}, [x1], #8
    ld1        {v18.8h}, [x3], #16
    st1        {v0.8h},  [x0], #16
    integral8h_sve  v17, v16, v18
    ld1b        {z17.h}, p0/z, [x1]
    add         x1, x1, #8
    //ld1        {v17.8b}, [x1], #8
    st1        {v0.8h},  [x0], #16
    b.gt        1b
    ret
endfunc

// void mbtree_fix8_pack( int16_t *dst, float *src, int count )
function mbtree_fix8_pack_sve, export=1
    ptrue       p0.s, vl4
    subs        w3,  w2,  #8
    b.lt        2f
1:
    subs        w3,  w3,  #8
    ld1w        {z0.s}, p0/z, [x1]
    add         x1, x1, #16
    ld1w        {z1.s}, p0/z, [x1]
    add         x1, x1, #16
    fcvtzs      v0.4s,  v0.4s,  #8
    fcvtzs      v1.4s,  v1.4s,  #8
    sqxtn       v2.4h,  v0.4s
    sqxtn2      v2.8h,  v1.4s
    rev16       v3.16b, v2.16b
    st1         {v3.8h},  [x0], #16
    b.ge        1b
2:
    adds        w3,  w3,  #8
    b.eq        4f
3:
    subs        w3,  w3,  #1
    ldr         s0, [x1], #4
    fcvtzs      w4,  s0,  #8
    rev16       w5,  w4
    strh        w5, [x0], #2
    b.gt        3b
4:
    ret
endfunc

