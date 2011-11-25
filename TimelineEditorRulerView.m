//
//  TimelineEditorRulerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TimelineEditorRulerView.h"


@implementation TimelineEditorRulerView

- (void)awakeFromNib
{
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setZoomFactor:)
                                                 name:@"timelineEditorZoomFactorDidChange" object:nil];		
	[super awakeFromNib];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoomFactor:(NSNotification *)aNotification
{
    float newZoomFactor = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];
	
	if(newZoomFactor != zoomFactor)
	{
		zoomFactor = newZoomFactor;
		
		// new width
		NSSize s = [self frame].size;
		s.width = [[self window] frame].size.width * 2;
		[self setFrameSize:s];

		[self setNeedsDisplay:YES];
    }
}

@end
