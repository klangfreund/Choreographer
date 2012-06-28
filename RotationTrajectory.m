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
        parameterBreakpointArray = [[BreakpointArray alloc] init];

		initialPosition = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.5 Y:0 Z:0]] retain];
        [initialPosition setDescriptor:@"Init"];
        [parameterBreakpointArray addBreakpoint:initialPosition];

		rotationCentre = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.0 Y:0 Z:0]] retain];
        [rotationCentre setDescriptor:@"Center"];
        [parameterBreakpointArray addBreakpoint:rotationCentre];

        parameterMode = 0; // 0=Angle, 1=Speed
        [self resetParameters];
}

    return self;	
}

- (void)resetParameters
{
    Breakpoint *bp;
    
    if(parameterMode == 0)
    {
        bp = [Breakpoint breakpointWithTime:0 value:0];
        [bp setDescriptor:@"Angle"];
        [bp setTimeEditable:NO]; // initial angle, time not editable
        [parameterBreakpointArray addBreakpoint:bp];

        bp = [Breakpoint breakpointWithTime:[[trajectoryItem valueForKey:@"duration"] unsignedLongValue] value:360];
        [bp setDescriptor:@"Angle"];
        [parameterBreakpointArray addBreakpoint:bp];
    }
    else
    {
        bp = [Breakpoint breakpointWithTime:0 value:10];
        [bp setDescriptor:@"Speed"];
        [bp setTimeEditable:NO]; // initial speed, time not editable
        [parameterBreakpointArray addBreakpoint:bp];
    }    
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
    }
    
    parameterMode = [coder decodeIntForKey:@"parameterMode"];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:parameterBreakpointArray forKey:@"parameterBreakpointArray"];
    [coder encodeInt:parameterMode forKey:@"parameterMode"];
}

- (void)dealloc
{
    [rotationCentre release];
    [initialPosition release];
    [parameterBreakpointArray release];
	[super dealloc];
}

- (int)parameterMode
{
    return parameterMode;
}

- (void)setParameterMode:(int)val
{
    if(parameterMode != val)
    {       
        parameterMode = val;

        // TODO: do you really want - dialog

        [parameterBreakpointArray removeBreakpointsWithDescriptor:@"Speed"];
        [parameterBreakpointArray removeBreakpointsWithDescriptor:@"Angle"];

        [self resetParameters];
        [trajectoryItem updateModel];        
    }
}



- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger originalDur = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
	NSUInteger duration;
	NSUInteger time = 0;
	
	Breakpoint *bp;
	SpatialPosition *startPosition, *tempPosition;
    
    BreakpointArray *speedBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Speed"];
    BreakpointArray *angleBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Angle"];
    float speed;
    int timeIncrement;
	int azimuthIncrement;

	if(pos)
		startPosition = [[pos copy] autorelease];
	else
		startPosition = [[[initialPosition position] copy] autorelease];
    
    tempPosition = [[startPosition copy] autorelease];
	
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
        [bp setPosition:[[tempPosition copy] autorelease]];
        [bp setTime:time];
        [tempArray addObject:bp];
        
        if(parameterMode == 0)
        {
            timeIncrement = 100;
            
            if(mode == durationModeOriginal)
            {
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:time]];           
            }
            else if(mode == durationModeScaled)
            {
                double scalingFactor = (double)originalDur / dur;
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:time * scalingFactor]];
            }            
            if(mode == durationModeLoop)
            {
                [tempPosition setA:[startPosition a] + [angleBreakpoints interpolatedValueAtTime:(time % originalDur)]];                       
            }
        }
        else
        {
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
            
            [tempPosition setA:[tempPosition a] + azimuthIncrement];
        }

         time += timeIncrement;
    }

	return [NSArray arrayWithArray:tempArray];
}

@end
