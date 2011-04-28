//
//  SelectionRectangle.m
//  Choreographer
//
//  Created by Philippe Kocher on 07.12.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SelectionRectangle.h"

static SelectionRectangle	*sharedSelectionRectangle = nil;

@implementation SelectionRectangle

+ (id)sharedSelectionRectangle;
{
    if (!sharedSelectionRectangle)
	{
        sharedSelectionRectangle = [[SelectionRectangle alloc] init];
    }
	return sharedSelectionRectangle;
}

+ (void)release
{
    [sharedSelectionRectangle removeFromSuperview];
    [sharedSelectionRectangle release];
    sharedSelectionRectangle = nil;
}

- (void)drawRect:(NSRect)rect
{    
	NSColor *selectionFrameColor	= [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 0.2 alpha: 0.6];
	NSColor *selectionFillColor		= [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.1];
	
	[selectionFillColor set];
	NSRectFillUsingOperation([self bounds], 2);
	[selectionFrameColor set];
	[NSBezierPath strokeRect:[self bounds]];
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)addRectangleWithOrigin:(NSPoint)pt forView:(NSView *)view
{
	if(![self superview])
	{
		[view addSubview:sharedSelectionRectangle positioned: NSWindowAbove relativeTo:nil];	
	}
	
	selectionRectStart = pt;
	selectionRectEnd = pt;
}

- (void)setCurrentMousePosition:(NSPoint)pt
{
	selectionRectEnd = pt;

	float selectionWidth = abs(selectionRectEnd.x - selectionRectStart.x);
	float selectionHeight = abs(selectionRectEnd.y - selectionRectStart.y);
	float selectionStartX = selectionRectStart.x < selectionRectEnd.x ? selectionRectStart.x : selectionRectEnd.x;
	float selectionStartY = selectionRectStart.y < selectionRectEnd.y ? selectionRectStart.y : selectionRectEnd.y;

	[self setFrame:NSMakeRect(selectionStartX, selectionStartY, selectionWidth, selectionHeight)];

	[self setNeedsDisplay:YES];
}

@end