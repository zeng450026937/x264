/****************************************************************************
 * quant-a-common.S: aarch64 motion compensation
 *****************************************************************************
 * Copyright (C) 2009-2023 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          Martin Storsjo <martin@martin.st>
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

const mask64, align=6
    .byte  0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
    .byte  0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
endconst


