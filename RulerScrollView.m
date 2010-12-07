//
//  RulerScrollView.m
//  Choreographer
//
//  Created by Philippe Kocher on 16.02.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "RulerScrollView.h"


@implementation RulerScrollView

- (void)resetCursorRects
{
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview
{
    NSView *synchronizedContentView;

    // stop an existing scroll view synchronizing
    [self stopSynchronizing];
 
    // don't retain the watched view, because we assume that it will
    // be retained by the view hierarchy for as long as we're around.
    synchronizedScrollView = scrollview;
 
    // get the content view of the 
    synchronizedContentView=[synchronizedScrollView contentView];
 
     // a register for those notifications on the synchronized content view.
    [[NSNotificationCenter defaultCenter] addObserver:self
							selector:@selector(synchronizedViewContentBoundsDidChange:)
							name:NSViewBoundsDidChangeNotification
							object:synchronizedContentView];
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
    // get the changed content view from the notification
    NSView *changedContentView=[notification object];
 
    // get the origin of the NSClipView of the scroll view that
    // we're watching
    NSPoint changedBoundsOrigin = [changedContentView bounds].origin;
 
    // get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
 
    // horizontal scrolling is synchronized, so
    // only modify the x component of the offset
    newOffset.x = changedBoundsOrigin.x;
 
    // if our synced position is different from our current
    // position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
		[[self contentView] scrollToPoint:newOffset];
		// tell the NSScrollView to update its scrollers
		[self reflectScrolledClipView:[self contentView]];
    }
}

- (void)stopSynchronizing
{
    if (synchronizedScrollView != nil)
	{
		NSView* synchronizedContentView = [synchronizedScrollView contentView];
 
		// remove any existing notification registration
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewBoundsDidChangeNotification
													  object:synchronizedContentView];
 
		// set synchronizedScrollView to nil
		synchronizedScrollView=nil;
    }
}

- (void) dealloc
{
	NSLog(@"RulerScrollView: dealloc");

	// remove any existing notification registration
	[[NSNotificationCenter defaultCenter] removeObserver:self
							name:NSViewBoundsDidChangeNotification
							object:nil];
 
	[super dealloc];
}


@end
