//
//  RadarEditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "RadarEditorWindowController.h"

static RadarEditorWindowController *sharedRadarEditorWindowController = nil;

#define MIN_WIDTH 300

@implementation RadarEditorWindowController

+ (id)sharedRadarEditorWindowController
{
    if (!sharedRadarEditorWindowController)
	{
        sharedRadarEditorWindowController = [[RadarEditorWindowController alloc] init];
    }
    return sharedRadarEditorWindowController;
}

- (id)init
{
	self = [self initWithWindowNibName:@"RadarEditor"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"RadarEditor"];
		
		ratio = 1;
		titleToolbarHeight = 0;
    }

    
	// get view mode from ratio
	float approximativeRatio = [[self window] frame].size.height / [[self window] frame].size.width;
	
	if (approximativeRatio < 1.5)
	{
		[self setViewMode:0];
	}
	else if (approximativeRatio < 2.0)
	{
		[self setViewMode:1];
	}
	else
	{
		[self setViewMode:2];
	}
		
	return self;
}


- (void) refreshView
{
	[radarView setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark IB actions
// -----------------------------------------------------------

// pop up menu in IB is bound to this instance variable
- (void)setViewMode:(int)value
{
	viewMode = value;
	[radarView setViewMode:viewMode];
	
	// 0 = horizontal
	// 1 = horizontal + vertical (half sphere)
	// 2 = horizontal + vertical (full sphere)
	
	NSRect frame = [[self window] frame];
	float oldHeight = frame.size.height;
	
	switch(viewMode)
	{
		case 0:
			frame.size.height = [radarView frame].size.width + [self titleToolbarHeight];
			ratio = 1.0;
			break;
		case 1:
			frame.size.height = [radarView frame].size.width * 1.5 + [self titleToolbarHeight];
			ratio = 1.5;
			break;
		case 2:
			frame.size.height = [radarView frame].size.width * 2.0 + [self titleToolbarHeight];
			ratio = 2.0;
			break;
	}
		
	// get size of main screen
	NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
	
	if(frame.size.height > visibleFrame.size.height)
	{
		frame.origin.y = visibleFrame.origin.y;
		frame.size.height = visibleFrame.size.height;
		frame.size.width = (visibleFrame.size.height - [self titleToolbarHeight]) / ratio;
	}
	else
	{
		frame.origin.y += oldHeight - frame.size.height;
		frame.origin.y = frame.origin.y > visibleFrame.origin.y ? frame.origin.y : visibleFrame.origin.y;
	}
		
	[[self window] setFrame:frame display:YES animate:YES];
}

- (float)titleToolbarHeight
{
	if(titleToolbarHeight == 0)
	{
		titleToolbarHeight = [[self window] frame].size.height - [radarView frame].size.height;
		[[self window] setMinSize: NSMakeSize(MIN_WIDTH, MIN_WIDTH + titleToolbarHeight)];
	}

	return titleToolbarHeight;
}

#pragma mark -
#pragma mark window delegate methods
// -----------------------------------------------------------

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	// user toggles between standard and user frame by pushing the green "zoom" button
	
	NSRect frame;
	
	frame.origin.y = newFrame.origin.y;
	frame.size.height = newFrame.size.height;
	frame.size.width = (newFrame.size.height - [self titleToolbarHeight]) / ratio;
	frame.origin.x = [[self window] frame].origin.x;
	
	return frame;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{	
	frameSize.height = frameSize.width * ratio + [self titleToolbarHeight];
	
	NSRect r = [sender frame];	
	
	if (r.origin.y < frameSize.height - r.size.height)
	{
		r.size.height += r.origin.y;
		r.origin.y = 0;
		r.size.width = (r.size.height - [self titleToolbarHeight]) / ratio;
		return r.size;
	}
	else
	{
		return frameSize;
	}
}



@end
