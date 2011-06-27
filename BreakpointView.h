//
//  BreakpointView.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.05.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Breakpoint.h"

@class Region;


@interface BreakpointView : NSObject
{
	NSRect frame;
	Region *owningRegion;
	
	NSMutableArray *breakpointArray;
	NSMutableSet *selectedBreakpoints;
	Breakpoint *hit;
	
	BOOL isKey; // this breakpoint view is being edited

	NSString *xAxisValueKeypath, *yAxisValueKeypath;
	unsigned int xAxisMax; // min is always 0
	float zoomFactorX;
	double yAxisMin, yAxisMax;
	
	NSColor *backgroundColor, *gridColor;
	NSColor *lineColor, *handleColor;

	NSBezierPath *gridPath;
	
	NSString *toolTipString;
	
	id callbackObject;
	SEL callbackSelector;
}

@property(retain) NSMutableArray *breakpointArray;
@property(retain) NSString *xAxisValueKeypath, *yAxisValueKeypath;
@property unsigned int xAxisMax;
@property float zoomFactorX;
@property double yAxisMin, yAxisMax;
@property(retain) NSString *toolTipString;


- (void)drawInRect:(NSRect)rect;

// mouse
- (void)mouseDown:(NSPoint)location;
- (NSPoint)proposedMouseDrag:(NSPoint)delta;
- (void)mouseDragged:(NSPoint)delta;
- (void)mouseUp:(NSEvent *)event;

- (void)setUpdateCallbackObject:(id)obj selector:(SEL)selector;
- (void)performUpdateCallback;
// selection
- (void)deselectAll;

//- (void)addBreakpoint;
//- (void)removeBreakpoint;
- (void)removeSelectedBreakpoints;
- (void)sortBreakpoints;


@end
