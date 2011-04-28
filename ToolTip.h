//
//  ToolTip.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.10.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ToolTipTextField : NSTextField
{
}
@end

@interface ToolTip : NSObject
{
    NSWindow                *window;
    NSTextField             *textField;
    NSDictionary            *textAttributes;
	
	id eventMonitor;
	NSEvent *event;
}

+ (id)sharedToolTip;
+ (void)release;
- (void)setString:(NSString *)string inView:(NSView *)view;

@end