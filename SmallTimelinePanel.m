//
//  SmallTimelinePanel.m
//  Choreographer
//
//  Created by Philippe Kocher on 06.11.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "SmallTimelinePanel.h"
#import "TrajectoryItem.h"
#import "Breakpoint.h"


static SmallTimelinePanel *sharedSmallTimelinePanel = nil;

@implementation SmallTimelinePanel

#pragma mark -
#pragma mark singleton
// -----------------------------------------------------------

+ (id)sharedSmallTimelinePanel
{
    if (!sharedSmallTimelinePanel)
	{
        sharedSmallTimelinePanel = [[SmallTimelinePanel alloc] init];
    }
    return sharedSmallTimelinePanel;
}

+ (void)release
{
    [sharedSmallTimelinePanel release];
    sharedSmallTimelinePanel = nil;
}

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)init
{    
   if(self = [super init])
   {
		NSLog(@"sharedSmallTimelinePanel");
        // These size are not really important, just the relation between the two...
        NSRect	r = {{ 0, 0 },{ 0, 0 }};
        
        window = [[NSWindow alloc] initWithContentRect: r
								   styleMask: NSBorderlessWindowMask
								   backing: NSBackingStoreBuffered
                                   defer: YES];
        
        [window setOpaque:NO];
        [window setAlphaValue:0.80];
        [window setBackgroundColor:[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1.0]];
        [window setHasShadow:YES];
        [window setLevel:NSStatusWindowLevel];
        [window setReleasedWhenClosed:YES];

		smallTimelinePanelView = [[SmallTimelinePanelView alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [smallTimelinePanelView release];
    [window release];
    [super dealloc];
}


- (void)editBreakpoint:(id)bp trajectory:(id)tr event:(NSEvent *)theEvent
{
    NSPoint cursorPosition = [[theEvent window] convertBaseToScreen:[theEvent locationInWindow]];
	int originalX = [theEvent locationInWindow].x;
	unsigned long originalTime = [bp time];

	[window setContentSize:NSMakeSize(300, 50)];
	[window setFrameTopLeftPoint:NSMakePoint(cursorPosition.x - 150, cursorPosition.y + 40)];

	[smallTimelinePanelView setFrame:[window frame]];
	[window setContentView:smallTimelinePanelView];


	// mouse tracking loop
	[window orderFront:nil];
    BOOL keepOn = YES;

    while (keepOn)
	{
		theEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([theEvent type])
		{
            case NSLeftMouseDragged:
                    printf("\nlocationInWindow %f...", [theEvent locationInWindow].x - originalX);
					[bp setTime:originalTime + [theEvent locationInWindow].x - originalX];
					[tr sortBreakpoints];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
                   break;
            case NSLeftMouseUp:
					[window orderOut:nil];
                    keepOn = NO;
                    break;
		}
	}
}

@end

#define HANDLE_SIZE 5

@implementation SmallTimelinePanelView : NSView
- (void)drawRect:(NSRect)rect
{
	int i;
	float height = [self frame].size.height;
	
	for(i=0;i<10;i++)
	{
		[[NSColor whiteColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(i * 20, height) toPoint:NSMakePoint(i * 20, height - 5)];
	}
}
@end
