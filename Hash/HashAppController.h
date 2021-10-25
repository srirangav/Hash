/* 
    Hash - HashAppController.h
    $Id: HashAppController.h 1402 2015-04-28 16:33:22Z ranga $
 
    History:
 
    v. 1.0.0 (10/20/2014) - Initial version
    v. 1.0.1 (04/17/2014) - Update to allow background processing of hashes
    v. 1.0.2 (04/27/2015) - Add progress bar support
    v. 1.0.3 (08/13/2019) - Add method to clear verification fields
    v. 1.0.4 (11/12/2020) - Add support for checking if a verification hash
                            is the correct length
    v. 1.0.5 (05/22/2021) - Add preference pane
    v. 1.0.6 (10/24/2021) - Add support for showing the file size
 
    Copyright (c) 2014-2021 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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

#import "HashOperation.h"

// Verification Message Types

typedef enum {
    VERIFY_FAILED  = 0,
    VERIFY_SUCCESS = 1,
    VERIFY_CLEAR   = 2,
} VerifyMessageType;

// Verification Hash Error Types

typedef enum {
    VERIFY_HASH_OKAY      = 0,
    VERIFY_HASH_TOO_SHORT = 1,
    VERIFY_HASH_TOO_LONG  = 2,
    VERIFY_HASH_INVALID   = 3,
} VerifyHashError;

@interface HashAppController : NSObject
{
    IBOutlet id selectedFileField;
    IBOutlet id messageField;
    IBOutlet id verifyConfirmField;
    IBOutlet id selectedHashPopUp;
    IBOutlet id verifyHashField;
    IBOutlet id appNameField;
    IBOutlet id cancelHashButton;
    IBOutlet id clearFileFieldButton;
    IBOutlet id clearVerifyFieldButton;
    IBOutlet id aboutText;
    IBOutlet id lowerCaseCheckBox;
    IBOutlet id showSizeCheckBox;
    IBOutlet id hashProgressMessage;
    IBOutlet NSProgressIndicator *hashProgress;
    IBOutlet NSPanel *hashSheet;
    IBOutlet NSPanel *aboutSheet;
    IBOutlet NSPanel *prefSheet;
    NSOpenPanel *selectFilePanel;
    NSString *appNameStr;
    NSOperationQueue *hashQueue;
    BOOL prefLowercase;
    BOOL prefShowSize;
    NSUserDefaults *hashDefaults;
}

-(IBAction)hashButtonClicked:(id)sender;

-(IBAction)selectFileButtonClicked:(id)sender;

-(IBAction)selectFileMenuClicked:(id)sender;

-(IBAction)clearButtonClicked:(id)sender;

-(IBAction)clearMenuClicked:(id)sender;

-(IBAction)clearFileFieldButtonClicked:(id)sender;

-(IBAction)clearVerifyFieldButtonClicked:(id)sender;

-(void)clearVerifyField;

-(IBAction)selectedFileEditingFinished:(id)sender;

-(IBAction)verifyButtonCLicked:(id)sender;

-(IBAction)showAboutSheet:(id)sender;

-(IBAction)endAboutSheet:(id)sender;

-(IBAction)showHashSheet:(id)sender;

-(IBAction)endHashSheet:(id)sender;

-(IBAction)showPrefSheet:(id)sender;

-(IBAction)endPrefSheet:(id)sender;

-(IBAction)actionToggleLowerCaseCheckbox:(id)sender;

-(IBAction)actionToggleShowSizeCheckbox:(id)sender;

-(void)hashComplete:(NSDictionary *)dict;

-(NSString *)verifyHash;

-(VerifyHashError)isValidHash: (HashType)type
                       verify: (NSString *)hash;

-(NSInteger)selectedHashType;

-(NSString *)selectedFile;

-(void)setSelectedFile:(NSString *)file;

-(void)setVerifyConfirm:(VerifyMessageType)verified;

-(void)setErrorMessage:(NSString *)message;

-(void)setErrorMessage:(NSString *)message
               comment:(NSString *)comment;

-(void)setMessage:(NSString *)message;

-(void)setMessage:(NSString *)message
            error:(BOOL)isErrorMessage;

-(void)setMessage:(NSString *)message
          comment:(NSString *)comment
            error:(BOOL)isErrorMessage;

-(void)setMessage:(NSString *)message
          comment:(NSString *)comment
            error:(BOOL)isErrorMessage
        monospace:(BOOL)makeTextMonoSpace;

@end
