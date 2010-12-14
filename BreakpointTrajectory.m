//
//  BreakpointTrajectory.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.06.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "CHGlobals.h"
#import "BreakpointTrajectory.h"
#import "TrajectoryItem.h"


@implementation BreakpointTrajectory

- (id)init
{
	if(self = [super init])
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeInitial];
		
		breakpointArray = [[NSMutableArray arrayWithObject:bp] retain];
	}
	return self;	
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    breakpointArray = [[coder decodeObjectForKey:@"breakpointArray"] retain];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:breakpointArray forKey:@"breakpointArray"];
}

- (void)dealloc
{
	[breakpointArray release];
	[super dealloc];
}


- (NSArray *)linkedBreakpoints
{
	return breakpointArray;
}



#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
{
	if(time == -1)
	{
		if([breakpointArray count] > 0)
			time = [[breakpointArray lastObject] time] + 1000;
		else time = 1000;
	}
	
	[trajectoryItem setValue:[NSNumber numberWithInt:time] forKey:@"duration"];
	
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	[bp setPosition:pos];
	[bp setTime:time];
	[bp setBreakpointType:breakpointTypeNormal];
	
	[breakpointArray addObject:bp];	
	
	[trajectoryItem updateModel];
}

- (void)removeBreakpoint:(id)bp
{
	if([breakpointArray indexOfObject:bp] == 0) // first breakpoint can't be removed
		NSBeep();
	else
		[breakpointArray removeObject:bp];
}

- (void)sortBreakpoints
{
	NSArray *breakpointsArraySorted;
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
	breakpointsArraySorted = [breakpointArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	[breakpointArray removeAllObjects];
	[breakpointArray addObjectsFromArray:breakpointsArraySorted];
}

- (NSArray *)playbackBreakpointArrayWithInitialPosition:(SpatialPosition *)pos duration:(long)dur mode:(int)mode
{
	if(!pos)
		return [NSArray arrayWithArray:breakpointArray];
	
	// adaptive initial breakpoint
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	if(pos)
	{
		[bp setPosition:pos];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeInitial];
	}
//	else
//	{
//		[bp setPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
//		[bp setTime:0];
//		[bp setBreakpointType:breakpointTypeAdaptiveInitial];
//	}
	
	NSMutableArray *tempArray = [breakpointArray mutableCopy];
	[tempArray replaceObjectAtIndex:0 withObject:bp];
	
	return tempArray;

}

@end
