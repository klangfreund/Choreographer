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
	if(self = [super init])
	{
		initialPosition = [[SpatialPosition positionWithX:0.0 Y:0 Z:0] retain];
		boundingVolumePoint1 = [[SpatialPosition positionWithX:-0.5 Y:-0.5 Z:0] retain];
		boundingVolumePoint2 = [[SpatialPosition positionWithX:0.5 Y:0.5 Z:0.5] retain];
		minSpeed = 0.1;
		maxSpeed = 0.2;
		stability = 1000;
	}
	return self;	
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    initialPosition = [[coder decodeObjectForKey:@"initialPosition"] retain];
    boundingVolumePoint1 = [[coder decodeObjectForKey:@"boundingVolumePoint1"] retain];
    boundingVolumePoint2 = [[coder decodeObjectForKey:@"boundingVolumePoint2"] retain];
    minSpeed = [[coder decodeObjectForKey:@"minSpeed"] floatValue];
    maxSpeed = [[coder decodeObjectForKey:@"maxSpeed"] floatValue];
    stability = [[coder decodeObjectForKey:@"stability"] unsignedLongValue];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	NSLog(@"encode with coder");
    [super encodeWithCoder:coder];
    [coder encodeObject:initialPosition forKey:@"initialPosition"];
    [coder encodeObject:boundingVolumePoint1 forKey:@"boundingVolumePoint1"];
    [coder encodeObject:boundingVolumePoint2 forKey:@"boundingVolumePoint2"];
    [coder encodeObject:[NSNumber numberWithFloat:minSpeed] forKey:@"minSpeed"];
    [coder encodeObject:[NSNumber numberWithFloat:maxSpeed] forKey:@"maxSpeed"];
    [coder encodeObject:[NSNumber numberWithUnsignedLong:stability] forKey:@"stability"];
}

- (void)dealloc
{
	[initialPosition release];
	[boundingVolumePoint1 release];
	[boundingVolumePoint1 release];
	[super dealloc];
}


- (NSArray *)additionalPositions
{
	if(!initialPosition || !boundingVolumePoint1 || !boundingVolumePoint2) return nil;
	
	if(![[trajectoryItem valueForKey:@"adaptiveInitialPosition"] boolValue])
	{
		return [NSArray arrayWithObjects:boundingVolumePoint1, boundingVolumePoint2, initialPosition, nil];
	}
	else
	{
		return [NSArray arrayWithObjects:boundingVolumePoint1, boundingVolumePoint2, nil];
	}
}

- (NSString *)additionalPositionName:(id)item
{
	if(item == initialPosition) return @"init";
	if(item == boundingVolumePoint1) return @"pt1";
	if(item == boundingVolumePoint2) return @"pt2";
	
	return @"--";
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
