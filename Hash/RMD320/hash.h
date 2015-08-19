/* -*-c-*-
 *
 * Generic handling for message digest functions
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

#ifndef CATACOMB_HASH_H
#define CATACOMB_HASH_H

#ifdef __cplusplus
  extern "C" {
#endif

/*----- Header files ------------------------------------------------------*/

#include <string.h>

/* changed to bits.h by Sriranga Veeraraghavan on 8/13/2015 */
      
/* #include <mLib/bits.h> */
#include "bits.h"

/*----- Macros ------------------------------------------------------------*/

/* --- @HASH_BUFFER@ --- *
 *
 * Arguments:	@PRE@, @pre@ = prefixes for hash-specific definitions
 *		@ictx@ = pointer to context block for the hash
 *		@ibuf@ = pointer to input data to hash
 *		@isz@ = size of buffer
 *
 * Use:		Handles buffering of input data to a hash function.  The
 *		hash's compression function is called when the buffer is
 *		full.  Note that the compression function can be called on
 *		data which is at odd alignments; it is expected to cope
 *		gracefully with this (possibly by copying the data into its
 *		internal buffer before starting).
 */

#define HASH_BUFFER(PRE, pre, ictx, ibuf, isz) do {			\
  pre##_ctx *_bctx = (ictx);						\
  size_t _bsz = (isz);							\
  const octet *_bbuf = (octet *)(ibuf);					\
									\
  /* --- Add on the size done so far --- *				\
   *									\
   * Messy, because trapping overflow is difficult when you don't know	\
   * how many bits you've actually got.					\
   */									\
									\
  {									\
    uint32 _l = U32(_bsz);						\
    uint32 _h = ((_bsz & ~MASK32) >> 16) >> 16;				\
    _bctx->nh += _h;							\
    _bctx->nl += _l;							\
    if (_bctx->nl < _l || _bctx->nl & ~MASK32)				\
      _bctx->nh++;							\
  }									\
									\
  /* --- Handle very small contributions --- */				\
									\
  if (_bctx->off + _bsz < PRE##_BUFSZ) {				\
    memcpy(_bctx->buf + _bctx->off, _bbuf, _bsz);			\
    _bctx->off += _bsz;							\
  } else {								\
									\
    /* --- Handle an initial partial buffer --- */			\
									\
    if (_bctx->off) {							\
      size_t s = PRE##_BUFSZ - _bctx->off;				\
      memcpy(_bctx->buf + _bctx->off, _bbuf, s);			\
      pre##_compress(_bctx, _bctx->buf);				\
      _bsz -= s; _bbuf += s;						\
    }									\
									\
    /* --- Do whole buffers while we can --- */				\
									\
    while (_bsz >= PRE##_BUFSZ) {					\
      pre##_compress(_bctx, _bbuf);					\
      _bsz -= PRE##_BUFSZ; _bbuf += PRE##_BUFSZ;			\
    }									\
									\
    /* --- And wrap up at the end --- */				\
									\
    if (_bsz)								\
      memcpy(_bctx->buf, _bbuf, _bsz);					\
    _bctx->off = _bsz;							\
  }									\
} while (0)

/* --- @HASH_PAD@ --- *
 *
 * Arguments:	@PRE@, @pre@ = prefixes for hash-specific definitions
 *		@ictx@ = pointer to context block for the hash
 *		@term@ = terminator character to write following the data
 *		@pad@ = pad character to fill with
 *		@diff@ = size of space to leave at the end of the last block
 *
 * Use:		Does padding for message digest functions.
 */

#define HASH_PAD(PRE, pre, ictx, term, pad, diff) do {			\
  pre##_ctx *_pctx = (ictx);						\
									\
  _pctx->buf[_pctx->off] = term;					\
  _pctx->off++;								\
  if (_pctx->off > PRE##_BUFSZ - diff) {				\
    if (_pctx->off < PRE##_BUFSZ)					\
      memset(_pctx->buf + _pctx->off, pad, PRE##_BUFSZ - _pctx->off);	\
    pre##_compress(_pctx, _pctx->buf);					\
    memset(_pctx->buf, pad, PRE##_BUFSZ - diff);			\
  } else								\
    memset(_pctx->buf + _pctx->off, pad,				\
	   PRE##_BUFSZ - _pctx->off - diff);				\
} while (0)

/* --- @HASH_MD5STRENGTH@ --- *
 *
 * Arguments:	@PRE@, @pre@ = prefixes for hash-specific definitions
 *		@ictx@ = pointer to context block for the hash
 *
 * Use:		Does MD5-style MD strengthening.  The data is terminated
 *		by a single set bit, padded with zero bits, and then a 64-
 *		bit length is written, little-end first.
 */

#define HASH_MD5STRENGTH(PRE, pre, ictx) do {				\
  pre##_ctx *_mctx = (ictx);						\
  HASH_PAD(PRE, pre, _mctx, 0x80u, 0, 8);				\
  STORE32_L(_mctx->buf + PRE##_BUFSZ - 8, _mctx->nl << 3);		\
  STORE32_L(_mctx->buf + PRE##_BUFSZ - 4,				\
	    (_mctx->nl >> 29) | (_mctx->nh << 3));			\
  pre##_compress(_mctx, _mctx->buf);					\
} while (0)

/* --- @HASH_TEST@ --- *
 *
 * Arguments:	@PRE@, @pre@ = prefixes for hash-specfic definitions
 *
 * Use:		Standard test rig for hash functions.
 */

#ifdef TEST_RIG

#include <mLib/quis.h>
#include <mLib/testrig.h>

#define HASH_BUFLEN 100000

#define HASH_TEST(PRE, pre)						\
									\
static int verify(dstr *v)						\
{									\
  pre##_ctx ctx;							\
  int ok = 1;								\
  int i;								\
  octet *p;								\
  int szs[] = { 1, 7, 192, -1, 0 }, *ip;				\
  size_t sz;								\
  dstr d;								\
									\
  dstr_create(&d);							\
  dstr_ensure(&d, PRE##_HASHSZ);					\
  d.len = PRE##_HASHSZ;							\
									\
  for (ip = szs; *ip; ip++) {						\
    i = *ip;								\
    sz = v[0].len;							\
    if (i == -1)							\
      i = sz;								\
    if (i > sz)								\
      continue;								\
    p = (octet *)v[0].buf;						\
    pre##_init(&ctx);							\
    while (sz) {							\
      if (i > sz)							\
	i = sz;								\
      pre##_hash(&ctx, p, i);						\
      p += i;								\
      sz -= i;								\
    }									\
    pre##_done(&ctx, d.buf);						\
    if (memcmp(d.buf, v[1].buf, PRE##_HASHSZ) != 0) {			\
      printf("\nfail:\n\tstep = %i\n\tinput = `%s'\n\texpected = ",	\
	     *ip, v[0].buf);						\
      type_hex.dump(&v[1], stdout);					\
      fputs("\n\tcomputed = ", stdout);					\
      type_hex.dump(&d, stdout);					\
      putchar('\n');							\
      ok = 0;								\
    }									\
  }									\
									\
  dstr_destroy(&d);							\
  return (ok);								\
}									\
									\
static int verifyrep(dstr *v)						\
{									\
  pre##_ctx ctx;							\
  size_t len = v[0].len;						\
  int n = *(int *)v[1].buf;						\
  int nd = 0;								\
  int nn = len;								\
  int ok = 1;								\
  octet *p, *q;								\
  dstr d = DSTR_INIT;							\
									\
  while (nn < HASH_BUFLEN && (n & 1) == 0) { nd++; nn <<= 1; n >>= 1; }	\
  p = xmalloc(nn);							\
  memcpy(p, v[0].buf, len);						\
  q = p + len;								\
  while (nd--) { memcpy(q, p, len); q += len; len <<= 1; }		\
									\
  dstr_ensure(&d, PRE##_HASHSZ);					\
  d.len = PRE##_HASHSZ;							\
  pre##_init(&ctx);							\
  while (n--) pre##_hash(&ctx, p, len);					\
  pre##_done(&ctx, d.buf);						\
									\
  if (memcmp(d.buf, v[2].buf, PRE##_HASHSZ) != 0) {			\
    printf("\nfail:\n\tinput = `%s'\n\treps = `%i'\n\texpected = ",	\
	     v[0].buf, *(int *)v[1].buf);				\
    type_hex.dump(&v[2], stdout);					\
    fputs("\n\tcomputed = ", stdout);					\
    type_hex.dump(&d, stdout);						\
    putchar('\n');							\
    ok = 0;								\
  }									\
  xfree(p);								\
  dstr_destroy(&d);							\
  return (ok);								\
}									\
									\
static test_chunk defs[] = {						\
  { #pre, verify, { &type_string, &type_hex, 0 } },			\
  { #pre "-rep", verifyrep,						\
    { &type_string, &type_int, &type_hex, 0 } },			\
  { 0, 0, { 0 } }							\
};									\
									\
int main(int argc, char *argv[])					\
{									\
  ego(argv[0]);								\
  test_run(argc, argv, defs, SRCDIR"/t/" #pre);				\
  return (0);								\
}

#else
#  define HASH_TEST(PRE, pre)
#endif

/*----- That's all, folks -------------------------------------------------*/

#ifdef __cplusplus
  }
#endif

#endif
