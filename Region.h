//
//  Region.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.08.09.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "BreakpointView.h"
#import "TrajectoryItem.h"

@class ArrangerView;

@interface Region : NSManagedObject
{
	ArrangerView *superview;
	
    NSManagedObject *trajectoryItem;
    NSManagedObject *projectSettings;

	NSMutableArray *gainBreakpointArray;
	BreakpointView *gainBreakpointView;

	NSRect frame;
	NSColor *color;
	
	NSArray *playbackBreakpointArray;
	unsigned int playbackIndex;
	
	BOOL selected, trajectorySelected;
	BOOL displaysTrajectoryPlaceholder;
	NSUInteger duration; // only used in GroupRegion subclass

	float contentOffset;
	float zoomFactorX, zoomFactorY;
}

- (void)commonAwake;

// drawing
- (void)drawRect:(NSRect)rect;
- (void)drawGainEnvelope:(NSRect)rect;
- (NSColor *)color;

// mouse
- (void)mouseDown:(NSPoint)location;
- (NSPoint)proposedMouseDrag:(NSPoint)delta;
- (void)mouseDragged:(NSPoint)delta;
- (void)mouseUp:(NSEvent *)event;

// drag & crop
- (void)moveByDeltaX:(float)deltaX deltaY:(float)deltaY;
- (void)cropByDeltaX1:(float)deltaX1 deltaX2:(float)deltaX2;

- (void)updateGainEnvelope;
- (void)updateTimeInModel;
//- (void)undoableRefreshView;

// gain
- (void)setGainBreakpointArray:(NSArray *)array;
- (void)removeSelectedGainBreakpoints;

// abstract methods
- (void)recalcFrame;
- (void)recalcWaveform;
- (float)offset;
- (void)removeFromView;
- (void)calculatePositionBreakpoints;

// accessors
- (void)setSelected:(BOOL)flag;
- (NSRect)frame;
- (void)setFrame:(NSRect)rect;
- (NSNumber *)duration;


// notifications
- (void)setZoom:(NSNotification *)notification;

// serialisation
- (void)archiveData;
- (void)unarchiveData;


@end


@interface PlaceholderRegion : NSObject
{
	NSRect frame;
	Region *region; // region a trajectory placeholder is attached to
}

+ (PlaceholderRegion *)placeholderRegionWithFrame:(NSRect)rect;

// drawing
- (void)draw;

// accessors
- (NSRect)frame;
- (void)setFrame:(NSRect)rect;

@end


