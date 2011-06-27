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
        // initialization
		
		level = -70;
		peakLevel = -70;
		
		isVertical = frame.size.height > frame.size.width;

		
    	// colors
		
		tickColor		= [[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1] retain];
		overloadColor	= [[NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 0.3 alpha: 1] retain];
		hotColor		= [[NSColor colorWithCalibratedRed: 1.0 green: 0.9 blue: 0.1 alpha: 1] retain];
		coolColor		= [[NSColor colorWithCalibratedRed: 0.1 green: 1.0 blue: 0.3 alpha: 1] retain];
		
	}
    return self;
}

- (void) dealloc
{
	[tickColor release];
	[overloadColor release];
	[hotColor release];
	[coolColor release];

	[super dealloc];
}


- (BOOL)isFlipped
{
	return YES;
}
	
- (void)drawRect:(NSRect)dirtyRect
{
	if(isVertical) [self drawVertical:dirtyRect];
	else [self drawHorizontal:dirtyRect];
}

- (void)drawVertical:(NSRect)dirtyRect
{
	int i;
	NSRect r = [self frame];
	
	float factor = r.size.height / 58;
	
	// Ticks
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[tickColor set];
	for(i=0;6 + i * factor < r.size.height - 6;i++)
	{
		if(i % 5)
			[NSBezierPath strokeLineFromPoint:NSMakePoint(3, 6 + i * factor) toPoint:NSMakePoint(22, 6 + i * factor)];
		else
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 6 + i * factor) toPoint:NSMakePoint(25, 6 + i * factor)];
	}
	

	// Rect
	r.size.width -= 10;
	r.size.height -= 10;
	r.origin.x = 5;
	r.origin.y = 5;
	
	[[NSColor blackColor] set];
	NSRectFill(r);
	
	
	// Meter Value
	//[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	r.size.width -= 2;
	r.origin.x = 6;
	r.size.height += level * factor - 1; 
	r.origin.y -= level * factor - 1;
	
	[coolColor set];
	NSRectFill(r);

	if(level > -6)
	{
		r = NSMakeRect(6, 6 - level * factor, 13, (level + 6) * factor);

		[hotColor set];
		NSRectFill(r);
	}

	if(level >= 0)
	{
		r.size.height = 5; 
		
		NSRectFill(r);

		[overloadColor set];
		NSRectFill(r);
	}
	
	// Peak
	if(peakLevel >= 0)
	{
		[overloadColor set];
		r = NSMakeRect(6, 6 - 0 * factor, 13, 4);
		NSRectFill(r);
	}
	else
	{
		if(peakLevel > -6)
			[hotColor set];
		else
			[coolColor set];
	
		r = NSMakeRect(6, 6 - peakLevel * factor, 13, 1);
		NSRectFill(r);
	}
}

- (void)drawHorizontal:(NSRect)dirtyRect
{
	int i;
	NSRect r = [self frame];
	
	float width = r.size.width;
	float factor = r.size.width / 58;
	float inset = r.size.height * 0.2;
	
	// Ticks
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[tickColor set];
	for(i=0;r.size.width - i * factor > 0;i++)
	{
		if(i % 5)
		{
			if (r.size.width > 200)
				[NSBezierPath strokeLineFromPoint:NSMakePoint(width - 1 - i * factor, 3) toPoint:NSMakePoint(width - 1 - i * factor, r.size.height - 3)];
		}
		else
			[NSBezierPath strokeLineFromPoint:NSMakePoint(width - 1 - i * factor, 0) toPoint:NSMakePoint(width - 1 - i * factor, r.size.height)];
	}
	
	
	// Rect
	r.size.height -= 2 * inset;
	r.origin.x = 0;
	r.origin.y = inset;
	
	[[NSColor blackColor] set];
	NSRectFill(r);
	
	
	// Meter Value
	//[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	r.size.height -= 2;
	r.origin.y += 1;
	r.size.width += level * factor - 1; 
	
	[coolColor set];
	NSRectFill(r);
	
	if(level > -6)
	{
		r.origin.x = width - 1 - 6 * factor;
		r.size.width = (level + 6) * factor; 
		
		[hotColor set];
		NSRectFill(r);
	}
	
	if(level >= 0)
	{
		r.origin.x = width - 3;
		r.size.width = 3; 
		
		NSRectFill(r);
		
		[overloadColor set];
		NSRectFill(r);
	}
}	

- (void)setLevel:(float)dBValue
{
	level = dBValue > 0 ? 0 : dBValue;
	
	[self setNeedsDisplay:YES];
}

- (void)setPeakLevel:(float)dBValue
{
	float value = dBValue > 0 ? 0 : dBValue;

	if(value > peakLevel || peakLevelCounter > 20)
	{
		peakLevel = value;
		peakLevelCounter = 0;
	}
	else
	{
		peakLevelCounter++;		
	}

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

@implementation LevelMeterPeakView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // initialization

		level = -70;
		
    	// colors
		
		normalColor		= [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1] retain];
		overloadColor	= [[NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 0.3 alpha: 1] retain];
		
	}
    return self;
}

- (void) dealloc
{
	[normalColor release];
	[overloadColor release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect r = [self bounds];
	
	if(level < 0)
		[normalColor set];
	else
		[overloadColor set];
	NSRectFill(r);
	
	
	NSString *label;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:[NSFont systemFontOfSize:9] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];

	label = [NSString stringWithFormat:@"%0.2f", level];
	[label drawAtPoint:NSMakePoint(0,4) withAttributes:attrs];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
	// first click activates the window automatically
	// so the user can immediately reset a peak
}

- (void)mouseDown:(NSEvent *)event
{
	if([event modifierFlags] & NSAlternateKeyMask)
	{
		[owner performSelectorInBackground:@selector(resetAllPeaks) withObject:nil];
	}
	else
	{
		[owner performSelectorInBackground:@selector(resetPeak) withObject:nil];
		level = -70;
		[self setNeedsDisplay:YES];
	}
}

- (void)setLevel:(float)dBValue
{
	level = dBValue;
	
	[self setNeedsDisplay:YES];
}

@end


@implementation DBLabelsView

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	// number fields
	NSString *label;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

	
	NSRect r = [self frame];
	float factor = r.size.height / 58;
	
	
	// Labels
	//[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	label = @"0";
	[label drawAtPoint:NSMakePoint(24,0) withAttributes:attrs];
	
	label = @"-5";
	[label drawAtPoint:NSMakePoint(17,5 * factor) withAttributes:attrs];
	
	label = @"-10";
	[label drawAtPoint:NSMakePoint(10,10 * factor) withAttributes:attrs];
	
	label = @"-20";
	[label drawAtPoint:NSMakePoint(10,20 * factor) withAttributes:attrs];
	
	label = @"-30";
	[label drawAtPoint:NSMakePoint(10,30 * factor) withAttributes:attrs];
	
	label = @"-40";
	[label drawAtPoint:NSMakePoint(10,40 * factor) withAttributes:attrs];
	
	label = @"-50";
	[label drawAtPoint:NSMakePoint(10,50 * factor) withAttributes:attrs];
	
}

@end


