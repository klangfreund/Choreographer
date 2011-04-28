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
	if(self = [super init])
	{
		rotationCentre = [[SpatialPosition positionWithX:0 Y:0 Z:0] retain];
		initialPosition = [[SpatialPosition positionWithX:0.5 Y:0 Z:0] retain];
		speed = 10;
	}
	return self;	
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    initialPosition = [[coder decodeObjectForKey:@"initialPosition"] retain];
    rotationCentre = [[coder decodeObjectForKey:@"centre"] retain];
    speed = [[coder decodeObjectForKey:@"speed"] floatValue];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:initialPosition forKey:@"initialPosition"];
    [coder encodeObject:rotationCentre forKey:@"centre"];
    [coder encodeObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
}

- (void)dealloc
{
	[initialPosition release];
	[rotationCentre release];
	[super dealloc];
}

- (void)setSpeed:(float)val
{
	speed = val;
	[trajectoryItem archiveData];
}

- (NSArray *)additionalPositions
{
	if(!initialPosition || !rotationCentre) return nil;
	
	if(![[trajectoryItem valueForKey:@"adaptiveInitialPosition"] boolValue])
	{
		return [NSArray arrayWithObjects:rotationCentre, initialPosition, nil];
	}
	else
	{
		return [NSArray arrayWithObjects:rotationCentre, nil];
	}
}

- (NSString *)additionalPositionName:(id)item
{
	if(item == initialPosition) return @"init";
	if(item == rotationCentre) return @"centre";
	
	return @"--";
}



- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger originalDur = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
	NSUInteger duration;
	NSUInteger time = 0;
	int timeIncrement = 1000. / fabs(speed);
	int azimuthIncrement = speed > 0 ? 1 : -1;
	
	Breakpoint *bp;
	SpatialPosition *tempPosition;

	if(pos)
		tempPosition = [pos copy];
	else
		tempPosition = [[initialPosition position] copy];
	
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
		
		if(mode == durationModePalindrome && (time % originalDur) == 0 && time != 0)
			azimuthIncrement *= -1;
		
		time += timeIncrement;
		[tempPosition setA:[tempPosition a] + azimuthIncrement];
	}

	return [NSArray arrayWithArray:tempArray];
}

@end
