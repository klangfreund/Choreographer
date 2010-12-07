//
//  TimelineEditorView.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TimelineEditorView.h"
#import "CHProjectDocument.h"
#import "CHGlobals.h"
#import "EditorContent.h"
#import "Breakpoint.h"
#import "BreakpointBezierPath.h"
#import "ToolTip.h"
#import "SelectionRectangle.h"


@implementation TimelineEditorView

#pragma mark -
#pragma mark initialisation
// -----------------------------------------------------------

- (void)awakeFromNib
{
	originalPosition = nil;
	
	// initialize breakpoint views
	BreakpointView *breakpointView1 = [[[BreakpointView alloc] init] autorelease];
	breakpointView1.yAxisValueKeypath = @"x";
	breakpointView1.toolTipString = @"time: %0.0f x: %0.2f";

	BreakpointView *breakpointView2 = [[[BreakpointView alloc] init] autorelease];
	breakpointView2.yAxisValueKeypath = @"y";
	breakpointView2.toolTipString = @"time: %0.0f y: %0.2f";

	BreakpointView *breakpointView3 = [[[BreakpointView alloc] init] autorelease];
	breakpointView3.yAxisValueKeypath = @"z";
	breakpointView3.toolTipString = @"time: %0.0f z: %0.2f";

	breakpointViews = [[NSArray arrayWithObjects:breakpointView1, breakpointView2, breakpointView3, nil] retain];
	
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView setValue:self forKey:@"owningRegion"];
		[bpView setValue:[[NSColor whiteColor] colorWithAlphaComponent:0.25] forKey:@"backgroundColor"];
		[bpView setValue:[NSColor blackColor] forKey:@"lineColor"];
		[bpView setValue:[NSColor blackColor] forKey:@"handleColor"];
	
		bpView.xAxisValueKeypath = @"time";
		bpView.xAxisMin = 0;
		bpView.xAxisMax = 10000;
		
		bpView.yAxisMin = -1;
		bpView.yAxisMax = 1;
	}
}

- (void) dealloc
{
	NSLog(@"RadarEditorView: dealloc");
	
	[breakpointViews release];
	[originalPosition release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	// draw background
	// -----------------------------------------------------------------------------
	NSColor *backgroundColor	= [NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];

	[backgroundColor set];
	NSRectFill([self bounds]);
	
	// draw content
	// -----------------------------------------------------------------------------
	
	EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	editorSelection = [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"];

	if(displayMode == regionDisplayMode)
	{
		return;
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		switch([[trajectory valueForKey:@"trajectoryType"] intValue])
		{
			case breakpointType:
				[self drawBreakpointTrajectory];
				break;
			case rotationType:
			case randomType:
				[self drawAutomatedTrajectory];
				break;
		}
	}
}

- (void)drawBreakpointTrajectory
{
	NSRect r = [self frame];
	r.size.height = 50;
	r.size.width -= 2;
	
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView setValue:[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] linkedBreakpointArray] forKey:@"breakpointArray"];
		[bpView setUpdateCallbackObject:[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] selector:@selector(archiveData)];

		[bpView drawInRect:r];
		
		r.origin.y += 51;
	}
}


- (void)drawAutomatedTrajectory;
{}


#pragma mark -
#pragma mark mouse events
// -----------------------------------------------------------

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
	// first click activates the window automatically
	// so the user can immediately start manipulating
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	storedEventLocation = localPoint;

	// pass the mouse event
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView mouseDown:localPoint];
	}
}

//- (NSPoint)proposedMouseDrag:(NSPoint)delta
//{
//	return [gainBreakpointView proposedMouseDrag:delta];
//}

- (void)mouseDragged:(NSEvent *)event
{
	NSPoint delta;
	NSPoint eventLocation = [event locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
		
	delta.x = localPoint.x - storedEventLocation.x;
	delta.y = localPoint.y - storedEventLocation.y;
		
	// pass the mouse event
	for(BreakpointView *bpView in breakpointViews)
	{
		delta = [bpView proposedMouseDrag:delta];
	}
	
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView mouseDragged:delta];
	}

	storedEventLocation.x += delta.x;
	storedEventLocation.y += delta.y;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}

- (void)mouseUp:(NSEvent *)event
{
	// pass the mouse event
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView mouseUp:event];	
	}
}


#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)flagsChanged:(NSEvent *)event
{
	CHProjectDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
	NSLog(@"timeline editor: flags changed (document %x)", document);

	if([event modifierFlags] & NSControlKeyMask)
		document.keyboardModifierKeys = modifierControl;
	else if([event modifierFlags] & NSShiftKeyMask && !([event modifierFlags] & NSControlKeyMask) && !([event modifierFlags] & NSAlternateKeyMask) && !([event modifierFlags] & NSCommandKeyMask))
		document.keyboardModifierKeys = modifierShift;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && !([event modifierFlags] & NSCommandKeyMask))
		document.keyboardModifierKeys = modifierAlt;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && !([event modifierFlags] & NSAlternateKeyMask) && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierCommand;
	else if(!([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierAltCommand;
	else if([event modifierFlags] & NSShiftKeyMask && !([event modifierFlags] & NSControlKeyMask) && [event modifierFlags] & NSAlternateKeyMask && [event modifierFlags] & NSCommandKeyMask)
		document.keyboardModifierKeys = modifierShiftAltCommand;
	
	else
		document.keyboardModifierKeys = modifierNone;
}	


#pragma mark -
#pragma mark editing
// -----------------------------------------------------------

- (BOOL)moveSelectedPointsBy:(NSPoint)delta
{
//	Position *pos;
//	BOOL inside = YES;
//	
//	NSEnumerator *enumerator;
//	id item; 
//	
//	enumerator = [editorSelection objectEnumerator];
//	while ((item = [enumerator nextObject]))
//	{
//		pos = [item valueForKey:@"position"];
//		
//		if([pos x] + delta.x < -1 || [pos x] + delta.x > 1 ||
//		   activeAreaOfDisplay == 0 &&
//		   ([pos y] + delta.y < -1 || [pos y] + delta.y > 1) ||
//		   activeAreaOfDisplay == 1 &&
//		   ([pos z] + delta.y < -1 || [pos z] + delta.y > 1))
//			inside = NO;
//	}
//	
//	if(!inside) return NO;
//	
//	enumerator = [editorSelection objectEnumerator];
//	while ((item = [enumerator nextObject]))
//	{
//		pos = [item valueForKey:@"position"];
//		
//		[pos setX:[pos x] + delta.x];
//		if(activeAreaOfDisplay == 0)
//			[pos setY:[pos y] + delta.y];
//		else
//			[pos setZ:[pos z] + delta.y];
//	}
//	
	return YES;
}

- (void)setSelectedPointsTo:(SpatialPosition *)pos
{
	NSEnumerator *enumerator;
	id item;
	
	enumerator = [editorSelection objectEnumerator];
	while ((item = [enumerator nextObject]))
	{
		[item setValue:pos forKey:@"position"];
	}
}


#pragma mark -
#pragma mark utility
// -----------------------------------------------------------
- (NSPoint)makePoint:(float)coordinate time:(unsigned long)time
{	
	return NSMakePoint(time * zoomFactorX, coordinate * TIMELINE_EDITOR_DATA_HEIGHT * 0.45 + TIMELINE_EDITOR_DATA_HEIGHT * 0.5);
}


@end
