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
	TrajectoryItem *trajectory;

	IBOutlet RulerScrollView			*rulerScrollView;
    IBOutlet ArrangerScrollView			*arrangerScrollView;
}

+ (id)sharedTimelineEditorWindowController;

- (void)refreshView;

// actions
- (IBAction)xZoomIn:(id)sender;
- (IBAction)xZoomOut:(id)sender;
- (IBAction)yZoomIn:(id)sender;
- (IBAction)yZoomOut:(id)sender;


@end
