#ifndef JH_H
#define JH_H

typedef __m128i  word128;   /*word128 defines a 128-bit SSE2 word*/

typedef unsigned char JH_BitSequence;
typedef unsigned long long JH_DataLength;

/* return codes for JH */

typedef enum {JH_SUCCESS = 0, JH_FAIL = 1, JH_BAD_HASHLEN = 2} JH_HashReturn;

/* JH Hash State */

typedef struct {
      int hashbitlen;	                /*the message digest size*/
      unsigned long long databitlen;    /*the message size in bits*/
      unsigned long long datasize_in_buffer;           /*the size of the message remained in buffer; assumed to be multiple of 8bits except for the last partial block at the end of the message*/
      word128  x0,x1,x2,x3,x4,x5,x6,x7; /*1024-bit state;*/
      unsigned char buffer[64];         /*512-bit message block;*/
} JH_HashState;

/* Prototypes for JH Functions */

JH_HashReturn JH_Init(JH_HashState *state, int hashbitlen);
JH_HashReturn JH_Update(JH_HashState *state,
                        const JH_BitSequence *data,
                        JH_DataLength databitlen);
JH_HashReturn JH_Final(JH_HashState *state,
                       JH_BitSequence *hashval);

#endif /* JH_H */
