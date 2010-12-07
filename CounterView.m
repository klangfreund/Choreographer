//
//  CounterView.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.08.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "CounterView.h"
#import "CHProjectDocument.h"


@implementation CounterTextBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		textColor = [NSColor blackColor];

		[self setEditable:NO];
		[self setSelectable:NO];
		[self setBordered:NO];
		[self setDrawsBackground:NO];
		[self setTextColor:textColor];
	}
    return self;
}

- (BOOL)isOpaque
{
	return NO;
}

@end

@implementation CounterSmallNumberBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		[self setFont: [NSFont systemFontOfSize:11]];
	}
	return self;
}

@end

@implementation CounterLargeNumberBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		[self setFont: [NSFont systemFontOfSize:20]];
	}
	return self;
}
	
- (void)select
{
	[self setTextColor:[NSColor whiteColor]];
}

- (void)deselect
{
	[self setTextColor:textColor];
}

- (void)mouseDown:(NSEvent *)event
{
	[(CounterView *)[self superview] setSelectedNumberBox:self];
}

@end


@implementation CounterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{

		// formatter for min and sec
		formatter1 = [[NSNumberFormatter alloc] init];
		[formatter1 setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[formatter1 setFormat:@"00"];

		// formatter for A and E
		formatter2 = [[NSNumberFormatter alloc] init];
		[formatter2 setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[formatter2 setFormat:@"000"];


		// : : .

		frame = NSMakeRect(28, 15, 8, 22);
		CounterTextBox *textBox;
		textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
		[textBox setFont: [NSFont systemFontOfSize:20]];
		[textBox setStringValue: @":"];
		[self addSubview:textBox];

		frame = NSMakeRect(68, 15, 8, 22);
		textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
		[textBox setFont: [NSFont systemFontOfSize:20]];
		[textBox setStringValue: @":"];
		[self addSubview:textBox];

		frame = NSMakeRect(108, 15, 8, 22);
		textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
		[textBox setFont: [NSFont systemFontOfSize:20]];
		[textBox setStringValue: @"."];
		[self addSubview:textBox];

        // Initialise large number boxes (main counter)

		frame = NSMakeRect(10, 17, 18, 20);
		CounterLargeNumberBox *hoursField = [[[CounterLargeNumberBox alloc] initWithFrame:frame] autorelease];
		[hoursField setIntValue:0];	
		[self addSubview:hoursField];
		
		frame = NSMakeRect(38, 17, 30, 20);
		CounterLargeNumberBox *minutesField = [[[CounterLargeNumberBox alloc] initWithFrame:frame] autorelease];		
		[minutesField setStringValue:@"00"];	
		[self addSubview:minutesField];
		
		frame = NSMakeRect(78, 17, 30, 20);
		CounterLargeNumberBox *secondsField = [[[CounterLargeNumberBox alloc] initWithFrame:frame] autorelease];		
		[secondsField setStringValue:@"00"];	
		[self addSubview:secondsField];
		
		frame = NSMakeRect(118, 17, 42, 20);
		CounterLargeNumberBox *milisecondsField = [[[CounterLargeNumberBox alloc] initWithFrame:frame] autorelease];		
		[milisecondsField setStringValue:@"000"];	
		[self addSubview:milisecondsField];

		counterNumberBoxes = [[NSArray alloc] initWithObjects:hoursField, minutesField, secondsField, milisecondsField, nil];
		
		
		frame = NSMakeRect(180, 33, 80, 12);
		NSTextField *text = [[[NSTextField alloc] initWithFrame:frame] autorelease];
		[text setEditable:NO];
		[text setBordered:NO];
		[text setBezeled:NO];
		[text setDrawsBackground:NO];
		[text setTextColor:[NSColor grayColor]];
		[text setFont: [NSFont systemFontOfSize:10]];
		[text setStringValue: @"Start"];
		[self addSubview:text];

		frame = NSMakeRect(180, 18, 80, 12);
		text = [[[NSTextField alloc] initWithFrame:frame] autorelease];
		[text setEditable:NO];
		[text setBordered:NO];
		[text setBezeled:NO];
		[text setDrawsBackground:NO];
		[text setTextColor:[NSColor grayColor]];
		[text setFont: [NSFont systemFontOfSize:10]];
		[text setStringValue: @"End"];
		[self addSubview:text];

		frame = NSMakeRect(180, 3, 80, 12);
		text = [[[NSTextField alloc] initWithFrame:frame] autorelease];
		[text setEditable:NO];
		[text setBordered:NO];
		[text setBezeled:NO];
		[text setDrawsBackground:NO];
		[text setTextColor:[NSColor grayColor]];
		[text setFont: [NSFont systemFontOfSize:10]];
		[text setStringValue: @"Length"];
		[self addSubview:text];
		
		// Initialise small number boxes (main counter)

		int i, y;
		for(i=0;i<3;i++)
		{
			y = 4 + 15 * i;
			
			// : : .

			frame = NSMakeRect(235, y, 5, 12);
			CounterTextBox *textBox;
			textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
			[textBox setFont: [NSFont boldSystemFontOfSize:11]];
			[textBox setStringValue: @":"];
			[self addSubview:textBox];

			frame = NSMakeRect(257, y, 5, 12);
			textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
			[textBox setFont: [NSFont boldSystemFontOfSize:11]];
			[textBox setStringValue: @":"];
			[self addSubview:textBox];

			frame = NSMakeRect(279, y, 5, 12);
			textBox = [[[CounterTextBox alloc] initWithFrame:frame] autorelease];
			[textBox setFont: [NSFont boldSystemFontOfSize:11]];
			[textBox setStringValue: @"."];
			[self addSubview:textBox];

			// Initialise small number boxes (selection)
 
			frame = NSMakeRect(225, y, 10, 12);
			hoursField = [[[CounterSmallNumberBox alloc] initWithFrame:frame] autorelease];
			[hoursField setIntValue:0];	
			[self addSubview:hoursField];
			
			frame = NSMakeRect(241, y, 18, 12);
			minutesField = [[[CounterSmallNumberBox alloc] initWithFrame:frame] autorelease];		
			[minutesField setStringValue:@"00"];	
			[self addSubview:minutesField];
			
			frame = NSMakeRect(263, y, 18, 12);
			secondsField = [[[CounterSmallNumberBox alloc] initWithFrame:frame] autorelease];		
			[secondsField setStringValue:@"00"];	
			[self addSubview:secondsField];
			
			frame = NSMakeRect(285, y, 25, 12);
			milisecondsField = [[[CounterSmallNumberBox alloc] initWithFrame:frame] autorelease];		
			[milisecondsField setStringValue:@"000"];	
			[self addSubview:milisecondsField];

			switch(i)
			{
				case 2:
					startNumberBoxes = [[NSArray alloc] initWithObjects:hoursField, minutesField, secondsField, milisecondsField, nil];
					break;
				case 1:
					endNumberBoxes = [[NSArray alloc] initWithObjects:hoursField, minutesField, secondsField, milisecondsField, nil];
					break;
				case 0:
					lengthNumberBoxes = [[NSArray alloc] initWithObjects:hoursField, minutesField, secondsField, milisecondsField, nil];
					break;
			}
		}
	}
    return self;
}

- (void)dealloc
{
	NSLog(@"CounterView: dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[formatter1 release];
	[formatter2 release];
	[counterNumberBoxes release];
	[startNumberBoxes release];
	[endNumberBoxes release];
	[lengthNumberBoxes release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	// background
	int i;
	NSRect r = [self bounds];
	NSRect bgr = [self bounds];

	int height = r.size.height;
	for(i=rect.origin.y;i<rect.origin.y + rect.size.height;i++)
	{
		if(i < 25)
			[[NSColor colorWithCalibratedRed: 1 - i * 0.01 green: 1 - i * 0.005 blue: 1 alpha: 1.0] set];
		else
			[[NSColor colorWithCalibratedRed: 0.385 + i * 0.01 green: 0.691 + i * 0.005 blue: 1 alpha: 1.0] set];
			
		bgr.origin.y = height - i;
		bgr.size.height = 1;
		NSRectFill(bgr);
	}

	// frame
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:r];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,r.size.height) toPoint:NSMakePoint(r.size.width,r.size.height)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,0) toPoint:NSMakePoint(0,r.size.height)];
	[[NSColor grayColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,r.size.height-1) toPoint:NSMakePoint(r.size.width,r.size.height-1)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(1,0) toPoint:NSMakePoint(1,r.size.height)];

	// separator (vertical line in the middle)
	[[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(170,0) toPoint:NSMakePoint(170,rect.size.height)];
}

- (void)setLocator:(unsigned long)value;
{	
	int time[4];
	miliseconds_to_time(value, time);
	
	[[counterNumberBoxes objectAtIndex:3] setStringValue:[formatter2 stringFromNumber:[NSNumber numberWithInt: time[3]]]];
	[[counterNumberBoxes objectAtIndex:2] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[2]]]];
	[[counterNumberBoxes objectAtIndex:1] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[1]]]];
	[[counterNumberBoxes objectAtIndex:0] setIntValue:time[0]];

	[self setNeedsDisplay:YES];
}

- (void)setSelectionFrom:(unsigned long)startTime to:(unsigned long)endTime
{
	int time[4];
	miliseconds_to_time(startTime, time);
	
	[[startNumberBoxes objectAtIndex:3] setStringValue:[formatter2 stringFromNumber:[NSNumber numberWithInt: time[3]]]];
	[[startNumberBoxes objectAtIndex:2] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[2]]]];
	[[startNumberBoxes objectAtIndex:1] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[1]]]];
	[[startNumberBoxes objectAtIndex:0] setIntValue:time[0]];

	miliseconds_to_time(endTime, time);
	
	[[endNumberBoxes objectAtIndex:3] setStringValue:[formatter2 stringFromNumber:[NSNumber numberWithInt: time[3]]]];
	[[endNumberBoxes objectAtIndex:2] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[2]]]];
	[[endNumberBoxes objectAtIndex:1] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[1]]]];
	[[endNumberBoxes objectAtIndex:0] setIntValue:time[0]];

	miliseconds_to_time(endTime - startTime, time);
	
	[[lengthNumberBoxes objectAtIndex:3] setStringValue:[formatter2 stringFromNumber:[NSNumber numberWithInt: time[3]]]];
	[[lengthNumberBoxes objectAtIndex:2] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[2]]]];
	[[lengthNumberBoxes objectAtIndex:1] setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: time[1]]]];
	[[lengthNumberBoxes objectAtIndex:0] setIntValue:time[0]];
}


- (void)setSelectedNumberBox:(CounterLargeNumberBox *)box
{
	selectedNumberBox = box;
	[counterNumberBoxes makeObjectsPerformSelector:@selector(deselect)];
	[selectedNumberBox select];
}

- (void)rotateSelection
{
	int index = [counterNumberBoxes indexOfObject:selectedNumberBox];
	index++;
	if(index >= [counterNumberBoxes count])
		index = 0;
		
	[self setSelectedNumberBox:[counterNumberBoxes objectAtIndex:index]];
}
	
- (BOOL)hasSelectedNumberBox
{
	if(selectedNumberBox) return YES;
	else return NO;
}

- (void)setNumber:(int)num
{
	int index = [counterNumberBoxes indexOfObject:selectedNumberBox];
	int oldValue = [selectedNumberBox intValue];
	int newValue;
	
	if(num == -1)
		oldValue = num = 0;
	
	switch(index)
	{
		case 0:
			[selectedNumberBox setIntValue:num];
			break;
		case 1:
		case 2:
			newValue = (num + 10 * oldValue) % 100;
			[selectedNumberBox setStringValue:[formatter1 stringFromNumber:[NSNumber numberWithInt: newValue]]];
			break;
		case 3:
			newValue = (num + 10 * oldValue) % 1000;
			[selectedNumberBox setStringValue:[formatter2 stringFromNumber:[NSNumber numberWithInt: newValue]]];
			break;
	}
}

@end

void miliseconds_to_time(unsigned long miliseconds, int *time)
{		
	time[3] = miliseconds % 1000;
	time[2] = (miliseconds / 1000) % 60;
	time[1]	= (miliseconds / 60000) % 60;
	time[0]	= (miliseconds / 3600000);
}
