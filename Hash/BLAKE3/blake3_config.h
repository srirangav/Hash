#ifndef BLAKE3_CONFIG_H
#define BLAKE3_CONFIG_H

/* disable x86 SMID code for now */

#define BLAKE3_NO_SSE2
#define BLAKE3_NO_SSE41
#define BLAKE3_NO_AVX2
#define BLAKE3_NO_AVX512

#endif /* BLAKE3_CONFIG_H */
