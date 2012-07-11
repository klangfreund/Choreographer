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
#import "SelectionRectangle.h"
#import "EditorContent.h"
#import "ToolTip.h"
#import "Region.h"

// TODO: draw grid



@implementation BreakpointView
@synthesize xAxisValueKeypath, yAxisValueKeypath;
@synthesize label;
@synthesize breakpointDescriptor;
@synthesize breakpointArray;
@synthesize xAxisMax;
@synthesize zoomFactorX;
@synthesize yAxisMin, yAxisMax;
@synthesize toolTipString;
@synthesize isKey, showMiddleLine;

- (id)init
{
	self = [super init];
    if(self)
	{
		isKey = NO;
        dirty = NO;
		selectedBreakpoints = [[NSMutableSet alloc] init];
        showSelectionRectangle = NO;
	}
	return self;
}

- (void)dealloc
{
	[gridPath release];
	[selectedBreakpoints release];
	[super dealloc];	
}

- (void)drawInRect:(NSRect)rect
{
	NSPoint p1, p2;
	BreakpointBezierPath *breakpointBezierPath;
	double xAxisValue, yAxisValue;
	Breakpoint *bp;
//	double halfHandleSize = [BreakpointBezierPath handleSize] * 0.5;
	

	// background

	if(isKey && keyBackgroundColor)
        [keyBackgroundColor set];
    else
        [backgroundColor set];
    
    if(xAxisMax > 0)
        rect.size.width = xAxisMax * zoomFactorX;
	
	[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:5 yRadius:5] fill];
    
	// too small
    if(rect.size.height < [BreakpointBezierPath handleSize] || rect.size.width < [BreakpointBezierPath handleSize]) return;
	
	frame = rect;

	double xAxisFactor = zoomFactorX;
	double yAxisFactor = rect.size.height / (yAxisMax - yAxisMin);
	

    // draw middle line
    
    if(showMiddleLine)
    {
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height * 0.5)
                                  toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height * 0.5)];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y-1 + rect.size.height * 0.5)
                                  toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y-1 + rect.size.height * 0.5)];
        [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    }
    

	// draw label

	NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
	NSArray *values = [NSArray arrayWithObjects:[NSFont systemFontOfSize:16], [NSColor colorWithCalibratedWhite:0.25 alpha:0.5], nil];
	NSDictionary *attributes = [[NSDictionary dictionaryWithObjects:values forKeys:keys] retain];
	[label drawAtPoint:NSMakePoint(rect.origin.x + 2, rect.origin.y + 2) withAttributes:attributes];


	// draw lines

	[lineColor set];
	
    p1 = NSMakePoint(rect.origin.x, -1);
	
	for(bp in breakpointArray)
	{
        if(breakpointDescriptor && ![breakpointDescriptor isEqualToString:[bp descriptor]]) continue;
		
        xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue] * xAxisFactor;		
		yAxisValue = ([[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - yAxisMin) * yAxisFactor;
		
		p2 = NSMakePoint(rect.origin.x + xAxisValue, rect.origin.y + rect.size.height - yAxisValue);
        if(p1.y == -1) p1.y = p2.y; // first point
		[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
		p1 = p2;
	}

	p2 = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - yAxisValue);
	[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];

	
	// draw breakpoint handles

	for(bp in breakpointArray)
	{
        if(breakpointDescriptor && ![breakpointDescriptor isEqualToString:[bp descriptor]]) continue;

        xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue] * xAxisFactor;
		
		// keep handles inside 
//		if(xAxisValue < halfHandleSize)
//			xAxisValue = halfHandleSize;
//		if(xAxisValue > frame.size.width - halfHandleSize)
//			xAxisValue = frame.size.width - halfHandleSize;

		yAxisValue = ([[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - yAxisMin) * yAxisFactor;

		p1 = NSMakePoint(rect.origin.x + xAxisValue, rect.origin.y + rect.size.height - yAxisValue);
		breakpointBezierPath = [BreakpointBezierPath breakpointBezierPathWithType:bp.breakpointType location:p1];
		
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
    {
        isKey = NO;
        return;
    }
	
	NSRect rect;
	NSPoint p;
	Breakpoint *bp;

	CHProjectDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
	
	double xAxisFactor = zoomFactorX;
	double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);

	rect.origin.x = (location.x - MOUSE_POINTER_SIZE * 0.5 - frame.origin.x) / xAxisFactor;
	rect.origin.y = (frame.size.height - location.y - MOUSE_POINTER_SIZE * 0.5 + frame.origin.y) / yAxisFactor + yAxisMin;
	rect.size.width = MOUSE_POINTER_SIZE / xAxisFactor;
	rect.size.height = MOUSE_POINTER_SIZE / yAxisFactor;
	
	hit = nil;
	isKey = YES;	

	// COMMAND click adds new point
	if(document.keyboardModifierKeys == modifierCommand)
	{
        bp = [[[Breakpoint alloc] init] autorelease];
        [bp setDescriptor:breakpointDescriptor];
        [bp setValue:[NSNumber numberWithFloat:rect.origin.x] forKey:xAxisValueKeypath];
        [bp setValue:[NSNumber numberWithFloat:rect.origin.y] forKey:yAxisValueKeypath];

        if([yAxisValueKeypath isEqualToString:@"value"])
        {
            [bp setBreakpointType:breakpointTypeValue];        
        }
        else
        {
            [bp setBreakpointType:breakpointTypeNormal];
        }
        
		[breakpointArray addBreakpoint:bp];

		// select the new point
		hit = bp;
		[selectedBreakpoints removeAllObjects];
		[selectedBreakpoints addObject:bp];
		
		dirty = YES;

		return;
	}
		
	for(bp in breakpointArray)
	{
        if(breakpointDescriptor && ![breakpointDescriptor isEqualToString:[bp descriptor]]) continue;

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
	
	// no hit:
	// shift not pressed - deselect all handles
	if(document.keyboardModifierKeys != modifierShift)
	{
        [self deselectAll];
	}
    
	// start selection rectangle
	//[tempEditorSelection setSet:editorSelection];
	[[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:location forView:[owningRegion valueForKey:@"superview"]];
	showSelectionRectangle = YES;
}

- (NSPoint)proposedMouseDrag:(NSPoint)delta
{
	if(![selectedBreakpoints count] || !isKey) return delta;

	NSPoint tempDelta = delta;
	
	double xAxisFactor = zoomFactorX;
	double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);
	
	double xAxisValue;
	double yAxisValue;
	
	tempDelta.x /= xAxisFactor; 
	tempDelta.y /= yAxisFactor;
	
	for(Breakpoint *bp in selectedBreakpoints)
	{
		xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue];
		yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue];

		if(xAxisValue + tempDelta.x < 0)
		{
			tempDelta.x = 0 - xAxisValue;
		}
		if(yAxisValue - tempDelta.y < yAxisMin)
		{
			tempDelta.y = yAxisValue - yAxisMin;
		}
		if(xAxisValue + tempDelta.x > xAxisMax && xAxisMax > 0)
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
    if(!isKey) return;
    
	if(!showSelectionRectangle && [selectedBreakpoints count])
    {
        // continue dragging handles
		
        double xAxisFactor = zoomFactorX;
        double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);

        NSUInteger xAxisValue;
        double yAxisValue;

        delta.x /= xAxisFactor; 
        delta.y /= yAxisFactor;
        
        for(Breakpoint *bp in selectedBreakpoints)
        {
            xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] unsignedLongLongValue] + delta.x;
            yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - delta.y;
            
            [bp setValue:[NSNumber numberWithUnsignedLongLong:xAxisValue] forKey:xAxisValueKeypath];
            [bp setValue:[NSNumber numberWithDouble:yAxisValue] forKey:yAxisValueKeypath];
        }
        
        [self sortBreakpoints];

        dirty = YES;

        [[ToolTip sharedToolTip] setString:	[NSString stringWithFormat:toolTipString, 
                                            [[hit valueForKeyPath:xAxisValueKeypath] doubleValue],
                                            [[hit valueForKeyPath:yAxisValueKeypath] doubleValue]]
                                    inView: [owningRegion valueForKey:@"superview"]];
    }
    else if(showSelectionRectangle)
    {
    	// selection rectangle
		[[SelectionRectangle sharedSelectionRectangle] setCurrentMouseDelta:delta];
        NSRect selectionRect = [[SelectionRectangle sharedSelectionRectangle] frame];
        
        double xAxisFactor = zoomFactorX;
        double yAxisFactor = frame.size.height / (yAxisMax - yAxisMin);

       // SpatialPosition *pos;
        NSPoint p;

        for(Breakpoint *bp in breakpointArray)
        {			
            if(breakpointDescriptor && ![breakpointDescriptor isEqualToString:[bp descriptor]]) continue;

			//pos = [bp valueForKey:@"position"];
            p.x = [[bp valueForKeyPath:xAxisValueKeypath] doubleValue] * xAxisFactor + frame.origin.x;
            p.y = (yAxisMax - [[bp valueForKeyPath:yAxisValueKeypath] doubleValue]) * yAxisFactor + frame.origin.y;
			
			if(NSPointInRect(p, selectionRect))
			{
				[selectedBreakpoints addObject:bp];
				[tempEditorSelection removeObject:bp];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
			}
			else if(![tempEditorSelection containsObject:bp])
			{
				[selectedBreakpoints removeObject:bp];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
			}
		}
    }
}

- (void)mouseUp:(NSEvent *)event
{
	if(dirty)
	{
		dirty = NO;
        [self performUpdateCallback];
    }

	[ToolTip release];

	[SelectionRectangle release];
	showSelectionRectangle = NO;
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

- (void)setSelectedBreakpoints:(NSMutableSet *)set
{
	[selectedBreakpoints release];
	selectedBreakpoints = [set retain];
}

- (void)deselectAll
{
	[selectedBreakpoints removeAllObjects];
}


- (void)removeSelectedBreakpoints
{
	for(Breakpoint *bp in selectedBreakpoints)
	{
		[breakpointArray removeBreakpoint:bp];
	}
	
	[self performUpdateCallback];
}


- (void)sortBreakpoints
{
	[breakpointArray sort];
}

#pragma mark -
#pragma mark editing
// -----------------------------------------------------------

- (void)moveSelectedPointsBy:(NSPoint)delta
{
    if(!isKey) return;

	NSUInteger xAxisValue;
    double yAxisValue;
	BOOL inside = YES;
    
	for(Breakpoint *bp in selectedBreakpoints)
	{
        xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] unsignedLongLongValue] + delta.x;
        yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue] - delta.y;
		
		if(xAxisValue + delta.x < 0 ||
           yAxisValue + delta.y < yAxisMin || yAxisValue + delta.y > yAxisMax)
			inside = NO;
	}
	
	if(!inside) return;
	
	for(Breakpoint *bp in selectedBreakpoints)
	{
        xAxisValue = [[bp valueForKeyPath:xAxisValueKeypath] unsignedLongLongValue] + delta.x;
        yAxisValue = [[bp valueForKeyPath:yAxisValueKeypath] doubleValue] + delta.y;
        
        [bp setValue:[NSNumber numberWithUnsignedLongLong:xAxisValue] forKey:xAxisValueKeypath];
        [bp setValue:[NSNumber numberWithDouble:yAxisValue] forKey:yAxisValueKeypath];
	}
	
	return;
}


@end