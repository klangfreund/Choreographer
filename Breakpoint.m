//
//  Breakpoint.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "Breakpoint.h"


@implementation Breakpoint

//+ (Breakpoint *)breakpointWithTime:(long)t value:(float)val
//{
//	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
//	
//	[bp setTime:t];
//	[bp setValue:val];
//	
//	return bp;
//}

+ (Breakpoint *)breakpointWithTime:(NSUInteger)t position:(SpatialPosition *)pos
{
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	[bp setTime:t];
	[bp setPosition:pos];
	
	return bp;
	
}


- (Breakpoint *)copy
{
	Breakpoint *newBp = [[Breakpoint alloc] init];
	
	[newBp setTime:time];
	[newBp setValue:value];
	[newBp setPosition:position];
	
	return newBp;
}


- (id)init
{
	if (self = [super init])
	{
		breakpointType = breakpointTypeNone;
		time = 0;
		value = 0;
		position = [[SpatialPosition alloc] init];
    }
    return self;
}

- (void)dealloc
{
	[position release];
	[super dealloc];
}


#pragma mark -
#pragma mark accessors
// ----------------------------------------------------------- 

- (void)setBreakpointType:(BreakpointType)bpType
{
	breakpointType = bpType;
}

- (BreakpointType)breakpointType
{
	return breakpointType;
}

- (void)setTime:(NSUInteger)val
{
	time = val > 0 ? val : 0;
}

- (NSUInteger)time {return time;}

- (void)setValue:(float)val
{
	value = val;	
}

- (float)value { return value; }

- (void)setPosition:(SpatialPosition *)aPosition
{
	[position release];
	position = [aPosition retain];
}

- (SpatialPosition *)position { return position; }

- (float)x { return position.x; }
- (float)y { return position.y; }
- (float)z { return position.z; }
- (float)a { return position.a; }
- (float)e { return position.e; }
- (float)d { return position.d; }

- (void)setX:(float)val { [position setX:val]; }
- (void)setY:(float)val { [position setY:val]; }
- (void)setZ:(float)val { [position setZ:val]; }




#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (id)initWithCoder:(NSCoder *)coder
{
    breakpointType = [coder decodeInt32ForKey:@"type"];
    time = [coder decodeInt32ForKey:@"time"];
    value = [coder decodeFloatForKey:@"val"];
    position = [[coder decodeObjectForKey:@"pos"] retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt32:breakpointType forKey:@"type"];
    [coder encodeInt32:time forKey:@"time"];
    [coder encodeFloat:value forKey:@"val"];
	[coder encodeObject:position forKey:@"pos"];
}

@end