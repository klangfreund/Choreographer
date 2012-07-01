//
//  RulerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

/*
 abstract superclass for all ruler views
 */


#import "RulerView.h"
#import "CHProjectDocument.h"

@implementation RulerView

- (void)awakeFromNib
{
	// Initialization
	int i;
	for(i=0;i<NUM_OF_LABELS;i++)
	{
		labels[i] = [[[NSTextField alloc] init] autorelease];
		[labels[i] setEditable:NO];
		[labels[i] setBordered:NO];
		[labels[i] setDrawsBackground:NO];
//		[labels[i] setBackgroundColor:[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1]];
		[labels[i] setTextColor:[NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1]];
		[labels[i] setFont: [NSFont systemFontOfSize:9]];
		[self addSubview:labels[i]];
	}


	// set initial length
	NSRect r = [self frame];
	r.size.width = 60000;
	
	[self setFrame:r];
	
	zoomFactor = 0.0;

	numOfAreas = 1;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)drawRect:(NSRect)rect
{
	// first make sure that the zoomFactor is set (new document)
	if(!zoomFactor)
		[self setZoomFactor:nil];

	// colors
	NSColor *backgroundColor	= [NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];
	NSColor *lineColor			= [NSColor colorWithCalibratedRed: 0.35 green: 0.35 blue: 0.35 alpha: 1];
	NSColor *lineShadowColor	= [NSColor colorWithCalibratedRed: 0.25 green: 0.25 blue: 0.25 alpha: 1];
	NSColor *tickColor			= [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1];
	
	// draw the background
	[backgroundColor set];
	NSRectFill(rect);
	
	// draw horizontal lines (division into areas)
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[lineColor set];
	if(numOfAreas > 1) [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, HEIGHT_1) toPoint:NSMakePoint(rect.origin.x + rect.size.width, HEIGHT_1)];
	if(numOfAreas > 2) [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, HEIGHT_1 + HEIGHT_2) toPoint:NSMakePoint(rect.origin.x + rect.size.width, HEIGHT_1 + HEIGHT_2)];
	[lineShadowColor set];
	if(numOfAreas > 1) [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, HEIGHT_1 + 1) toPoint:NSMakePoint(rect.origin.x + rect.size.width, HEIGHT_1 + 1)];
	if(numOfAreas > 2) [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, HEIGHT_1 + HEIGHT_2 + 1) toPoint:NSMakePoint(rect.origin.x + rect.size.width, HEIGHT_1 + HEIGHT_2 + 1)];

	[tickColor set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, 0) toPoint:NSMakePoint(rect.origin.x + rect.size.width, 0)];

	long i, increment = 1;
	int hour, min, sec, milisec;
	int index,j;
	int subdivision = 4;

	if(TRUE)//type == minSecRulerType)
	{		
		if(zoomFactor <= 100 && zoomFactor > 13)
		{
			increment = 10;
			
			subdivision = 10;
		}
		else if(zoomFactor <= 13 && zoomFactor > 9)
		{
			increment = 10;
			subdivision = 5;
		}
		else if(zoomFactor <= 9 && zoomFactor > 4)
		{
			increment = 25;
			subdivision = 5;
		}
		else if(zoomFactor <= 4 && zoomFactor > 2)
		{
			increment = 50;
			subdivision = 5;
		}
		else if(zoomFactor <= 2 && zoomFactor > 1.2)
		{
			increment = 100;
			subdivision = 5;
		}
		else if(zoomFactor <= 1.2 && zoomFactor > 0.3)
		{
			increment = 250;
			subdivision = 5;
		}
		else if(zoomFactor <= 0.3 && zoomFactor > 0.2)
		{
			increment = 500;
			subdivision = 5;
		}
		else if(zoomFactor <= 0.2 && zoomFactor > 0.06)
		{
			increment = 1000;
			subdivision = 4;
		}
		else if(zoomFactor <= 0.06 && zoomFactor > 0.03)
		{
			increment = 2000;
			subdivision = 4;
		}
		else if(zoomFactor <= 0.03 && zoomFactor > 0.015)
		{
			increment = 5000;
			subdivision = 5;
		}
		else if(zoomFactor <= 0.015 && zoomFactor > 0.006)
		{
			increment = 10000;
			subdivision = 5;
		}
		else if(zoomFactor <= 0.006 && zoomFactor > 0.003)
		{
			increment = 20000;
			subdivision = 4;
		}
		else if(zoomFactor <= 0.003 && zoomFactor > 0.0018)
		{
			increment = 30000;
			subdivision = 6;
		}
		else if(zoomFactor <= 0.0018 && zoomFactor > 0.0009)
		{
			increment = 60000;
			subdivision = 6;
		}
		else if(zoomFactor <= 0.0009 && zoomFactor > 0.0005)
		{
			increment = 120000;
			subdivision = 4;
		}
		else if(zoomFactor <= 0.0005 && zoomFactor > 0.0002)
		{
			increment = 300000;
			subdivision = 5;
		}
		else if(zoomFactor <= 0.0002 && zoomFactor > 0.00001)
		{
			increment = 600000;
			subdivision = 6;
		}
	}

	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		
	// draw only visible part
	float viewStart = rect.origin.x / zoomFactor;
	int startTime = viewStart - (int)viewStart % increment;
	int endTime = rect.origin.x / zoomFactor + rect.size.width / zoomFactor;
	float y = 4;
	
	if(numOfAreas > 1) y += HEIGHT_1;
	if(numOfAreas > 2) y += HEIGHT_2;

	i=startTime;
	index=0;
	while(index < NUM_OF_LABELS && i < endTime)
	{
		// label
		[labels[index] setFrame:NSMakeRect(i * zoomFactor + 2 + ARRANGER_OFFSET, y, 50, 10)];
		

		type = minSecRulerType;
		switch(type)
		{
			case minSecRulerType:
				milisec = i  % 1000;
				sec = (i / 1000) % 60;
				min = (i / 60000) % 60;
				hour = (i / 3600000);
				if(increment >= 600000) [labels[index] setStringValue:[NSString stringWithFormat:@"%d:%d:%02d", hour, min, sec]];
				if(increment < 1000) [labels[index] setStringValue:[NSString stringWithFormat:@"%d:%02d.%03d", min, sec, milisec]];
				else [labels[index] setStringValue:[NSString stringWithFormat:@"%d:%02d", min, sec]];
				break;
				
				
			case samplesRulerType:
				[labels[index] setStringValue:[NSString stringWithFormat:@"%d", index * 1000]];
				break;
		}
				

		// major ticks
		[tickColor set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(i * zoomFactor + ARRANGER_OFFSET, 0) toPoint:NSMakePoint(i * zoomFactor + ARRANGER_OFFSET, 40)];

		// minor ticks
		for(j=1;j<subdivision;j++)
		{
			[NSBezierPath strokeLineFromPoint:NSMakePoint(i * zoomFactor + increment * zoomFactor / subdivision * j + ARRANGER_OFFSET, 0)
									  toPoint:NSMakePoint(i * zoomFactor + increment * zoomFactor / subdivision * j + ARRANGER_OFFSET, 5)];
		}
		
		i+=increment;
		index++;
	}
	
	while(index < NUM_OF_LABELS)
	{
		[labels[index] setFrame:NSMakeRect(0, 0, 0, 0)];
		index++;
	}

}
	
- (void)setHorizontalRulerType:(NSPopUpButton *)sender
{
	int num = [sender indexOfSelectedItem];
	type = num;
	[self setNeedsDisplay:YES];
}

- (void)setZoomFactor:(NSNotification *)notification {}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
	// first click activates the window automatically
	// so the user can immediately start manipulating
}

@end
