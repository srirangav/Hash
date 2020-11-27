/*
    Hash - HashOperation.h
    $Id: HashConstants.h 1377 2014-10-29 07:43:13Z ranga $

    History:

    v. 1.0.0 (04/12/2015) - Initial version
    v. 1.0.1 (04/22/2015) - Add support for Whirlpool and SHA3
    v. 1.0.2 (04/27/2015) - Add progress bar support
    v. 1.0.3 (08/15/2015) - Add support for CRC, cksum, and RMD320
    v. 1.0.4 (06/27/2016) - Add support for BLAKE2B
    v. 1.0.5 (06/29/2016) - Add support for Skein
    v. 1.0.6 (07/06/2016) - Add support for BLAKE2BP, BLAKE2S, BLAKE2SP
    v. 1.0.7 (07/06/2016) - Add support for SHA224, SHA384, SHA3 224,
                            SHA3 284
    v. 1.0.8 (06/28/2017) - Add support for MD6 256, MD6 512 
    v. 1.1.0 (08/07/2019) - Add support for JH, Tiger, Tiger2. HAS-160, BLAKE
    v. 1.1.1 (09/30/2019) - Add support for SHA1 collision detection
    v. 1.1.2 (11/27/2020) - Add support for SHAKE128, SHAKE256

    Based on: http://www.joel.lopes-da-silva.com/2010/09/07/compute-md5-or-sha-hash-of-large-file-efficiently-on-ios-and-mac-os-x/
              http://www.cimgf.com/2008/02/23/nsoperation-example/
              http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues
              http://www.informit.com/articles/article.aspx?p=1768318

    Copyright (c) 2015-2019 Sriranga R. Veeraraghavan <ranga@calalum.org>

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CommonCrypto/CommonDigest.h>

// Supported Hash Types

typedef enum {
    HASH_NONE           =  0,
    HASH_MD5            =  1,
    HASH_SHA1           =  2,
    HASH_SHA256         =  3,
    HASH_RMD160         =  4,
    HASH_SHA512         =  5,
    HASH_WPOOL          =  6,
    HASH_SHA3_256       =  7,
    HASH_SHA3_512       =  8,
    HASH_CRC32          =  9,
    HASH_CKSUM          = 10,
    HASH_RMD320         = 11,
    HASH_BLAKE2B_256    = 12,
    HASH_BLAKE2B_512    = 13,
    HASH_SKEIN_256      = 14,
    HASH_SKEIN_512      = 15,
    HASH_SKEIN_1024     = 16,
    HASH_SKEIN_512_256  = 17,
    HASH_SKEIN_1024_256 = 18,
    HASH_SKEIN_1024_512 = 19,
    HASH_BLAKE2S_256    = 20,
    HASH_BLAKE2S_512    = 21,
    HASH_BLAKE2SP_256   = 22,
    HASH_BLAKE2SP_512   = 23,
    HASH_BLAKE2BP_256   = 24,
    HASH_BLAKE2BP_512   = 25,
    HASH_SHA224         = 26,
    HASH_SHA384         = 27,
    HASH_SHA3_224       = 28,
    HASH_SHA3_384       = 29,
    HASH_MD6_256        = 30,
    HASH_MD6_512        = 31,
    HASH_JH_224         = 32,
    HASH_JH_256         = 33,
    HASH_JH_384         = 34,
    HASH_JH_512         = 35,
    HASH_TIGER          = 36,
    HASH_TIGER2         = 37,
    HASH_HAS160         = 38,
    HASH_BLAKE224       = 39,
    HASH_BLAKE256       = 40,
    HASH_BLAKE384       = 41,
    HASH_BLAKE512       = 42,
    HASH_GROESTL224     = 43,
    HASH_GROESTL256     = 44,
    HASH_GROESTL384     = 45,
    HASH_GROESTL512     = 46,
    HASH_SHA1DC         = 47,
    HASH_SNEFRU128      = 48,
    HASH_SNEFRU256      = 49,
    HASH_SHAKE128       = 50,
    HASH_SHAKE256       = 51,
} HashType;

// Default File Buffer Size (400K)

enum {
    FileHashDefaultFileBufferSize = 409600,
};

@interface HashOperation : NSOperation {
    NSObject *requester;
    NSString *filePath;
    NSProgressIndicator *progress;
    NSWindow *sender;
    HashType hashType;
    BOOL isLowerCase;
}

-(id)initWithFileHashTypeAndProgress: (NSString *)path
                                type: (HashType)hash
                           lowercase: (BOOL)lowerCase
                            progress: (NSProgressIndicator *)progressBar
                           requester: (id)requestingObj
                              sender: (NSWindow *)sendingObj;
-(void)main;

@end
