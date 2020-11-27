#ifndef JH_H
#define JH_H

typedef unsigned long long JH_uint64;
typedef unsigned char JH_BitSequence;
typedef unsigned long long JH_DataLength;

/* return codes for JH */

typedef enum {
    JH_SUCCESS = 0,
    JH_FAIL = 1,
    JH_BAD_HASHLEN = 2,
} JH_HashReturn;

/*define data alignment for different C compilers*/
#if defined(__GNUC__)
      #define DATA_ALIGN16(x) x __attribute__ ((aligned(16)))
#else
      #define DATA_ALIGN16(x) __declspec(align(16)) x
#endif

/* JH Hash State */

typedef struct {
    int hashbitlen;                   /*the message digest size*/
    unsigned long long databitlen;    /*the message size in bits*/
    unsigned long long datasize_in_buffer;      /*the size of the message remained in buffer; assumed to be multiple of 8bits except for the last partial block at the end of the message*/
    DATA_ALIGN16(JH_uint64 x[8][2]);     /*the 1024-bit state, ( x[i][0] || x[i][1] ) is the ith row of the state in the pseudocode*/
    unsigned char buffer[64];         /*the 512-bit message block to be hashed;*/
} JH_HashState;

/* Prototypes for JH Functions */

JH_HashReturn JH_Init(JH_HashState *state, int hashbitlen);
JH_HashReturn JH_Update(JH_HashState *state,
                        const JH_BitSequence *data,
                        JH_DataLength databitlen);
JH_HashReturn JH_Final(JH_HashState *state,
                       JH_BitSequence *hashval);

#endif /* JH_H */
