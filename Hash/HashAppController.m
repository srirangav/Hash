/*
    Hash - HashAppController.m

    History:

    v. 1.0.0  (10/20/2014) - Initial version
    v. 1.0.1  (04/17/2014) - Update to allow background processing of hashes
    v. 1.0.2  (04/17/2014) - Add support for Whirlpool and SHA3
    v. 1.0.3  (04/27/2015) - Add progress bar support
    v. 1.0.4  (08/15/2015) - Add support for CRC, cksum, and RMD320
    v. 1.0.5  (06/27/2016) - Add support for BLAKE2B
    v. 1.0.6  (06/29/2016) - Add support for Skein
    v. 1.0.7  (07/06/2016) - Add support for BLAKE2BP, BLAKE2S, BLAKE2SP
    v. 1.0.8  (07/06/2016) - Add support for SHA224, SHA384, SHA3 224,
                             SHA3 284
    v. 1.0.9  (06/28/2017) - Add support for MD6 256, MD6 512
    v. 1.1.0  (06/30/2019) - Add dark mode support
    v. 1.1.1  (08/01/2019) - Try to ensure text fields always display some
                             text
    v. 1.1.2  (08/07/2019) - Add support for JH, Tiger, Tiger 2, HAS-160, BLAKE
    v. 1.1.3  (08/13/2019) - Clear verification and message fields when the
                             selected file changes
    v. 1.1.4  (09/30/2019) - Add support for SHA1 collision detection
    v. 1.1.6  (XX/XX/2020) - Add support for outputing the hash in lowercase
    v. 1.1.6  (11/12/2020) - Check the verfication hash to see if it the right
                             length
    v. 1.1.7  (11/27/2020) - Add support for SHAKE128, SHAKE256
    v. 1.1.8  (11/27/2020) - Add support for BLAKE3
    v. 1.1.9  (05/22/2021) - Add preference pane
    v. 1.1.10 (05/26/2021) - Add support for LSH
    v. 1.1.11 (10/24/2021) - Add support for showing the file size
    v. 1.1.12 (10/24/2021) - Add selected hash and file to progress sheet
    v. 1.1.13 (06/30/2022) - Synchronize preferences sheet checkboxs with
                             stored preference settings on application
                             startup
    v. 1.1.14 (08/05/2022) - Add support for K12
    v. 1.1.15 (06/09/2023) - fix deprication warnings
    v. 1.1.16 (01/31/2024) - Add support for advanced mode

    Based on: http://www.insanelymac.com/forum/topic/91735-a-full-cocoaxcodeinterface-builder-tutorial/

    Copyright (c) 2014-2024 Sriranga R. Veeraraghavan <ranga@calalum.org>

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

#import "HashConstants.h"
#import "HashOperation.h"
#import "HashAppController.h"
#import "rmd160.h"
#import "Whirlpool.h"
#import "tiger.h"
#import "has160.h"
#import "snefru.h"

NSString *gAppGroup = @"CLN8R9E6QM.org.calalum.ranga.HashGroup";
NSString *gPrefLowercase = @"lowercase";
NSString *gPrefShowSize = @"showsize";
NSString *gPrefAdvancedMode = @"advancedmode";
NSInteger gDefaultHash = HASH_SHA1;

@implementation HashAppController

-(void)awakeFromNib
{
    /*
        Register for fileDroppedEvents
        Based on: https://stackoverflow.com/questions/7896646/how-to-pass-object-with-nsnotificationcenter
    */

    [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(fileDroppedAction:)
               name: fileDroppedEvent
             object: nil];

    /*
        Initialize the operation queue
        Based on: http://www.cimgf.com/2008/02/23/nsoperation-example/
    */

    hashQueue = [[NSOperationQueue alloc] init];

    /*
        Try to make sure that text is always shown in the editable text
        fields.  See:
    https://stackoverflow.com/questions/7113371/how-do-i-force-the-cursor-to-the-end-of-a-nstextfield
     */

    [[selectedFileField currentEditor] moveToEndOfLine: nil];
    [[selectedFileField currentEditor] moveToEndOfDocument: nil];
    [[verifyHashField currentEditor] moveToEndOfLine: nil];
    [[verifyHashField currentEditor] moveToEndOfDocument: nil];

    hashDefaults = [[NSUserDefaults alloc] initWithSuiteName: gAppGroup];

    prefLowercase = [hashDefaults boolForKey: gPrefLowercase];
    [lowerCaseCheckBox setState: (prefLowercase ?
                                  NSControlStateValueOn :
                                  NSControlStateValueOff)];

    prefShowSize = [hashDefaults boolForKey: gPrefShowSize];
    [showSizeCheckBox setState: (prefShowSize ?
                                NSControlStateValueOn :
                                NSControlStateValueOff)];

    prefAdvancedMode = [hashDefaults boolForKey: gPrefAdvancedMode];
    [advancedModeCheckBox setState: (prefAdvancedMode ?
                                     NSControlStateValueOff :
                                     NSControlStateValueOn)];

    [selectedHashPopUp setAutoenablesItems: NO];

    /* default to simple mode */

    if (prefAdvancedMode == NO)
    {
        [self disableAdvancedMode];
    }
    else
    {
        [self enableAdvancedMode];
    }
}

/*
    fileDroppedAction - handle notifications when a file is dropped on
                        the application icon
    Based on: https://stackoverflow.com/questions/7896646/how-to-pass-object-with-nsnotificationcenter
*/

#pragma mark - Notification
-(void) fileDroppedAction:(NSNotification *) notification
{
    NSDictionary *userInfo = nil;
    NSString *path = nil;

    // make sure a valid notification was provided

    if (notification == nil ||
        notification.name == nil ||
        notification.userInfo == nil)
    {
        return;
    }

    // check if the notification is a fileDroppedEvent

    if ([notification.name isEqualToString: fileDroppedEvent] == FALSE)
    {
        return;
    }

    // check if the userInfo contains a valid path

    userInfo = notification.userInfo;
    path = (NSString *)[userInfo objectForKey: fileDroppedKey];
    if (path == nil)
    {
        return;
    }

    // set the selected file to the specificed path

    [self setSelectedFile: path];

    // clear the verification fields and the message file

    [self clearVerifyField];
    [self setMessage: @""];
}

/* actionToggleLowerCaseCheckbox - toggle the lower case checkbox */

-(IBAction)actionToggleLowerCaseCheckbox:(id)sender
{
    prefLowercase = !prefLowercase;

    [hashDefaults setBool: prefLowercase
                   forKey: gPrefLowercase];

    [lowerCaseCheckBox setState: (prefLowercase ?
                                  NSControlStateValueOn :
                                  NSControlStateValueOff)];
}

/* actionToggleShowSizeCheckbox - toggle the show size checkbox */

-(IBAction)actionToggleShowSizeCheckbox:(id)sender
{
    prefShowSize = !prefShowSize;

    [hashDefaults setBool: prefShowSize
                   forKey: gPrefShowSize];

    [showSizeCheckBox setState: (prefShowSize ?
                                NSControlStateValueOn :
                                NSControlStateValueOff)];
}

/* actionToggleAdvancedModeCheckbox - toggle the advanced mode checkbox */

-(IBAction)actionToggleAdvancedModeCheckbox:(id)sender
{
    prefAdvancedMode = !prefAdvancedMode;

    [hashDefaults setBool: prefAdvancedMode
                   forKey: gPrefAdvancedMode];

    [advancedModeCheckBox setState: (prefAdvancedMode ?
                                     NSControlStateValueOff :
                                     NSControlStateValueOn)];
}

/*
    selectedFileEditingFinished - process the selected file when enter is
                                  pressed in the selectedFile text field
                                  (just do the same thing as when the Hash
                                  button is clicked)
    Based on: https://lists.apple.com/archives/Cocoa-dev/2008/Jun/msg02257.html
              https://stackoverflow.com/questions/21285709/whats-the-use-of-the-sent-actions-option-for-an-nstextfield
*/

-(IBAction)selectedFileEditingFinished:(id)sender
{
    [self hashButtonClicked: sender];
}

/*
    hashButtonClicked - handle the Hash button
*/

-(IBAction)hashButtonClicked:(id)sender
{
    [self hashButtonClicked: sender
                     verify: NO];
}

/*
    hashButtonClicked - handle the Hash button
*/

-(IBAction)hashButtonClicked:(id)sender
                      verify:(BOOL)verifyHash
{
    NSString *theFile = nil;
    NSString *verificationHash = nil;
    NSMutableString *hashProgressStr = nil;
    NSFileManager *fileManager = nil;
    NSInteger selectedHash = -1;
    BOOL isDir = NO;
    VerifyHashError verifyErr = VERIFY_HASH_OKAY;
    HashOperation *hashOp = nil;

    // clear the message field and the verification confirmation field

    [self setMessage: @""];
    [self setVerifyConfirm: VERIFY_CLEAR];

    // get the selected file

    theFile = [self selectedFile];
    if (theFile == nil || [theFile isEqualToString: @""])
    {
        [self setErrorMessage: NSLocalizedString(@"HASH_SELECT_FILE",
                                                 @"HASH_SELECT_FILE")];
        return;
    }

    /*
        check to see if the file is exists, is readable, and is not a directory
        Based on: http://www.techotopia.com/index.php/Working_with_Files_in_Objective-C#Checking_if_a_File_is_Readable.2FWritable.2FExecutable.2FDeletable
     */

    fileManager = [NSFileManager defaultManager];
    if (fileManager == nil)
    {
        [self setErrorMessage: NSLocalizedString(@"HASH_CANT_OPEN",
                                                 @"HASH_CANT_OPEN")];
        return;
    }

    if ([fileManager fileExistsAtPath: theFile
                          isDirectory: &isDir] == YES)
    {
        if (isDir == YES)
        {
            [self setErrorMessage: NSLocalizedString(@"HASH_FILE_NOT_DIR",
                                                     @"HASH_FILE_NOT_DIR")];
            return;
        }
    }

    if ([fileManager isReadableFileAtPath: theFile] == FALSE)
    {
        [self setErrorMessage: NSLocalizedString(@"HASH_CANT_READ",
                                                 @"HASH_CANT_READ")];
        return;
    }

    /* get the select hash */

    selectedHash = [self selectedHashType];

    switch ((HashType)selectedHash) {
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
        case HASH_LSH224:
        case HASH_LSH256:
        case HASH_LSH384:
        case HASH_LSH512:
        case HASH_K12_256:
        case HASH_K12_384:
        case HASH_K12_512:

            /*
                valid hash type selected, compute the file's hash and
                display a sheet while the hash is being computed
             */

            /*
                if verification is requested, check to see if a valid
                verification hash was specified
             */

            if (verifyHash == YES)
            {
                verificationHash = [self verifyHash];
                if (verificationHash == nil)
                {
                    [self setErrorMessage: NSLocalizedString(@"HASH_NO_HASH",
                                                             @"HASH_NO_HASH")];
                    return;
                }

                verifyErr = [self isValidHash: (HashType)selectedHash
                                       verify: verificationHash];
                if (verifyErr != VERIFY_HASH_OKAY)
                {
                    switch (verifyErr)
                    {
                        case VERIFY_HASH_TOO_SHORT:
                            [self setErrorMessage:
                                NSLocalizedString(@"HASH_INVALID_HASH_SHORT",
                                                  @"HASH_INVALID_HASH_SHORT")];
                            break;
                        case VERIFY_HASH_TOO_LONG:
                            [self setErrorMessage:
                                NSLocalizedString(@"HASH_INVALID_HASH_LONG",
                                                  @"HASH_INVALID_HASH_LONG")];
                            break;
                        default:
                            [self setErrorMessage:
                                NSLocalizedString(@"HASH_INVALID_HASH",
                                                  @"HASH_INVALID_HASH")];
                            break;
                    }
                    return;
                }
            }
            else
            {

                /*
                    verification was not requested, so clear the
                    verify field
                 */

                [self setVerifyConfirm: VERIFY_CLEAR];
                [verifyHashField setStringValue: @""];
            }

            hashProgressStr =
                [NSMutableString stringWithString: @"Calculating "];

            switch ((HashType)selectedHash)
            {
                case HASH_CKSUM:
                    [hashProgressStr appendString: @"Checksum"];
                    break;
                case HASH_CRC32:
                    [hashProgressStr appendString: @"CRC32"];
                    break;
                case HASH_MD5:
                    [hashProgressStr appendString: @"MD5"];
                    break;
                case HASH_MD6_256:
                    [hashProgressStr appendString: @"MD6 (256)"];
                    break;
                case HASH_MD6_512:
                    [hashProgressStr appendString: @"MD6 (512)"];
                    break;
                case HASH_SHA1:
                    [hashProgressStr appendString: @"SHA1"];
                    break;
                case HASH_SHA1DC:
                    [hashProgressStr appendString:
                         @"SHA1 (with collision detection)"];
                    break;
                case HASH_SHA224:
                    [hashProgressStr appendString: @"SHA224"];
                    break;
                case HASH_SHA256:
                    [hashProgressStr appendString: @"SHA256"];
                    break;
                case HASH_SHA384:
                    [hashProgressStr appendString: @"SHA384"];
                    break;
                case HASH_SHA512:
                    [hashProgressStr appendString: @"SHA512"];
                    break;
                case HASH_SHAKE128:
                    [hashProgressStr appendString: @"SHAKE (128)"];
                   break;
                case HASH_SHAKE256:
                    [hashProgressStr appendString: @"SHAKE (256)"];
                    break;
                case HASH_SHA3_224:
                    [hashProgressStr appendString: @"SHA3 (224)"];
                    break;
                case HASH_SHA3_256:
                    [hashProgressStr appendString: @"SHA3 (256)"];
                    break;
                case HASH_SHA3_384:
                    [hashProgressStr appendString: @"SHA3 (384)"];
                    break;
                case HASH_SHA3_512:
                    [hashProgressStr appendString: @"SHA3 (512)"];
                    break;
                case HASH_RMD160:
                    [hashProgressStr appendString: @"RIPEMD (160)"];
                    break;
                case HASH_RMD320:
                    [hashProgressStr appendString: @"RIPEMD (320)"];
                    break;
                case HASH_WPOOL:
                    [hashProgressStr appendString: @"Whirlpool"];
                    break;
                case HASH_BLAKE2B_256:
                    [hashProgressStr appendString: @"BLAKE2B (256)"];
                    break;
                case HASH_BLAKE2B_512:
                    [hashProgressStr appendString: @"BLAKE2B (512)"];
                    break;
                //case HASH_BLAKE2BP_256:
                //case HASH_BLAKE2BP_512:
                case HASH_BLAKE2S_256:
                    [hashProgressStr appendString: @"BLAKE2S (256)"];
                    break;
                //case HASH_BLAKE2S_512:
                //case HASH_BLAKE2SP_256:
                //case HASH_BLAKE2SP_512:
                case HASH_BLAKE3:
                    [hashProgressStr appendString: @"BLAKE3"];
                    break;
                case HASH_SKEIN_256:
                    [hashProgressStr appendString: @"Skein (256)"];
                    break;
                case HASH_SKEIN_512:
                    [hashProgressStr appendString: @"Skein (512)"];
                    break;
                case HASH_SKEIN_512_256:
                    [hashProgressStr appendString: @"Skein (512/256)"];
                    break;
                case HASH_SKEIN_1024:
                    [hashProgressStr appendString: @"Skein (1024)"];
                    break;
                case HASH_SKEIN_1024_256:
                    [hashProgressStr appendString: @"Skein (1024/256)"];
                    break;
                case HASH_SKEIN_1024_512:
                    [hashProgressStr appendString: @"Skein (1024/512)"];
                    break;
                case HASH_JH_224:
                    [hashProgressStr appendString: @"JH (224)"];
                    break;
                case HASH_JH_256:
                    [hashProgressStr appendString: @"JH (256)"];
                    break;
                case HASH_JH_384:
                    [hashProgressStr appendString: @"JH (384)"];
                    break;
                case HASH_JH_512:
                    [hashProgressStr appendString: @"JH (512)"];
                    break;
                case HASH_TIGER:
                    [hashProgressStr appendString: @"Tiger"];
                    break;
                case HASH_TIGER2:
                    [hashProgressStr appendString: @"Tiger2"];
                    break;
                case HASH_HAS160:
                    [hashProgressStr appendString: @"HAS160"];
                    break;
                case HASH_BLAKE224:
                    [hashProgressStr appendString: @"BLAKE (224)"];
                    break;
                case HASH_BLAKE256:
                    [hashProgressStr appendString: @"BLAKE (256)"];
                    break;
                case HASH_BLAKE384:
                    [hashProgressStr appendString: @"BLAKE (384)"];
                    break;
                case HASH_BLAKE512:
                    [hashProgressStr appendString: @"BLAKE (512)"];
                    break;
                case HASH_GROESTL224:
                    [hashProgressStr appendString: @"Grøstl (224)"];
                    break;
                case HASH_GROESTL256:
                    [hashProgressStr appendString: @"Grøstl (256)"];
                    break;
                case HASH_GROESTL384:
                    [hashProgressStr appendString: @"Grøstl (384)"];
                    break;
                case HASH_GROESTL512:
                    [hashProgressStr appendString: @"Grøstl (512)"];
                    break;
                case HASH_SNEFRU128:
                    [hashProgressStr appendString: @"Snefru (128)"];
                    break;
                case HASH_SNEFRU256:
                    [hashProgressStr appendString: @"Snefru (256)"];
                    break;
                case HASH_LSH224:
                    [hashProgressStr appendString: @"LSH (224)"];
                    break;
                case HASH_LSH256:
                    [hashProgressStr appendString: @"LSH (256)"];
                    break;
                case HASH_LSH384:
                    [hashProgressStr appendString: @"LSH (384)"];
                    break;
                case HASH_LSH512:
                    [hashProgressStr appendString: @"LSH (512)"];
                    break;
                case HASH_K12_256:
                    [hashProgressStr appendString: @"K12 (256)"];
                    break;
                case HASH_K12_384:
                    [hashProgressStr appendString: @"K12 (348)"];
                    break;
                case HASH_K12_512:
                    [hashProgressStr appendString: @"K12 (512)"];
                    break;
                default:
                    [hashProgressStr appendString: @"Hash"];
                    break;
            }

            [hashProgressStr appendString: @" for "];

            [hashProgressStr appendString:
             [fileManager displayNameAtPath: theFile]];

            [hashProgressStr appendString: @"..."];

            [hashProgressMessage setStringValue: hashProgressStr];

            hashOp = [[HashOperation alloc]
                      initWithFileHashTypeAndProgress: theFile
                                                 type: (HashType)selectedHash
                                            lowercase: prefLowercase
                                             progress: hashProgress
                                            requester: self
                                               sender: hashSheet];
            [hashQueue addOperation: hashOp];

            [self showHashSheet: sender];

            break;

        default:

            /* invalid (unknown) hash type was selected */

            [self setErrorMessage:
             NSLocalizedString(@"HASH_INVALID_HASH_TYPE",
                               @"HASH_INVALID_HASH_TYPE")];
            break;
    }
}

/*
    showHashSheet - show a panel while processing a file
    Based on: https://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
 */

-(IBAction)showHashSheet:(id)sender
{
    NSWindow *theWindow = nil;

    // get the main window

    theWindow = [[NSApplication sharedApplication] mainWindow];
    if (theWindow == nil)
    {
        return;
    }

    // (re)enable the cancel button

    [cancelHashButton setEnabled: YES];

    // display the sheet

    [theWindow beginSheet: hashSheet
        completionHandler: nil];
}

/*
    endHashSheet - cancel hash calculation
 */

-(IBAction)endHashSheet:(id)sender
{
    /*
     cancel any pending hash calculation
     Based on: http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues
     */

    if (hashQueue == nil)
    {
        return;
    }

    [hashQueue cancelAllOperations];

    /* reset the progress bar */

    [hashProgress stopAnimation: sender];
    [hashProgress setDoubleValue: 0.0];

    // disable the cancel button

    [cancelHashButton setEnabled: NO];

    // close the sheet

    [NSApp endSheet: hashSheet];
    [hashSheet orderOut:sender];
}

/*
    hashComplete - call back for when the hash calculation is finished
*/

-(void)hashComplete:(NSDictionary *)dict
{
    NSString *verifyHash = nil;
    NSString *hashResult = nil;
    NSString *fileSize = nil;
    NSWindow *sender = nil;
    NSMutableString *resultString = nil;

    /*
        if the dictionary is nil or contains no elements,
        some problem occured while calculating the hash
     */

    if (dict == nil)
    {
        return;
    }

    if ([dict count] == 0)
    {
        return;
    }

    do {

        /* couldn't calculate the hash, set an error message and return */

        hashResult = [dict objectForKey: keyHashResult];
        if (hashResult == nil)
        {
            [self setErrorMessage: NSLocalizedString(@"HASH_CANT_GET_HASH",
                                                     @"HASH_CANT_GET_HASH")];
            break;
        }

        /*
            display the calculated hash with the file's size
            (when requested through the prefs)
         */

        resultString = [NSMutableString stringWithString: hashResult];
        if (resultString != nil)
        {
            if (prefShowSize == TRUE)
            {
                fileSize = [dict objectForKey: keyFileSize];
                if (fileSize != nil)
                {
                    [resultString appendFormat: @" (%@ B)", fileSize];
                }
            }

            [self setMessage: resultString
                     comment: nil
                       error: NO
                   monospace: YES];
        }
        else
        {
            [self setMessage: hashResult
                     comment: nil
                       error: NO
                   monospace: YES];
        }

        /*
            if verification was requested, verify if the hash matches the
            specified verification hash; use a case insensitive search in
            case the user specified uppercase letters
            Based on: http://stackoverflow.com/questions/2582306/case-insensitive-comparison-nsstring
            https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Strings/Articles/SearchingStrings.html
         */

        verifyHash = [self verifyHash];
        if (verifyHash != nil)
        {
            if ([hashResult compare:verifyHash
                            options:NSCaseInsensitiveSearch] ==
                NSOrderedSame)
            {
                [self setVerifyConfirm: VERIFY_SUCCESS];
            }
            else
            {
                [self setVerifyConfirm: VERIFY_FAILED];
            }
        }
    } while (FALSE);

    /* close the hashSheet */

    sender = [dict objectForKey: keySender];
    if (sender != nil)
    {
        [NSApp endSheet: hashSheet];
        [hashSheet orderOut:sender];
    }
}

/*
    clearButtonClicked - clear the file and verify fields
*/

-(IBAction)clearButtonClicked:(id)sender
{
    [self clearFileFieldButtonClicked: sender];
    [self clearVerifyFieldButtonClicked: sender];
    [self setMessage: @""];
}

/*
    clearMenuClicked - clear the file and verify fields
*/

-(IBAction)clearMenuClicked:(id)sender
{
    [self clearButtonClicked: sender];
}

/*
    clearFileButtonClicked - clear the file field
*/

-(IBAction)clearFileFieldButtonClicked:(id)sender
{
    [self setSelectedFile: @""];
}

/*
    clearVerifyFieldButtonClicked - clear the verify field
*/

-(IBAction)clearVerifyFieldButtonClicked:(id)sender
{
    [self clearVerifyField];
}

/*
    clearVerifyField - clear the verify field
*/

-(void)clearVerifyField
{
    [self setVerifyConfirm: VERIFY_CLEAR];
    [verifyHashField setStringValue: @""];
}

/*
    showAboutSheet - show a panel with information about this application
    Based on: https://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
              http://www.macdevcenter.com/pub/a/mac/2002/06/14/cocoa.html?page=2
              http://cocoadevcentral.com/articles/000071.php
              http://www.cocoabuilder.com/archive/cocoa/211734-trying-to-display-static-image-on-my-window-any-tips-would-be-great.html

 */

-(IBAction)showAboutSheet:(id)sender
{
    NSWindow *theWindow = nil;
    NSDictionary *infoDictionary = nil;
    NSMutableString *tmpAppNameStr = nil;
    NSString *appName = nil;
    NSString *appVers = nil;
    NSString *appBuild = nil;

    /* get the main window */

    theWindow = [[NSApplication sharedApplication] mainWindow];
    if (theWindow == nil)
    {
        return;
    }

    /*
        inset the about text by 25 pixel in width and 5 pixels in height
        Based on: http://www.cocoabuilder.com/archive/cocoa/173150-nstextview-settextcontainerinset-issues.html
     */

    [aboutText setTextContainerInset:NSMakeSize(25, 5)];

    if (appNameStr == nil)
    {
        infoDictionary = [[NSBundle mainBundle] infoDictionary];
        if (infoDictionary != nil)
        {

            /*
                Set the name and version of the application in the about box
                Based on: http://iosdevelopertips.com/cocoa/get-application-name.html
                          https://developer.apple.com/library/ios/documentation/general/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW1
             */

            appName = [infoDictionary objectForKey: @"CFBundleName"];
            if (appName == nil)
            {
                appName = defaultHashAppName;
            }

            appVers = [infoDictionary objectForKey:
                                      @"CFBundleShortVersionString"];
            if (appVers == nil)
            {
                appVers = defaultHashAppVers;
            }

            appBuild = [infoDictionary objectForKey: @"CFBundleVersion"];
            if (appBuild == nil)
            {
                appBuild = defaultHashAppBuild;
            }
        }
        else
        {
            appName = defaultHashAppName;
            appVers = defaultHashAppVers;
            appBuild = defaultHashAppBuild;
        }

        tmpAppNameStr = [NSMutableString stringWithCapacity: 20];
        [tmpAppNameStr appendFormat:@"%@ %@ (%@)",
                                        appName,
                                        appVers,
                                        appBuild];
        appNameStr = [NSString stringWithString: tmpAppNameStr];
    }

    [appNameField setStringValue: appNameStr];

    [theWindow beginSheet: aboutSheet
        completionHandler: nil];
}

/*
    endAboutSheet - close panel with information about this application
    Based on: https://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
 */

-(IBAction)endAboutSheet:(id)sender
{
    [NSApp endSheet: aboutSheet];
    [aboutSheet orderOut:sender];
}

/*
    showPrefSheet - show a panel to set preferences
    Based on: https://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
              http://www.macdevcenter.com/pub/a/mac/2002/06/14/cocoa.html?page=2
              http://cocoadevcentral.com/articles/000071.php
              http://www.cocoabuilder.com/archive/cocoa/211734-trying-to-display-static-image-on-my-window-any-tips-would-be-great.html

 */

-(IBAction)showPrefSheet:(id)sender
{
    NSWindow *theWindow = nil;

    /* get the main window */

    theWindow = [[NSApplication sharedApplication] mainWindow];
    if (theWindow == nil)
    {
        return;
    }

    [lowerCaseCheckBox setState: (prefLowercase ?
                                  NSControlStateValueOn :
                                  NSControlStateValueOff)];

    [showSizeCheckBox setState: (prefShowSize ?
                                 NSControlStateValueOn :
                                 NSControlStateValueOff)];

    [advancedModeCheckBox setState: (prefAdvancedMode ?
                                     NSControlStateValueOff :
                                     NSControlStateValueOn)];

    [theWindow beginSheet: prefSheet
        completionHandler: nil];
}

/*
    endPrefSheet - close the prefernce panel
    Based on: https://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
 */

-(IBAction)endPrefSheet:(id)sender
{
    if (prefAdvancedMode == YES)
    {
        [self enableAdvancedMode];
    }
    else
    {
        [self disableAdvancedMode];
    }

    [NSApp endSheet: prefSheet];
    [prefSheet orderOut:sender];
}

/*
    selectFile - Create panel to select a file

    Based on: https://stackoverflow.com/questions/6924186/how-do-i-create-an-open-file-dialog-in-a-xcode-cocoa-project
*/

-(void)selectFile: (NSWindow *) window
{
    NSWindow *theWindow = nil;

    /* get the main window */

    theWindow = [[NSApplication sharedApplication] mainWindow];
    if (theWindow == nil)
    {
        return;
    }

    if (selectFilePanel == nil)
    {
        selectFilePanel = [NSOpenPanel openPanel];
        if (selectFilePanel == nil)
        {
            return;
        }
        [selectFilePanel setCanChooseFiles: YES];
        [selectFilePanel setCanChooseDirectories: NO];
        [selectFilePanel setAllowsMultipleSelection: NO];
        [selectFilePanel setShowsHiddenFiles: YES];
        [selectFilePanel setShowsResizeIndicator: YES];
        [selectFilePanel setTreatsFilePackagesAsDirectories: YES];
    }

    [selectFilePanel beginSheetModalForWindow: theWindow
                          completionHandler:^(NSInteger result)
     {
         NSURL *selection = NULL;
         NSString *path = NULL;

         if (result == NSModalResponseOK) {
             selection = self->selectFilePanel.URLs[0];
             if (selection != nil) {
                 path = [[selection path] stringByResolvingSymlinksInPath];
                 [self setSelectedFile:path];
             }
         }
     }];
}

/*
    selectFileButtonClicked - handle the Select File button
*/

-(IBAction)selectFileButtonClicked:(id)sender
{
    [self selectFile: [sender window]];
}

/*
    selectFileMenuClicked - handle the Select File menu item
*/

-(IBAction)selectFileMenuClicked:(id)sender
{
    [self selectFile: nil];
}

/*
    verifyButtonClicked - handle the Verify button
*/

-(IBAction)verifyButtonCLicked:(id)sender
{
    [self hashButtonClicked: sender
                     verify: YES];
}

/*
    selectedHashType - return the currently selected hash type
    or HASH_NONE on error
*/

-(NSInteger)selectedHashType
{
    NSInteger hashType = HASH_NONE;

    hashType = [[(NSPopUpButton *)selectedHashPopUp selectedItem] tag];

    switch (hashType)
    {
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
        case HASH_LSH224:
        case HASH_LSH256:
        case HASH_LSH384:
        case HASH_LSH512:
        case HASH_K12_256:
        case HASH_K12_384:
        case HASH_K12_512:

            /* valid hashType, return it */

            break;

        default:

            /* unknown hashType, return HASH_NONE to signal an error */

            hashType = HASH_NONE;
            break;
    }

    return hashType;
}

/*
    selectedFile - return the currently selected file
*/

-(NSString *)selectedFile
{
    NSString *theFile = nil;
    NSString *theFileTildeExpanded = nil;
    NSString *trimmedFile = nil;

    theFile = [selectedFileField stringValue];
    if (theFile == nil)
    {
        return nil;
    }

    /*
        Remove any whitespace from the beginning and end of the filename
        Based on: http://www.cocoanetics.com/2009/01/remove-whitespace-from-nsstring/
     */

    trimmedFile = [theFile stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedFile == nil || [trimmedFile isEqualToString: @""])
    {
        return nil;
    }

    /* tilde expand the file name */

    theFileTildeExpanded = [theFile stringByExpandingTildeInPath];
    if (theFileTildeExpanded == nil)
    {
        return nil;
    }

    /* resolve any symlinks in the file name */

    return [theFileTildeExpanded stringByResolvingSymlinksInPath];
}

/*
    setSelectedFile - set the currently selected file
*/

-(void)setSelectedFile:(NSString *)file
{
    if (file == nil)
    {
        return;
    }

    /* set the selectedFileField's value to the specific file */

    [selectedFileField setStringValue: file];

    /*
        Add the specified file to the open recent  menu:
        Based on: http://www.cocoabuilder.com/archive/cocoa/116272-open-recent-menu.html
     */

    [[NSDocumentController sharedDocumentController]
     noteNewRecentDocumentURL:[NSURL fileURLWithPath: file]];
}

/*
    setMessage - set the text for the message field and mark it in red
                 to signify an error
*/

-(void)setErrorMessage:(NSString *)message
               comment:(NSString *)comment
{
    [self setMessage: message
             comment: comment
               error: TRUE];
}

/*
    setMessage - set the text for the message field and mark it in red
                 to signify an error
*/

-(void)setErrorMessage:(NSString *)message
{
    [self setErrorMessage: message
                  comment: nil];
}

/*
    setMessage - set the text for the message field
*/

-(void)setMessage:(NSString *)message
{
    [self setMessage: message
               error: FALSE];
}

/*
    setMessage - set the text for the message field, using a flag for
                 error messages
*/

-(void)setMessage:(NSString *)message
            error:(BOOL)isErrorMessage
{
    [self setMessage: message
             comment: nil
               error: isErrorMessage];
}

/*
    setMessage - set the text for the message field, using a flag for
                 error messages
*/

-(void)setMessage:(NSString *)message
          comment:(NSString *)comment
            error:(BOOL)isErrorMessage
{
    [self setMessage: message
             comment: comment
               error: isErrorMessage
           monospace: NO];
}

/*
    setMessage - set the text for the message field, using a flag for
                 error messages
*/

-(void)setMessage:(NSString *)message
          comment:(NSString *)comment
            error:(BOOL)isErrorMessage
        monospace:(BOOL)makeTextMonoSpace
{

    // by default, disable copying of text from the messageField

    [messageField setEnabled: FALSE];
    [messageField setSelectable: FALSE];

    /*
        set the font back to the default size
        based on: https://stackoverflow.com/questions/1100903/how-to-customize-nstextfield-look-font-used-font-size-in-cocoa#1100949
     */

    [messageField setFont: [NSFont systemFontOfSize:0]];

    if (message != nil)
    {

        /*
            if this is a error message, set the text color to system's
            current accessibility / mode equivalent of red:
            https://developer.apple.com/documentation/appkit/nscolor/2879262-systemred
         */

        if (isErrorMessage == YES)
        {
            [messageField setTextColor: [NSColor systemRedColor]];
        }
        else
        {

            /*
                this is not an error message, so enable copying of text
                from the messageField and set the text color to the system's
                label color:
                https://developer.apple.com/documentation/appkit/nscolor/1534657-labelcolor
             */

            [messageField setEnabled: TRUE];
            [messageField setSelectable: TRUE];
            [messageField setTextColor: [NSColor labelColor]];

            /*
                if monospaced text is requested, set the font to
                the system's fixed ptich font

                based on: https://stackoverflow.com/questions/1100903/how-to-customize-nstextfield-look-font-used-font-size-in-cocoa#1100949
             */

            if (makeTextMonoSpace)
            {
                [messageField setFont:[NSFont userFixedPitchFontOfSize:0]];
            }
        }

        /* if a comment is specified, look up the localized message */

        if (comment != nil)
        {
            [messageField setStringValue: NSLocalizedString(message,
                                                            comment)];
        }
        else
        {
            [messageField setStringValue:message];
        }
    }
}

/*
    verifyHash - return the hash to verify against (if one is specified)
*/

-(NSString *)verifyHash
{
    NSString *theVerifyHash = nil;
    NSString *trimmedVerifyHash = nil;

    theVerifyHash = [verifyHashField stringValue];
    if (theVerifyHash == nil)
    {
        return nil;
    }

    /*
        Remove any whitespace from the hash
        Based on: http://www.cocoanetics.com/2009/01/remove-whitespace-from-nsstring/
                  http://stackoverflow.com/questions/925780/remove-characters-from-nsstring
    */

    trimmedVerifyHash =
        [[theVerifyHash componentsSeparatedByCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    if (trimmedVerifyHash == nil ||
        [trimmedVerifyHash isEqualToString: @""])
    {
        return nil;
    }

    [verifyHashField setStringValue: trimmedVerifyHash];

    return trimmedVerifyHash;
}

/*
    isValidHash - verify whether the specified hash is valid
*/

-(VerifyHashError)isValidHash: (HashType)type
                       verify: (NSString *)hash
{
    NSRegularExpression *regex = nil;
    NSError *error = nil;
    NSUInteger matches = 0;
    size_t digestLength = 0;
    size_t verifyLength = 0;

    if (hash == nil)
    {
        return VERIFY_HASH_INVALID;
    }

    verifyLength = [hash length];

    if (verifyLength == 0)
    {
        return VERIFY_HASH_TOO_SHORT;
    }

    /*
        Use a regular expression to verify that only hex digits and letters
        are present in the specified hash string.
        Based on: http://sketchytech.blogspot.com/2012/04/finding-text-in-xcode-nsscanner-and.html
     */

    regex = [NSRegularExpression
             regularExpressionWithPattern: @"^[0-9a-f]+$"
                                  options: NSRegularExpressionCaseInsensitive
                                    error:  &error];
    if (regex == nil || error != nil)
    {
        return VERIFY_HASH_INVALID;
    }

    matches = [regex numberOfMatchesInString: hash
                                     options: 0
                                       range: NSMakeRange(0, [hash length])];
    if (matches != 1)
    {
        return VERIFY_HASH_INVALID;
    }

    /* make sure the specified hash has the right length */

    switch (type)
    {
        case HASH_CKSUM:
            digestLength = 1;
            break;
        case HASH_CRC32:
            digestLength = 1;
            break;
        case HASH_MD5:
            digestLength = CC_MD5_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_SHA1:
        case HASH_SHA1DC:
            digestLength = CC_SHA1_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_TIGER:
        case HASH_TIGER2:
            digestLength = tiger_hash_length*sizeof(unsigned char);
            break;
        case HASH_SHA224:
        case HASH_SHA3_224:
        case HASH_JH_224:
        case HASH_BLAKE224:
        case HASH_GROESTL224:
        case HASH_LSH224:
            digestLength = CC_SHA224_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_MD6_256:
        case HASH_SHA256:
        case HASH_SHAKE128:
        case HASH_SHA3_256:
        case HASH_BLAKE2B_256:
        case HASH_BLAKE2BP_256:
        case HASH_BLAKE2S_256:
        case HASH_BLAKE2SP_256:
        case HASH_SKEIN_256:
        case HASH_SKEIN_512_256:
        case HASH_SKEIN_1024_256:
        case HASH_JH_256:
        case HASH_BLAKE256:
        case HASH_BLAKE3:
        case HASH_GROESTL256:
        case HASH_LSH256:
        case HASH_K12_256:
            digestLength = CC_SHA256_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_SHA384:
        case HASH_SHA3_384:
        case HASH_JH_384:
        case HASH_BLAKE384:
        case HASH_GROESTL384:
        case HASH_LSH384:
        case HASH_K12_384:
            digestLength = CC_SHA384_DIGEST_LENGTH*sizeof(unsigned char);
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
        case HASH_LSH512:
        case HASH_K12_512:
            digestLength = CC_SHA512_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_SKEIN_1024:
            digestLength = 2*(CC_SHA512_DIGEST_LENGTH*sizeof(unsigned char));
            break;
        case HASH_RMD160:
            digestLength = RMD160_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_RMD320:
            digestLength = 2*(RMD160_DIGEST_LENGTH*sizeof(unsigned char));
            break;
        case HASH_WPOOL:
            digestLength = NESSIE_DIGEST_LENGTH*sizeof(unsigned char);
            break;
        case HASH_HAS160:
            digestLength = has160_hash_size*sizeof(unsigned char);
            break;
        case HASH_SNEFRU128:
            digestLength = snefru128_hash_length*sizeof(unsigned char);
            break;
        case HASH_SNEFRU256:
            digestLength = snefru256_hash_length*sizeof(unsigned char);
            break;
        default:
            digestLength = 0;
            break;
    }

    digestLength *= 2;

    if (verifyLength < digestLength)
    {
        return VERIFY_HASH_TOO_SHORT;
    }

    if (verifyLength > digestLength)
    {
        return VERIFY_HASH_TOO_LONG;
    }

    return VERIFY_HASH_OKAY;
}

/*
    setVerifyConfirm - set the value of the confirmation verification field
*/

-(void)setVerifyConfirm:(VerifyMessageType)verified
{
    [verifyConfirmField setEnabled: FALSE];
    [verifyConfirmField setSelectable: FALSE];
    [verifyConfirmField setTextColor: [NSColor labelColor]];

    switch (verified)
    {
        case VERIFY_SUCCESS:
            [verifyConfirmField setTextColor: [NSColor systemGreenColor]];
            [verifyConfirmField setStringValue: @"✔︎"];
            break;
        case VERIFY_FAILED:
            [verifyConfirmField setTextColor: [NSColor systemRedColor]];
            [verifyConfirmField setStringValue: @"✘"];
            break;
        case VERIFY_CLEAR:
            [verifyConfirmField setStringValue: @""];
            break;
    }
}

-(void)disableAdvancedMode
{
    NSInteger numItems = 0, i = 0, tag = 0, selected = 0;

    numItems = [selectedHashPopUp numberOfItems];
    if (numItems <= 0)
    {
        return;
    }

    /* get the currently selected hash */

    selected = [[(NSPopUpButton *)selectedHashPopUp selectedItem] tag];

    /*
        go through each item in the hash menu and deactive all but
        MD5, SHA1, SHA 256, SHA 512, RipeMD 160, and BLAKE3
     */

    for (i = 0; i < numItems; i++)
    {
        tag = [[(NSPopUpButton *)selectedHashPopUp itemAtIndex: i] tag];
        switch (tag)
        {
            case HASH_MD5:
            case HASH_SHA1:
            case HASH_SHA256:
            case HASH_SHA512:
            case HASH_RMD160:
            case HASH_BLAKE3:

                break;

            default:

                /* disable this menu item for simple mode */

                [[(NSPopUpButton *)selectedHashPopUp itemAtIndex: i]
                 setHidden: YES];

                /*
                    if we are disabling this item, switch the selected
                    hash to the default hash (SHA1)
                 */

                if (tag == selected)
                {
                    [(NSPopUpButton *)selectedHashPopUp
                     selectItemWithTag: gDefaultHash];
                }

                break;
        }
    }
}

-(void)enableAdvancedMode
{
    NSInteger numItems = 0, i = 0;

    numItems = [selectedHashPopUp numberOfItems];
    if (numItems <= 0)
    {
        return;
    }

    /* enable each item in the hash menu */

    for (i = 0; i < numItems; i++)
    {
        [[(NSPopUpButton *)selectedHashPopUp itemAtIndex: i]
         setHidden: NO];
    }
}

@end
