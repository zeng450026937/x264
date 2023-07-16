/****************************************************************************
 * mc-a-common.S: aarch64 motion compensation
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

// 0 < weight < 64
.macro load_weights_add_add
    mov         w6,  w6
.endm

// weight > 64
.macro load_weights_add_sub
    neg         w7,  w7
.endm

// weight < 0
.macro load_weights_sub_add
    neg         w6,  w6
.endm

.macro weight_add_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.16b
    umlal2      \dst, \s2, v31.16b
.else
    umull       \dst, \s1, v30.8b
    umlal       \dst, \s2, v31.8b
.endif
.endm

.macro weight_add_sub dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.16b
    umlsl2      \dst, \s2, v31.16b
.else
    umull       \dst, \s1, v30.8b
    umlsl       \dst, \s2, v31.8b
.endif
.endm

.macro weight_sub_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s2, v31.16b
    umlsl2      \dst, \s1, v30.16b
.else
    umull       \dst, \s2, v31.8b
    umlsl       \dst, \s1, v30.8b
.endif
.endm

function pixel_avg_w4_neon
1:  subs        w9,  w9,  #2
    ld1        {v0.s}[0], [x2], x3
    ld1        {v2.s}[0], [x4], x5
    urhadd      v0.8b,  v0.8b,  v2.8b
    ld1        {v1.s}[0], [x2], x3
    ld1        {v3.s}[0], [x4], x5
    urhadd      v1.8b,  v1.8b,  v3.8b
    st1        {v0.s}[0], [x0], x1
    st1        {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_w8_neon
1:  subs        w9,  w9,  #4
    ld1        {v0.8b}, [x2], x3
    ld1        {v1.8b}, [x4], x5
    ld1        {v2.8b}, [x2], x3
    urhadd      v0.8b,  v0.8b,  v1.8b
    ld1        {v3.8b}, [x4], x5
    st1        {v0.8b}, [x0], x1
    ld1        {v4.8b}, [x2], x3
    urhadd      v1.8b,  v2.8b,  v3.8b
    ld1        {v5.8b}, [x4], x5
    st1        {v1.8b}, [x0], x1
    ld1        {v6.8b}, [x2], x3
    ld1        {v7.8b}, [x4], x5
    urhadd      v2.8b,  v4.8b,  v5.8b
    urhadd      v3.8b,  v6.8b,  v7.8b
    st1        {v2.8b}, [x0], x1
    st1        {v3.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_w16_neon
1:  subs        w9,  w9,  #4
    ld1        {v0.16b}, [x2], x3
    ld1        {v1.16b}, [x4], x5
    ld1        {v2.16b}, [x2], x3
    urhadd      v0.16b, v0.16b, v1.16b
    ld1        {v3.16b}, [x4], x5
    st1        {v0.16b}, [x0], x1
    ld1        {v4.16b}, [x2], x3
    urhadd      v1.16b, v2.16b, v3.16b
    ld1        {v5.16b}, [x4], x5
    st1        {v1.16b}, [x0], x1
    ld1        {v6.16b}, [x2], x3
    ld1        {v7.16b}, [x4], x5
    urhadd      v2.16b, v4.16b, v5.16b
    urhadd      v3.16b, v6.16b, v7.16b
    st1        {v2.16b}, [x0], x1
    st1        {v3.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

