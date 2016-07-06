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

    Based on: http://www.joel.lopes-da-silva.com/2010/09/07/compute-md5-or-sha-hash-of-large-file-efficiently-on-ios-and-mac-os-x/
              http://www.cimgf.com/2008/02/23/nsoperation-example/
              http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues
              http://www.informit.com/articles/article.aspx?p=1768318

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
}

-(id)initWithFileHashTypeAndProgress: (NSString *)path
                                type: (HashType)hash
                            progress: (NSProgressIndicator *)progressBar
                           requester: (id)requestingObj
                              sender: (NSWindow *)sendingObj;
-(void)main;

@end