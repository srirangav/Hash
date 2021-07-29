/*
    Hash - crc.h
    $Id: crc.h 1446 2015-08-17 17:55:37Z ranga $
 
    History:
 
    v. 1.0.0 (08/13/2015) - Initial version
    v. 1.0.1 (08/17/2015) - Added crc_init, crc32_update, and crcContext
    v. 1.0.2 (07/06/2016) - Added cksum_init, crc32_finalize
 
    Copyright (c) 2015-2016 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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

#ifndef Hash_crc_h
#define Hash_crc_h

typedef struct crcContext {
    uint32_t crc;
} crcContext;

void crc32_init(crcContext *ctx);
void crc32_update(crcContext *ctx, const void *buf, size_t size);
int  crc32_finalize(crcContext *ctx);

void cksum_init(crcContext *ctx);
void cksum_update(crcContext *ctx, unsigned char *buf, uint32_t len);
void cksum_finalize(crcContext *ctx, unsigned long long len);

#endif
