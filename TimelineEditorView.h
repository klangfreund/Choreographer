//
//  TimelineEditorView.h
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BreakpointView.h"

@interface TimelineEditorView : NSView
{	
	id controller;
	
	NSArray *breakpointViews;

	int coordinateMode, gridMode, viewMode;

	float zoomFactorX;
	float nudgeAmount;
	
	// data from Editor Content
	id trajectory;
	NSString *selector;
	id editorSelection;
		
	// clicking and dragging
	id hit;
	NSPoint storedEventLocation;
	NSPoint draggingOrigin;
	id originalPosition;
	BOOL dirty;
	
	// selection
	BOOL showSelectionRectangle;
}

// drawing
- (void)drawBreakpointTrajectory;
- (void)drawAutomatedTrajectory;

// editing
- (BOOL)moveSelectedPointsBy:(NSPoint)delta;
- (void)setSelectedPointsTo:(SpatialPosition *)pos;

// utility
- (NSPoint)makePoint:(float)coordinate time:(unsigned long)time;

@end
