//
//  BreakpointTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "CHGlobals.h"
#import "BreakpointTrajectory.h"
#import "TrajectoryItem.h"


@implementation BreakpointTrajectory

- (id)init
{
	if((self = [super init]))
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeInitial];
        [bp setTimeEditable:NO];
		
		positionBreakpointArray = [[BreakpointArray alloc] init];
        [positionBreakpointArray addBreakpoint:bp];
	}
	return self;	
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    positionBreakpointArray = [[coder decodeObjectForKey:@"posBpArray"] retain];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:positionBreakpointArray forKey:@"posBpArray"];
}

- (void)dealloc
{
	[positionBreakpointArray release];
	[super dealloc];
}


- (NSArray *)positionBreakpoints
{
	return positionBreakpointArray.breakpoints;
}



#pragma mark -
#pragma mark accessor
// -----------------------------------------------------------

- (NSUInteger)trajectoryDuration
{
	return [[positionBreakpointArray lastObject] time];
}

- (void)setTrajectoryDuration:(NSUInteger)val
{
    NSLog(@"set duration");
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
{
	if(time == -1)
	{
		if([positionBreakpointArray count] > 0)
			time = [[positionBreakpointArray lastObject] time] + 1000;
		else time = 1000;
	}
	
//	[trajectoryItem setValue:[NSNumber numberWithInt:time] forKey:@"duration"];
	
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	[bp setPosition:pos];
	[bp setTime:time];
	[bp setBreakpointType:breakpointTypeNormal];
	
	[positionBreakpointArray addBreakpoint:bp];	
	
	[trajectoryItem updateModel];
}

- (void)removeBreakpoint:(id)bp
{
	[positionBreakpointArray removeBreakpoint:bp];
}

//- (void)sortBreakpoints
//{
//	[positionBreakpointArray sort];
//}

- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	NSUInteger originalDur = [[trajectoryItem valueForKey:@"duration"] unsignedLongValue];
	Breakpoint *bp, *scaledBp;
	NSUInteger timeOffset = 0, time = 0;
	NSUInteger count, i = 0, direction = 0;

	NSMutableArray *tempArray;
	
	if(mode == durationModeScaled)
	{
		tempArray = [[[NSMutableArray alloc] init] autorelease];
		double scalingFactor = (double)dur / originalDur;
			  
		for(bp in positionBreakpointArray)
		{	
			scaledBp = [bp copy];
			scaledBp.time = bp.time * scalingFactor;
			
			[tempArray addObject:scaledBp];
		}
	}
	else if(mode == durationModeOriginal)
	{
		tempArray = [positionBreakpointArray mutableCopy];
	}
	else if(mode == durationModeLoop)
	{
		tempArray = [[[NSMutableArray alloc] init] autorelease];
		count = [positionBreakpointArray count];
		while (time < dur)
		{
			bp = [[positionBreakpointArray objectAtIndex:(i++ % count)] copy];
			if(bp.time == 0 && i != 1) // first breakpoint (NB. it is assumed that there is always a bp at time == 0)
			{
				timeOffset += originalDur;
				time = bp.time + timeOffset + 1;
			}
			else
			{
				time = bp.time + timeOffset;
			}
			
			bp.time = time;
			
			NSLog(@"time = %u", time);
			
			[tempArray addObject:bp];
		}
	}
	else if(mode == durationModePalindrome)
	{
		tempArray = [[[NSMutableArray alloc] init] autorelease];
		count = [positionBreakpointArray count];
		while (time < dur)
		{
			bp = [[positionBreakpointArray objectAtIndex:(i % count)] copy];
			if(bp.time == 0 && direction != 0) // first breakpoint (NB. it is assumed that there is always a bp at time == 0)
			{
				timeOffset += originalDur;
				time = bp.time + timeOffset;
				direction = 0; // upwards
			}
			else if(i == count-1) // last breakpoint
			{
				time = bp.time + timeOffset;
				direction = 1; // downwards
				timeOffset += originalDur;
			}
			else
			{
				if(direction == 0)
					time = bp.time + timeOffset;
				else
					time = (originalDur - bp.time + timeOffset);
			}
			
			bp.time = time;
			
			i += direction == 0 ? 1 : -1;
			
			[tempArray addObject:bp];
		}
	}


	if(pos)  // override initial position
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:pos];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeInitial];
		[tempArray replaceObjectAtIndex:0 withObject:bp];
	}
	
	
	return [NSArray arrayWithArray:tempArray];
}

@end
