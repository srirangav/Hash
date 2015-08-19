/*
    Hash - Whirlpool.h
    $Id: HashConstants.h 1377 2014-10-29 07:43:13Z ranga $

    History:

    v. 1.0.0 (04/21/2015) - Initial version

    Source: http://www.larc.usp.br/~pbarreto/WhirlpoolPage.html
 
    Copyright (c) 2015 Sriranga R. Veeraraghavan <ranga@calalum.org>

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */

#ifndef Hash_Whirlpool_h
#define Hash_Whirlpool_h

#include "nessie.h"

enum {
    NESSIE_DIGEST_LENGTH = 64,
};

void NESSIEinit(struct NESSIEstruct * const structpointer);

void NESSIEadd(const unsigned char * const source,
               unsigned long sourceBits,
               struct NESSIEstruct * const structpointer);

void NESSIEfinalize(struct NESSIEstruct * const structpointer,
                    unsigned char * const result);

#endif
