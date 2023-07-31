/*****************************************************************************
 * quant-a-sve.S: aarch64 deblocking
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
#include "quant-a-common.S"

.arch armv8-a+sve

function decimate_score64_sve, export=1
    ld1        {v0.8h,v1.8h}, [x0], #32
    ld1        {v2.8h,v3.8h}, [x0], #32
    ld1        {v4.8h,v5.8h}, [x0], #32
    ld1        {v6.8h,v7.8h}, [x0]
    movrel      x6,  mask64
    movi        v31.16b, #0x01
    sqxtn       v16.8b,  v1.8h
    sqxtn2      v16.16b, v0.8h
    sqxtn       v17.8b,  v3.8h
    sqxtn2      v17.16b, v2.8h
    sqxtn       v18.8b,  v5.8h
    sqxtn2      v18.16b, v4.8h
    sqxtn       v19.8b,  v7.8h
    sqxtn2      v19.16b, v6.8h
    abs         v4.16b, v16.16b
    abs         v5.16b, v17.16b
    abs         v6.16b, v18.16b
    abs         v7.16b, v19.16b
    ld1        {v30.16b}, [x6]
    ptrue       p0.b, vl16
    cmpeq       p1.b, p0/z, z16.b, #0
    cmpeq       p2.b, p0/z, z17.b, #0
    cmpeq       p3.b, p0/z, z18.b, #0
    cmpeq       p4.b, p0/z, z19.b, #0 
    umax        v4.16b, v4.16b, v5.16b
    umax        v6.16b, v6.16b, v7.16b
    mov         z0.b, p1/m, z30.b
    mov         z1.b, p2/m, z30.b
    mov         z2.b, p3/m, z30.b
    mov         z3.b, p4/m, z30.b
    umax        v4.16b, v4.16b, v6.16b
    addp        v0.16b, v1.16b, v0.16b
    addp        v2.16b, v3.16b, v2.16b
    cmhi        v4.16b, v4.16b, v31.16b
    addp        v0.16b, v2.16b, v0.16b
    shrn        v4.8b,  v4.8h,  #4
    addp        v0.16b, v0.16b, v0.16b
    fmov        x2,  d4
    fmov        x1,  d0
    cbnz        x2,  9f
    mvn         x1,  x1
    mov         w0,  #0
    cbz         x1,  0f
    movrel      x5,  X264(decimate_table8)
1:
    clz         x3,  x1
    lsl         x1,  x1,  x3
    ldrb        w7,  [x5, x3]
    lsl         x1,  x1,  #1
    add         w0,  w0,  w7
    cbnz        x1,  1b
    ret
9:
    mov         w0,  #9
0:
    ret
endfunc
