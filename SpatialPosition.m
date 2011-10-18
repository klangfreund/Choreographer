//
//  SpatialPosition.m
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SpatialPosition.h"


@implementation SpatialPosition

+ (SpatialPosition *)position
{
	return [[[SpatialPosition alloc] init] autorelease];
}
	
+ (SpatialPosition *)positionWithX:(float)x Y:(float)y Z:(float)z
{
	SpatialPosition *pos = [[[SpatialPosition alloc] init] autorelease];
	
	[pos setX:x];
	[pos setY:y];
	[pos setZ:z];
	
	return pos;
}


- (id)init
{    
    self = [super init];
	if(self)
	{
		x = y = z = 0;
		a = e = d = 0;
	}
	return self;
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (SpatialPosition *)position { return self; }


- (void)setX:(float)value
{
	x = value;
	[self cartopol];
}

- (void)setY:(float)value
{
	y = value;
	[self cartopol];
}

- (void)setZ:(float)value
{
	z = value;
	[self cartopol];
}

- (void)setA:(float)value
{
	a = value;
	[self poltocar];
}

- (void)setE:(float)value
{
	e = value;
	[self poltocar];
}

- (void)setD:(float)value
{
	d = value;
	[self poltocar];
}

- (float)x { return x; }
- (float)y { return y; }
- (float)z { return z; }
- (float)a { return a; }
- (float)e { return e; }
- (float)d { return d; }


- (id)copyWithZone:(NSZone *)zone
{
	SpatialPosition *copy = [[[SpatialPosition alloc] init] autorelease];
	[copy setX:x];
	[copy setY:y];
	[copy setZ:z];

	return copy;
}

#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (id)initWithCoder:(NSCoder *)coder
{
    x = [coder decodeDoubleForKey:@"x"];
    y = [coder decodeDoubleForKey:@"y"];
    z = [coder decodeDoubleForKey:@"z"];

	[self cartopol];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeDouble:x forKey:@"x"];
    [coder encodeDouble:y forKey:@"y"];
    [coder encodeDouble:z forKey:@"z"];
}


#pragma mark -
#pragma mark mathematics
// -----------------------------------------------------------

#define PI 3.141593

- (void)cartopol		// xyz to aed
{
	a = atan2(x, y) / PI * 180;
	e = atan2(z, pow(pow(y,2)+pow(x,2),0.5)) / PI * 180;
	d = pow(pow(x,2)+pow(y,2)+pow(z,2), 0.5);
}

- (void)poltocar		// aed to xyz
{
	x = cos((90 - a) / 180 * PI) * cos(e / 180 * PI) * d;
	y = sin((90 - a) / 180 * PI) * cos(e / 180 * PI) * d;
	z = sin(e / 180 * PI) * d;
}

@end
