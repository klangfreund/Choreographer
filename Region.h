//
//  Region.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.08.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "BreakpointView.h"
#import "AudioItem.h"
#import "TrajectoryItem.h"

@class ArrangerView;

@interface Region : NSManagedObject
{
	ArrangerView *superview;
	
    NSManagedObject *projectSettings;

	BreakpointArray *gainBreakpointArray;
	BreakpointView *gainBreakpointView;

	NSRect frame;
	NSRect trajectoryRect, trajectoryFrame;
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
- (void)drawFrame:(NSRect)rect;
- (NSColor *)color;

// mouse
- (void)mouseDown:(NSPoint)location;
- (NSPoint)proposedMouseDrag:(NSPoint)delta;
- (void)mouseDragged:(NSPoint)delta;
- (void)mouseUp:(NSEvent *)event;

// drag & crop
- (void)moveByDeltaX:(float)deltaX deltaY:(float)deltaY;
- (void)cropByDeltaX1:(float)deltaX1 deltaX2:(float)deltaX2;

- (void)updateTimeInModel;
//- (void)undoableRefreshView;

// gain
//- (void)setGainBreakpointArray:(NSArray *)array;
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
- (NSRect)trajectoryFrame;
- (NSNumber *)duration;
- (void)setGainBreakpointArray:(BreakpointArray *)gainBreakpointArray;

// position
- (void)modulateTrajectory;


// notifications
- (void)setZoom:(NSNotification *)notification;

// serialisation
- (void)archiveData;
- (void)unarchiveData;


@end


@interface PlaceholderRegion : NSObject
{
	NSRect frame;
	NSString *filePath;		// the file path (dragging from finder)
	AudioItem *audioItem;	// the audio item the placeholder stands for (dragging audio regions)
	Region *region;			// the region a trajectory placeholder is attached to (dragging trajectories)
}

+ (PlaceholderRegion *)placeholderRegionWithFrame:(NSRect)rect;

// drawing
- (void)draw;

// accessors
- (NSRect)frame;
- (void)setFrame:(NSRect)rect;

@end


