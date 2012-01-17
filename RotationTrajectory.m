//
//  RotationTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 16.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "RotationTrajectory.h"
#import "TrajectoryItem.h"


@implementation RotationTrajectory

- (id)init
{
    self = [super init];
	if(self)
	{
		initialPosition = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.5 Y:0 Z:0]] retain];
        [initialPosition setDescriptor:@"Init"];
		rotationCentre = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.0 Y:0 Z:0]] retain];
        [rotationCentre setDescriptor:@"Center"];
		initialSpeed = [[Breakpoint breakpointWithTime:0 value:10] retain];
        [initialSpeed setDescriptor:@"Speed"];
        [initialSpeed setTimeEditable:NO];
        
        parameterBreakpointArray = [[BreakpointArray alloc] init];
        [parameterBreakpointArray addBreakpoint:initialPosition];
        [parameterBreakpointArray addBreakpoint:rotationCentre];
        [parameterBreakpointArray addBreakpoint:initialSpeed];
	}
	return self;	
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    parameterBreakpointArray = [[coder decodeObjectForKey:@"parameterBreakpointArray"] retain];

    for(Breakpoint *bp in parameterBreakpointArray)
    {
        if([[bp descriptor] isEqualToString:@"Center"])
            rotationCentre = [bp retain];
        else if([[bp descriptor] isEqualToString:@"Init"])
            initialPosition = [bp retain];
        else if([[bp descriptor] isEqualToString:@"Speed"] && [bp time] == 0)
            initialSpeed = [bp retain];
    }

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:parameterBreakpointArray forKey:@"parameterBreakpointArray"];
}

- (void)dealloc
{
    [rotationCentre release];
    [initialPosition release];
    [initialSpeed release];
    [parameterBreakpointArray release];
	[super dealloc];
}

- (void)setInitialSpeed:(float)val
{
    [initialSpeed setValue:val];
	[trajectoryItem archiveData];
}

//- (NSArray *)additionalPositions
//{
//    return nil;
//}
//
//- (NSString *)additionalPositionName:(id)item
//{
//	return @"- nil -";
//}


- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger originalDur = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
	NSUInteger duration;
	NSUInteger time = 0;
	
	Breakpoint *bp;
	SpatialPosition *startPosition, *tempPosition;
    
    BreakpointArray *speedBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Speed"];
    float speed;
    int timeIncrement;
	int azimuthIncrement;

	if(pos)
		startPosition = [pos copy];
	else
		startPosition = [[initialPosition position] copy];
    
    tempPosition = [startPosition copy];
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];

	if(mode == durationModeOriginal)
	{
		duration = originalDur;
		duration = duration > dur ? dur : duration;
	}
	else
		duration = dur;
	
	while(time < duration)
	{
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[tempPosition copy]];
		[bp setTime:time];
		[tempArray addObject:bp];
        
        speed = [speedBreakpoints interpolatedValueAtTime:time];
		timeIncrement = 1000. / fabs(speed);
        azimuthIncrement = speed > 0 ? 1 : -1;
        
		if(mode == durationModeLoop && (time % originalDur) < timeIncrement && time > timeIncrement)
        {
            [tempPosition setA:[startPosition a]];
            time -= (time % originalDur);
        }
        else if(mode == durationModePalindrome && (time % originalDur) < timeIncrement && time > timeIncrement)
			azimuthIncrement *= -1;
		
		time += timeIncrement;
		[tempPosition setA:[tempPosition a] + azimuthIncrement];
	}

	return [NSArray arrayWithArray:tempArray];
}

@end
