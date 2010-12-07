//
//  RadarEditorView.m
//  Choreographer
//
//  Created by Philippe Kocher on 18.02.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrajectoryItem.h"
#import "SpatialPosition.h"
#import "AudioRegion.h"

typedef struct _RadarPoint
{
	float	x, y1, y2;
} RadarPoint;


@interface RadarEditorView : NSView
{	
	id controller;
	
	int coordinateMode, gridMode, viewMode;

	float radarSize, offset;

	NSBezierPath *gridPath;
	
	// Context Menu
	IBOutlet id nudgeAngleMenu;
	IBOutlet id nudgeUnitMenu;
	
	// data from Editor Content
	id editorSelection;
	id displayedTrajectories;
	id editableTrajectory;
	
	SpatialPosition *tempAudioRegionPosition; // the region currently drawn
	
	// clicking and dragging
	id hit;
	NSPoint storedEventLocationInView;
	NSPoint draggingOrigin;
	id originalPosition;
	int activeAreaOfDisplay; // 0 = top (xy), 1 = bottom (xz)
	BOOL dirty;
	
	// selection
	BOOL showSelectionRectangle;
	
	// colors
	NSColor *backgroundColor;
	NSColor *circleColor;  
	NSColor *gridColor;

	NSColor *handleFrameColorEditable;
	NSColor *handleFrameColorNonEditable;  
	NSColor *handleFillColorEditable;
	NSColor *handleFillColorNonEditable;  
	NSColor *handleFillColorSelected;  
	NSColor *lineColorEditable;  
	NSColor *lineColorNonEditable;  

	// string attributes
	NSDictionary *attributesRegion;
	NSDictionary *attributesEditable;
	NSDictionary *attributesNonEditable;
}

- (void)recalculateGridPath;

// drawing
- (void)drawRegionPositions:(NSRect)rect;
- (void)drawTrajectories:(NSRect)rect;

- (void)drawLinkedBreakpoints:(TrajectoryItem *)trajectory forRegion:(AudioRegion *)region;
- (void)drawAdditionalHandles:(TrajectoryItem *)trajectory;
- (void)drawAdditionalShapes:(TrajectoryItem *)trajectory forRegion:(AudioRegion *)region;

//- (void)drawRotationTrajectory:(id)trajectory;
//- (void)drawRandomTrajectory:(id)trajectory;

// IB actions
- (IBAction)gridModeMenu:(id)sender;

// editing
- (BOOL)moveSelectedPointsBy:(NSPoint)delta;
- (BOOL)rotateSelectedPointsBy:(NSPoint)delta;
- (void)setSelectedPointsTo:(SpatialPosition *)pos;

// keyboard events
- (void)nudge:(NSEvent *)event;

// accessors
- (void)setViewMode:(int)value;

// utility
- (RadarPoint)makePointX:(float)xCoordinate Y:(float)yCoordinate Z:(float)zCoordinate;

@end


