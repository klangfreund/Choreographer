//
//  BreakpointBezierPath.m
//  Choreographer
//
//  Created by Philippe Kocher on 04.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "BreakpointBezierPath.h"

#define HANDLE_SIZE 4.0


@implementation BreakpointBezierPath

+ (BreakpointBezierPath *)breakpointBezierPathWithType:(BreakpointType)bpType location:(NSPoint)loc
{
	BreakpointBezierPath *path;
	NSRect r;

	switch(bpType)
	{
		case breakpointTypeNone:
			return nil;
			
		case breakpointTypeNormal:
		case breakpointTypeCentre:
			r = NSMakeRect(loc.x - HANDLE_SIZE * 0.75, loc.y - HANDLE_SIZE * 0.75, HANDLE_SIZE * 1.5, HANDLE_SIZE * 1.5);
			return (BreakpointBezierPath *)[NSBezierPath bezierPathWithRect:r];		
			
		case breakpointTypeAudioRegion:
			r = NSMakeRect(loc.x - HANDLE_SIZE, loc.y - HANDLE_SIZE, HANDLE_SIZE * 2, HANDLE_SIZE * 2);
			return (BreakpointBezierPath *)[NSBezierPath bezierPathWithOvalInRect:r];
			
		case breakpointTypeInitial:
			path = [[[BreakpointBezierPath alloc] init] autorelease];
			
			[path moveToPoint:NSMakePoint(loc.x - HANDLE_SIZE, loc.y)];
			[path lineToPoint:NSMakePoint(loc.x, loc.y - HANDLE_SIZE)];
			[path lineToPoint:NSMakePoint(loc.x + HANDLE_SIZE, loc.y)];
			[path lineToPoint:NSMakePoint(loc.x, loc.y + HANDLE_SIZE)];
			[path closePath];
			
			return path;
			
		case breakpointTypeAdaptiveInitial:
			path = [[[BreakpointBezierPath alloc] init] autorelease];
			
			[path moveToPoint:NSMakePoint(loc.x + HANDLE_SIZE * 0.75, loc.y)];
			[path lineToPoint:NSMakePoint(loc.x - HANDLE_SIZE * 0.75, loc.y + HANDLE_SIZE)];
			[path lineToPoint:NSMakePoint(loc.x - HANDLE_SIZE * 0.75, loc.y - HANDLE_SIZE)];
			[path closePath];
			
			return path;
			
		case breakpointTypeAuxiliary:
			r = NSMakeRect(loc.x - HANDLE_SIZE * 0.5, loc.y - HANDLE_SIZE * 0.5, HANDLE_SIZE * 1.0, HANDLE_SIZE * 1.0);
			return (BreakpointBezierPath *)[NSBezierPath bezierPathWithRect:r];	
	}
	
	return nil;
}


+ (float)handleSize
{
	return HANDLE_SIZE;
}

@end
