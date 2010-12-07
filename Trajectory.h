//
//  Trajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 15.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Breakpoint.h"
#import "Trajectory.h"


@interface Trajectory : NSObject <NSCoding>
{
	id trajectoryItem;
	unsigned long duration;

	SpatialPosition	*initialPosition;
}

+ (Trajectory *)trajectoryOfType:(int)trajectoryType;

// breakpoints for visualisation
- (NSArray *)linkedBreakpoints;
- (NSArray *)additionalPositions;
- (NSString *)additionalPositionName:(id)item;

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
- (void)removeBreakpoint:(id)bp;

// abstract
- (void)sortBreakpoints;
- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode;
- (id)trajectoryAttributeForKey:(NSString *)key;



@end
