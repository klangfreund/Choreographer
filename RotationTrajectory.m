//
//  RotationTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 16.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "RotationTrajectory.h"


@implementation RotationTrajectory

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    initialPosition = [[coder decodeObjectForKey:@"initialPosition"] retain];
    rotationCentre = [[coder decodeObjectForKey:@"centre"] retain];
    speed = [[coder decodeObjectForKey:@"speed"] floatValue];
	
	NSLog(@"unarchiveData %@ %@", self, rotationCentre);
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

// accessors
//- (void)initialPosition:(SpatialPosition *)pos
//{
//	if(initialPosition != pos)
//	{
//		[initialPosition release];
//		initialPosition = [pos retain];
//	}
//}
//
//- (void)rotationCentre:(SpatialPosition *)pos
//{
//	if(rotationCentre != pos)
//	{
//		[rotationCentre release];
//		rotationCentre = [pos retain];
//	}
//}


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
	long time = 0;
	int timeIncrement = 1000. / fabs(speed);
	int azimuthIncrement = speed > 0 ? 1 : -1;
	
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
		[tempPosition setA:[tempPosition a] + azimuthIncrement];
	}

	return [NSArray arrayWithArray:tempArray];
}

@end
