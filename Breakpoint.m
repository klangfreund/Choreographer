//
//  Breakpoint.m
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "Breakpoint.h"


@implementation Breakpoint

@synthesize hasTime;
@synthesize timeEditable;
@synthesize descriptor;

+ (Breakpoint *)breakpointWithTime:(long)t value:(float)val
{
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	[bp setTime:t];
	[bp setValue:val];
    [bp setBreakpointType:breakpointTypeValue];
	
	return bp;
}

+ (Breakpoint *)breakpointWithTime:(NSUInteger)t position:(SpatialPosition *)pos
{
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	[bp setTime:t];
	[bp setPosition:pos];
	
	return bp;	
}

+ (Breakpoint *)breakpointWithPosition:(SpatialPosition *)pos
{
	Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
	
	[bp setPosition:pos];
	
	return bp;	
}



- (Breakpoint *)copyWithZone:(NSZone *)zone
{
	Breakpoint *newBp = [[Breakpoint alloc] init];
	
	[newBp setTime:time];
	[newBp setValue:value];
	[newBp setPosition:position];
	
	return newBp;
}


- (id)init
{
    self = [super init];
	if (self)
	{
		position = [[SpatialPosition alloc] init];
        breakpointType = breakpointTypeNone;
		time = 0;
		value = 0;
        hasTime = NO;
        timeEditable = YES;
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
    if(timeEditable)
    {
        hasTime = YES;
        time = val;
    }
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
    hasTime = [coder decodeBoolForKey:@"has_time"];
    timeEditable = [coder decodeBoolForKey:@"time_edit"];
    descriptor = [[coder decodeObjectForKey:@"descr"] retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt32:breakpointType forKey:@"type"];
    [coder encodeInt32:time forKey:@"time"];
    [coder encodeFloat:value forKey:@"val"];
	[coder encodeObject:position forKey:@"pos"];
    [coder encodeBool:hasTime forKey:@"has_time"];
    [coder encodeBool:timeEditable forKey:@"time_edit"];
    [coder encodeObject:descriptor forKey:@"descr"];
}

@end