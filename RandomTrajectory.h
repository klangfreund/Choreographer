//
//  RandomTrajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 21.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Trajectory.h"


@interface RandomTrajectory : Trajectory
{
    Breakpoint *initialPosition;
}

- (SpatialPosition *)point1AtTime:(NSNumber *)time;
- (SpatialPosition *)point2AtTime:(NSNumber *)time;

@end
