//
//  Breakpoint.h
//  Choreographer
//
//  Created by Philippe Kocher on 21.10.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
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
    breakpointTypeValue,
} BreakpointType;



@interface Breakpoint : NSObject
{
	BreakpointType breakpointType;
	NSUInteger time;
    bool hasTime;
    bool timeEditable;
	float value;
	SpatialPosition *position;
    NSString *descriptor;
}

@property BreakpointType breakpointType;
@property bool hasTime;
@property bool timeEditable;
@property (retain) NSString *descriptor;

+ (Breakpoint *)breakpointWithTime:(long)t value:(float)val;
+ (Breakpoint *)breakpointWithTime:(NSUInteger)t position:(SpatialPosition *)pos;
+ (Breakpoint *)breakpointWithPosition:(SpatialPosition *)pos;

// accessors

- (NSUInteger)time;
- (void)setTime:(NSUInteger)val;

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
