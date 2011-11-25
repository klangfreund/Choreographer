//
//  BreakpointBezierPath.h
//  Choreographer
//
//  Created by Philippe Kocher on 04.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Breakpoint.h"


@interface BreakpointBezierPath : NSBezierPath
{

}

+ (BreakpointBezierPath *)breakpointBezierPathWithType:(BreakpointType)bpType location:(NSPoint)loc;

//+ (BreakpointBezierPath *)breakpointPosition:(NSPoint)point;
//+ (BreakpointBezierPath *)audioRegionPosition:(NSPoint)point;
//+ (BreakpointBezierPath *)centrePosition:(NSPoint)point;
//+ (BreakpointBezierPath *)initialPosition:(NSPoint)point;
//+ (BreakpointBezierPath *)adaptiveInitialPosition:(NSPoint)point;
//+ (BreakpointBezierPath *)auxilaryHandlePosition:(NSPoint)point;

+ (float)handleSize;

@end


