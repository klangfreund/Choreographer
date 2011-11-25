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
		initialPosition = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]] retain];
        [initialPosition setDescriptor:@"Init"];
		boundingVolumePoint1 = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:-0.5 Y:-0.5 Z:0]] retain];
        [boundingVolumePoint1 setDescriptor:@"pt1"];
		boundingVolumePoint2 = [[Breakpoint breakpointWithPosition:[SpatialPosition positionWithX:0.5 Y:0.5 Z:0.5]] retain];
        [boundingVolumePoint2 setDescriptor:@"pt2"];
		initialMinSpeed = [[Breakpoint breakpointWithTime:0 value:0.1] retain];
        [initialMinSpeed setDescriptor:@"minSpeed"];
        [initialMinSpeed setTimeEditable:NO];
		initialMaxSpeed = [[Breakpoint breakpointWithTime:0 value:0.2] retain];
        [initialMaxSpeed setDescriptor:@"maxSpeed"];
        [initialMaxSpeed setTimeEditable:NO];

        
        parameterBreakpointArray = [[NSMutableArray arrayWithObjects:initialPosition, boundingVolumePoint1, boundingVolumePoint2, initialMinSpeed, initialMaxSpeed, nil] retain];

		stability = 1000;
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
        else if([[bp descriptor] isEqualToString:@"pt1"])
            boundingVolumePoint1 = [bp retain];
        else if([[bp descriptor] isEqualToString:@"pt2"])
            boundingVolumePoint2 = [bp retain];
        else if([[bp descriptor] isEqualToString:@"minSpeed"] && [bp time] == 0)
            initialMinSpeed = [bp retain];
        else if([[bp descriptor] isEqualToString:@"maxSpeed"] && [bp time] == 0)
            initialMaxSpeed = [bp retain];
    }

    stability = 1000;
	
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
	[boundingVolumePoint1 release];
	[boundingVolumePoint1 release];
    [initialMinSpeed release];
    [initialMaxSpeed release];
    
	[super dealloc];
}


- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger time = 0;
	NSUInteger duration;
	int timeIncrement = 100;
	BOOL flip = NO;
	
	float x = [boundingVolumePoint1 x] < [boundingVolumePoint2 x] ? [boundingVolumePoint1 x] : [boundingVolumePoint2 x];
	float y = [boundingVolumePoint1 y] < [boundingVolumePoint2 y] ? [boundingVolumePoint1 y] : [boundingVolumePoint2 y];
	
	float xDimension = fabs([boundingVolumePoint1 x] - [boundingVolumePoint2 x]);
	float yDimension = fabs([boundingVolumePoint1 y] - [boundingVolumePoint2 y]);
	
	SpatialPosition *spatialIncrement = [SpatialPosition position];

	
	Breakpoint *bp;
	SpatialPosition *tempPosition;
    
    float minSpeed = [initialMinSpeed value];
    float maxSpeed = [initialMaxSpeed value];
	
	if(pos)
		tempPosition = [pos copy];
	else
		tempPosition = [[initialPosition position] copy];
	
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
		if(0 == (time % stability))
		{
			spatialIncrement.d = minSpeed + (float)rand() / RAND_MAX * (maxSpeed - minSpeed);
			spatialIncrement.a = (float)rand() / RAND_MAX * 360;
			// - when bounding box z=0,
		}
		
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[tempPosition copy]];
		[bp setTime:time];
		[tempArray addObject:bp];
		
		time += timeIncrement;
		[tempPosition setX:tempPosition.x + spatialIncrement.x];
		[tempPosition setY:tempPosition.y + spatialIncrement.y];
		
		// tempPosition is outside boundaries
		// - mirror position and reverse the spatialIncrement
		if(tempPosition.x < x)
		{
			tempPosition.x = 2 * x - tempPosition.x;
			flip = YES;
		}
		if(tempPosition.x > x + xDimension)
		{
			tempPosition.x = 2 * (x + xDimension) - tempPosition.x;
			flip = YES;
		}
		if(tempPosition.y < y)
		{
			tempPosition.y = 2 * y - tempPosition.y;
			flip = YES;
		}
		if(tempPosition.y > y + yDimension)
		{
			tempPosition.y = 2 * (y + yDimension) - tempPosition.y;
			flip = YES;
		}
		
		if(flip)
		{
			spatialIncrement.d *= -1;
			flip = NO;
		}
	}
	
	return [NSArray arrayWithArray:tempArray];
}


@end
