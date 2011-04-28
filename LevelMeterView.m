//
//  LevelMeterView.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.04.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "LevelMeterView.h"


@implementation LevelMeterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
		level = -70;
		peakLevel = -70;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	// colors
	NSColor *tickColor			= [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1];
	NSColor *overloadColor		= [NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 0.3 alpha: 1];
	NSColor *hotColor			= [NSColor colorWithCalibratedRed: 1.0 green: 0.8 blue: 0.0 alpha: 1];
	NSColor *coolColor			= [NSColor colorWithCalibratedRed: 0.1 green: 1.0 blue: 0.3 alpha: 1];

	int i;
	NSRect r = [self frame];
	
	// Ticks
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[tickColor set];
	for(i=0;i<56;i++)
	{
		if(i % 5)
			[NSBezierPath strokeLineFromPoint:NSMakePoint(3, 9 + i * 3) toPoint:NSMakePoint(22, 9 + i * 3)];
		else
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 9 + i * 3) toPoint:NSMakePoint(25, 9 + i * 3)];
	}
	

	// Rect
	r.size.width -= 10;
	r.size.height -= 10;
	r.origin.x = 5;
	r.origin.y = 5;
	
	[[NSColor blackColor] set];
	NSRectFill(r);
	
	
	// Meter Value
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	r.size.width -= 2;
	r.origin.x = 6;
	r.size.height += level * 3; 
	
	[coolColor set];
	NSRectFill(r);

	if(level > -6)
	{
		r.origin.y += 150;
		r.size.height -= 150; 
		
		[hotColor set];
		NSRectFill(r);
	}

	if(level >= 0)
	{
		r.origin.y += 15;
		r.size.height = 5; 
		
		[overloadColor set];
		NSRectFill(r);
	}
	
	// Peak
	if(peakLevel >= 0)
	{
		[overloadColor set];
		r = NSMakeRect(6, 174, 13, 4);
		NSRectFill(r);
	}
	else
	{
		if(peakLevel > -6)
			[hotColor set];
		else
			[coolColor set];
	
		r = NSMakeRect(6, 174 + peakLevel * 3, 13, 1);
		NSRectFill(r);
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
	// first click activates the window automatically
	// so the user can immediately reset a peak
}

- (void)mouseDown:(NSEvent *)event
{
	[owner performSelectorInBackground:@selector(resetPeak) withObject:nil];
	peakLevel = -70;
	
	[self setNeedsDisplay:YES];
}

- (void)setLevel:(float)dBValue
{
	level = dBValue > 0 ? 0 : dBValue;
	
	[self setNeedsDisplay:YES];
}

- (void)setPeakLevel:(float)dBValue
{
	peakLevel = dBValue > 0 ? 0 : dBValue;

	[self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent *)event
{
//	unsigned short keyCode = [event keyCode];
//	NSLog(@"Level Meter View key code: %d ", keyCode);
[[[[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0] window] keyDown:event];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

@end
