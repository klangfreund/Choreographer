//
//  Trajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 15.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "CHGlobals.h"
#import "BreakpointTrajectory.h"
#import "RotationTrajectory.h"
#import "RandomTrajectory.h"
#import "CircularRandomTrajectory.h"


@implementation Trajectory

@synthesize positionBreakpointArray;
@synthesize parameterBreakpointArray;

+ (Trajectory *)trajectoryOfType:(int)trajectoryType forItem:(id)trajectoryItem
{
	Trajectory *trajectory = nil;
	
	switch(trajectoryType)
	{
		case breakpointType:
			trajectory = [[[BreakpointTrajectory alloc] initWithDefaultBreakpoint] autorelease];
			break;
		case rotationSpeedType:
		case rotationAngleType:
			[trajectoryItem setValue:[NSNumber numberWithInt:1000] forKey:@"duration"];
			[trajectoryItem setValue:[NSNumber numberWithBool:YES] forKey:@"adaptiveInitialPosition"];
			trajectory = [[[RotationTrajectory alloc] initWithTrajectoryItem:trajectoryItem] autorelease];
			break;
		case randomType:
			[trajectoryItem setValue:[NSNumber numberWithInt:1000] forKey:@"duration"];
			[trajectoryItem setValue:[NSNumber numberWithBool:YES] forKey:@"adaptiveInitialPosition"];
			trajectory = [[[RandomTrajectory alloc] init] autorelease];
			break;
		case circularRandomType:
			[trajectoryItem setValue:[NSNumber numberWithInt:1000] forKey:@"duration"];
			[trajectoryItem setValue:[NSNumber numberWithBool:YES] forKey:@"adaptiveInitialPosition"];
			trajectory = [[[CircularRandomTrajectory alloc] init] autorelease];
			break;
	}
		
	return trajectory;
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

#pragma mark -

- (NSArray *)positionBreakpoints { return nil; }

- (NSArray *)parameterBreakpoints
{
    return parameterBreakpointArray.breakpoints;
}

- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos
                                               duration:(long)dur
                                                   mode:(int)mode { return nil; }

//- (id)trajectoryAttributeForKey:(NSString *)key
//{
//    return [self valueForKey:key];
//}

- (void)sortBreakpoints
{
	[positionBreakpointArray sort];
	[parameterBreakpointArray sort];
}

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
{
	NSBeep();
}

- (void)removeBreakpoint:(id)bp
{
	[positionBreakpointArray removeBreakpoint:bp];
	[parameterBreakpointArray removeBreakpoint:bp];
}

@end
