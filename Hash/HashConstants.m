/* 
    Hash - HashConstants.m
    $Id: HashConstants.m 1399 2015-04-27 07:23:23Z ranga $
 
    History:
 
    v. 1.0.0 (10/20/2014) - Initial version
    v. 1.0.1 (04/17/2014) - Update to allow background processing of hashes

    Based on: https://stackoverflow.com/questions/538996/constants-in-objective-c
 
    Copyright (c) 2014 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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

#import "HashConstants.h"

NSString *const fileDroppedEvent = @"fileDroppedEvent";
NSString *const fileDroppedKey = @"droppedFile";
NSString *const defaultHashAppName = @"Hash";
NSString *const defaultHashAppVers = @"1.0";
NSString *const defaultHashAppBuild = @"1";
NSString *const keyHashResult = @"hashResult";
NSString *const keySender = @"sender";