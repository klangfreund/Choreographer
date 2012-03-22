//
//  Trajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 15.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BreakpointArray.h"
#import "Trajectory.h"


@interface Trajectory : NSObject <NSCoding>
{
	id trajectoryItem;
	BreakpointArray *positionBreakpointArray;
	BreakpointArray *parameterBreakpointArray;
}

@property (retain) BreakpointArray *positionBreakpointArray;
@property (retain) BreakpointArray *parameterBreakpointArray;

+ (Trajectory *)trajectoryOfType:(int)trajectoryType forItem:(id)trajectoryItem;


// breakpoints for visualisation
- (NSArray *)positionBreakpoints;
- (NSArray *)parameterBreakpoints;

// breakpoints for playback
- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode;

// breakpoints for export (SpatDIF)
//- (NSArray *)renderedPositionBreakpoints;

// accessors
- (id)trajectoryAttributeForKey:(NSString *)key;

// actions
- (void)sortBreakpoints;
- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
- (void)removeBreakpoint:(id)bp;


@end
