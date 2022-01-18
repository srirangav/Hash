#ifndef __groestl_opt_h
#define __groestl_opt_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "brg_endian.h"
#define NEED_UINT_64T
//#include "brg_types.h"

#define u8 unsigned char
#define u32 unsigned int
#define u64 unsigned long long

/* some sizes (number of bytes) */
#define ROWS 8
#define LENGTHFIELDLEN ROWS
#define COLS512 8
#define COLS1024 16
#define SIZE512 (ROWS*COLS512)
#define SIZE1024 (ROWS*COLS1024)

#define ROUNDS512 10
#define ROUNDS1024 14

#define ROTL64(a,n) ((((a)<<(n))|((a)>>(64-(n))))&(0xffffffffffffffffULL))

#if (PLATFORM_BYTE_ORDER == IS_BIG_ENDIAN)
#define EXT_BYTE(var,n) ((u8)((u64)(var) >> (8*(7-(n)))))
#define U64BIG(a) (a)
#endif /* IS_BIG_ENDIAN */

#if (PLATFORM_BYTE_ORDER == IS_LITTLE_ENDIAN)
#define EXT_BYTE(var,n) ((u8)((u64)(var) >> (8*n)))
#define U64BIG(a) \
  ((ROTL64(a, 8) & (0x000000FF000000FFULL)) | \
   (ROTL64(a,24) & (0x0000FF000000FF00ULL)) | \
   (ROTL64(a,40) & (0x00FF000000FF0000ULL)) | \
   (ROTL64(a,56) & (0xFF000000FF000000ULL)))
#endif /* IS_LITTLE_ENDIAN */

enum { LONG = SIZE1024, SHORT = SIZE512 };

/* srv 2020-11-27 - modify the NIST API to avoid name collisions */
#ifndef NIST_API
/* NIST API begin */
typedef unsigned char groestl_BitSequence;
typedef unsigned long long groestl_DataLength;
typedef enum { groestl_SUCCESS = 0,
               groestl_FAIL = 1,
               groestl_BAD_HASHLEN = 2 } groestl_HashReturn;
typedef struct {
  u64 *chaining __attribute__((aligned(16)));            /* actual state */
  groestl_BitSequence *buffer;      /* data buffer */
  u64 block_counter;        /* message block counter */
  int buf_ptr;              /* data buffer pointer */
  int bits_in_last_byte;    /* no. of message bits in last byte of
			       data buffer */
  int hashbitlen;           /* output length in bits */
  int size;                 /* LONG or SHORT */
} groestl_HashState;

groestl_HashReturn groestl_Init(groestl_HashState*, int);
groestl_HashReturn groestl_Update(groestl_HashState*,
                                  const groestl_BitSequence*,
                                  groestl_DataLength);
groestl_HashReturn groestl_Final(groestl_HashState*,
                                 groestl_BitSequence*);
groestl_HashReturn groestl_Hash(int,
                                const groestl_BitSequence*,
                                groestl_DataLength,
                                groestl_BitSequence*);
/* NIST API end   */

/* helper functions */
void PrintHash(const groestl_BitSequence*, int);
#else /* NIST_API */
/* NIST API begin */
typedef unsigned char BitSequence;
typedef unsigned long long DataLength;
typedef enum { SUCCESS = 0, FAIL = 1, BAD_HASHLEN = 2 } HashReturn;
typedef struct {
  u64 *chaining __attribute__((aligned(16)));            /* actual state */
  BitSequence *buffer;      /* data buffer */
  u64 block_counter;        /* message block counter */
  int buf_ptr;              /* data buffer pointer */
  int bits_in_last_byte;    /* no. of message bits in last byte of
                   data buffer */
  int hashbitlen;           /* output length in bits */
  int size;                 /* LONG or SHORT */
} hashState;

HashReturn Init(hashState*, int);
HashReturn Update(hashState*, const BitSequence*, DataLength);
HashReturn Final(hashState*, BitSequence*);
HashReturn Hash(int, const BitSequence*, DataLength, BitSequence*);
/* NIST API end   */

/* helper functions */
void PrintHash(const BitSequence*, int);
#endif /* NIST_API */

#endif /* __groestl_opt_h */
