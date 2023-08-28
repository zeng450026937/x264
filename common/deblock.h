/*****************************************************************************
 * dct.h: deblocking
 *****************************************************************************
 * Copyright (C) 2003-2023 x264 project
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

#include "common.h"

#define x264_setupDeblockSvePrimitives x264_template(setupDeblockSvePrimitives)
void x264_setupDeblockSvePrimitives(x264_deblock_function_t *pf);
#define x264_setupDeblockNeonPrimitives x264_template(setupDeblockNeonPrimitives)
void x264_setupDeblockNeonPrimitives(x264_deblock_function_t *pf);
