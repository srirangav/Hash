#ifndef __groestl_mmx_h
#define __groestl_mmx_h

#include <stdio.h>
#include <stdlib.h>
#include "brg_endian.h"
#define NEED_UINT_64T
#include "brg_types.h"

/* some sizes (number of bytes) */
#define ROWS 8
#define LENGTHFIELDLEN ROWS
#define COLS512 8
#define COLS1024 16
#define SIZE512 (ROWS*COLS512)
#define SIZE1024 (ROWS*COLS1024)

#define ROUNDS512 10
#define ROUNDS1024 14

/* move to groestl-mmx.c - SRV 08/09/2019 */
/* #define ROTL32(a,n) ((((a)<<(n))|((a)>>(32-(n))))&li_32(ffffffff)) */

#if (PLATFORM_BYTE_ORDER == IS_BIG_ENDIAN)
#define EXT_BYTE(var,n) ((u8)((u64)(var) >> (8*(7-(n)))))
#define U32BIG(a) (a)
#endif /* IS_BIG_ENDIAN */

#if (PLATFORM_BYTE_ORDER == IS_LITTLE_ENDIAN)
#define EXT_BYTE(var,n) ((u8)((u64)(var) >> (8*n)))
#define U32BIG(a) \
  ((ROTL32(a, 8) & li_32(00FF00FF)) |		\
   (ROTL32(a,24) & li_32(FF00FF00)))
#endif /* IS_LITTLE_ENDIAN */

/* add groestl_ prefix to avoid name collision - SRV 08/09/2019 */

/* NIST API begin */
typedef unsigned char groestl_BitSequence;
typedef unsigned long long groestl_DataLength;
typedef enum
{
    groestl_SUCCESS = 0,
    groestl_FAIL = 1,
    groestl_BAD_HASHLEN = 2
} groestl_HashReturn;

typedef struct {
  u32 *chaining;            /* actual state */
  u64 block_counter;        /* message block counter */
  int hashbitlen;           /* output length in bits */
  groestl_BitSequence *buffer;      /* data buffer */
  int buf_ptr;              /* data buffer pointer */
  int bits_in_last_byte;    /* no. of message bits in last byte of
			       data buffer */
  int columns;              /* no. of columns in state */
  int statesize;            /* total no. of bytes in state */

/* change to hashState to groestl_hashState to avoid collisions -
   SRV 08/09/2019 */
} groestl_hashState;

groestl_HashReturn groestl_Init(groestl_hashState*, int);
groestl_HashReturn groestl_Update(groestl_hashState*,
                                  const groestl_BitSequence*,
                                  groestl_DataLength);
groestl_HashReturn groestl_Final(groestl_hashState*, groestl_BitSequence*);

/* message hashing not required, disable it - SRV 08/09/2019 */

#ifdef groestl_HASH

HashReturn Hash(int, const BitSequence*, DataLength, BitSequence*);
/* NIST API end   */

/* helper functions */
void PrintHash(const BitSequence*, int);

#endif /* groestl_HASH */

#endif /* __groestl_mmx_h */
