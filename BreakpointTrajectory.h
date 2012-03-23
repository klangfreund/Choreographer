//
//  BreakpointTrajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Trajectory.h"
#import "BreakpointArray.h"


@interface BreakpointTrajectory : Trajectory
{
}

@property NSUInteger trajectoryDuration;

- (id)initWithDefaultBreakpoint;

// accessors
- (NSUInteger)trajectoryDuration;
- (void)setTrajectoryDuration:(NSUInteger)val;

@end
