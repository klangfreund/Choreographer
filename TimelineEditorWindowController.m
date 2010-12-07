//
//  TimelineEditorWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TimelineEditorWindowController.h"

static TimelineEditorWindowController *sharedTimelineEditorWindowController = nil;

@implementation TimelineEditorWindowController

+ (id)sharedTimelineEditorWindowController
{
    if (!sharedTimelineEditorWindowController)
	{
        sharedTimelineEditorWindowController = [[TimelineEditorWindowController alloc] init];
    }
    return sharedTimelineEditorWindowController;
}


- (id)init
{
	self = [self initWithWindowNibName:@"TimelineEditor"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"TimelineEditor"];
		
		trajectoryType = notSet;
    }
    return self;
}

//- (void)dealloc
//{
//	[super dealloc];
//}

- (void) refreshView
{
	TrajectoryItem *trajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
	TrajectoryType tempTrajectoryType = [[trajectory valueForKey:@"trajectoryType"] intValue];
	if (trajectoryType != tempTrajectoryType)
	{
		trajectoryType = tempTrajectoryType;
		[self adjustView];
	} 
	
	[view setNeedsDisplay:YES];
}

- (void)adjustView
{
//	NSRect frame = [timelineView frame];
//	
//	frame.origin.y = [[[timelineView superview] superview] frame].size.height - 3 * TIMELINE_EDITOR_DATA_HEIGHT;
//	frame.size.height = 3 * TIMELINE_EDITOR_DATA_HEIGHT;
//	[timelineView setFrame:frame];
//	
//	frame.size.height = TIMELINE_EDITOR_DATA_HEIGHT;
//	frame.origin.y = 2 * TIMELINE_EDITOR_DATA_HEIGHT; 
//	[subview1 setFrame:frame];
//	
//	frame.origin.y = TIMELINE_EDITOR_DATA_HEIGHT;
//	[subview2 setFrame:frame];
//	
//	frame.origin.y = 0;
//	[subview3 setFrame:frame];
}


@end
