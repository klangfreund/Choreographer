//
//  TrajectoryItem.h
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHGlobals.h"
#import "Breakpoint.h"
#import "Trajectory.h"


@interface TrajectoryItem : NSManagedObject
{
	Trajectory		*trajectory;
	TrajectoryType	trajectoryType;
}

// accessors
- (TrajectoryType)trajectoryType;
- (void)setTrajectoryType:(TrajectoryType)type;

// breakpoints/handles for visualisation
- (NSArray *)linkedBreakpointArray;
- (NSArray *)linkedBreakpointArrayWithInitialPosition:(SpatialPosition *)pos;
- (NSArray *)additionalPositions;
- (NSString *)additionalPositionName:(id)item;
- (SpatialPosition *)namePosition;

//- (NSEnumerator *)breakpointEnumerator;
//- (id)trajectoryAttributeForKey:(NSString *)key;

// breakpoints for audio playback
- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur;

- (void)updateModel;
- (void)undoableUpdate;


- (NSString *)trajectoryTypeString;
- (NSString*)name;

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
- (void)sortBreakpoints;
- (void)removeBreakpoint:(id)bp;

// serialisation
- (void)archiveData;
- (void)unarchiveData;

@end