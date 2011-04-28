//
//  BreakpointView.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.05.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "BreakpointView.h"
#import "BreakpointBezierPath.h"
#import "CHProjectDocument.h"
#import "CHGlobals.h"
#import "ToolTip.h"
#import "Region.h"

// TODO: draw grid



@implementation BreakpointView
@synthesize xAxisValueKeypath, yAxisValueKeypath;
@synthesize breakpointArray;
@synthesize xAxisMin, xAxisMax;
@synthesize yAxisMin, yAxisMax;
@synthesize 
toolTipString;


- (id)init
{
	if(self = [super init])
	{
		selectedBreakpoints = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[selectedBreakpoints release];
	[gridPath release];
	
	[super dealloc];	
}

- (void)drawInRect:(NSRect)rect
{
	NSPoint p1, p2;
	BreakpointBezierPath *breakpointBezierPath;
	double xAxisValue, yAxisValue;
	Breakpoint *bp;
	

	// background

	[backgroundColor set];
	[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:5 yRadius:5] fill];
	
	if(rect.size.height < [BreakpointBezierPath handleSize] || rect.size.width < [BreakpointBezierPath handleSize]) return;
	
	rect = NSInsetRect(rect, [BreakpointBezierPath handleSize], [BreakpointBezierPath handleSize]);
	frame = rect;

	double xAxisFactor = rect.size.width / (xAxisMax - xAxisMin);
	double yAxisFactor = rect.size.height / (yAxisMax - yAxisMin);
	

	// draw lines

	[lineColor set];
	
	bp = [breakpointArray objectAtIndex:0];
	yAxisValue = ([[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - yAxisMin) * yAxisFactor;

	p1 = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - yAxisValue);
	
	for(bp in breakpointArray)
	{
		xAxisValue = ([[bp valueForKeyPath:xAxisValueKeypath] doubleValue] - xAxisMin) * xAxisFactor;
		yAxisValue = ([[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - yAxisMin) * yAxisFactor;
		
		p2 = NSMakePoint(rect.origin.x + xAxisValue, rect.origin.y + rect.size.height - yAxisValue);
		[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
		p1 = p2;
	}

	p2 = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - yAxisValue);
	[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];

	
	// draw breakpoint handles

	for(bp in breakpointArray)
	{
		xAxisValue = ([[bp valueForKeyPath:xAxisValueKeypath] doubleValue] - xAxisMin) * xAxisFactor;
		yAxisValue = ([[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - yAxisMin) * yAxisFactor;

		p1 = NSMakePoint(rect.origin.x + xAxisValue, rect.origin.y + rect.size.height - yAxisValue);
		breakpointBezierPath = [BreakpointBezierPath breakpointBezierPathWithType:breakpointTypeNormal location:p1];
		
		if([selectedBreakpoints containsObject:bp])
			[[NSColor blackColor] set];
		else
			[[NSColor whiteColor] set];
		[breakpointBezierPath fill];
		
		[handleColor set];
		[breakpointBezierPath stroke];
	}	
}

#pragma mark -
#pragma mark mouse
// -----------------------------------------------------------

- (void)mouseDown:(NSPoint)location
{
	// return if location is not inside view
	if(location.y < frame.origin.y || location.y > frame.origin.y + frame.size.height)
		return;
	
	NSRect rect;
	NSPoint p;
	id bp;

	CHProjectDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
	
	double xAxisFactor = frame.size.width / (xAxisMax - xAxisMin);
	double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);

	rect.origin.x = (location.x - MOUSE_POINTER_SIZE * 0.5 - frame.origin.x) / xAxisFactor + xAxisMin;
	rect.origin.y = (frame.size.height - location.y - MOUSE_POINTER_SIZE * 0.5 + frame.origin.y) / yAxisFactor + yAxisMin;
	rect.size.width = MOUSE_POINTER_SIZE / xAxisFactor;
	rect.size.height = MOUSE_POINTER_SIZE / yAxisFactor;
	
	hit = nil;
	

	// COMMAND click adds new point
	if(document.keyboardModifierKeys == modifierCommand)
	{
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:[NSNumber numberWithFloat:rect.origin.x] forKey:xAxisValueKeypath];
		[bp setValue:[NSNumber numberWithFloat:rect.origin.y] forKey:yAxisValueKeypath];
		[breakpointArray addObject:bp];
		[self sortBreakpoints];

		// select the new point
		hit = bp;
		[selectedBreakpoints removeAllObjects];
		[selectedBreakpoints addObject:bp];
		
		return;
	}
		
	for(bp in breakpointArray)
	{
		p.x = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue];
		p.y = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue];

		// SHIFT key pressed
		if(document.keyboardModifierKeys == modifierShift)
		{
			if(NSPointInRect(p, rect))
			{
				if([selectedBreakpoints containsObject:bp])
				{
					[selectedBreakpoints removeObject:bp];
				}
				else
				{
					hit = bp;
					[selectedBreakpoints addObject:bp];
					[self sortBreakpoints];
				}
				return;
			}
		}
		// no modifier key pressed
		else
		{
			if(NSPointInRect(p, rect))
			{
				hit = bp;
				if(![selectedBreakpoints containsObject:bp])
				{
					[selectedBreakpoints removeAllObjects];
					[selectedBreakpoints addObject:bp];
				}
				return;
			}
		}		
	}
	
	// no hit
	[self deselectAll];
}

- (NSPoint)proposedMouseDrag:(NSPoint)delta
{
	if(![selectedBreakpoints count]) return delta;

	NSPoint tempDelta = delta;
	
	double xAxisFactor = frame.size.width / (xAxisMax - xAxisMin);
	double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);
	
	double xAxisValue;
	double yAxisValue;
	
	tempDelta.x /= xAxisFactor; 
	tempDelta.y /= yAxisFactor;
	
	for(Breakpoint *bp in selectedBreakpoints)
	{
		xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue];
		yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue];

		if(xAxisValue + tempDelta.x < xAxisMin)
		{
			tempDelta.x = (float)xAxisMin - xAxisValue;
		}
		if(yAxisValue - tempDelta.y < yAxisMin)
		{
			tempDelta.y = yAxisValue - yAxisMin;
		}
		if(xAxisValue + tempDelta.x > xAxisMax)
		{
			tempDelta.x = xAxisMax - xAxisValue;
		}
		if(yAxisValue - tempDelta.y > yAxisMax)
		{
			tempDelta.y = yAxisValue - yAxisMax;
		}
	}

	tempDelta.x *= xAxisFactor; 
	tempDelta.y *= yAxisFactor;

	return tempDelta;
}

- (void)mouseDragged:(NSPoint)delta
{
	if(![selectedBreakpoints count]) return;
		
	double xAxisFactor = frame.size.width / (xAxisMax - xAxisMin);
	double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);

	double xAxisValue;
	double yAxisValue;

	delta.x /= xAxisFactor; 
	delta.y /= yAxisFactor;
	
	for(Breakpoint *bp in selectedBreakpoints)
	{
		xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue] + delta.x;
		yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - delta.y;
		
		[bp setValue:[NSNumber numberWithDouble:xAxisValue] forKey:xAxisValueKeypath];
		[bp setValue:[NSNumber numberWithDouble:yAxisValue] forKey:yAxisValueKeypath];
	}
	
	[self sortBreakpoints];


	[[ToolTip sharedToolTip] setString:	[NSString stringWithFormat:toolTipString, 
										[[hit valueForKeyPath:xAxisValueKeypath] doubleValue],
										[[hit valueForKeyPath:yAxisValueKeypath] doubleValue]]
								inView: [owningRegion valueForKey:@"superview"]];
}

- (void)mouseUp:(NSEvent *)event
{
	[self performUpdateCallback];

	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[managedObjectContext undoManager] setActionName:[NSString stringWithFormat:@"edit gain envelope"]];
//	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableUpdateView];

	[ToolTip release];
}


- (void)setUpdateCallbackObject:(id)obj selector:(SEL)selector
{
	callbackObject = obj;
	callbackSelector = selector;
}

- (void)performUpdateCallback
{
	[callbackObject performSelector:callbackSelector];
}


#pragma mark -
#pragma mark selection
// -----------------------------------------------------------

- (void)deselectAll
{
	[selectedBreakpoints removeAllObjects];
}


- (void)removeSelectedBreakpoints
{
	for(Breakpoint *bp in selectedBreakpoints)
	{
		[breakpointArray removeObject:bp];
	}
	
	[self performUpdateCallback];
//	[owningRegion archiveData];	
}


- (void)sortBreakpoints
{
	NSArray *breakpointsArraySorted;
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
	breakpointsArraySorted = [breakpointArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
	[breakpointArray removeAllObjects];

	[breakpointArray addObjectsFromArray:breakpointsArraySorted];
}

@end