//
//  TimelineEditorView.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "BreakpointView.h"

@interface TimelineEditorView : NSView
{	
	id controller;
	
	NSArray *breakpointViews;
    NSUInteger numOfBreakpointViews;

	int coordinateMode, gridMode, viewMode;

	float nudgeAmount;
	
	// data from Editor Content
	id displayedTrajectories;
	id editableTrajectory;
	NSString *selector;
	id editorSelection;
		
	// clicking and dragging
	id hit;
	NSPoint storedEventLocation;
	NSPoint draggingOrigin;
	id originalPosition;
}

- (void)setupSubviews;

// drawing
//- (void)drawBreakpointTrajectory;
//- (void)drawAutomatedTrajectory;
- (void)redraw;

// editing
- (void)moveSelectedPointsBy:(NSPoint)delta;
- (void)setSelectedPointsTo:(SpatialPosition *)pos;

// keyboard events
- (void)nudge:(NSEvent *)event;

// utility
- (NSPoint)makePoint:(float)coordinate time:(unsigned long)time;


@end
