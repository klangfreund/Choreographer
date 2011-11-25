//
//  RulerPlayhead.m
//  Choreographer
//
//  Created by Philippe Kocher on 06.08.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "RulerPlayhead.h"
#import "CHProjectDocument.h"
#import "PlaybackController.h"

@implementation RulerPlayhead
@synthesize inDraggingSession;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{

    	inDraggingSession = NO;
	}
    return self;
}

- (void)drawRect:(NSRect)rect
{
	// cursor
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[[NSColor whiteColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(6, 0) toPoint:NSMakePoint(6, rect.size.height - 1)];

    // triangle
    NSPoint p1 = NSMakePoint(6, 6);
    NSPoint p2 = NSMakePoint(0, 11);
    NSPoint p3 = NSMakePoint(12, 11);

    NSBezierPath *triangle = [NSBezierPath bezierPath];
    [triangle moveToPoint:p1];
    [triangle lineToPoint:p2];
    [triangle lineToPoint:p3];
    [triangle lineToPoint:p1];

	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
    [[NSColor blackColor] set];
    [triangle stroke];
    [[NSColor redColor] set];
	[triangle fill];
}


- (void)resetCursorRects
{
	NSRect r = [self bounds];
	[self addCursorRect:r cursor:[NSCursor openHandCursor]];
}

- (void)mouseDown:(NSEvent *)event
{
	[[NSCursor closedHandCursor] push];
	[[self window] disableCursorRects];
	
	inDraggingSession = YES;
}

-(void)mouseUp:(NSEvent *)event
{
 	[NSCursor pop];
	[[self window] enableCursorRects];

	inDraggingSession = NO;

	if([[AudioEngine sharedAudioEngine] isPlaying])
		[playbackController startPlayback];
}

-(void)mouseDragged:(NSEvent *)event
{
	float eventLocator = [self convertPoint:[event locationInWindow] fromView:self].x + [[[self superview] superview] bounds].origin.x;
	NSUInteger newLocator = eventLocator < 0 ? 0 : eventLocator / zoomFactorX;
	newLocator = round(newLocator / resolution) * resolution;
	
	[playbackController setLocator:newLocator];
}

@end