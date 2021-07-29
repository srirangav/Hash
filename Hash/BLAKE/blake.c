/*
 BLAKE reference C implementation
 
 Copyright (c) 2012 Jean-Philippe Aumasson <jeanphilippe.aumasson@gmail.com>
 
 To the extent possible under law, the author(s) have dedicated all copyright
 and related and neighboring rights to this software to the public domain
 worldwide. This software is distributed without any warranty.
 
 You should have received a copy of the CC0 Public Domain Dedication along with
 this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

#include "blake.h"

/* use support header to eliminate duplicate symbols  - SRV 08/09/2019 */

#include "blake_support.h"

#define ROT(x,n) (((x)<<(32-n))|( (x)>>(n)))
#define G(a,b,c,d,e)          \
v[a] += (m[sigma[i][e]] ^ u256[sigma[i][e+1]]) + v[b]; \
v[d] = ROT( v[d] ^ v[a],16);        \
v[c] += v[d];           \
v[b] = ROT( v[b] ^ v[c],12);        \
v[a] += (m[sigma[i][e+1]] ^ u256[sigma[i][e]])+v[b]; \
v[d] = ROT( v[d] ^ v[a], 8);        \
v[c] += v[d];           \
v[b] = ROT( v[b] ^ v[c], 7);

/* rename ROT and G for BLAKE 384, 512 as ROT64 and G64 so all BLAKE
   can be in one file - SRV 08/09/2019 */

#define ROT64(x,n) (((x)<<(64-n))|( (x)>>(n)))
#define G64(a,b,c,d,e)          \
v[a] += (m[sigma[i][e]] ^ u512[sigma[i][e+1]]) + v[b];\
v[d] = ROT64( v[d] ^ v[a],32);        \
v[c] += v[d];           \
v[b] = ROT64( v[b] ^ v[c],25);        \
v[a] += (m[sigma[i][e+1]] ^ u512[sigma[i][e]])+v[b];  \
v[d] = ROT64( v[d] ^ v[a],16);        \
v[c] += v[d];           \
v[b] = ROT64( v[b] ^ v[c],11);

/* from blake224.c */

/* 2021-07-27 srv - make internal function static */

static void blake224_compress( state224 *S, const uint8_t *block )
{
    uint32_t v[16], m[16], i;
    
    for( i = 0; i < 16; ++i )  m[i] = U8TO32_BIG( block + i * 4 );
    
    for( i = 0; i < 8; ++i )  v[i] = S->h[i];
    
    v[ 8] = S->s[0] ^ u256[0];
    v[ 9] = S->s[1] ^ u256[1];
    v[10] = S->s[2] ^ u256[2];
    v[11] = S->s[3] ^ u256[3];
    v[12] = u256[4];
    v[13] = u256[5];
    v[14] = u256[6];
    v[15] = u256[7];
    
    /* don't xor t when the block is only padding */
    if ( !S->nullt )
    {
        v[12] ^= S->t[0];
        v[13] ^= S->t[0];
        v[14] ^= S->t[1];
        v[15] ^= S->t[1];
    }
    
    for( i = 0; i < 14; ++i )
    {
        /* column step */
        G( 0,  4,  8, 12,  0 );
        G( 1,  5,  9, 13,  2 );
        G( 2,  6, 10, 14,  4 );
        G( 3,  7, 11, 15,  6 );
        /* diagonal step */
        G( 0,  5, 10, 15,  8 );
        G( 1,  6, 11, 12, 10 );
        G( 2,  7,  8, 13, 12 );
        G( 3,  4,  9, 14, 14 );
    }
    
    for( i = 0; i < 16; ++i )  S->h[i % 8] ^= v[i];
    
    for( i = 0; i < 8 ; ++i )  S->h[i] ^= S->s[i % 4];
}

void blake224_init( state224 *S )
{
    S->h[0] = 0xc1059ed8;
    S->h[1] = 0x367cd507;
    S->h[2] = 0x3070dd17;
    S->h[3] = 0xf70e5939;
    S->h[4] = 0xffc00b31;
    S->h[5] = 0x68581511;
    S->h[6] = 0x64f98fa7;
    S->h[7] = 0xbefa4fa4;
    S->t[0] = S->t[1] = S->buflen = S->nullt = 0;
    S->s[0] = S->s[1] = S->s[2] = S->s[3] = 0;
}

void blake224_update( state224 *S, const uint8_t *in, uint64_t inlen )
{
    int left = S->buflen;
    int fill = 64 - left;
    
    /* data left and data received fill a block  */
    if( left && ( inlen >= fill ) )
    {
        memcpy( ( void * ) ( S->buf + left ), ( void * ) in, fill );
        S->t[0] += 512;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake224_compress( S, S->buf );
        in += fill;
        inlen  -= fill;
        left = 0;
    }
    
    /* compress blocks of data received */
    while( inlen >= 64 )
    {
        S->t[0] += 512;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake224_compress( S, in );
        in += 64;
        inlen -= 64;
    }
    
    /* store any data left */
    if( inlen > 0 )
    {
        memcpy( ( void * ) ( S->buf + left ), \
               ( void * ) in, ( size_t ) inlen );
        S->buflen = left + ( int )inlen;
    }
    else S->buflen = 0;
}

void blake224_final( state224 *S, uint8_t *out )
{
    uint8_t msglen[8], zz = 0x00, oz = 0x80;
    uint32_t lo = S->t[0] + ( S->buflen << 3 ), hi = S->t[1];
    
    /* support for hashing more than 2^32 bits */
    if ( lo < ( S->buflen << 3 ) ) hi++;
    
    U32TO8_BIG(  msglen + 0, hi );
    U32TO8_BIG(  msglen + 4, lo );
    
    if ( S->buflen == 55 )   /* one padding byte */
    {
        S->t[0] -= 8;
        blake224_update( S, &oz, 1 );
    }
    else
    {
        if ( S->buflen < 55 )   /* enough space to fill the block  */
        {
            if ( !S->buflen ) S->nullt = 1;
            
            S->t[0] -= 440 - ( S->buflen << 3 );
            blake224_update( S, padding, 55 - S->buflen );
        }
        else   /* need 2 compressions */
        {
            S->t[0] -= 512 - ( S->buflen << 3 );
            blake224_update( S, padding, 64 - S->buflen );
            S->t[0] -= 440;
            blake224_update( S, padding + 1, 55 );
            S->nullt = 1;
        }
        
        blake224_update( S, &zz, 1 );
        S->t[0] -= 8;
    }
    
    S->t[0] -= 64;
    blake224_update( S, msglen, 8 );
    U32TO8_BIG( out + 0, S->h[0] );
    U32TO8_BIG( out + 4, S->h[1] );
    U32TO8_BIG( out + 8, S->h[2] );
    U32TO8_BIG( out + 12, S->h[3] );
    U32TO8_BIG( out + 16, S->h[4] );
    U32TO8_BIG( out + 20, S->h[5] );
    U32TO8_BIG( out + 24, S->h[6] );
}

/* from blake256.c */

/* 2021-07-27 srv - make internal function static */

static void blake256_compress( state256 *S, const uint8_t *block )
{
    uint32_t v[16], m[16], i;

    for( i = 0; i < 16; ++i )  m[i] = U8TO32_BIG( block + i * 4 );
    
    for( i = 0; i < 8; ++i )  v[i] = S->h[i];
    
    v[ 8] = S->s[0] ^ u256[0];
    v[ 9] = S->s[1] ^ u256[1];
    v[10] = S->s[2] ^ u256[2];
    v[11] = S->s[3] ^ u256[3];
    v[12] = u256[4];
    v[13] = u256[5];
    v[14] = u256[6];
    v[15] = u256[7];
    
    /* don't xor t when the block is only padding */
    if ( !S->nullt )
    {
        v[12] ^= S->t[0];
        v[13] ^= S->t[0];
        v[14] ^= S->t[1];
        v[15] ^= S->t[1];
    }
    
    for( i = 0; i < 14; ++i )
    {
        /* column step */
        G( 0,  4,  8, 12,  0 );
        G( 1,  5,  9, 13,  2 );
        G( 2,  6, 10, 14,  4 );
        G( 3,  7, 11, 15,  6 );
        /* diagonal step */
        G( 0,  5, 10, 15,  8 );
        G( 1,  6, 11, 12, 10 );
        G( 2,  7,  8, 13, 12 );
        G( 3,  4,  9, 14, 14 );
    }
    
    for( i = 0; i < 16; ++i )  S->h[i % 8] ^= v[i];
    
    for( i = 0; i < 8 ; ++i )  S->h[i] ^= S->s[i % 4];
}

void blake256_init( state256 *S )
{
    S->h[0] = 0x6a09e667;
    S->h[1] = 0xbb67ae85;
    S->h[2] = 0x3c6ef372;
    S->h[3] = 0xa54ff53a;
    S->h[4] = 0x510e527f;
    S->h[5] = 0x9b05688c;
    S->h[6] = 0x1f83d9ab;
    S->h[7] = 0x5be0cd19;
    S->t[0] = S->t[1] = S->buflen = S->nullt = 0;
    S->s[0] = S->s[1] = S->s[2] = S->s[3] = 0;
}

void blake256_update( state256 *S, const uint8_t *in, uint64_t inlen )
{
    int left = S->buflen;
    int fill = 64 - left;
    
    /* data left and data received fill a block  */
    if( left && ( inlen >= fill ) )
    {
        memcpy( ( void * ) ( S->buf + left ), ( void * ) in, fill );
        S->t[0] += 512;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake256_compress( S, S->buf );
        in += fill;
        inlen  -= fill;
        left = 0;
    }
    
    /* compress blocks of data received */
    while( inlen >= 64 )
    {
        S->t[0] += 512;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake256_compress( S, in );
        in += 64;
        inlen -= 64;
    }
    
    /* store any data left */
    if( inlen > 0 )
    {
        memcpy( ( void * ) ( S->buf + left ),   \
               ( void * ) in, ( size_t ) inlen );
        S->buflen = left + ( int )inlen;
    }
    else S->buflen = 0;
}

void blake256_final( state256 *S, uint8_t *out )
{
    uint8_t msglen[8], zo = 0x01, oo = 0x81;
    uint32_t lo = S->t[0] + ( S->buflen << 3 ), hi = S->t[1];
    
    /* support for hashing more than 2^32 bits */
    if ( lo < ( S->buflen << 3 ) ) hi++;
    
    U32TO8_BIG(  msglen + 0, hi );
    U32TO8_BIG(  msglen + 4, lo );
    
    if ( S->buflen == 55 )   /* one padding byte */
    {
        S->t[0] -= 8;
        blake256_update( S, &oo, 1 );
    }
    else
    {
        if ( S->buflen < 55 )   /* enough space to fill the block  */
        {
            if ( !S->buflen ) S->nullt = 1;
            
            S->t[0] -= 440 - ( S->buflen << 3 );
            blake256_update( S, padding, 55 - S->buflen );
        }
        else   /* need 2 compressions */
        {
            S->t[0] -= 512 - ( S->buflen << 3 );
            blake256_update( S, padding, 64 - S->buflen );
            S->t[0] -= 440;
            blake256_update( S, padding + 1, 55 );
            S->nullt = 1;
        }
        
        blake256_update( S, &zo, 1 );
        S->t[0] -= 8;
    }
    
    S->t[0] -= 64;
    blake256_update( S, msglen, 8 );
    U32TO8_BIG( out + 0, S->h[0] );
    U32TO8_BIG( out + 4, S->h[1] );
    U32TO8_BIG( out + 8, S->h[2] );
    U32TO8_BIG( out + 12, S->h[3] );
    U32TO8_BIG( out + 16, S->h[4] );
    U32TO8_BIG( out + 20, S->h[5] );
    U32TO8_BIG( out + 24, S->h[6] );
    U32TO8_BIG( out + 28, S->h[7] );
}

/* from blake384.c */

/* 2021-07-27 srv - make internal function static */

static void blake384_compress( state384 *S, const uint8_t *block )
{
    uint64_t v[16], m[16], i;

    for( i = 0; i < 16; ++i )  m[i] = U8TO64_BIG( block + i * 8 );
    
    for( i = 0; i < 8; ++i )  v[i] = S->h[i];
    
    v[ 8] = S->s[0] ^ u512[0];
    v[ 9] = S->s[1] ^ u512[1];
    v[10] = S->s[2] ^ u512[2];
    v[11] = S->s[3] ^ u512[3];
    v[12] =  u512[4];
    v[13] =  u512[5];
    v[14] =  u512[6];
    v[15] =  u512[7];
    
    /* don't xor t when the block is only padding */
    if ( !S->nullt )
    {
        v[12] ^= S->t[0];
        v[13] ^= S->t[0];
        v[14] ^= S->t[1];
        v[15] ^= S->t[1];
    }
    
    for( i = 0; i < 16; ++i )
    {
        /* column step */
        G64( 0, 4, 8, 12, 0 );
        G64( 1, 5, 9, 13, 2 );
        G64( 2, 6, 10, 14, 4 );
        G64( 3, 7, 11, 15, 6 );
        /* diagonal step */
        G64( 0, 5, 10, 15, 8 );
        G64( 1, 6, 11, 12, 10 );
        G64( 2, 7, 8, 13, 12 );
        G64( 3, 4, 9, 14, 14 );
    }
    
    for( i = 0; i < 16; ++i )  S->h[i % 8] ^= v[i];
    
    for( i = 0; i < 8 ; ++i )  S->h[i] ^= S->s[i % 4];
}

void blake384_init( state384 *S )
{
    S->h[0] = 0xcbbb9d5dc1059ed8ULL;
    S->h[1] = 0x629a292a367cd507ULL;
    S->h[2] = 0x9159015a3070dd17ULL;
    S->h[3] = 0x152fecd8f70e5939ULL;
    S->h[4] = 0x67332667ffc00b31ULL;
    S->h[5] = 0x8eb44a8768581511ULL;
    S->h[6] = 0xdb0c2e0d64f98fa7ULL;
    S->h[7] = 0x47b5481dbefa4fa4ULL;
    S->t[0] = S->t[1] = S->buflen = S->nullt = 0;
    S->s[0] = S->s[1] = S->s[2] = S->s[3] = 0;
}

void blake384_update( state384 *S, const uint8_t *in, uint64_t inlen )
{
    int left = S->buflen;
    int fill = 128 - left;
    
    /* data left and data received fill a block  */
    if( left && ( inlen >= fill ) )
    {
        memcpy( ( void * ) ( S->buf + left ), ( void * ) in, fill );
        S->t[0] += 1024;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake384_compress( S, S->buf );
        in += fill;
        inlen  -= fill;
        left = 0;
    }
    
    /* compress blocks of data received */
    while( inlen >= 128 )
    {
        S->t[0] += 1024;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake384_compress( S, in );
        in += 128;
        inlen -= 128;
    }
    
    /* store any data left */
    if( inlen > 0 )
    {
        memcpy( ( void * ) ( S->buf + left ), \
               ( void * ) in, ( size_t ) inlen );
        S->buflen = left + ( int )inlen;
    }
    else S->buflen = 0;
}

void blake384_final( state384 *S, uint8_t *out )
{
    uint8_t msglen[16], zz = 0x00, oz = 0x80;
    uint64_t lo = S->t[0] + ( S->buflen << 3 ), hi = S->t[1];
    
    /* support for hashing more than 2^32 bits */
    if ( lo < ( S->buflen << 3 ) ) hi++;
    
    U64TO8_BIG(  msglen + 0, hi );
    U64TO8_BIG(  msglen + 8, lo );
    
    if ( S->buflen == 111 )   /* one padding byte */
    {
        S->t[0] -= 8;
        blake384_update( S, &oz, 1 );
    }
    else
    {
        if ( S->buflen < 111 )  /* enough space to fill the block */
        {
            if ( !S->buflen ) S->nullt = 1;
            
            S->t[0] -= 888 - ( S->buflen << 3 );
            blake384_update( S, padding, 111 - S->buflen );
        }
        else   /* need 2 compressions */
        {
            S->t[0] -= 1024 - ( S->buflen << 3 );
            blake384_update( S, padding, 128 - S->buflen );
            S->t[0] -= 888;
            blake384_update( S, padding + 1, 111 );
            S->nullt = 1;
        }
        
        blake384_update( S, &zz, 1 );
        S->t[0] -= 8;
    }
    
    S->t[0] -= 128;
    blake384_update( S, msglen, 16 );
    U64TO8_BIG( out + 0, S->h[0] );
    U64TO8_BIG( out + 8, S->h[1] );
    U64TO8_BIG( out + 16, S->h[2] );
    U64TO8_BIG( out + 24, S->h[3] );
    U64TO8_BIG( out + 32, S->h[4] );
    U64TO8_BIG( out + 40, S->h[5] );
}

/* from blake512.c */

/* 2021-07-27 srv - make internal function static */

static void blake512_compress( state512 *S, const uint8_t *block )
{
    uint64_t v[16], m[16], i;
    
    for( i = 0; i < 16; ++i )  m[i] = U8TO64_BIG( block + i * 8 );
    
    for( i = 0; i < 8; ++i )  v[i] = S->h[i];
    
    v[ 8] = S->s[0] ^ u512[0];
    v[ 9] = S->s[1] ^ u512[1];
    v[10] = S->s[2] ^ u512[2];
    v[11] = S->s[3] ^ u512[3];
    v[12] =  u512[4];
    v[13] =  u512[5];
    v[14] =  u512[6];
    v[15] =  u512[7];
    
    /* don't xor t when the block is only padding */
    if ( !S->nullt )
    {
        v[12] ^= S->t[0];
        v[13] ^= S->t[0];
        v[14] ^= S->t[1];
        v[15] ^= S->t[1];
    }
    
    for( i = 0; i < 16; ++i )
    {
        /* column step */
        G64( 0, 4, 8, 12, 0 );
        G64( 1, 5, 9, 13, 2 );
        G64( 2, 6, 10, 14, 4 );
        G64( 3, 7, 11, 15, 6 );
        /* diagonal step */
        G64( 0, 5, 10, 15, 8 );
        G64( 1, 6, 11, 12, 10 );
        G64( 2, 7, 8, 13, 12 );
        G64( 3, 4, 9, 14, 14 );
    }
    
    for( i = 0; i < 16; ++i )  S->h[i % 8] ^= v[i];
    
    for( i = 0; i < 8 ; ++i )  S->h[i] ^= S->s[i % 4];
}


void blake512_init( state512 *S )
{
    S->h[0] = 0x6a09e667f3bcc908ULL;
    S->h[1] = 0xbb67ae8584caa73bULL;
    S->h[2] = 0x3c6ef372fe94f82bULL;
    S->h[3] = 0xa54ff53a5f1d36f1ULL;
    S->h[4] = 0x510e527fade682d1ULL;
    S->h[5] = 0x9b05688c2b3e6c1fULL;
    S->h[6] = 0x1f83d9abfb41bd6bULL;
    S->h[7] = 0x5be0cd19137e2179ULL;
    S->t[0] = S->t[1] = S->buflen = S->nullt = 0;
    S->s[0] = S->s[1] = S->s[2] = S->s[3] = 0;
}


void blake512_update( state512 *S, const uint8_t *in, uint64_t inlen )
{
    int left = S->buflen;
    int fill = 128 - left;
    
    /* data left and data received fill a block  */
    if( left && ( inlen >= fill ) )
    {
        memcpy( ( void * ) ( S->buf + left ), ( void * ) in, fill );
        S->t[0] += 1024;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake512_compress( S, S->buf );
        in += fill;
        inlen  -= fill;
        left = 0;
    }
    
    /* compress blocks of data received */
    while( inlen >= 128 )
    {
        S->t[0] += 1024;
        
        if ( S->t[0] == 0 ) S->t[1]++;
        
        blake512_compress( S, in );
        in += 128;
        inlen -= 128;
    }
    
    /* store any data left */
    if( inlen > 0 )
    {
        memcpy( ( void * ) ( S->buf + left ),   \
               ( void * ) in, ( size_t ) inlen );
        S->buflen = left + ( int )inlen;
    }
    else S->buflen = 0;
}


void blake512_final( state512 *S, uint8_t *out )
{
    uint8_t msglen[16], zo = 0x01, oo = 0x81;
    uint64_t lo = S->t[0] + ( S->buflen << 3 ), hi = S->t[1];
    
    /* support for hashing more than 2^32 bits */
    if ( lo < ( S->buflen << 3 ) ) hi++;
    
    U64TO8_BIG(  msglen + 0, hi );
    U64TO8_BIG(  msglen + 8, lo );
    
    if ( S->buflen == 111 )   /* one padding byte */
    {
        S->t[0] -= 8;
        blake512_update( S, &oo, 1 );
    }
    else
    {
        if ( S->buflen < 111 )  /* enough space to fill the block */
        {
            if ( !S->buflen ) S->nullt = 1;
            
            S->t[0] -= 888 - ( S->buflen << 3 );
            blake512_update( S, padding, 111 - S->buflen );
        }
        else   /* need 2 compressions */
        {
            S->t[0] -= 1024 - ( S->buflen << 3 );
            blake512_update( S, padding, 128 - S->buflen );
            S->t[0] -= 888;
            blake512_update( S, padding + 1, 111 );
            S->nullt = 1;
        }
        
        blake512_update( S, &zo, 1 );
        S->t[0] -= 8;
    }
    
    S->t[0] -= 128;
    blake512_update( S, msglen, 16 );
    U64TO8_BIG( out + 0, S->h[0] );
    U64TO8_BIG( out + 8, S->h[1] );
    U64TO8_BIG( out + 16, S->h[2] );
    U64TO8_BIG( out + 24, S->h[3] );
    U64TO8_BIG( out + 32, S->h[4] );
    U64TO8_BIG( out + 40, S->h[5] );
    U64TO8_BIG( out + 48, S->h[6] );
    U64TO8_BIG( out + 56, S->h[7] );
}


