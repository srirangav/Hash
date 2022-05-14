/* 
    Hash - HashConstants.h
    $Id: HashConstants.h 1399 2015-04-27 07:23:23Z ranga $
 
    History:
 
    v. 1.0.0 (10/20/2014) - Initial version
    v. 1.0.1 (04/17/2014) - Update to allow background processing of hashes
    v. 1.0.2 (10/24/2021) - Add support for showing the file size

    Based on: https://stackoverflow.com/questions/538996/constants-in-objective-c

    Copyright (c) 2014, 2021 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
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

#ifndef HashConstants_h
#define HashConstants_h

FOUNDATION_EXPORT NSString *const fileDroppedEvent;
FOUNDATION_EXPORT NSString *const fileDroppedKey;
FOUNDATION_EXPORT NSString *const defaultHashAppName;
FOUNDATION_EXPORT NSString *const defaultHashAppVers;
FOUNDATION_EXPORT NSString *const defaultHashAppBuild;
FOUNDATION_EXPORT NSString *const keyHashResult;
FOUNDATION_EXPORT NSString *const keySender;
FOUNDATION_EXPORT NSString *const keyFileSize;
FOUNDATION_EXPORT NSString *const outputLowerCase;

#endif /* HashConstants_h */
