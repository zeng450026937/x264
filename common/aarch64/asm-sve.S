/*****************************************************************************
 * asm-sve.S: AArch64 utility macros
 *****************************************************************************
 * Copyright (C) 2008-2023 x264 project
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

#include "asm.S"

.arch armv8-a+sve

.macro transpose4x4.h_sve z0, z1, z2, z3, t0, t1, t2, t3
    transpose   \t0\().s,  \t2\().s,  \z0\().s,  \z2\().s
    transpose   \t1\().s,  \t3\().s,  \z1\().s,  \z3\().s
    transpose   \z0\().h,  \z1\().h,  \t0\().h,  \t1\().h
    transpose   \z2\().h,  \z3\().h,  \t2\().h,  \t3\().h
.endm

.macro transpose4x8.h_sve z0, z1, z2, z3, t0, t1, t2, t3
    transpose   \t0\().s,  \t2\().s,  \z0\().s,  \z2\().s
    transpose   \t1\().s,  \t3\().s,  \z1\().s,  \z3\().s
    transpose   \z0\().h,  \z1\().h,  \t0\().h,  \t1\().h
    transpose   \z2\().h,  \z3\().h,  \t2\().h,  \t3\().h
.endm

.macro transpose8x8.h_sve r0, r1, r2, r3, r4, r5, r6, r7, r8, r9
    trn1        \r8\().H,  \r0\().H,  \r1\().H
    trn2        \r9\().H,  \r0\().H,  \r1\().H
    trn1        \r1\().H,  \r2\().H,  \r3\().H
    trn2        \r3\().H,  \r2\().H,  \r3\().H
    trn1        \r0\().H,  \r4\().H,  \r5\().H
    trn2        \r5\().H,  \r4\().H,  \r5\().H
    trn1        \r2\().H,  \r6\().H,  \r7\().H
    trn2        \r7\().H,  \r6\().H,  \r7\().H

    trn1        \r4\().S,  \r0\().S,  \r2\().S
    trn2        \r2\().S,  \r0\().S,  \r2\().S
    trn1        \r6\().S,  \r5\().S,  \r7\().S
    trn2        \r7\().S,  \r5\().S,  \r7\().S
    trn1        \r5\().S,  \r9\().S,  \r3\().S
    trn2        \r9\().S,  \r9\().S,  \r3\().S
    trn1        \r3\().S,  \r8\().S,  \r1\().S
    trn2        \r8\().S,  \r8\().S,  \r1\().S

    trn1        \r0\().D,  \r3\().D,  \r4\().D
    trn2        \r4\().D,  \r3\().D,  \r4\().D

    trn1        \r1\().D,  \r5\().D,  \r6\().D
    trn2        \r5\().D,  \r5\().D,  \r6\().D

    trn2        \r6\().D,  \r8\().D,  \r2\().D
    trn1        \r2\().D,  \r8\().D,  \r2\().D

    trn1        \r3\().D,  \r9\().D,  \r7\().D
    trn2        \r7\().D,  \r9\().D,  \r7\().D
.endm

.macro transpose_8x16_sve r0, r1, r2, r3, r4, r5, r6, r7, t0, t1
    trn1        \t0\().b, \r0\().b, \r1\().b
    trn2        \t1\().b, \r0\().b, \r1\().b
    trn1        \r1\().b, \r2\().b, \r3\().b
    trn2        \r3\().b, \r2\().b, \r3\().b
    trn1        \r0\().b, \r4\().b, \r5\().b
    trn2        \r5\().b, \r4\().b, \r5\().b
    trn1        \r2\().b, \r6\().b, \r7\().b
    trn2        \r7\().b, \r6\().b, \r7\().b

    trn1        \r4\().h,  \r0\().h, \r2\().h
    trn2        \r2\().h,  \r0\().h, \r2\().h
    trn1        \r6\().h,  \r5\().h, \r7\().h
    trn2        \r7\().h,  \r5\().h, \r7\().h
    trn1        \r5\().h,  \t1\().h, \r3\().h
    trn2        \t1\().h,  \t1\().h, \r3\().h
    trn1        \r3\().h,  \t0\().h, \r1\().h
    trn2        \t0\().h,  \t0\().h, \r1\().h

    trn1        \r0\().s,  \r3\().s,  \r4\().s
    trn2        \r4\().s,  \r3\().s,  \r4\().s

    trn1        \r1\().s,  \r5\().s,  \r6\().s
    trn2        \r5\().s,  \r5\().s,  \r6\().s

    trn2        \r6\().s,  \t0\().s,  \r2\().s
    trn1        \r2\().s,  \t0\().s,  \r2\().s

    trn1        \r3\().s,  \t1\().s,  \r7\().s
    trn2        \r7\().s,  \t1\().s,  \r7\().s
.endm

.macro  transpose_4x16_sve r0, r1, r2, r3, t4, t5, t6, t7
    trn1        \t4\().b, \r0\().b,  \r1\().b
    trn2        \t5\().b, \r0\().b,  \r1\().b
    trn1        \t6\().b, \r2\().b,  \r3\().b
    trn2        \t7\().b, \r2\().b,  \r3\().b

    trn1        \r0\().h,  \t4\().h,  \t6\().h
    trn2        \r2\().h,  \t4\().h,  \t6\().h
    trn1        \r1\().h,  \t5\().h,  \t7\().h
    trn2        \r3\().h,  \t5\().h,  \t7\().h
.endm
