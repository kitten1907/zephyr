/*
 * Copyright (c) 2016 Cadence Design Systems, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

/******************************************************************************
  Xtensa interrupt handling data and assembly routines.
  Also see xtensa_intr.c and xtensa_vectors.S.
******************************************************************************/

#include <xtensa/hal.h>
#include <xtensa/config/core.h>
#include "xtensa_rtos.h"
#include "xtensa_context.h"

#if XCHAL_HAVE_INTERRUPTS

/*
-------------------------------------------------------------------------------
  INTENABLE virtualization information.
-------------------------------------------------------------------------------
*/

	.data
	.global _xt_intdata
	.align  8
_xt_intdata:
	.global _xt_intenable
	.type   _xt_intenable,@object
	.size   _xt_intenable,4
	.global _xt_vpri_mask
	.type   _xt_vpri_mask,@object
	.size   _xt_vpri_mask,4

_xt_intenable:     .word   0             /* Virtual INTENABLE     */
_xt_vpri_mask:     .word   0xFFFFFFFF    /* Virtual priority mask */


#endif /* XCHAL_HAVE_INTERRUPTS */


/*
-------------------------------------------------------------------------------
  unsigned int z_xt_ints_on ( unsigned int mask )

  Enables a set of interrupts. Does not simply set INTENABLE directly, but
  computes it as a function of the current virtual priority.
  Can be called from interrupt handlers.
-------------------------------------------------------------------------------
*/

	.text
	.align  4
	.global z_xt_ints_on
	.type   z_xt_ints_on,@function

z_xt_ints_on:

	ENTRY0
#if XCHAL_HAVE_INTERRUPTS
	movi    a3, 0
	movi    a4, _xt_intdata
	xsr     a3, INTENABLE        /* Disables all interrupts   */
	rsync
	l32i    a3, a4, 0            /* a3 = _xt_intenable        */
	l32i    a6, a4, 4            /* a6 = _xt_vpri_mask        */
	or      a5, a3, a2           /* a5 = _xt_intenable | mask */
	s32i    a5, a4, 0            /* _xt_intenable |= mask     */
	and     a5, a5, a6           /* a5 = _xt_intenable & _xt_vpri_mask */
	wsr     a5, INTENABLE        /* Reenable interrupts       */
	mov     a2, a3               /* Previous mask             */
#else
	movi    a2, 0                /* Return zero */
#endif
	RET0

	.size   z_xt_ints_on, . - z_xt_ints_on


/*
-------------------------------------------------------------------------------
  unsigned int z_xt_ints_off ( unsigned int mask )

  Disables a set of interrupts. Does not simply set INTENABLE directly,
  but computes it as a function of the current virtual priority.
  Can be called from interrupt handlers.
-------------------------------------------------------------------------------
*/

	.text
	.align  4
	.global z_xt_ints_off
	.type   z_xt_ints_off,@function

z_xt_ints_off:

	ENTRY0
#if XCHAL_HAVE_INTERRUPTS
	movi    a3, 0
	movi    a4, _xt_intdata
	xsr     a3, INTENABLE        /* Disables all interrupts    */
	rsync
	l32i    a3, a4, 0            /* a3 = _xt_intenable         */
	l32i    a6, a4, 4            /* a6 = _xt_vpri_mask         */
	or      a5, a3, a2           /* a5 = _xt_intenable | mask  */
	xor     a5, a5, a2           /* a5 = _xt_intenable & ~mask */
	s32i    a5, a4, 0            /* _xt_intenable &= ~mask     */
	and     a5, a5, a6           /* a5 = _xt_intenable & _xt_vpri_mask */
	wsr     a5, INTENABLE        /* Reenable interrupts        */
	mov     a2, a3               /* Previous mask              */
#else
	movi    a2, 0                /* return zero */
#endif
	RET0

	.size   z_xt_ints_off, . - z_xt_ints_off


