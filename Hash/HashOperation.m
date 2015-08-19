/*
    Hash - HashOperation.m
    $Id: HashConstants.h 1377 2014-10-29 07:43:13Z ranga $

    History:

    v. 1.0.0 (04/12/2015) - Initial version
    v. 1.0.1 (04/22/2015) - Add support for Whirlpool and SHA3
    v. 1.0.2 (04/27/2015) - Add progress bar support
    v. 1.0.3 (08/15/2015) - Add support for CRC, cksum, and RMD320

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

#import "HashOperation.h"
#import "HashAppController.h"
#import "HashConstants.h"
#import "crc.h"
#import "rmd160.h"
#import "rmd320.h"
#import "Whirlpool.h"
#import "KeccakHash.h"

@implementation HashOperation

/*
    init - initialize all the instance variables to nil
*/

-(id) init
{
    return [self initWithFileHashTypeAndProgress: nil
                                            type: HASH_NONE
                                        progress: nil
                                       requester: nil
                                          sender: nil];
}

/*
    initWithFileAndHashType - initial the file path and the hash type
*/

-(id) initWithFileHashTypeAndProgress: (NSString *)path
                                 type: (HashType)hash
                             progress: (NSProgressIndicator *)progressBar
                            requester: (id)requestingObj
                               sender: (id)sendingObj
{
    self = [super init];
    if (self != nil) {

        // set the path to the file

        filePath = path;

        // verify that a valid hash type was specified

        switch (hash) {
            case HASH_CKSUM:
            case HASH_CRC32:
            case HASH_MD5:
            case HASH_SHA1:
            case HASH_SHA256:
            case HASH_SHA512:
            case HASH_RMD160:
            case HASH_RMD320:
            case HASH_WPOOL:
            case HASH_SHA3_256:
            case HASH_SHA3_512:

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

        /* hash objects for the supported hashes */

        crcContext crcHashObject;
        CC_MD5_CTX md5HashObject;
        CC_SHA1_CTX sha1HashObject;
        CC_SHA256_CTX sha256HashObject;
        CC_SHA512_CTX sha512HashObject;
        RMD160_CTX rmd160HashObject;
        rmd320_ctx rmd320HashObject;
        NESSIEstruct whirlpoolHashObject;
        Keccak_HashInstance sha3HashObject;
        
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
                    digestLength = CC_SHA1_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_SHA256:
                case HASH_SHA3_256:
                    digestLength = CC_SHA256_DIGEST_LENGTH*sizeof(*digest);
                    break;
                case HASH_SHA512:
                case HASH_SHA3_512:
                    digestLength = CC_SHA512_DIGEST_LENGTH*sizeof(*digest);
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
                case HASH_CRC32:
                    crc_init(&crcHashObject);
                    break;
                case HASH_MD5:
                    CC_MD5_Init(&md5HashObject);
                    break;
                case HASH_SHA1:
                    CC_SHA1_Init(&sha1HashObject);
                    break;
                case HASH_SHA256:
                    CC_SHA256_Init(&sha256HashObject);
                    break;
                case HASH_SHA512:
                    CC_SHA512_Init(&sha512HashObject);
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
                case HASH_SHA3_256:
                    Keccak_HashInitialize_SHA3_256(&sha3HashObject);
                    break;
                case HASH_SHA3_512:
                    Keccak_HashInitialize_SHA3_512(&sha3HashObject);
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
                [progress setIndeterminate: NO];
                [progress setDoubleValue: 0.0];
                [progress startAnimation: sender];
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
                    [progress setDoubleValue:
                        (double)(((double)bytesSoFar/(double)fileSize)*100)];
                    [progress displayIfNeeded];
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
                    case HASH_SHA1:
                        CC_SHA1_Update(&sha1HashObject,
                                       (const void *)buffer,
                                       (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA256:
                        CC_SHA256_Update(&sha256HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
                        break;
                    case HASH_SHA512:
                        CC_SHA512_Update(&sha512HashObject,
                                         (const void *)buffer,
                                         (CC_LONG)bytesRead);
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
                    case HASH_SHA3_256:
                    case HASH_SHA3_512:
                        Keccak_HashUpdate(&sha3HashObject,
                                          (const BitSequence *)buffer,
                                          (DataLength)bytesRead*8);
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
                    // nothing to do for CRC32
                    break;
                case HASH_MD5:
                    CC_MD5_Final(digest, &md5HashObject);
                    break;
                case HASH_SHA1:
                    CC_SHA1_Final(digest, &sha1HashObject);
                    break;
                case HASH_SHA256:
                    CC_SHA256_Final(digest, &sha256HashObject);
                    break;
                case HASH_SHA512:
                    CC_SHA512_Final(digest, &sha512HashObject);
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
                case HASH_SHA3_256:
                case HASH_SHA3_512:
                    Keccak_HashFinal(&sha3HashObject, digest);
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
                    hashResult = [NSMutableString stringWithCapacity:
                              (2*digestLength) + 1];
                    for (i = 0; i < digestLength; ++i) {
                        [hashResult appendFormat:@"%02x",(int)(digest[i])];
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