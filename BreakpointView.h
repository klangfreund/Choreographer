//
//  BreakpointView.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.05.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Breakpoint.h"
#import "BreakpointArray.h"

@class Region;


@interface BreakpointView : NSObject
{
	NSRect frame;
	Region *owningRegion;
	
	BreakpointArray *breakpointArray;
	NSMutableSet *selectedBreakpoints;
	Breakpoint *hit;

	BOOL showSelectionRectangle;
	NSMutableSet *tempEditorSelection;
	
	BOOL isKey; // this breakpoint view is being edited

    NSString *label;

	NSString *xAxisValueKeypath, *yAxisValueKeypath;
    NSString *breakpointDescriptor;
	unsigned int xAxisMax; // min is always 0
	float zoomFactorX;
	double yAxisMin, yAxisMax;
    BOOL showMiddleLine;
	
	NSColor *backgroundColor, *keyBackgroundColor;
	NSColor *gridColor;
	NSColor *lineColor, *handleColor;

	NSBezierPath *gridPath;
	
	NSString *toolTipString;
	
	id callbackObject;
	SEL callbackSelector;
	BOOL dirty;
}

@property(retain) BreakpointArray *breakpointArray;
@property(retain) NSString *xAxisValueKeypath, *yAxisValueKeypath;
@property(retain) NSString *label;
@property(retain) NSString *breakpointDescriptor;
@property unsigned int xAxisMax;
@property float zoomFactorX;
@property double yAxisMin, yAxisMax;
@property(retain) NSString *toolTipString;
@property BOOL showMiddleLine;
@property BOOL isKey;


- (void)drawInRect:(NSRect)rect;

// mouse
- (void)mouseDown:(NSPoint)location;
- (NSPoint)proposedMouseDrag:(NSPoint)delta;
- (void)mouseDragged:(NSPoint)delta;
- (void)mouseUp:(NSEvent *)event;

- (void)setUpdateCallbackObject:(id)obj selector:(SEL)selector;
- (void)performUpdateCallback;

// selection
- (void)setSelectedBreakpoints:(NSMutableSet *)set;
- (void)deselectAll;

// editing
- (void)moveSelectedPointsBy:(NSPoint)delta;


//- (void)addBreakpoint;
//- (void)removeBreakpoint;
- (void)removeSelectedBreakpoints;
- (void)sortBreakpoints;


@end
