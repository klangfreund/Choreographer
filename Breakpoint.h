//
//  Breakpoint.h
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpatialPosition.h"

typedef enum _BreakpointType
{
	breakpointTypeNone = 0,
	breakpointTypeNormal,
	breakpointTypeInitial,
	breakpointTypeAdaptiveInitial,
	breakpointTypeAudioRegion,
	breakpointTypeCentre,
	breakpointTypeAuxiliary,
} BreakpointType;



@interface Breakpoint : NSObject
{
	BreakpointType breakpointType;
	long time;
	float value;
	SpatialPosition *position;
}

@property BreakpointType breakpointType;

+ (Breakpoint *)breakpointWithTime:(long)t value:(float)val;

// accessors

- (long)time;
- (void)setTime:(long)val;

- (float)value;
- (void)setValue:(float)val;

- (void)setPosition:(SpatialPosition *)aPosition;
- (SpatialPosition *)position;

- (float)x;
- (float)y;
- (float)z;
- (float)a;
- (float)e;
- (float)d;

- (void)setX:(float)val;
- (void)setY:(float)val;
- (void)setZ:(float)val;

@end
