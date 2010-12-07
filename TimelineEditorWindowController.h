//
//  TimelineEditorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "EditorWindowController.h"
#import "TimelineEditorView.h"


@interface TimelineEditorWindowController : EditorWindowController
{
	IBOutlet TimelineEditorView *view;
	TrajectoryType trajectoryType;
}

+ (id)sharedTimelineEditorWindowController;

- (void)refreshView;
- (void)adjustView;

@end
