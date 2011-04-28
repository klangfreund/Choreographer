//
//  Path.h
//  Choreographer
//
//  Created by Philippe Kocher on 23.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Path : NSObject
{
}

+ (NSString *)path:(NSURL *)path relativeTo:(NSURL *)base;
@end
