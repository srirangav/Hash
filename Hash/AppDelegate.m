/*
    Hash - AppDelegate.m
    $Id: AppDelegate.m 1399 2015-04-27 07:23:23Z ranga $
 
    History:
 
    v. 1.0.0 (10/20/2014) - Initial version
    v. 1.0.1 (08/13/2019) - Add support for finder service
 
    Copyright (c) 2014, 2019 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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

#import "AppDelegate.h"
#import "HashConstants.h"

@interface AppDelegate ()

/* 
    NOTE: Changed @property (weak) to @property (unsafe_unretained) below 
          to build for 10.6; auto-layout also removed for xibs to build for
          10.6
    Based on: https://stackoverflow.com/questions/7761901/iphone-4-ios5-core-plot-and-arc-errorthe-current-deployment-target-does-not-su
              https://stackoverflow.com/questions/9566789/remove-autolayout-constraints-in-interface-builder 
*/

@property (unsafe_unretained) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /*
        Register the Hash finder service.  See:
    https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/providing.html#//apple_ref/doc/uid/20000853-98488
    https://stackoverflow.com/questions/41442474/how-to-register-service-from-app-in-macos-application
     */
    
    service = [[HashAppService alloc] init];
    [NSApp setServicesProvider: service];
    NSUpdateDynamicServices();
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

/*
    Quit when main window is closes
    Based on: https://stackoverflow.com/questions/5268757/how-to-quit-cocoa-app-when-windows-close
 */

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return TRUE;
}

/*
    Open a file that is dragged onto the application's icon
    Based on: http://www.cocoabuilder.com/archive/cocoa/89704-drag-and-drop-to-the-app-dock-icon.html
              http://www.cocoabuilder.com/archive/cocoa/225428-accepting-ical-events-dropped-on-my-application-icon.html
              https://stackoverflow.com/questions/7896646/how-to-pass-object-with-nsnotificationcenter
 */

-(BOOL)application: (NSApplication *)theApplication
          openFile: (NSString *)path
{
    NSDictionary* fileInfo = nil;

    // if no path was specified, there is nothing to do
    
    if (path == nil) {
        return FALSE;
    }
    
    // post a fileDroppedEvent (HashAppController will receive & handle it)
    
    fileInfo = @{fileDroppedKey: path};
    [[NSNotificationCenter defaultCenter] postNotificationName: fileDroppedEvent
                                                        object: self
                                                      userInfo: fileInfo];
    return TRUE;
}

@end
