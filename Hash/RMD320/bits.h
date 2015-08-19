/* -*-c-*-
 *
 * Portable bit-level manipulation macros
 *
 * (c) 1998 Straylight/Edgeware
 */

/*----- Licensing notice --------------------------------------------------*
 *
 * This file is part of the mLib utilities library.
 *
 * mLib is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * mLib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with mLib; if not, write to the Free
 * Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
 * MA 02111-1307, USA.
 */

#ifndef MLIB_BITS_H
#define MLIB_BITS_H

#ifdef __cplusplus
  extern "C" {
#endif

/*----- Header files ------------------------------------------------------*/

#include <limits.h>
#include <stddef.h>
#if __STDC_VERSION__ >= 199900l
#  include <stdint.h>
#endif

/*----- Decide on some types ----------------------------------------------*/

/* --- Make GNU C shut up --- */

#if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 91)
#  define MLIB_BITS_EXTENSION __extension__
#else
#  define MLIB_BITS_EXTENSION
#endif

/* --- Decide on a 32-bit type --- *
 *
 * I want a type which is capable of expressing 32-bit numbers.  Because some
 * implementations have 64-bit @long@s (infinitely preferable to the abortion
 * that is @long long@), using @unsigned long@ regardless is wasteful.  So,
 * if @int@ appears to be good enough, then I'll go with that.
 */

#if UINT_MAX >= 0xffffffffu
  typedef unsigned int uint32;
#else
  typedef unsigned long uint32;
#endif

/* --- Decide on a 64-bit type --- *
 *
 * The test is quite subtle.  Think about it.  Note that (at least on my
 * machine), the 32-bit macros are *much* faster than GCC's @long long@
 * support.
 */

#if defined(ULONG_LONG_MAX) && !defined(ULLONG_MAX)
#  define ULLONG_MAX ULONG_LONG_MAX
#endif

#if UINT_MAX >> 31 > 0xffffffff
#  define HAVE_UINT64
   typedef unsigned int uint64;
#elif ULONG_MAX >> 31 > 0xffffffff
#  define HAVE_UINT64

      /*
       typedef for uint64 changed from unsigned long to uint64_t to fix OSX 
       complier warning by Sriranga Veeraraghavan on 8/13/2015
       */

     /* typedef unsigned long uint64; */
     typedef uint64_t uint64;
#elif defined(ULLONG_MAX)
#  define HAVE_UINT64
   MLIB_BITS_EXTENSION typedef unsigned long long uint64;
#endif

#ifdef DEBUG64
#  undef HAVE_UINT64
#endif

#ifdef HAVE_UINT64
  typedef struct { uint64 i; } kludge64;
#else
  typedef struct { uint32 hi, lo; } kludge64;
#endif

/* --- Decide on a 24-bit type --- */

#if UINT_MAX >= 0x00ffffffu
  typedef unsigned int uint24;
#else
  typedef unsigned long uint24;
#endif

/* --- Decide on 16-bit and 8-bit types --- *
 *
 * This is more for brevity than anything else.
 */

typedef unsigned short uint16;
typedef unsigned char octet, uint8;

/* --- WARNING! --- *
 *
 * Never lose sight of the fact that the above types may be wider than the
 * names suggest.  Some architectures have 32-bit @short@s for example.
 */

/*----- Macros ------------------------------------------------------------*/

/* --- Useful masks --- */

#define MASK8 0xffu
#define MASK16 0xffffu
#define MASK16_L MASK16
#define MASK16_B MASK16
#define MASK24 0xffffffu
#define MASK24_L MASK24
#define MASK24_B MASK24
#define MASK32 0xffffffffu
#define MASK32_L MASK32
#define MASK32_B MASK32

#ifdef HAVE_UINT64
#  define MASK64 MLIB_BITS_EXTENSION 0xffffffffffffffffu
#  define MASK64_L MASK64
#  define MASK64_B MASK64
#endif

/* --- Sizes --- */

#define SZ_8 1
#define SZ_16 2
#define SZ_16_L 2
#define SZ_16_B 2
#define SZ_24 3
#define SZ_24_L 3
#define SZ_24_B 3
#define SZ_32 4
#define SZ_32_L 4
#define SZ_32_B 4

#ifdef HAVE_UINT64
#  define SZ_64 8
#  define SZ_64_L 8
#  define SZ_64_B 8
#endif

/* --- Type aliases --- */

#define TY_U8 octet
#define TY_U16 uint16
#define TY_U16_L uint16
#define TY_U16_B uint16
#define TY_U24 uint24
#define TY_U24_L uint24
#define TY_U24_B uint24
#define TY_U32 uint32
#define TY_U32_L uint32
#define TY_U32_B uint32

#ifdef HAVE_UINT64
#  define TY_U64 uint64
#  define TY_U64_L uint64
#  define TY_U64_B uint64
#endif

/* --- List macros --- */

#ifdef HAVE_UINT64
#  define  DOUINTCONV(_)						\
     _(8, 8, 8)								\
     _(16, 16, 16) _(16, 16_L, 16l) _(16, 16_B, 16b)			\
     _(24, 24, 24) _(24, 24_L, 24l) _(24, 24_B, 24b)			\
     _(32, 32, 32) _(32, 32_L, 32l) _(32, 32_B, 32b)			\
     _(64, 64, 64) _(64, 64_L, 64l) _(64, 64_B, 64b)
#  define DOUINTSZ(_) _(8) _(16) _(24) _(32) _(64)
#else
#  define  DOUINTCONV(_)						\
     _(8, 8, 8)								\
     _(16, 16, 16) _(16, 16_L, 16l) _(16, 16_B, 16b)			\
     _(24, 24, 24) _(24, 24_L, 24l) _(24, 24_B, 24b)			\
     _(32, 32, 32) _(32, 32_L, 32l) _(32, 32_B, 32b)
#  define DOUINTSZ(_) _(8) _(16) _(24) _(32)
#endif

/* --- Type coercions --- */

#define U8(x) ((octet)((x) & MASK8))
#define U16(x) ((uint16)((x) & MASK16))
#define U24(x) ((uint24)((x) & MASK24))
#define U32(x) ((uint32)((x) & MASK32))

#ifdef HAVE_UINT64
#  define U64(x) ((uint64)(x) & MASK64)
#  define U64_(d, x) ((d).i = U64(x).i)
#else
#  define U64_(d, x) ((d).hi = U32((x).hi), (d).lo = U32((x).lo))
#endif

/* --- Safe shifting macros --- */

#define LSL8(v, s) U8(U8(v) << ((s) & 7u))
#define LSR8(v, s) U8(U8(v) >> ((s) & 7u))
#define LSL16(v, s) U16(U16(v) << ((s) & 15u))
#define LSR16(v, s) U16(U16(v) >> ((s) & 15u))
#define LSL24(v, s) U24(U24(v) << ((s) % 24u))
#define LSR24(v, s) U24(U24(v) >> ((s) % 24u))
#define LSL32(v, s) U32(U32(v) << ((s) & 31u))
#define LSR32(v, s) U32(U32(v) >> ((s) & 31u))

#ifdef HAVE_UINT64
#  define LSL64(v, s) U64(U64(v) << ((s) & 63u))
#  define LSR64(v, s) U64(U64(v) >> ((s) & 63u))
#  define LSL64_(d, v, s) ((d).i = LSL64((v).i, (s)))
#  define LSR64_(d, v, s) ((d).i = LSR64((v).i, (s)))
#else
#  define LSL64_(d, v, s) do {						\
     unsigned _s = (s) & 63u;						\
     uint32 _l = (v).lo, _h = (v).hi;					\
     kludge64 *_d = &(d);						\
     if (_s >= 32) {							\
       _d->hi = LSL32(_l, _s - 32u);					\
       _d->lo = 0;							\
     } else if (!_s) {							\
       _d->lo = _l;							\
       _d->hi = _h;							\
     } else {								\
       _d->hi = LSL32(_h, _s) | LSR32(_l, 32u - _s);			\
       _d->lo = LSL32(_l, _s);						\
     }									\
   } while (0)
#  define LSR64_(d, v, s) do {						\
     unsigned _s = (s) & 63u;						\
     uint32 _l = (v).lo, _h = (v).hi;					\
     kludge64 *_d = &(d);						\
     if (_s >= 32) {							\
       _d->lo = LSR32(_h, _s - 32u);					\
       _d->hi = 0;							\
     } else if (!_s) {							\
       _d->lo = _l;							\
       _d->hi = _h;							\
     } else {								\
       _d->lo = LSR32(_l, _s) | LSL32(_h, 32u - _s);			\
       _d->hi = LSR32(_h, _s);						\
     }									\
   } while (0)
#endif

/* --- Rotation macros --- */

#define ROL8(v, s) (LSL8((v), (s)) | (LSR8((v), 8u - (s))))
#define ROR8(v, s) (LSR8((v), (s)) | (LSL8((v), 8u - (s))))
#define ROL16(v, s) (LSL16((v), (s)) | (LSR16((v), 16u - (s))))
#define ROR16(v, s) (LSR16((v), (s)) | (LSL16((v), 16u - (s))))
#define ROL24(v, s) (LSL24((v), (s)) | (LSR24((v), 24u - (s))))
#define ROR24(v, s) (LSR24((v), (s)) | (LSL24((v), 24u - (s))))
#define ROL32(v, s) (LSL32((v), (s)) | (LSR32((v), 32u - (s))))
#define ROR32(v, s) (LSR32((v), (s)) | (LSL32((v), 32u - (s))))

#ifdef HAVE_UINT64
#  define ROL64(v, s) (LSL64((v), (s)) | (LSR64((v), 64u - (s))))
#  define ROR64(v, s) (LSR64((v), (s)) | (LSL64((v), 64u - (s))))
#  define ROL64_(d, v, s) ((d).i = ROL64((v).i, (s)))
#  define ROR64_(d, v, s) ((d).i = ROR64((v).i, (s)))
#else
#  define ROL64_(d, v, s) do {						\
     unsigned _s = (s) & 63u;						\
     uint32 _l = (v).lo, _h = (v).hi;					\
     kludge64 *_d = &(d);						\
     if (_s > 32) {							\
       _d->hi = LSL32(_l, _s - 32u) | LSR32(_h, 64u - _s);		\
       _d->lo = LSL32(_h, _s - 32u) | LSR32(_l, 64u - _s);		\
     } else if (!_s) {							\
       _d->lo = _l;							\
       _d->hi = _h;							\
     } else if (_s == 32) {						\
       _d->lo = _h;							\
       _d->hi = _l;							\
     } else {								\
       _d->hi = LSL32(_h, _s) | LSR32(_l, 32u - _s);			\
       _d->lo = LSL32(_l, _s) | LSR32(_h, 32u - _s);			\
     }									\
   } while (0)
#  define ROR64_(d, v, s) do {						\
     unsigned _s = (s) & 63u;						\
     uint32 _l = (v).lo, _h = (v).hi;					\
     kludge64 *_d = &(d);						\
     if (_s > 32) {							\
       _d->hi = LSR32(_l, _s - 32u) | LSL32(_h, 64u - _s);		\
       _d->lo = LSR32(_h, _s - 32u) | LSL32(_l, 64u - _s);		\
     } else if (!_s) {							\
       _d->lo = _l;							\
       _d->hi = _h;							\
     } else if (_s == 32) {						\
       _d->lo = _h;							\
       _d->hi = _l;							\
     } else {								\
       _d->hi = LSR32(_h, _s) | LSL32(_l, 32u - _s);			\
       _d->lo = LSR32(_l, _s) | LSL32(_h, 32u - _s);			\
     }									\
   } while (0)
#endif

/* --- Storage and retrieval --- */

#define GETBYTE(p, o) (((octet *)(p))[o] & MASK8)
#define PUTBYTE(p, o, v) (((octet *)(p))[o] = U8((v)))

#define LOAD8(p) (GETBYTE((p), 0))
#define STORE8(p, v) (PUTBYTE((p), 0, (v)))

#define LOAD16_B(p)							\
  (((uint16)GETBYTE((p), 0) << 8) |					\
   ((uint16)GETBYTE((p), 1) << 0))
#define LOAD16_L(p)							\
  (((uint16)GETBYTE((p), 0) << 0) |					\
   ((uint16)GETBYTE((p), 1) << 8))
#define LOAD16(p) LOAD16_B((p))

#define STORE16_B(p, v)							\
  (PUTBYTE((p), 0, (uint16)(v) >> 8),					\
   PUTBYTE((p), 1, (uint16)(v) >> 0))
#define STORE16_L(p, v)							\
  (PUTBYTE((p), 0, (uint16)(v) >> 0),					\
   PUTBYTE((p), 1, (uint16)(v) >> 8))
#define STORE16(p, v) STORE16_B((p), (v))

#define LOAD24_B(p)							\
  (((uint24)GETBYTE((p), 0) << 16) |					\
   ((uint24)GETBYTE((p), 1) <<	8) |					\
   ((uint24)GETBYTE((p), 2) <<	0))
#define LOAD24_L(p)							\
  (((uint24)GETBYTE((p), 0) <<	0) |					\
   ((uint24)GETBYTE((p), 1) <<	8) |					\
   ((uint24)GETBYTE((p), 2) << 16))
#define LOAD24(p) LOAD24_B((p))

#define STORE24_B(p, v)							\
  (PUTBYTE((p), 0, (uint24)(v) >> 16),					\
   PUTBYTE((p), 1, (uint24)(v) >>  8),					\
   PUTBYTE((p), 2, (uint24)(v) >>  0))
#define STORE24_L(p, v)							\
  (PUTBYTE((p), 0, (uint24)(v) >>  0),					\
   PUTBYTE((p), 1, (uint24)(v) >>  8),					\
   PUTBYTE((p), 2, (uint24)(v) >> 16))
#define STORE24(p, v) STORE24_B((p), (v))

#define LOAD32_B(p)							\
  (((uint32)GETBYTE((p), 0) << 24) |					\
   ((uint32)GETBYTE((p), 1) << 16) |					\
   ((uint32)GETBYTE((p), 2) <<	8) |					\
   ((uint32)GETBYTE((p), 3) <<	0))
#define LOAD32_L(p)							\
  (((uint32)GETBYTE((p), 0) <<	0) |					\
   ((uint32)GETBYTE((p), 1) <<	8) |					\
   ((uint32)GETBYTE((p), 2) << 16) |					\
   ((uint32)GETBYTE((p), 3) << 24))
#define LOAD32(p) LOAD32_B((p))

#define STORE32_B(p, v)							\
  (PUTBYTE((p), 0, (uint32)(v) >> 24),					\
   PUTBYTE((p), 1, (uint32)(v) >> 16),					\
   PUTBYTE((p), 2, (uint32)(v) >>  8),					\
   PUTBYTE((p), 3, (uint32)(v) >>  0))
#define STORE32_L(p, v)							\
  (PUTBYTE((p), 0, (uint32)(v) >>  0),					\
   PUTBYTE((p), 1, (uint32)(v) >>  8),					\
   PUTBYTE((p), 2, (uint32)(v) >> 16),					\
   PUTBYTE((p), 3, (uint32)(v) >> 24))
#define STORE32(p, v) STORE32_B((p), (v))

#ifdef HAVE_UINT64

#  define LOAD64_B(p)							\
    (((uint64)GETBYTE((p), 0) << 56) |					\
     ((uint64)GETBYTE((p), 1) << 48) |					\
     ((uint64)GETBYTE((p), 2) << 40) |					\
     ((uint64)GETBYTE((p), 3) << 32) |					\
     ((uint64)GETBYTE((p), 4) << 24) |					\
     ((uint64)GETBYTE((p), 5) << 16) |					\
     ((uint64)GETBYTE((p), 6) <<  8) |					\
     ((uint64)GETBYTE((p), 7) <<  0))
#  define LOAD64_L(p)							\
    (((uint64)GETBYTE((p), 0) <<  0) |					\
     ((uint64)GETBYTE((p), 1) <<  8) |					\
     ((uint64)GETBYTE((p), 2) << 16) |					\
     ((uint64)GETBYTE((p), 3) << 24) |					\
     ((uint64)GETBYTE((p), 4) << 32) |					\
     ((uint64)GETBYTE((p), 5) << 40) |					\
     ((uint64)GETBYTE((p), 6) << 48) |					\
     ((uint64)GETBYTE((p), 7) << 56))
#  define LOAD64(p) LOAD64_B((p))
#  define LOAD64_B_(d, p) ((d).i = LOAD64_B((p)))
#  define LOAD64_L_(d, p) ((d).i = LOAD64_L((p)))
#  define LOAD64_(d, p) LOAD64_B_((d), (p))

#  define STORE64_B(p, v)						\
    (PUTBYTE((p), 0, (uint64)(v) >> 56),				\
     PUTBYTE((p), 1, (uint64)(v) >> 48),				\
     PUTBYTE((p), 2, (uint64)(v) >> 40),				\
     PUTBYTE((p), 3, (uint64)(v) >> 32),				\
     PUTBYTE((p), 4, (uint64)(v) >> 24),				\
     PUTBYTE((p), 5, (uint64)(v) >> 16),				\
     PUTBYTE((p), 6, (uint64)(v) >>  8),				\
     PUTBYTE((p), 7, (uint64)(v) >>  0))
#  define STORE64_L(p, v)						\
    (PUTBYTE((p), 0, (uint64)(v) >>  0),				\
     PUTBYTE((p), 1, (uint64)(v) >>  8),				\
     PUTBYTE((p), 2, (uint64)(v) >> 16),				\
     PUTBYTE((p), 3, (uint64)(v) >> 24),				\
     PUTBYTE((p), 4, (uint64)(v) >> 32),				\
     PUTBYTE((p), 5, (uint64)(v) >> 40),				\
     PUTBYTE((p), 6, (uint64)(v) >> 48),				\
     PUTBYTE((p), 7, (uint64)(v) >> 56))
#  define STORE64(p, v) STORE64_B((p), (v))
#  define STORE64_B_(p, v) STORE64_B((p), (v).i)
#  define STORE64_L_(p, v) STORE64_L((p), (v).i)
#  define STORE64_(p, v) STORE64_B_((p), (v))

#else

#  define LOAD64_B_(d, p)						\
    ((d).hi = LOAD32_B((octet *)(p) + 0),				\
     (d).lo = LOAD32_B((octet *)(p) + 4))
#  define LOAD64_L_(d, p)						\
    ((d).lo = LOAD32_L((octet *)(p) + 0),				\
     (d).hi = LOAD32_L((octet *)(p) + 4))
#  define LOAD64_(d, p) LOAD64_B_((d), (p))

#  define STORE64_B_(p, v)						\
    (STORE32_B((octet *)(p) + 0, (v).hi),				\
     STORE32_B((octet *)(p) + 4, (v).lo))
#  define STORE64_L_(p, v)						\
    (STORE32_L((octet *)(p) + 0, (v).lo),				\
     STORE32_L((octet *)(p) + 4, (v).hi))
#  define STORE64_(p, v) STORE64_B_((p), (v))

#endif

/* --- Other operations on 64-bit integers --- */

#ifdef HAVE_UINT64
#  define SET64(d, h, l) ((d).i = (U64((h)) << 32) | U64((l)))
#  define ASSIGN64(d, x) ((d).i = U64((x)))
#  define HI64(x) U32((x).i >> 32)
#  define LO64(x) U32((x).i)
#  define GET64(t, x) ((t)(x).i)
#else
#  define SET64(d, h, l) ((d).hi = U32(h), (d).lo = U32(l))
#  define ASSIGN64(d, x)						\
    ((d).hi = ((x & ~MASK32) >> 16) >> 16, (d).lo = U32(x))
#  define HI64(x) U32((x).hi)
#  define LO64(x) U32((x).lo)
#  define GET64(t, x) (((((t)HI64(x) << 16) << 16) & ~MASK32) | (t)LO64(x))
#endif

#ifdef HAVE_UINT64
#  define AND64(d, x, y) ((d).i = (x).i & (y).i)
#  define OR64(d, x, y) ((d).i = (x).i | (y).i)
#  define XOR64(d, x, y) ((d).i = (x).i ^ (y).i)
#  define CPL64(d, x) ((d).i = ~(x).i)
#  define ADD64(d, x, y) ((d).i = (x).i + (y).i)
#  define SUB64(d, x, y) ((d).i = (x).i - (y).i)
#  define CMP64(x, op, y) ((x).i op (y).i)
#  define ZERO64(x) ((x) == 0)
#else
#  define AND64(d, x, y) ((d).lo = (x).lo & (y).lo, (d).hi = (x).hi & (y).hi)
#  define OR64(d, x, y) ((d).lo = (x).lo | (y).lo, (d).hi = (x).hi | (y).hi)
#  define XOR64(d, x, y) ((d).lo = (x).lo ^ (y).lo, (d).hi = (x).hi ^ (y).hi)
#  define CPL64(d, x) ((d).lo = ~(x).lo, (d).hi = ~(x).hi)
#  define ADD64(d, x, y) do {						\
     uint32 _x = U32((x).lo + (y).lo);					\
     (d).hi = (x).hi + (y).hi + (_x < (x).lo);				\
     (d).lo = _x;							\
   } while (0)
#  define SUB64(d, x, y) do {						\
     uint32 _x = U32((x).lo - (y).lo);					\
     (d).hi = (x).hi - (y).hi - (_x > (x).lo);				\
     (d).lo = _x;							\
   } while (0)
#  define CMP64(x, op, y)						\
    ((x).hi == (y).hi ? (x).lo op (y).lo : (x).hi op (y).hi)
#  define ZERO64(x) ((x).lo == 0 && (x).hi == 0)
#endif

/* --- Storing integers in tables --- */

#ifdef HAVE_UINT64
#  define X64(x, y) { 0x##x##y }
#else
#  define X64(x, y) { 0x##x, 0x##y }
#endif

/*----- That's all, folks -------------------------------------------------*/

#ifdef __cplusplus
  }
#endif

#endif
