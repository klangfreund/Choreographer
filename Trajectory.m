//
//  Trajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 15.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "CHGlobals.h"
#import "BreakpointTrajectory.h"
#import "RotationTrajectory.h"
#import "RandomTrajectory.h"


@implementation Trajectory

+ (Trajectory *)trajectoryOfType:(int)trajectoryType
{
	Trajectory *trajectory = nil;
	
	switch(trajectoryType)
	{
		case breakpointType:
			trajectory = [[[BreakpointTrajectory alloc] init] autorelease];
			break;
		case rotationType:
			trajectory = [[[RotationTrajectory alloc] init] autorelease];
			break;
		case randomType:
			trajectory = [[[RandomTrajectory alloc] init] autorelease];
			break;
	}
		
	return trajectory;
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    duration = [[coder decodeObjectForKey:@"duration"] unsignedLongValue];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSNumber numberWithUnsignedLong:duration] forKey:@"duration"];
}



// breakpoints for visualisation
- (NSArray *)linkedBreakpoints { return nil; }
- (NSArray *)additionalPositions { return nil; }
- (NSString *)additionalPositionName:(id)item { return @"add..."; }


- (void)sortBreakpoints {}
- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode { return nil; }

- (id)trajectoryAttributeForKey:(NSString *)key { return [self valueForKey:key]; }


- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
{
	NSBeep();
}

- (void)removeBreakpoint:(id)bp
{
	NSBeep();
}

@end
