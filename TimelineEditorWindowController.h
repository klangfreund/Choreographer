//
//  TimelineEditorWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "EditorWindowController.h"
#import "TimelineEditorView.h"
#import "RulerScrollView.h"
#import "ArrangerScrollView.h"


@interface TimelineEditorWindowController : EditorWindowController
{
	IBOutlet TimelineEditorView *view;
	TrajectoryType trajectoryType;

	IBOutlet RulerScrollView			*rulerScrollView;
    IBOutlet ArrangerScrollView			*arrangerScrollView;
}

+ (id)sharedTimelineEditorWindowController;

- (void)refreshView;
- (void)adjustView;

@end
