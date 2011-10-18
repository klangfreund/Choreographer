//
//  SelectionRectangle.h
//  Choreographer
//
//  Created by Philippe Kocher on 07.12.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SelectionRectangle : NSView
{
	NSPoint selectionRectStart, selectionRectEnd;
}

+ (id)sharedSelectionRectangle;
+ (void)release;
- (void)addRectangleWithOrigin:(NSPoint)pt forView:(NSView *)view;
- (void)setCurrentMousePosition:(NSPoint)pt;
- (void)setCurrentMouseDelta:(NSPoint)delta;

@end