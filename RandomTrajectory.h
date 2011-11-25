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
	NSUInteger stability;
	
    Breakpoint *initialPosition;
	Breakpoint *boundingVolumePoint1, *boundingVolumePoint2;
    Breakpoint *initialMinSpeed, *initialMaxSpeed;
}

@end
