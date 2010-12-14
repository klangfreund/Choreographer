//
//  RandomTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "RandomTrajectory.h"


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
		stability = 0;
		[trajectoryItem setValue:[NSNumber numberWithInt:1000] forKey:@"duration"];
		[trajectoryItem setValue:[NSNumber numberWithBool:YES] forKey:@"adaptiveInitialPosition"];
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
    stability = [[coder decodeObjectForKey:@"stability"] floatValue];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:initialPosition forKey:@"initialPosition"];
    [coder encodeObject:boundingVolumePoint1 forKey:@"boundingVolumePoint1"];
    [coder encodeObject:boundingVolumePoint2 forKey:@"boundingVolumePoint2"];
    [coder encodeObject:[NSNumber numberWithFloat:minSpeed] forKey:@"minSpeed"];
    [coder encodeObject:[NSNumber numberWithFloat:maxSpeed] forKey:@"maxSpeed"];
    [coder encodeObject:[NSNumber numberWithFloat:stability] forKey:@"stability"];
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
	long time = 0;
	int timeIncrement = 100;
	
	float x = [boundingVolumePoint1 x] < [boundingVolumePoint2 x] ? [boundingVolumePoint1 x] : [boundingVolumePoint2 x];
	float y = [boundingVolumePoint1 y] < [boundingVolumePoint2 y] ? [boundingVolumePoint1 y] : [boundingVolumePoint2 y];
	
	float xDimension = fabs([boundingVolumePoint1 x] - [boundingVolumePoint2 x]);
	float yDimension = fabs([boundingVolumePoint1 y] - [boundingVolumePoint2 y]);
	
	Breakpoint *bp;
	SpatialPosition *tempPosition;
	
	if(pos)
		tempPosition = [pos copy];
	else
		tempPosition = [[initialPosition position] copy];
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
	
	while(time < dur)
	{
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[tempPosition copy]];
		[bp setTime:time];
		[tempArray addObject:bp];
		
		time += timeIncrement;
		[tempPosition setX:x + (float)rand() / RAND_MAX * xDimension];
		[tempPosition setY:y + (float)rand() / RAND_MAX * yDimension];
	}
	
	return [NSArray arrayWithArray:tempArray];
}


@end
