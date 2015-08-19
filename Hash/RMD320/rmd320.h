/* -*-c-*-
 *
 * The RIPEMD-320 message digest function
 *
 * (c) 1998 Straylight/Edgeware
 */

/*----- Licensing notice --------------------------------------------------*
 *
 * This file is part of Catacomb.
 *
 * Catacomb is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * Catacomb is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with Catacomb; if not, write to the Free
 * Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
 * MA 02111-1307, USA.
 */

/*----- Notes on the RIPEMD-320 hash function -----------------------------*
 *
 * RIPEMD-320 was invented by Hans Dobbertin, Antoon Bosselaers and Bart
 * Preneel.  It's a double-width version of RIPEMD-160, constructed simply by
 * not gluing together the two parallel computations which RIPEMD-160 usually
 * does in its compression function.  The authors warn that, while its output
 * is twice as wide as that of RIPEMD-160, they don't expect it to offer any
 * more security.
 */

#ifndef CATACOMB_RMD320_H
#define CATACOMB_RMD320_H

#ifdef __cplusplus
  extern "C" {
#endif

/*----- Header files ------------------------------------------------------*/

//#include <mLib/bits.h>
#include "bits.h"

/* Commented out by Sriranga Veeraraghavan on 8/13/2015 */
      
/*
#ifndef CATACOMB_GHASH_H
#  include "ghash.h"
#endif
*/
      
/*----- Magic numbers -----------------------------------------------------*/

#define RMD320_BUFSZ 64
#define RMD320_HASHSZ 40
#define RMD320_STATESZ 40

/*----- Data structures ---------------------------------------------------*/

typedef struct rmd320_ctx {
  uint32 a, b, c, d, e;			/* Chaining variables */
  uint32 A, B, C, D, E;			/* More chaining variables */
  uint32 nl, nh;                /* Byte count so far */

  /*
    offset changed from unsigned to size_t to fix OSX complier warning by
    Sriranga Veeraraghavan on 8/13/2015
   */
    
  /* unsigned off; */               /* Offset into buffer */
  size_t off;                   /* Offset into buffer */
  octet buf[RMD320_BUFSZ];		/* Accumulation buffer */
} rmd320_ctx;

/*----- Functions provided ------------------------------------------------*/

/* --- @rmd320_compress@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@const void *sbuf@ = pointer to buffer of appropriate size
 *
 * Returns:	---
 *
 * Use:		RIPEMD-320 compression function.
 */

extern void rmd320_compress(rmd320_ctx */*ctx*/, const void */*sbuf*/);

/* --- @rmd320_init@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block to initialize
 *
 * Returns:	---
 *
 * Use:		Initializes a context block ready for hashing.
 */

extern void rmd320_init(rmd320_ctx */*ctx*/);

/* --- @rmd320_set@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@const void *buf@ = pointer to state buffer
 *		@unsigned long count@ = current count of bytes processed
 *
 * Returns:	---
 *
 * Use:		Initializes a context block from a given state.  This is
 *		useful in cases where the initial hash state is meant to be
 *		secret, e.g., for NMAC and HMAC support.
 */

extern void rmd320_set(rmd320_ctx */*ctx*/,
		       const void */*buf*/, unsigned long /*count*/);

/* --- @rmd320_hash@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@const void *buf@ = buffer of data to hash
 *		@size_t sz@ = size of buffer to hash
 *
 * Returns:	---
 *
 * Use:		Hashes a buffer of data.  The buffer may be of any size and
 *		alignment.
 */

extern void rmd320_hash(rmd320_ctx */*ctx*/,
			const void */*buf*/, size_t /*sz*/);

/* --- @rmd320_done@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@void *hash@ = pointer to output buffer
 *
 * Returns:	---
 *
 * Use:		Returns the hash of the data read so far.
 */

extern void rmd320_done(rmd320_ctx */*ctx*/, void */*hash*/);

/* --- @rmd320_state@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context
 *		@void *state@ = pointer to buffer for current state
 *
 * Returns:	Number of bytes written to the hash function so far.
 *
 * Use:		Returns the current state of the hash function such that
 *		it can be passed to @rmd320_set@.
 */

extern unsigned long rmd320_state(rmd320_ctx */*ctx*/, void */*state*/);

/*----- Generic hash interface --------------------------------------------*/

/* Commented out by Sriranga Veeraraghavan on 8/13/2015 */

/*
extern const gchash rmd320;
*/
      
/*----- That's all, folks -------------------------------------------------*/

#ifdef __cplusplus
  }
#endif

#endif
