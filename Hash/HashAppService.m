/*
    Hash - HashAppService.m

    History:
 
    v. 1.0.0 (08/13/2019) - Initial version
 
    Copyright (c) 2019 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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
#import "HashAppService.h"
#import "HashConstants.h"

@implementation HashAppService

- (void)hashSelectedFile: (NSPasteboard *)pboard
                userData: (NSString *)userData
                   error: (NSString **)error
{
    /*
        Implement the service method.  See:

    https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/providing.html#//apple_ref/doc/uid/20000853-98262
   
    https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/properties.html#//apple_ref/doc/uid/20000852-CHDJDFIC
    https://stackoverflow.com/questions/41442474/how-to-register-service-from-app-in-macos-application
    
    https://stackoverflow.com/questions/9430216/unable-to-add-item-in-finders-contextual-menu-using-services-in-cocoa/9472723?r=SearchResults#9472723
     
     */
    
    NSPropertyListFormat format;
    NSString *errorDesc = nil;
    NSData *pboardData = nil;
    NSDictionary *files = nil;
    NSDictionary *fileInfo = nil;
    NSString *key = nil;
    
    if (pboard == nil)
    {
        return;
    }
    
    /* get filename data from the pasteboard */
    
    pboardData = [pboard dataForType: NSFilenamesPboardType];
    if (pboardData == nil)
    {
        return;
    }


    /*
        Convert the pasteboard data into a dictionary, where each
        key will be a file name selected in the finder.  See:
     
    https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/QuickStartPlist/QuickStartPlist.html#//apple_ref/doc/uid/10000048i-CH4-SW6
     */
    
    files =
        (NSDictionary *)[NSPropertyListSerialization
                         propertyListFromData: pboardData
                             mutabilityOption: NSPropertyListImmutable
//                             NSPropertyListMutableContainersAndLeaves
                                       format: &format
                             errorDescription: &errorDesc];
    if (files == nil)
    {
        return;
    }

    /*
        Process the first key by sending HashAppController a file
        dropped message (same as if a file was dropped onto the
        icon).  If multiple files are selected in the finder,
        there may be more than one key, but we skip those
     */
    
    for (key in files)
    {
        if (key == nil)
        {
            continue;
        }
        fileInfo = @{fileDroppedKey: key};
        [[NSNotificationCenter defaultCenter]
            postNotificationName: fileDroppedEvent
                          object: self
                        userInfo: fileInfo];
        break;
    }
}

@end
