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

/*----- Header files ------------------------------------------------------*/

/* changed to bits.h by Sriranga Veeraraghavan on 8/13/2015 */

/* #include <mLib/bits.h> */
#include "bits.h"

/* Commented out by Sriranga Veeraraghavan on 8/13/2015 */

/*
#include "ghash.h"
#include "ghash-def.h"
*/

#include "hash.h"
#include "rmd320.h"

/*----- Main code ---------------------------------------------------------*/

/* --- @rmd320_compress@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@const void *sbuf@ = pointer to buffer of appropriate size
 *
 * Returns:	---
 *
 * Use:		RIPEMD-320 compression function.
 */

void rmd320_compress(rmd320_ctx *ctx, const void *sbuf)
{
  uint32 a, b, c, d, e;
  uint32 A, B, C, D, E;
  uint32 buf[16];

  /* --- Fetch the chaining variables --- */

  a = ctx->a;
  b = ctx->b;
  c = ctx->c;
  d = ctx->d;
  e = ctx->e;

  A = ctx->A;
  B = ctx->B;
  C = ctx->C;
  D = ctx->D;
  E = ctx->E;

  /* --- Fetch the buffer contents --- */

  {
    int i;
    const octet *p;

    for (i = 0, p = sbuf; i < 16; i++, p += 4)
      buf[i] = LOAD32_L(p);
  }

  /* --- Definitions for round functions --- */

#define F(x, y, z) ((x) ^ (y) ^ (z))
#define G(x, y, z) (((x) & (y)) | (~(x) & (z)))
#define H(x, y, z) (((x) | ~(y)) ^ (z))
#define I(x, y, z) (((x) & (z)) | ((y) & ~(z)))
#define J(x, y, z) ((x) ^ ((y) | ~(z)))

#define T(v, w, x, y, z, i, r, f, k) do {				\
  uint32 _t = v + f(w, x, y) + buf[i] + k;				\
  v = ROL32(_t, r) + z; x = ROL32(x, 10);				\
} while (0)

#define F1(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, F, 0x00000000)
#define G1(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, G, 0x5a827999)
#define H1(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, H, 0x6ed9eba1)
#define I1(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, I, 0x8f1bbcdc)
#define J1(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, J, 0xa953fd4e)

#define F2(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, J, 0x50a28be6)
#define G2(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, I, 0x5c4dd124)
#define H2(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, H, 0x6d703ef3)
#define I2(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, G, 0x7a6d76e9)
#define J2(v, w, x, y, z, i, r) T(v, w, x, y, z, i, r, F, 0x00000000)

  /* --- We must do both lines together --- */

  F1(a, b, c, d, e,  0, 11);
  F1(e, a, b, c, d,  1, 14);
  F1(d, e, a, b, c,  2, 15);
  F1(c, d, e, a, b,  3, 12);
  F1(b, c, d, e, a,  4,	 5);
  F1(a, b, c, d, e,  5,	 8);
  F1(e, a, b, c, d,  6,	 7);
  F1(d, e, a, b, c,  7,	 9);
  F1(c, d, e, a, b,  8, 11);
  F1(b, c, d, e, a,  9, 13);
  F1(a, b, c, d, e, 10, 14);
  F1(e, a, b, c, d, 11, 15);
  F1(d, e, a, b, c, 12,	 6);
  F1(c, d, e, a, b, 13,	 7);
  F1(b, c, d, e, a, 14,	 9);
  F1(a, b, c, d, e, 15,	 8);

  F2(A, B, C, D, E,  5,	 8);
  F2(E, A, B, C, D, 14,	 9);
  F2(D, E, A, B, C,  7,	 9);
  F2(C, D, E, A, B,  0,	11);
  F2(B, C, D, E, A,  9,	13);
  F2(A, B, C, D, E,  2,	15);
  F2(E, A, B, C, D, 11,	15);
  F2(D, E, A, B, C,  4,	 5);
  F2(C, D, E, A, B, 13,	 7);
  F2(B, C, D, E, A,  6,	 7);
  F2(A, B, C, D, E, 15,	 8);
  F2(E, A, B, C, D,  8,	11);
  F2(D, E, A, B, C,  1,	14);
  F2(C, D, E, A, B, 10,	14);
  F2(B, C, D, E, A,  3,	12);
  F2(A, B, C, D, E, 12,	 6);

  G1(e, A, b, c, d,  7,	 7);
  G1(d, e, A, b, c,  4,	 6);
  G1(c, d, e, A, b, 13,	 8);
  G1(b, c, d, e, A,  1,	13);
  G1(A, b, c, d, e, 10,	11);
  G1(e, A, b, c, d,  6,	 9);
  G1(d, e, A, b, c, 15,	 7);
  G1(c, d, e, A, b,  3,	15);
  G1(b, c, d, e, A, 12,	 7);
  G1(A, b, c, d, e,  0,	12);
  G1(e, A, b, c, d,  9,	15);
  G1(d, e, A, b, c,  5,	 9);
  G1(c, d, e, A, b,  2,	11);
  G1(b, c, d, e, A, 14,	 7);
  G1(A, b, c, d, e, 11,	13);
  G1(e, A, b, c, d,  8,	12);

  G2(E, a, B, C, D,  6,	 9);
  G2(D, E, a, B, C, 11,	13);
  G2(C, D, E, a, B,  3,	15);
  G2(B, C, D, E, a,  7,	 7);
  G2(a, B, C, D, E,  0,	12);
  G2(E, a, B, C, D, 13,	 8);
  G2(D, E, a, B, C,  5,	 9);
  G2(C, D, E, a, B, 10,	11);
  G2(B, C, D, E, a, 14,	 7);
  G2(a, B, C, D, E, 15,	 7);
  G2(E, a, B, C, D,  8,	12);
  G2(D, E, a, B, C, 12,	 7);
  G2(C, D, E, a, B,  4,	 6);
  G2(B, C, D, E, a,  9,	15);
  G2(a, B, C, D, E,  1,	13);
  G2(E, a, B, C, D,  2,	11);

  H1(d, e, A, B, c,  3,	11);
  H1(c, d, e, A, B, 10,	13);
  H1(B, c, d, e, A, 14,	 6);
  H1(A, B, c, d, e,  4,	 7);
  H1(e, A, B, c, d,  9,	14);
  H1(d, e, A, B, c, 15,	 9);
  H1(c, d, e, A, B,  8,	13);
  H1(B, c, d, e, A,  1,	15);
  H1(A, B, c, d, e,  2,	14);
  H1(e, A, B, c, d,  7,	 8);
  H1(d, e, A, B, c,  0,	13);
  H1(c, d, e, A, B,  6,	 6);
  H1(B, c, d, e, A, 13,	 5);
  H1(A, B, c, d, e, 11,	12);
  H1(e, A, B, c, d,  5,	 7);
  H1(d, e, A, B, c, 12,	 5);

  H2(D, E, a, b, C, 15,	 9);
  H2(C, D, E, a, b,  5,	 7);
  H2(b, C, D, E, a,  1,	15);
  H2(a, b, C, D, E,  3,	11);
  H2(E, a, b, C, D,  7,	 8);
  H2(D, E, a, b, C, 14,	 6);
  H2(C, D, E, a, b,  6,	 6);
  H2(b, C, D, E, a,  9,	14);
  H2(a, b, C, D, E, 11,	12);
  H2(E, a, b, C, D,  8,	13);
  H2(D, E, a, b, C, 12,	 5);
  H2(C, D, E, a, b,  2,	14);
  H2(b, C, D, E, a, 10,	13);
  H2(a, b, C, D, E,  0,	13);
  H2(E, a, b, C, D,  4,	 7);
  H2(D, E, a, b, C, 13,	 5);

  I1(C, d, e, A, B,  1,	11);
  I1(B, C, d, e, A,  9,	12);
  I1(A, B, C, d, e, 11,	14);
  I1(e, A, B, C, d, 10,	15);
  I1(d, e, A, B, C,  0,	14);
  I1(C, d, e, A, B,  8,	15);
  I1(B, C, d, e, A, 12,	 9);
  I1(A, B, C, d, e,  4,	 8);
  I1(e, A, B, C, d, 13,	 9);
  I1(d, e, A, B, C,  3,	14);
  I1(C, d, e, A, B,  7,	 5);
  I1(B, C, d, e, A, 15,	 6);
  I1(A, B, C, d, e, 14,	 8);
  I1(e, A, B, C, d,  5,	 6);
  I1(d, e, A, B, C,  6,	 5);
  I1(C, d, e, A, B,  2,	12);

  I2(c, D, E, a, b,  8,	15);
  I2(b, c, D, E, a,  6,	 5);
  I2(a, b, c, D, E,  4,	 8);
  I2(E, a, b, c, D,  1,	11);
  I2(D, E, a, b, c,  3,	14);
  I2(c, D, E, a, b, 11,	14);
  I2(b, c, D, E, a, 15,	 6);
  I2(a, b, c, D, E,  0,	14);
  I2(E, a, b, c, D,  5,	 6);
  I2(D, E, a, b, c, 12,	 9);
  I2(c, D, E, a, b,  2,	12);
  I2(b, c, D, E, a, 13,	 9);
  I2(a, b, c, D, E,  9,	12);
  I2(E, a, b, c, D,  7,	 5);
  I2(D, E, a, b, c, 10,	15);
  I2(c, D, E, a, b, 14,	 8);

  J1(B, C, D, e, A,  4,	 9);
  J1(A, B, C, D, e,  0,	15);
  J1(e, A, B, C, D,  5,	 5);
  J1(D, e, A, B, C,  9,	11);
  J1(C, D, e, A, B,  7,	 6);
  J1(B, C, D, e, A, 12,	 8);
  J1(A, B, C, D, e,  2,	13);
  J1(e, A, B, C, D, 10,	12);
  J1(D, e, A, B, C, 14,	 5);
  J1(C, D, e, A, B,  1,	12);
  J1(B, C, D, e, A,  3,	13);
  J1(A, B, C, D, e,  8,	14);
  J1(e, A, B, C, D, 11,	11);
  J1(D, e, A, B, C,  6,	 8);
  J1(C, D, e, A, B, 15,	 5);
  J1(B, C, D, e, A, 13,	 6);

  J2(b, c, d, E, a, 12,	 8);
  J2(a, b, c, d, E, 15,	 5);
  J2(E, a, b, c, d, 10,	12);
  J2(d, E, a, b, c,  4,	 9);
  J2(c, d, E, a, b,  1,	12);
  J2(b, c, d, E, a,  5,	 5);
  J2(a, b, c, d, E,  8,	14);
  J2(E, a, b, c, d,  7,	 6);
  J2(d, E, a, b, c,  6,	 8);
  J2(c, d, E, a, b,  2,	13);
  J2(b, c, d, E, a, 13,	 6);
  J2(a, b, c, d, E, 14,	 5);
  J2(E, a, b, c, d,  0,	15);
  J2(d, E, a, b, c,  3,	13);
  J2(c, d, E, a, b,  9,	11);
  J2(b, c, d, E, a, 11,	11);

  /* --- Write out the result --- */

  ctx->a += A;
  ctx->b += B;
  ctx->c += C;
  ctx->d += D;
  ctx->e += E;
  ctx->A += a;
  ctx->B += b;
  ctx->C += c;
  ctx->D += d;
  ctx->E += e;
}

/* --- @rmd320_init@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block to initialize
 *
 * Returns:	---
 *
 * Use:		Initializes a context block ready for hashing.
 */

void rmd320_init(rmd320_ctx *ctx)
{
  ctx->a = 0x67452301;
  ctx->b = 0xefcdab89;
  ctx->c = 0x98badcfe;
  ctx->d = 0x10325476;
  ctx->e = 0xc3d2e1f0;
  ctx->A = 0x76543210;
  ctx->B = 0xfedcba98;
  ctx->C = 0x89abcdef;
  ctx->D = 0x01234567;
  ctx->E = 0x3c2d1e0f;
  ctx->off = 0;
  ctx->nl = ctx->nh = 0;
}

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

void rmd320_set(rmd320_ctx *ctx, const void *buf, unsigned long count)
{
  const octet *p = buf;
  ctx->a = LOAD32_L(p +	 0);
  ctx->b = LOAD32_L(p +	 4);
  ctx->c = LOAD32_L(p +	 8);
  ctx->d = LOAD32_L(p + 12);
  ctx->e = LOAD32_L(p + 16);
  ctx->A = LOAD32_L(p + 20);
  ctx->B = LOAD32_L(p + 24);
  ctx->C = LOAD32_L(p + 28);
  ctx->D = LOAD32_L(p + 32);
  ctx->E = LOAD32_L(p + 36);
  ctx->off = 0;
  ctx->nl = U32(count);
  ctx->nh = U32(((count & ~MASK32) >> 16) >> 16);
}

/* --- @rmd320_hash@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@const void *buf@ = buffer of data to hash
 *		@size_t sz@ = size of buffer to hash
 *
 * Returns:	---
 *
 * Use:		Hashes a buffer of data.  The buffer may be of any size and
 *		    alignment.
 */

void rmd320_hash(rmd320_ctx *ctx, const void *buf, size_t sz)
{
  HASH_BUFFER(RMD320, rmd320, ctx, buf, sz);
}

/* --- @rmd320_done@ --- *
 *
 * Arguments:	@rmd320_ctx *ctx@ = pointer to context block
 *		@void *hash@ = pointer to output buffer
 *
 * Returns:	---
 *
 * Use:		Returns the hash of the data read so far.
 */

void rmd320_done(rmd320_ctx *ctx, void *hash)
{
  octet *p = hash;
  HASH_MD5STRENGTH(RMD320, rmd320, ctx);
  STORE32_L(p +	 0, ctx->a);
  STORE32_L(p +	 4, ctx->b);
  STORE32_L(p +	 8, ctx->c);
  STORE32_L(p + 12, ctx->d);
  STORE32_L(p + 16, ctx->e);
  STORE32_L(p + 20, ctx->A);
  STORE32_L(p + 24, ctx->B);
  STORE32_L(p + 28, ctx->C);
  STORE32_L(p + 32, ctx->D);
  STORE32_L(p + 36, ctx->E);
}

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

unsigned long rmd320_state(rmd320_ctx *ctx, void *state)
{
  octet *p = state;
  STORE32_L(p +	 0, ctx->a);
  STORE32_L(p +	 4, ctx->b);
  STORE32_L(p +	 8, ctx->c);
  STORE32_L(p + 12, ctx->d);
  STORE32_L(p + 16, ctx->e);
  STORE32_L(p + 20, ctx->A);
  STORE32_L(p + 24, ctx->B);
  STORE32_L(p + 28, ctx->C);
  STORE32_L(p + 32, ctx->D);
  STORE32_L(p + 36, ctx->E);
  return (ctx->nl | ((ctx->nh << 16) << 16));
}

/* Commented out by Sriranga Veeraraghavan on 8/13/2015 */

/* --- Generic interface --- */

/* GHASH_DEF(RMD320, rmd320) */

/* --- Test code --- */

/* HASH_TEST(RMD320, rmd320) */

/*----- That's all, folks -------------------------------------------------*/
