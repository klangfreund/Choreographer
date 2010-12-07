//
//  ProgressPanel.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.12.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "ProgressPanel.h"

#define TOP_OFFSET 30

static ProgressPanel* sharedProgressPanel;

@implementation ProgressPanel

+ (id)sharedProgressPanel 
{
	if (!sharedProgressPanel)
	{
		sharedProgressPanel = [[ProgressPanel alloc] init];
	}
	return sharedProgressPanel;
}

- (id) init
{    
   if(self = [super init])
   {

        [self setFrame:NSMakeRect(0, 0, 300, 40 + TOP_OFFSET) display:YES];
        [self setOpaque:YES];
//        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:NSStatusWindowLevel];
		[self setTitle:@"Actions"];
        [self setReleasedWhenClosed:NO]; // don't release!

		progressSubviews = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[contentView release];
	[progressSubviews release];
	[super dealloc];
    sharedProgressPanel = nil;
}


- (id)addProgressWithTitle:(NSString *)title
{
	NSRect r = NSMakeRect(0,0,[self frame].size.width, 40);
	ProgressSubview *progressSubview = [[[ProgressSubview alloc] initWithFrame:r andText:title] autorelease];
	[[self contentView] addSubview:progressSubview];
	[progressSubviews addObject:progressSubview];

	[self orderFront:nil];
	[self recalcSize:[NSArray arrayWithArray:progressSubviews]];
	
	return progressSubview;
}

- (void)setProgressValue:(float)theValue forProgress:(id)progress
{
	if([progressSubviews containsObject:progress])
		[progress setProgressValue:theValue];

}

- (void)removeProgress:(id)theProgress
{
	[theProgress removeFromSuperview];
	[progressSubviews removeObject:theProgress];
	
	if(![progressSubviews count])
		[self close];
	else
		[self recalcSize:[NSArray arrayWithArray:progressSubviews]];
}

- (void)recalcSize:(NSArray *)subviews
{
	// this method takes a copy of the subviews array in order to assure thread safety
	// (= mutating arrays while being enumeated
	NSEnumerator *enumerator = [subviews objectEnumerator];
	id progressSubview;
	NSRect frame = NSMakeRect(0,[subviews count] * 40,[self frame].size.width, 40);
	
	while (progressSubview = [enumerator nextObject])
	{
		frame.origin.y -= 40;
		[progressSubview setFrame:frame];
	}

	frame = NSMakeRect([self frame].origin.x,
					   [self frame].origin.y,
					   [self frame].size.width,
					   TOP_OFFSET + [subviews count] * 40);

	[self setFrame:frame display:YES];

}

@end


@implementation ProgressSubview : NSView

- (id)initWithFrame:(NSRect)frame andText:(NSString *)text
{    
   if(self = [super initWithFrame:frame])
	{
		textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 15, frame.size.width - 40, 20)];
		[textField setEditable:NO];
		[textField setBordered:NO];
		[textField setDrawsBackground:NO];
		[textField setTextColor:[NSColor blackColor]];
		[textField setFont: [NSFont systemFontOfSize:10]];
		[textField setStringValue:text];
		[self addSubview:textField];
		
		progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 8, frame.size.width - 40, 10)];
		[progressIndicator setIndeterminate:NO];
		[self addSubview:progressIndicator];
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
	[textField release];
	[progressIndicator release];
}

- (void)setProgressValue:(float)theValue
{
	[progressIndicator setDoubleValue:theValue * 100.0];
}


- (void)drawRect:(NSRect)rect
{
//	[[NSColor grayColor] set];
//	[NSBezierPath fillRect:[self bounds]];
	
}
@end
