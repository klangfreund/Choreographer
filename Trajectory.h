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

// actions
- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
- (void)removeBreakpoint:(id)bp;

// abstract
- (void)sortBreakpoints;
- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode;
- (id)trajectoryAttributeForKey:(NSString *)key;



@end
