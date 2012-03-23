//
//  BreakpointArray.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "BreakpointArray.h"
#import "Breakpoint.h"



@implementation BreakpointArray

@synthesize breakpoints;

- (id)init
{
    self = [super init];
    if (self)
    {
        breakpoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [breakpoints release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
    breakpoints = [[coder decodeObjectForKey:@"bp"] retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:breakpoints forKey:@"bp"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BreakpointArray *copy = [[[self class] allocWithZone: zone] init];
    [copy setBreakpoints:[[self breakpoints] mutableCopyWithZone:zone]];
    return copy;
}

#pragma mark -
#pragma mark deriving new arrays
// -----------------------------------------------------------------------------

- (BreakpointArray *)filteredBreakpointArrayUsingDescriptor:(NSString *)descriptor
{
    BreakpointArray* filteredArray = [[[BreakpointArray alloc] init] autorelease];
    
    for(Breakpoint *bp in breakpoints)
    {
        if([bp.descriptor isEqualToString:descriptor])
        {
            [filteredArray addBreakpoint:bp];
        }
    }
    
    return filteredArray;
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------------------------

- (NSUInteger)count
{
    return [breakpoints count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [breakpoints objectAtIndex:index];
}

- (id)lastObject
{
    return [breakpoints lastObject];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
    return [breakpoints countByEnumeratingWithState:state objects:stackbuf count:len];
}



#pragma mark -
#pragma mark crop
// -----------------------------------------------------------------------------

- (void)cropStart:(float)start duration:(float)duration
{
	NSMutableArray *tempArray = [breakpoints copy];
    Breakpoint *bp;
    
    float startValue = [self interpolatedValueAtTime:start];
    float endValue = [self interpolatedValueAtTime:start + duration];
    
	for(bp in tempArray)
	{
        if(bp.time < start ||
		   bp.time > start + duration)
		{
			[breakpoints removeObject:bp];
		}
		else
		{
			bp.time -= start;
		}
	}
    
	// if the breakpoint array has been emptied
    // add a breakpoint at the beginning
	if(![breakpoints count])
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:startValue];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeValue];
		[breakpoints addObject:bp];	
	}
    
    // set interpolated values if appropriate
    if([(Breakpoint *)[breakpoints objectAtIndex:0] value] != startValue)
    {
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:startValue];
		[bp setTime:0];
		[bp setBreakpointType:breakpointTypeValue];
        [breakpoints insertObject:bp atIndex:0];
	}
    
    if([(Breakpoint *)[breakpoints lastObject] value] != endValue)
    {
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:endValue];
		[bp setTime:duration];
		[bp setBreakpointType:breakpointTypeValue];
        [breakpoints addObject:bp];
	}

}


#pragma mark -
#pragma mark interpolated values
// -----------------------------------------------------------------------------
- (SpatialPosition *)interpolatedPositionAtTime:(NSUInteger)time
{
    Breakpoint *bp1, *bp2;
    
    for(Breakpoint *bp in breakpoints)
    {
        if([bp time] == time)
            return [bp position];
        
        if([bp time] < time)
        {
            bp1 = bp;
        }
        else
        {
            bp2 = bp;
            break;
        }
    }
    
	float factor = (float)(time - [bp1 time]) / ([bp2 time] - [bp1 time]);
	
	return [SpatialPosition positionWithX:[bp1 x] * (1 - factor) + [bp2 x] * factor
										Y:[bp1 y] * (1 - factor) + [bp2 y] * factor
										Z:[bp1 z] * (1 - factor) + [bp2 z] * factor];
}

- (float)interpolatedValueAtTime:(NSUInteger)time
{
    Breakpoint *bp1, *bp2 = nil;
    
    if([breakpoints count] == 1 || time == 0)
        return [(Breakpoint *)[breakpoints objectAtIndex:0] value];
    
    for(Breakpoint *bp in breakpoints)
    {
        if([bp time] == time)
            return [bp value];
        
        if([bp time] < time)
        {
            bp1 = bp;
        }
        else
        {
            bp2 = bp;
            break;
        }
    }
    
    if(!bp2) return [bp1 value];
    
	float factor = (float)(time - [bp1 time]) / ([bp2 time] - [bp1 time]); 
	return [bp1 value] * (1 - factor) + [bp2 value] * factor;
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)addBreakpoint:(Breakpoint *)bp
{
	[breakpoints addObject:bp];
    [self sort];
}

- (void)addBreakpointAtPosition:(SpatialPosition *)pos time:(unsigned long)time;
{
	if(time == -1)
	{
		if([breakpoints count] > 0)
			time = [[breakpoints lastObject] time] + 1000;
		else time = 1000;
	}
	
    //	[trajectoryItem setValue:[NSNumber numberWithInt:time] forKey:@"duration"];
	
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	[bp setPosition:pos];
	[bp setTime:time];
	[bp setBreakpointType:breakpointTypeNormal];
	
	[breakpoints addObject:bp];	
}

- (void)removeBreakpoint:(id)bp
{
	if([breakpoints count] > 1 && // only breakpoint can't be removed
       ([breakpoints indexOfObject:bp] != 0 || [bp timeEditable]))  // first breakpoint can't be removed
    {
		[breakpoints removeObject:bp];
    }
}

- (void)sort
{
	NSArray *breakpointsSorted;
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
	breakpointsSorted = [breakpoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	[breakpoints removeAllObjects];
	[breakpoints addObjectsFromArray:breakpointsSorted];
}


@end
