//
//  CircularRandomTrajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 11.07.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Trajectory.h"


@interface CircularRandomTrajectory : Trajectory
{
    Breakpoint *initialPosition;
    Breakpoint *rotationCentre;
}

@end
