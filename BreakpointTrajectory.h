//
//  BreakpointTrajectory.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Trajectory.h"


@interface BreakpointTrajectory : Trajectory
{
	NSMutableArray *breakpointArray;
}

// accessor
- (NSUInteger)duration;
@end
