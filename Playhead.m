//
//  Playhead.m
//  Choreographer
//
//  Created by Philippe Kocher on 12.10.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "Playhead.h"
#import "CHProjectDocument.h"
#import "CHGlobals.h"

@implementation Playhead

- (void)awakeFromNib
{
	[self setLocator:0];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(setZoomFactor:)
										  name:@"arrangerViewZoomFactorDidChange" object:nil];		

	// register for notifications
	// here! document is not yet known during init
}

- (void)dealloc
{
	NSLog(@"Playhead: dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[super dealloc];
}


- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill([self bounds]);
}

- (void)setOrigin
{
	int originX = 10.5 + locator * zoomFactorX + ARRANGER_OFFSET - [self bounds].size.width * 0.5;
	
	NSPoint newOrigin = NSMakePoint(originX - 10, 0);
			
	[self setFrameOrigin:newOrigin];

//	NSRect r = [self bounds];
//	r.size.width = 10;	
//	[self scrollRectToVisible:r]; 
	
	[[self superview] setNeedsDisplay:YES];
}

// -----------------------------------------------------------

- (void)setZoomFactor:(NSNotification *)notification
{
	zoomFactorX = [[[[self window] windowController] document] zoomFactorX];

	resolution = ceil(pow(10,round(log10(1/zoomFactorX))));

	[self setOrigin];
}

- (void)setLocator:(unsigned long)value
{
	locator = value;
	[self setOrigin];
}

@end
