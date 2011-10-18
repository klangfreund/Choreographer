//
//  RotationTrajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 16.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Trajectory.h"
#import "BreakpointArray.h"


@interface RotationTrajectory : Trajectory
{
    Breakpoint *rotationCentre;
    Breakpoint *initialPosition;
    Breakpoint *initialSpeed;
}

// accessors
- (void)setInitialSpeed:(float)val;


@end
