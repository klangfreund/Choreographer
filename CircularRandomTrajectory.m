//
//  CircularRandomTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.07.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "CircularRandomTrajectory.h"
#import "CHGlobals.h"

@implementation CircularRandomTrajectory

- (id)init
{
    self = [super init];
    if (self) 
    {
        parameterBreakpointArray = [[BreakpointArray alloc] init];
        
		initialPosition = [Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
        [initialPosition setDescriptor:@"Init"];
        [parameterBreakpointArray addBreakpoint:initialPosition];
        
		rotationCentre = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.0 Y:0 Z:0]] retain];
        [rotationCentre setDescriptor:@"Center"];
        [parameterBreakpointArray addBreakpoint:rotationCentre];

        Breakpoint *bp;
		
        // speed
        bp = [Breakpoint breakpointWithTime:0 value:-15];
        [bp setDescriptor:@"MinSpeed"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];
        
        bp = [Breakpoint breakpointWithTime:0 value:15];
        [bp setDescriptor:@"MaxSpeed"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];
        
        // stability
        bp = [Breakpoint breakpointWithTime:0 value:1.0];
        [bp setDescriptor:@"Stability"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];
 	}
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    parameterBreakpointArray = [[coder decodeObjectForKey:@"parameterBreakpointArray"] retain];
    
    for(Breakpoint *bp in parameterBreakpointArray)
    {
        if([[bp descriptor] isEqualToString:@"Init"])
            initialPosition = [bp retain];
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
	[initialPosition release];    
	[super dealloc];
}

- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger time = 0;
    NSUInteger timeSegment = 0;
	NSUInteger duration;
	int timeIncrement = 100;
    int stability = 100;
    BOOL needsBreakpoint;
    float minSpeed, maxSpeed, currentSpeed;
    
	Breakpoint *bp;
	SpatialPosition *tempPosition;
        
    BreakpointArray *minSpeedBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"MinSpeed"];
    BreakpointArray *maxSpeedBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"MaxSpeed"];
    
    BreakpointArray *stabilityBreakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Stability"];
    
	
	if(pos)
		tempPosition = [[pos copy] autorelease];
	else
		tempPosition = [[[initialPosition position] copy] autorelease];
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
	
	if(mode == durationModeOriginal)
	{
		duration = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
		duration = duration > dur ? dur : duration;
	}
	else
		duration = dur;
    
	while(time < duration)
	{        
        stability = [stabilityBreakpoints interpolatedValueAtTime:time] * 1000; // s to ms
        
		if(time == 0 || timeSegment >= stability)
		{
            minSpeed = [minSpeedBreakpoints interpolatedValueAtTime:time];
            maxSpeed = [maxSpeedBreakpoints interpolatedValueAtTime:time];
            
			currentSpeed = minSpeed + (float)rand() / RAND_MAX * (maxSpeed - minSpeed);
            needsBreakpoint = YES;
            
            timeSegment = 0;
		}
		
		// update breakpoint
        if(needsBreakpoint)
        {
            bp = [[[Breakpoint alloc] init] autorelease];
            [bp setPosition:[[tempPosition copy] autorelease]];
            [bp setTime:time];
            [tempArray addObject:bp];
        }
		
		time += timeIncrement;
		timeSegment += timeIncrement;
        
		[tempPosition setA:tempPosition.a + currentSpeed * timeIncrement * 0.001];
	}
    
	return [NSArray arrayWithArray:tempArray];
}
@end
