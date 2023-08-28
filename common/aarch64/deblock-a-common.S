/*****************************************************************************
 * deblock-a-common.S: aarch64 deblocking
 *****************************************************************************
 * Copyright (C) 2009-2023 x264 project
 *
 * Authors: Mans Rullgard <mans@mansr.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          David Chen <david.chen@myais.com.cn>
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

.macro h264_loop_filter_start
    cmp             w2,  #0
    ldr             w6,  [x4]
    ccmp            w3,  #0, #0, ne
    mov             v24.s[0], w6
    and             w8,  w6,  w6,  lsl #16
    b.eq            1f
    ands            w8,  w8,  w8,  lsl #8
    b.ge            2f
1:
    ret
2:
.endm

.macro h264_loop_filter_luma
    dup             v22.16b, w2                     // alpha
    uxtl            v24.8h,  v24.8b
    uabd            v21.16b, v16.16b, v0.16b        // abs(p0 - q0)
    uxtl            v24.4s,  v24.4h
    uabd            v28.16b, v18.16b, v16.16b       // abs(p1 - p0)
    sli             v24.8h,  v24.8h,  #8
    uabd            v30.16b, v2.16b,  v0.16b        // abs(q1 - q0)
    sli             v24.4s,  v24.4s,  #16
    cmhi            v21.16b, v22.16b, v21.16b       // < alpha
    dup             v22.16b, w3                     // beta
    cmlt            v23.16b, v24.16b, #0
    cmhi            v28.16b, v22.16b, v28.16b       // < beta
    cmhi            v30.16b, v22.16b, v30.16b       // < beta
    bic             v21.16b, v21.16b, v23.16b
    uabd            v17.16b, v20.16b, v16.16b       // abs(p2 - p0)
    and             v21.16b, v21.16b, v28.16b
    uabd            v19.16b,  v4.16b,  v0.16b       // abs(q2 - q0)
    cmhi            v17.16b, v22.16b, v17.16b       // < beta
    and             v21.16b, v21.16b, v30.16b
    cmhi            v19.16b, v22.16b, v19.16b       // < beta
    and             v17.16b, v17.16b, v21.16b
    and             v19.16b, v19.16b, v21.16b
    and             v24.16b, v24.16b, v21.16b
    urhadd          v28.16b, v16.16b,  v0.16b
    sub             v21.16b, v24.16b, v17.16b
    uqadd           v23.16b, v18.16b, v24.16b
    uhadd           v20.16b, v20.16b, v28.16b
    sub             v21.16b, v21.16b, v19.16b
    uhadd           v28.16b,  v4.16b, v28.16b
    umin            v23.16b, v23.16b, v20.16b
    uqsub           v22.16b, v18.16b, v24.16b
    uqadd           v4.16b,   v2.16b, v24.16b
    umax            v23.16b, v23.16b, v22.16b
    uqsub           v22.16b,  v2.16b, v24.16b
    umin            v28.16b,  v4.16b, v28.16b
    uxtl            v4.8h,    v0.8b
    umax            v28.16b, v28.16b, v22.16b
    uxtl2           v20.8h,   v0.16b
    usubw           v4.8h,    v4.8h,  v16.8b
    usubw2          v20.8h,  v20.8h,  v16.16b
    shl             v4.8h,    v4.8h,  #2
    shl             v20.8h,  v20.8h,  #2
    uaddw           v4.8h,    v4.8h,  v18.8b
    uaddw2          v20.8h,  v20.8h,  v18.16b
    usubw           v4.8h,    v4.8h,   v2.8b
    usubw2          v20.8h,  v20.8h,   v2.16b
    rshrn           v4.8b,    v4.8h,  #3
    rshrn2          v4.16b,  v20.8h,  #3
    bsl             v17.16b, v23.16b, v18.16b
    bsl             v19.16b, v28.16b,  v2.16b
    neg             v23.16b, v21.16b
    uxtl            v28.8h,  v16.8b
    smin            v4.16b,   v4.16b, v21.16b
    uxtl2           v21.8h,  v16.16b
    smax            v4.16b,   v4.16b, v23.16b
    uxtl            v22.8h,   v0.8b
    uxtl2           v24.8h,   v0.16b
    saddw           v28.8h,  v28.8h,  v4.8b
    saddw2          v21.8h,  v21.8h,  v4.16b
    ssubw           v22.8h,  v22.8h,  v4.8b
    ssubw2          v24.8h,  v24.8h,  v4.16b
    sqxtun          v16.8b,  v28.8h
    sqxtun2         v16.16b, v21.8h
    sqxtun          v0.8b,   v22.8h
    sqxtun2         v0.16b,  v24.8h
.endm

.macro h264_loop_filter_start_intra
    orr             w4,  w2,  w3
    cmp             w4,  #0
    b.ne            1f
    ret
1:
    dup             v30.16b, w2                // alpha
    dup             v31.16b, w3                // beta
.endm

.macro h264_loop_filter_chroma_neon
    dup             v22.16b, w2              // alpha
    uxtl            v24.8h,  v24.8b
    uabd            v26.16b, v16.16b, v0.16b   // abs(p0 - q0)
    uxtl            v4.8h,   v0.8b
    uxtl2           v5.8h,   v0.16b
    uabd            v28.16b, v18.16b, v16.16b  // abs(p1 - p0)
    usubw           v4.8h,   v4.8h,   v16.8b
    usubw2          v5.8h,   v5.8h,   v16.16b
    sli             v24.8h,  v24.8h,  #8
    shl             v4.8h,   v4.8h,   #2
    shl             v5.8h,   v5.8h,   #2
    uabd            v30.16b, v2.16b,  v0.16b   // abs(q1 - q0)
    uxtl            v24.4s,  v24.4h
    uaddw           v4.8h,   v4.8h,   v18.8b
    uaddw2          v5.8h,   v5.8h,   v18.16b
    cmhi            v26.16b, v22.16b, v26.16b  // < alpha
    usubw           v4.8h,   v4.8h,   v2.8b
    usubw2          v5.8h,   v5.8h,   v2.16b
    sli             v24.4s,  v24.4s,  #16
    dup             v22.16b, w3              // beta
    rshrn           v4.8b,   v4.8h,   #3
    rshrn2          v4.16b,  v5.8h,   #3
    cmhi            v28.16b, v22.16b, v28.16b  // < beta
    cmhi            v30.16b, v22.16b, v30.16b  // < beta
    smin            v4.16b,  v4.16b,  v24.16b
    neg             v25.16b, v24.16b
    and             v26.16b, v26.16b, v28.16b
    smax            v4.16b,  v4.16b,  v25.16b
    and             v26.16b, v26.16b, v30.16b
    uxtl            v22.8h,  v0.8b
    uxtl2           v23.8h,  v0.16b
    and             v4.16b,  v4.16b,  v26.16b
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
