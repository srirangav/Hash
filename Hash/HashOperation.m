/*
    Hash - HashOperation.m
    $Id: HashConstants.h 1377 2014-10-29 07:43:13Z ranga $

    History:

    v. 1.0.0 (04/12/2015) - Initial version
    v. 1.0.1 (04/22/2015) - Add support for Whirlpool and SHA3
    v. 1.0.2 (04/27/2015) - Add progress bar support
    v. 1.0.3 (08/15/2015) - Add support for CRC, cksum, and RMD320
    v. 1.0.4 (06/27/2016) - Add support for BLAKE2B
    v. 1.0.5 (06/29/2016) - Add support for Skein
    v. 1.0.6 (07/06/2016) - Add support for BLAKE2BP, BLAKE2S, BLAKE2SP
    v. 1.0.7 (07/06/2016) - Add support for SHA224, SHA384
    v. 1.0.8 (06/28/2017) - Add support for MD6 256, MD6 512 
    v. 1.1.0 (08/07/2019) - Add support for JH, Tiger, Tiger2, HAS-160, BLAKE
    v. 1.1.1 (09/30/2019) - Add support for SHA1 collision detection
    v. 1.1.2 (11/27/2020) - Add support for SHAKE128, SHAKE256
    v. 1.1.3 (11/27/2020) - Add support for BLAKE3

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

#import "HashOperation.h"
#import "HashAppController.h"
#import "HashConstants.h"
#import "crc.h"
#import "md6.h"
#import "rmd160.h"
#import "rmd320.h"
#import "Whirlpool.h"
#import "keccak-tiny.h"
#import "blake2.h"
#import "blake3_impl.h"
#import "skein.h"
#import "jh.h"
#import "tiger.h"
#import "has160.h"
#import "blake.h"
#import "Groestl-opt.h"
#import "sha1dc.h"
#import "snefru.h"

@implementation HashOperation

/*
    init - initialize all the instance variables to nil
*/

-(id) init
{
    return [self initWithFileHashTypeAndProgress: nil
                                            type: HASH_NONE
                                       lowercase: false
                                        progress: nil
                                       requester: nil
                                          sender: nil];
}

/*
    initWithFileAndHashType - initialize the file path and the hash type
*/

-(id) initWithFileHashTypeAndProgress: (NSString *)path
                                 type: (HashType)hash
                            lowercase: (BOOL)lowerCase
                             progress: (NSProgressIndicator *)progressBar
                            requester: (id)requestingObj
                               sender: (id)sendingObj
{
    self = [super init];
    if (self != nil) {

        // set the path to the file

        filePath = path;

        isLowerCase = lowerCase;
        
        // verify that a valid hash type was specified

        switch (hash) {
            case HASH_CKSUM:
            case HASH_CRC32:
            case HASH_MD5:
            case HASH_MD6_256:
            case HASH_MD6_512:
            case HASH_SHA1:
            case HASH_SHA1DC:
            case HASH_SHA224:
            case HASH_SHA256:
            case HASH_SHA384:
            case HASH_SHA512:
            case HASH_SHAKE128:
            case HASH_SHAKE256:
            case HASH_SHA3_224:
            case HASH_SHA3_256:
            case HASH_SHA3_384:
            case HASH_SHA3_512:
            case HASH_RMD160:
            case HASH_RMD320:
            case HASH_WPOOL:
            case HASH_BLAKE2B_256:
            case HASH_BLAKE2B_512:
            //case HASH_BLAKE2BP_256:
            //case HASH_BLAKE2BP_512:
            case HASH_BLAKE2S_256:
            //case HASH_BLAKE2S_512:
            //case HASH_BLAKE2SP_256:
            //case HASH_BLAKE2SP_512:
            case HASH_BLAKE3:
            case HASH_SKEIN_256:
            case HASH_SKEIN_512:
            case HASH_SKEIN_512_256:
            case HASH_SKEIN_1024:
            case HASH_SKEIN_1024_256:
            case HASH_SKEIN_1024_512:
            case HASH_JH_224:
            case HASH_JH_256:
            case HASH_JH_384:
            case HASH_JH_512:
            case HASH_TIGER:
            case HASH_TIGER2:
            case HASH_HAS160:
            case HASH_BLAKE224:
            case HASH_BLAKE256:
            case HASH_BLAKE384:
            case HASH_BLAKE512:
            case HASH_GROESTL224:
            case HASH_GROESTL256:
            case HASH_GROESTL384:
            case HASH_GROESTL512:
            case HASH_SNEFRU128:
            case HASH_SNEFRU256:
                
                // valid hashType

                hashType = hash;
                break;

            default:

                // unknown or invalid hashType
                
                hashType = HASH_NONE;
                break;
        }

        progress = progressBar;
        requester = requestingObj;
        sender = sendingObj;

    }
    return self;
}

/*
    main - calculate the hash, abort if canceled
*/

-(void)main {
    @autoreleasepool {
        
        /* the string containing the hash result */

        NSMutableString *hashResult = nil;

        /* file information */

        NSError *error = nil;
        NSDictionary *attribs = nil;
        unsigned long long fileSize = -1;

        /* the digest */

        unsigned char *digest = NULL;
        size_t digestLength = 0;
        size_t i = 0;

        /* read buffer and bytes read */
        
        uint8_t buffer[FileHashDefaultFileBufferSize];
        size_t bufferLength = FileHashDefaultFileBufferSize;
        NSInteger bytesRead = 0;
        unsigned long long bytesSoFar = 0;

        /* stream to read from */

        NSInputStream *iStream = nil;

        /* flags to indicate whether more data is available and whether
           reading has failed */

        bool hasMoreData = TRUE;
        bool readFailed = FALSE;

        /* variables to handle collisions */
        
        int collision = 0;
        NSString *collisonMsg = NSLocalizedString(@"HASH_COLLISION_DETECTED",
                                                  @"HASH_COLLISION_DETECTED");
        unsigned long collisionMsgExtraBufferSize = [collisonMsg length] + 1;
        
        /* hash objects for the supported hashes */

        crcContext crcHashObject;
        CC_MD5_CTX md5HashObject;
        CC_SHA1_CTX sha1HashObject;
        SHA1_CTX sha1DCHashObject;
        CC_SHA256_CTX sha256HashObject;
        CC_SHA512_CTX sha512HashObject;
        keccak_state sha3HashObject;
        md6_state md6HashObject;
        RMD160_CTX rmd160HashObject;
        rmd320_ctx rmd320HashObject;
        NESSIEstruct whirlpoolHashObject;
        blake2b_state blake2bHashObject;
        blake2s_state blake2sHashObject;
        blake3_hasher blake3HashObject;
        /*
        blake2bp_state blake2bpHashObject;
        blake2sp_state blake2spHashObject;
        */
        Skein_256_Ctxt_t skein256HashObject;
        Skein_512_Ctxt_t skein512HashObject;
        Skein1024_Ctxt_t skein1024HashObject;
        JH_HashState jhHashObject;
        tiger_ctx tigerHashObject;
        has160_ctx has160HashObject;
        state224 blake224HashObject;
        state256 blake256HashObject;
        state384 blake384HashObject;
        state512 blake512HashObject;
        groestl_HashState groestlHashObject;
        snefru_ctx snefruHashObject;
        
        do {
            
            // return if no file is specified

            if (filePath == nil) {
                break;
            }

            // get the file size
            // based on: http://stackoverflow.com/questions/7846495/how-to-get-file-size-properly-and-convert-it-to-mb-gb-in-cocoa

            attribs = [[NSFileManager defaultManager]
                       attributesOfItemAtPath:filePath error:&error];
            if (attribs != nil) {
                fileSize = [attribs fileSize];
            }

            // set the digest length for the specified hash

            switch (hashType) {
                case HASH_CKSUM:
                    digestLength = 1;
                    break;
                case HASH_CRC32:
                    digestLength = 1;
                    break;
                case HASH_MD5:
                    digestLength = CC_MD5_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_SHA1:
                case HASH_SHA1DC:
                    digestLength = CC_SHA1_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_TIGER:
                case HASH_TIGER2:
                    digestLength = tiger_hash_length*sizeof(*digest);
                    break;
                case HASH_SHA224:
                case HASH_SHA3_224:
                case HASH_JH_224:
                case HASH_BLAKE224:
                case HASH_GROESTL224:
                    digestLength = CC_SHA224_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_MD6_256:
                case HASH_SHA256:
                case HASH_SHAKE128:
                case HASH_SHA3_256:
                case HASH_BLAKE2B_256:
                case HASH_BLAKE2BP_256:
                case HASH_BLAKE2S_256:
                case HASH_BLAKE2SP_256:
                case HASH_BLAKE3:
                case HASH_SKEIN_256:
                case HASH_SKEIN_512_256:
                case HASH_SKEIN_1024_256:
                case HASH_JH_256:
                case HASH_BLAKE256:
                case HASH_GROESTL256:
                    digestLength = CC_SHA256_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_SHA384:
                case HASH_SHA3_384:
                case HASH_JH_384:
                case HASH_BLAKE384:
                case HASH_GROESTL384:
                    digestLength = CC_SHA384_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_MD6_512:
                case HASH_SHA512:
                case HASH_SHAKE256:
                case HASH_SHA3_512:
                case HASH_BLAKE2B_512:
                case HASH_BLAKE2BP_512:
                case HASH_BLAKE2S_512:
                case HASH_BLAKE2SP_512:
                case HASH_SKEIN_512:
                case HASH_SKEIN_1024_512:
                case HASH_JH_512:
                case HASH_BLAKE512:
                case HASH_GROESTL512:
                    digestLength = CC_SHA512_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_SKEIN_1024:
                    digestLength = 2*(CC_SHA512_DIGEST_LENGTH*sizeof(*digest));
                    break;
                case HASH_RMD160:
                    digestLength = RMD160_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_RMD320:
                    digestLength = 2*(RMD160_DIGEST_LENGTH*sizeof(*digest));
                    break;
                case HASH_WPOOL:
                    digestLength = NESSIE_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_HAS160:
                    digestLength = has160_hash_size*sizeof(*digest);
                    break;
                case HASH_SNEFRU128:
                    digestLength = snefru128_hash_length*sizeof(*digest);
                    break;
                case HASH_SNEFRU256:
                    digestLength = snefru256_hash_length*sizeof(*digest);
                    break;
                default:
                    digestLength = 0;
                    break;
            }

            // return if an unknown hash was specified

            if (digestLength <= 0) {
                break;
            }

            // allocate space for the digest
            
            digest = malloc(digestLength);
            if (digest == NULL) {
                break;
            }
            memset(digest, 0, digestLength);

            // Create and open the read stream

            iStream = [NSInputStream inputStreamWithFileAtPath:filePath];

            if (iStream == nil) {
                break;
            }

            [iStream open];

            // initialize the hash object for the specified hash

            switch (hashType) {
                case HASH_CKSUM:
                    cksum_init(&crcHashObject);
                    break;
                case HASH_CRC32:
                    crc32_init(&crcHashObject);
                    break;
                case HASH_MD5:
                    CC_MD5_Init(&md5HashObject);
                    break;
                case HASH_MD6_256:
                    md6_init(&md6HashObject, 256);
                    break;
                case HASH_MD6_512:
                    md6_init(&md6HashObject, 512);
                    break;
                case HASH_SHA1:
                    CC_SHA1_Init(&sha1HashObject);
                    break;
                case HASH_SHA1DC:
                    SHA1DCInit(&sha1DCHashObject);
                    break;
                case HASH_SHA224:
                    CC_SHA224_Init(&sha256HashObject);
                    break;
                case HASH_SHA256:
                    CC_SHA256_Init(&sha256HashObject);
                    break;
                case HASH_SHA384:
                    CC_SHA384_Init(&sha512HashObject);
                    break;
                case HASH_SHA512:
                    CC_SHA512_Init(&sha512HashObject);
                    break;
                case HASH_SHAKE128:
                    keccak_cleanse(&sha3HashObject);
                    keccak_xof_init(&sha3HashObject, 128);
                    break;
                case HASH_SHAKE256:
                    keccak_cleanse(&sha3HashObject);
                    keccak_xof_init(&sha3HashObject, 256);
                    break;
                case HASH_SHA3_224:
                    keccak_cleanse(&sha3HashObject);
                    keccak_digest_init(&sha3HashObject, 224);
                    break;
                case HASH_SHA3_256:
                    keccak_cleanse(&sha3HashObject);
                    keccak_digest_init(&sha3HashObject, 256);
                    break;
                case HASH_SHA3_384:
                    keccak_cleanse(&sha3HashObject);
                    keccak_digest_init(&sha3HashObject, 384);
                    break;
                case HASH_SHA3_512:
                    keccak_cleanse(&sha3HashObject);
                    keccak_digest_init(&sha3HashObject, 512);
                    break;
                case HASH_RMD160:
                    RMD160Init(&rmd160HashObject);
                    break;
                case HASH_RMD320:
                    rmd320_init(&rmd320HashObject);
                    break;
                case HASH_WPOOL:
                    NESSIEinit(&whirlpoolHashObject);
                    break;
                case HASH_BLAKE2B_256:
                    blake2b_init(&blake2bHashObject, 32);
                    break;
                case HASH_BLAKE2B_512:
                    blake2b_init(&blake2bHashObject, 64);
                    break;
                /*
                case HASH_BLAKE2BP_256:
                    blake2bp_init(&blake2bpHashObject, 32);
                    break;
                case HASH_BLAKE2BP_512:
                    blake2bp_init(&blake2bpHashObject, 64);
                    break;
                */
                case HASH_BLAKE2S_256:
                    blake2s_init(&blake2sHashObject, 32);
                    break;
                /*
                case HASH_BLAKE2S_512:
                    blake2s_init(&blake2sHashObject, 64);
                    break;
                case HASH_BLAKE2SP_256:
                    blake2sp_init(&blake2spHashObject, 32);
                    break;
                case HASH_BLAKE2SP_512:
                    blake2sp_init(&blake2spHashObject, 64);
                    break;
                */
                case HASH_BLAKE3:
                    blake3_hasher_init(&blake3HashObject);
                    break;
                case HASH_SKEIN_256:
                    Skein_256_Init(&skein256HashObject, 256);
                    break;
                case HASH_SKEIN_512_256:
                    Skein_512_Init(&skein512HashObject, 256);
                    break;
                case HASH_SKEIN_512:
                    Skein_512_Init(&skein512HashObject, 512);
                    break;
                case HASH_SKEIN_1024:
                    Skein1024_Init(&skein1024HashObject, 1024);
                    break;
                case HASH_SKEIN_1024_256:
                    Skein1024_Init(&skein1024HashObject, 256);
                    break;
                case HASH_SKEIN_1024_512:
                    Skein1024_Init(&skein1024HashObject, 512);
                    break;
                case HASH_JH_224:
                    JH_Init(&jhHashObject, 224);
                    break;
                case HASH_JH_256:
                    JH_Init(&jhHashObject, 256);
                    break;
                case HASH_JH_384:
                    JH_Init(&jhHashObject, 384);
                    break;
                case HASH_JH_512:
                    JH_Init(&jhHashObject, 512);
                    break;
                case HASH_TIGER:
                    rhash_tiger_init(&tigerHashObject);
                    break;
                case HASH_TIGER2:
                    rhash_tiger2_init(&tigerHashObject);
                    break;
                case HASH_HAS160:
                    rhash_has160_init(&has160HashObject);
                    break;
                case HASH_BLAKE224:
                    blake224_init(&blake224HashObject);
                    break;
                case HASH_BLAKE256:
                    blake256_init(&blake256HashObject);
                    break;
                case HASH_BLAKE384:
                    blake384_init(&blake384HashObject);
                    break;
                case HASH_BLAKE512:
                    blake512_init(&blake512HashObject);
                    break;
                case HASH_GROESTL224:
                    groestl_Init(&groestlHashObject, 224);
                    break;
                case HASH_GROESTL256:
                    groestl_Init(&groestlHashObject, 256);
                    break;
                case HASH_GROESTL384:
                    groestl_Init(&groestlHashObject, 384);
                    break;
                case HASH_GROESTL512:
                    groestl_Init(&groestlHashObject, 512);
                    break;
                case HASH_SNEFRU128:
                    rhash_snefru128_init(&snefruHashObject);
                    break;
                case HASH_SNEFRU256:
                    rhash_snefru256_init(&snefruHashObject);
                    break;
                default:
                    hasMoreData = FALSE;
                    readFailed = TRUE;
                    break;
            }

            // clear the read buffer

            memset(buffer, 0, bufferLength);

            /* 
                Read the file one buffer at a time and update the hash
                accordingly
                Based on: http://samplecodebank.blogspot.com/2013/05/nsinputstream-read-example-ios.html
                          https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSInputStream_Class/index.html#//apple_ref/occ/instm/NSInputStream/read:maxLength:
             */

            // if a progress bar was specified, start it
            // based on: http://cocoadev.com/HowToAddAProgressBar
            //           http://stackoverflow.com/questions/2509612/how-do-i-update-a-progress-bar-in-cocoa-during-a-long-running-loop#2520387

            if (progress != nil ) {

                // make sure the progress bar runs in the main queue (to fix a
                // Xcode 9 warning.
                // based on:
                // https://stackoverflow.com/questions/11582223/ios-ensure-execution-on-main-thread#11582577
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self->progress setIndeterminate: NO];
                    [self->progress setDoubleValue: 0.0];
                    [self->progress startAnimation: self->sender];
                }];
            }

            while (hasMoreData) {

                // check whether the calculation has been cancelled

                if (self.isCancelled == TRUE) {
                    readFailed = TRUE;
                    break;
                }

                bytesRead = [iStream read:buffer maxLength:bufferLength];

                // if the bytes read is less than 0, reading failed

                if (bytesRead == -1) {
                    NSLog(@"ERROR: %@",[iStream streamError]);
                    readFailed = TRUE;
                    break;
                }

                // if the bytes read is 0, end of file was reached and
                // there is no more data

                if (bytesRead == 0) {
                    hasMoreData = FALSE;
                    continue;
                }

                // if a progress bar was specified, update it
                // based on: http://cocoadev.com/HowToAddAProgressBar

                if (progress != nil) {
                    bytesSoFar += bytesRead;
                    
                    // make sure the progress bar runs in the main queue (to fix a
                    // Xcode 9 warning.
                    // based on:
                    // https://stackoverflow.com/questions/11582223/ios-ensure-execution-on-main-thread#11582577

                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        [self->progress setDoubleValue:
                         (double)(((double)bytesSoFar/(double)fileSize)*100)];
                        [self->progress displayIfNeeded];
                    }];
                }

                // update the hash with the data that was just read

                switch (hashType) {
                    case HASH_CKSUM:
                        cksum_update(&crcHashObject,
                                    (unsigned char *)buffer,
                                     (uint32_t) bytesRead);
                        break;
                    case HASH_CRC32:
                        crc32_update(&crcHashObject,
                                    (const void *)buffer,
                                    (size_t) bytesRead);
                        break;
                    case HASH_MD5:
                        CC_MD5_Update(&md5HashObject,
                                      (const void *)buffer,
                                      (CC_LONG)bytesRead);
                        break;
                    case HASH_MD6_256:
                    case HASH_MD6_512:
                        
                        /*
                            Update the MD6 sum, passing in the number
                            of bits (bytes*8) read (see md6sum.c in the
                            reference implementation).
                         */
                        
                        md6_update(&md6HashObject,
                                   (unsigned char *)buffer,
                                   bytesRead*8);
                        break;
                    case HASH_SHA1:
                        CC_SHA1_Update(&sha1HashObject,
                                       (const void *)buffer,
                                       (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA1DC:
                        SHA1DCUpdate(&sha1DCHashObject,
                                     (const char*)buffer,
                                     (unsigned)bytesRead);
                        break;
                    case HASH_SHA224:
                        CC_SHA224_Update(&sha256HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA256:
                        CC_SHA256_Update(&sha256HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA384:
                        CC_SHA384_Update(&sha512HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA512:
                        CC_SHA512_Update(&sha512HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
                        break;
                    case HASH_SHAKE128:
                    case HASH_SHAKE256:
                        keccak_xof_absorb(&sha3HashObject,
                                          buffer,
                                          bytesRead);
                        break;
                    case HASH_SHA3_224:
                    case HASH_SHA3_256:
                    case HASH_SHA3_384:
                    case HASH_SHA3_512:
                        
                        /*
                            Update the SHA3 sum, passing in the number
                            of bits (bytes*8) read.
                         */
                        keccak_digest_update(&sha3HashObject,
                                             buffer,
                                             bytesRead);
                        break;
                    case HASH_RMD160:
                        RMD160Update(&rmd160HashObject,
                                     (const void *)buffer,
                                     (uint32_t)bytesRead);
                        break;
                    case HASH_RMD320:
                        rmd320_hash(&rmd320HashObject,
                                    (const void *)buffer,
                                    (size_t)bytesRead);
                        break;
                    case HASH_WPOOL:
                        NESSIEadd(buffer,
                                  (unsigned long)bytesRead*8,
                                  &whirlpoolHashObject);
                        break;
                    case HASH_BLAKE2B_256:
                    case HASH_BLAKE2B_512:
                        blake2b_update(&blake2bHashObject,
                                       (const uint8_t *)buffer,
                                       (uint64_t)bytesRead);
                        break;
                    /*
                    case HASH_BLAKE2BP_256:
                    case HASH_BLAKE2BP_512:
                        blake2bp_update(&blake2bpHashObject,
                                       (const uint8_t *)buffer,
                                       (uint64_t)bytesRead);
                        break;
                    */
                    case HASH_BLAKE2S_256:
                    //case HASH_BLAKE2S_512:
                        blake2s_update(&blake2sHashObject,
                                       (const uint8_t *)buffer,
                                       (uint64_t)bytesRead);
                        break;
                    /*
                    case HASH_BLAKE2SP_256:
                    case HASH_BLAKE2SP_512:
                        blake2sp_update(&blake2spHashObject,
                                        (const uint8_t *)buffer,
                                        (uint64_t)bytesRead);
                        break;
                    */
                    case HASH_BLAKE3:
                        blake3_hasher_update(&blake3HashObject,
                                             buffer,
                                             bytesRead);
                        break;
                    case HASH_SKEIN_256:
                        Skein_256_Update(&skein256HashObject,
                                         (const u08b_t *)buffer,
                                         (size_t)bytesRead);
                        break;
                    case HASH_SKEIN_512:
                    case HASH_SKEIN_512_256:
                        Skein_512_Update(&skein512HashObject,
                                         (const u08b_t *)buffer,
                                         (size_t)bytesRead);
                        break;
                    case HASH_SKEIN_1024:
                    case HASH_SKEIN_1024_256:
                    case HASH_SKEIN_1024_512:
                        Skein1024_Update(&skein1024HashObject,
                                         (const u08b_t *)buffer,
                                         (size_t)bytesRead);
                        break;
                    case HASH_JH_224:
                    case HASH_JH_256:
                    case HASH_JH_384:
                    case HASH_JH_512:

                        /*
                            Update the JH sum, passing in the number
                            of bits (bytes*8) read.
                         */

                        JH_Update(&jhHashObject,
                                  (const JH_BitSequence *)buffer,
                                  (JH_DataLength)(bytesRead*8));
                        break;
                    case HASH_TIGER:
                    case HASH_TIGER2:
                        rhash_tiger_update(&tigerHashObject,
                                           (const unsigned char*)buffer,
                                           (size_t)bytesRead);
                        break;
                    case HASH_HAS160:
                        rhash_has160_update(&has160HashObject,
                                           (const unsigned char*)buffer,
                                           (size_t)bytesRead);
                        break;
                    case HASH_BLAKE224:
                        blake224_update(&blake224HashObject,
                                        (const uint8_t *)buffer,
                                        bytesRead);
                        break;
                    case HASH_BLAKE256:
                        blake256_update(&blake256HashObject,
                                        (const uint8_t *)buffer,
                                        bytesRead);
                        break;
                    case HASH_BLAKE384:
                        blake384_update(&blake384HashObject,
                                        (const uint8_t *)buffer,
                                        bytesRead);
                        break;
                    case HASH_BLAKE512:
                        blake512_update(&blake512HashObject,
                                        (const uint8_t *)buffer,
                                        bytesRead);
                        break;
                    case HASH_GROESTL224:
                    case HASH_GROESTL256:
                    case HASH_GROESTL384:
                    case HASH_GROESTL512:
                        groestl_Update(&groestlHashObject,
                                       (const groestl_BitSequence *)buffer,
                                       (groestl_DataLength)(bytesRead*8));
                        break;
                    case HASH_SNEFRU128:
                    case HASH_SNEFRU256:
                        rhash_snefru_update(&snefruHashObject,
                                            (const unsigned char*)buffer,
                                            (size_t)bytesRead);
                        break;
                    default:
                        hasMoreData = FALSE;
                        readFailed = TRUE;
                        break;
                }
            }

            // finalize the hash

            switch (hashType) {
                case HASH_CKSUM:
                    cksum_finalize(&crcHashObject, fileSize);
                    break;
                case HASH_CRC32:
                    crc32_finalize(&crcHashObject);
                    break;
                case HASH_MD5:
                    CC_MD5_Final(digest, &md5HashObject);
                    break;
                case HASH_MD6_256:
                case HASH_MD6_512:
                    md6_final(&md6HashObject, digest);
                    break;
                case HASH_SHA1:
                    CC_SHA1_Final(digest, &sha1HashObject);
                    break;
                case HASH_SHA1DC:
                    collision = SHA1DCFinal(digest, &sha1DCHashObject);
                    break;
                case HASH_SHA224:
                    CC_SHA224_Final(digest, &sha256HashObject);
                    break;
                case HASH_SHA256:
                    CC_SHA256_Final(digest, &sha256HashObject);
                    break;
                case HASH_SHA384:
                    CC_SHA384_Final(digest, &sha512HashObject);
                    break;
                case HASH_SHA512:
                    CC_SHA512_Final(digest, &sha512HashObject);
                    break;
                case HASH_SHAKE128:
                case HASH_SHAKE256:
                    keccak_xof_squeeze(&sha3HashObject,
                                       digest,
                                       digestLength);
                    break;
                case HASH_SHA3_224:
                case HASH_SHA3_256:
                case HASH_SHA3_384:
                case HASH_SHA3_512:
                    keccak_finalize(&sha3HashObject);
                    keccak_squeeze(&sha3HashObject,
                                   digest,
                                   digestLength);
                    break;
                case HASH_RMD160:
                    RMD160Final(digest, &rmd160HashObject);
                    break;
                case HASH_RMD320:
                    rmd320_done(&rmd320HashObject, digest);
                    break;
                case HASH_WPOOL:
                    NESSIEfinalize(&whirlpoolHashObject, digest);
                    break;
                case HASH_BLAKE2B_256:
                    blake2b_final(&blake2bHashObject, digest, 32);
                    break;
                case HASH_BLAKE2B_512:
                    blake2b_final(&blake2bHashObject, digest, 64);
                    break;
                /*
                case HASH_BLAKE2BP_256:
                    blake2bp_final(&blake2bpHashObject, digest, 32);
                    break;
                case HASH_BLAKE2BP_512:
                    blake2bp_final(&blake2bpHashObject, digest, 64);
                    break;
                 */
                case HASH_BLAKE2S_256:
                    blake2s_final(&blake2sHashObject, digest, 32);
                    break;
                /*
                case HASH_BLAKE2S_512:
                    blake2s_final(&blake2sHashObject, digest, 64);
                    break;
                case HASH_BLAKE2SP_256:
                    blake2sp_final(&blake2spHashObject, digest, 32);
                    break;
                case HASH_BLAKE2SP_512:
                    blake2sp_final(&blake2spHashObject, digest, 64);
                    break;
                */
                case HASH_BLAKE3:
                    blake3_hasher_finalize(&blake3HashObject,
                                           digest,
                                           digestLength);
                    break;
                case HASH_SKEIN_256:
                    Skein_256_Final(&skein256HashObject,
                                    digest);
                    break;
                case HASH_SKEIN_512:
                case HASH_SKEIN_512_256:
                    Skein_512_Final(&skein512HashObject,
                                    digest);
                    break;
                case HASH_SKEIN_1024:
                case HASH_SKEIN_1024_256:
                case HASH_SKEIN_1024_512:
                    Skein1024_Final(&skein1024HashObject,
                                    digest);
                    break;
                case HASH_JH_224:
                case HASH_JH_256:
                case HASH_JH_384:
                case HASH_JH_512:
                    JH_Final(&jhHashObject,
                             (JH_BitSequence *)digest);
                    break;
                case HASH_TIGER:
                case HASH_TIGER2:
                    rhash_tiger_final(&tigerHashObject,
                                      digest);
                    break;
                case HASH_HAS160:
                    rhash_has160_final(&has160HashObject,
                                       digest);
                    break;
                case HASH_BLAKE224:
                    blake224_final(&blake224HashObject,
                                   digest);
                    break;
                case HASH_BLAKE256:
                    blake256_final(&blake256HashObject,
                                   digest);
                    break;
                case HASH_BLAKE384:
                    blake384_final(&blake384HashObject,
                                   digest);
                    break;
                case HASH_BLAKE512:
                    blake512_final(&blake512HashObject,
                                   digest);
                    break;
                case HASH_GROESTL224:
                case HASH_GROESTL256:
                case HASH_GROESTL384:
                case HASH_GROESTL512:
                    groestl_Final(&groestlHashObject,
                                  (groestl_BitSequence *)digest);
                    break;
                case HASH_SNEFRU128:
                case HASH_SNEFRU256:
                    rhash_snefru_final(&snefruHashObject,
                                       digest);
                    break;
                default:
                    hasMoreData = FALSE;
                    readFailed = TRUE;
                    break;
            }
            
            // If the file was successfully read, covert the hash to a string
            
            if (readFailed == FALSE) {
                if (hashType == HASH_CRC32 ||
                    hashType == HASH_CKSUM) {
                    hashResult = [NSMutableString stringWithFormat: @"%u",
                                  crcHashObject.crc];
                } else {
                    
                    /*
                        allocate enough room to store the hash result,
                        plus a collision detected message.
                     */
                    
                    hashResult = [NSMutableString stringWithCapacity:
                                  (2*digestLength) +
                                  (hashType == HASH_SHA1DC ?
                                   collisionMsgExtraBufferSize : 0) +
                                  1];
                    
                    /*
                        unless lowercase output was requested, output the
                        hash in hex with capital letters for A-F
                     */
                    
                    for (i = 0; i < digestLength; ++i) {
                        [hashResult appendFormat:
                         (isLowerCase ? @"%02x" : @"%02X"), (int)(digest[i])];
                    }
                    
                    /* if there was a collision, add the collision message */
                    
                    if (hashType == HASH_SHA1DC &&
                        collision != 0) {
                        [hashResult appendString: collisonMsg];
                    }
                }
            }
            
        } while (FALSE);

        // clean up - close the read stream and free the digest

        if (iStream != nil) {
            [iStream close];
        }

        if (digest != NULL) {
            free(digest);
        }

        // call the hashComplete callback function if a requesting
        // object was specified

        if (requester != nil) {
            [requester performSelectorOnMainThread: @selector(hashComplete:)
                                        withObject:
                        [NSDictionary dictionaryWithObjectsAndKeys:
                                    hashResult, keyHashResult,
                                    sender, keySender,
                                    nil]
                                     waitUntilDone: YES];
        }
    }
}

@end
