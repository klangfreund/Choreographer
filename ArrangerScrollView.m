//
//  ArrangerScrollView.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.01.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ArrangerScrollView.h"


@implementation ArrangerScrollView

- (void)awakeFromNib
{
	[self addSubview:xZoomInButton];
	[self addSubview:xZoomOutButton];
	[self addSubview:yZoomInButton];
	[self addSubview:yZoomOutButton];
	
	[xZoomInButton setBezelStyle:6];
	[xZoomOutButton setBezelStyle:6];
	[yZoomInButton setBezelStyle:6];
	[yZoomOutButton setBezelStyle:6];
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

- (void)tile
{
	NSRect scrollerRect, buttonRect;
	float buttonSize = [[self horizontalScroller] frame].size.height + 2;
	
	[super tile];
	
	// place the x zoom buttons next to the horizontal scroller
	scrollerRect = [[self horizontalScroller] frame];
	NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, buttonSize * 2, NSMaxXEdge);
	
	[[self horizontalScroller] setFrame: scrollerRect];

	buttonRect.size.width = buttonSize;
	[xZoomOutButton setFrame: buttonRect];

	buttonRect.origin.x += buttonSize;
	[xZoomInButton setFrame: buttonRect];


	// place the y zoom buttons next to the vertical scroller
	scrollerRect = [[self verticalScroller] frame];
	NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, buttonSize * 2, NSMaxYEdge);
	
	[[self verticalScroller] setFrame: scrollerRect];

	buttonRect.size.height = buttonSize;
	[yZoomOutButton setFrame: buttonRect];

	buttonRect.origin.y += buttonSize;
	[yZoomInButton setFrame: buttonRect];
}
@end
