//
//  RandomTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "RandomTrajectory.h"
#import "CHGlobals.h"


@implementation RandomTrajectory

- (id)init
{
	self = [super init];
    if(self)
	{
        parameterBreakpointArray = [[BreakpointArray alloc] init];

		initialPosition = [Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
        [initialPosition setDescriptor:@"Init"];
        [parameterBreakpointArray addBreakpoint:initialPosition];
        
        Breakpoint *bp;
		
        // bounding volume
        bp = [Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:-0.5 Y:-0.5 Z:0]];
        [bp setDescriptor:@"Point1"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];

        bp = [Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.5 Y:0.5 Z:0]];
        [bp setDescriptor:@"Point2"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];

        // speed
        bp = [Breakpoint breakpointWithTime:0 value:0.1];
        [bp setDescriptor:@"MinSpeed"];
        [bp setTimeEditable:NO]; // initial value, time not editable
        [parameterBreakpointArray addBreakpoint:bp];
        
        bp = [Breakpoint breakpointWithTime:0 value:0.2];
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
    int stability = 1000;
    float minSpeed, maxSpeed;
    float xMin, yMin, zMin;
    float xMax, yMax, zMax;

	Breakpoint *bp;
	SpatialPosition *vector = [SpatialPosition position];	
	SpatialPosition *tempPosition;
    SpatialPosition *point1, *point2;
    
    BreakpointArray *point1Breakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Point1"];
    BreakpointArray *point2Breakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Point2"];

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
		// calculate bounding volume
        point1 = [point1Breakpoints interpolatedPositionAtTime:time];        
        point2 = [point2Breakpoints interpolatedPositionAtTime:time];
        
        if(point1.x < point2.x)
        { 
            xMin = point1.x;
            xMax = point2.x;
        }
        else
        { 
            xMin = point2.x;
            xMax = point1.x;
        }
        
        if(point1.y < point2.y)
        { 
            yMin = point1.y;
            yMax = point2.y;
        }
        else
        { 
            yMin = point2.y;
            yMax = point1.y;
        }
        
        if(point1.z < point2.z)
        { 
            zMin = point1.z;
            zMax = point2.z;
        }
        else
        { 
            zMin = point2.z;
            zMax = point1.z;
        }
        
        
        stability = [stabilityBreakpoints interpolatedValueAtTime:time] * 1000; // s to ms

		if(time == 0 || timeSegment >= stability)
		{
            minSpeed = [minSpeedBreakpoints interpolatedValueAtTime:time];
            maxSpeed = [maxSpeedBreakpoints interpolatedValueAtTime:time];

			// calculate a new vector
            vector.d = minSpeed + (float)rand() / RAND_MAX * (maxSpeed - minSpeed);
			vector.a = (float)rand() / RAND_MAX * 360;			
            
            vector.e = zMin == zMax ? 0 : (float)rand() / RAND_MAX * 360;
            
            timeSegment = 0;
		}
		
		// update breakpoint
        bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[[tempPosition copy] autorelease]];
		[bp setTime:time];
		[tempArray addObject:bp];
		
		time += timeIncrement;
		timeSegment += timeIncrement;
        
		[tempPosition setX:tempPosition.x + vector.x];
		[tempPosition setY:tempPosition.y + vector.y];
		[tempPosition setZ:tempPosition.z + vector.z];
		

        // check if tempPosition is inside bounding volume
		// - mirror position and reverse the vector
        if(tempPosition.x < xMin)
		{
			tempPosition.x = 2 * xMin - tempPosition.x;
            vector.x *= -1;
		}
		if(tempPosition.x > xMax)
		{
            tempPosition.x = 2 * xMax - tempPosition.x;
            if(tempPosition.x < xMin) tempPosition.x = xMin;
            vector.x *= -1;
		}

		if(tempPosition.y < yMin)
		{
			tempPosition.y = 2 * yMin - tempPosition.y;
            vector.y *= -1;
		}
		if(tempPosition.y > yMax)
		{
            tempPosition.y = 2 * yMax - tempPosition.y;
            if(tempPosition.y < yMin) tempPosition.y = yMin;
            vector.y *= -1;
		}
        
        if(tempPosition.z < zMin)
		{
			tempPosition.z = 2 * zMin - tempPosition.z;
            vector.z *= -1;
		}
		if(tempPosition.z > zMax)
		{
            tempPosition.z = 2 * zMax - tempPosition.z;
            if(tempPosition.z < zMin) tempPosition.z = zMin;
            vector.z *= -1;
		}
	}
	
	return [NSArray arrayWithArray:tempArray];
}

- (SpatialPosition *)point1AtTime:(NSNumber *)time
{
    BreakpointArray *point1Breakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Point1"];
    return [point1Breakpoints interpolatedPositionAtTime:[time unsignedIntegerValue]];
}

- (SpatialPosition *)point2AtTime:(NSNumber *)time
{
    BreakpointArray *point2Breakpoints = [parameterBreakpointArray filteredBreakpointArrayUsingDescriptor:@"Point2"];
    return [point2Breakpoints interpolatedPositionAtTime:[time unsignedIntegerValue]];
}



@end
