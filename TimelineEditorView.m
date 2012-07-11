//
//  TimelineEditorView.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.02.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "TimelineEditorView.h"
#import "CHProjectDocument.h"
#import "EditorContent.h"
#import "Breakpoint.h"
#import "BreakpointBezierPath.h"
#import "ToolTip.h"
#import "SelectionRectangle.h"
#import "SpatialPosition.h"


@implementation TimelineEditorView

#pragma mark -
#pragma mark initialisation
// -----------------------------------------------------------

- (void)awakeFromNib
{
	originalPosition = nil;
	
	// initialize breakpoint views
	BreakpointView *breakpointView1 = [[[BreakpointView alloc] init] autorelease];
	BreakpointView *breakpointView2 = [[[BreakpointView alloc] init] autorelease];
	BreakpointView *breakpointView3 = [[[BreakpointView alloc] init] autorelease];

	breakpointViews = [[NSArray arrayWithObjects:breakpointView1, breakpointView2, breakpointView3, nil] retain];
	
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView setValue:self forKey:@"owningRegion"];
		[bpView setValue:[[NSColor whiteColor] colorWithAlphaComponent:0.15] forKey:@"backgroundColor"];
		[bpView setValue:[[NSColor whiteColor] colorWithAlphaComponent:0.3] forKey:@"keyBackgroundColor"];
		[bpView setValue:[NSColor blackColor] forKey:@"lineColor"];
		[bpView setValue:[NSColor blackColor] forKey:@"handleColor"];
	
		bpView.xAxisValueKeypath = @"time";
		bpView.zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];	

        bpView.yAxisMin = -1;
		bpView.yAxisMax = 1;
    }
    
    numOfBreakpointViews = 0;
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redraw)
                                                 name:@"timelineEditorZoomFactorDidChange" object:nil];		
}

- (void)setupSubviews
{
    BreakpointView *breakpointView;

    editableTrajectory = [[EditorContent sharedEditorContent] valueForKeyPath:@"editableTrajectory"];
	displayedTrajectories = [[EditorContent sharedEditorContent] valueForKey:@"displayedTrajectories"];

    Trajectory *trajectory = [editableTrajectory valueForKey:@"trajectory"];
	TrajectoryType trajectoryType = [[editableTrajectory valueForKey:@"trajectoryType"] intValue];
    
    switch(trajectoryType)
    {
        case breakpointType:
            breakpointView = [breakpointViews objectAtIndex:0];
            breakpointView.breakpointArray = [trajectory positionBreakpointArray];
            breakpointView.yAxisValueKeypath = @"x";
            breakpointView.toolTipString = @"time: %0.0f x: %0.2f";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];
            breakpointView.breakpointDescriptor = nil;
            breakpointView.yAxisMin = -1;
            breakpointView.yAxisMax = 1;
            breakpointView.xAxisMax = 0;
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"X";
            
            breakpointView = [breakpointViews objectAtIndex:1];
            breakpointView.breakpointArray = [trajectory positionBreakpointArray];
            breakpointView.yAxisValueKeypath = @"y";
            breakpointView.toolTipString = @"time: %0.0f y: %0.2f";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];
            breakpointView.breakpointDescriptor = nil;
            breakpointView.yAxisMin = -1;
            breakpointView.yAxisMax = 1;
            breakpointView.xAxisMax = 0;
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Y";

            breakpointView = [breakpointViews objectAtIndex:2];
            breakpointView.breakpointArray = [trajectory positionBreakpointArray];
            breakpointView.yAxisValueKeypath = @"z";
            breakpointView.toolTipString = @"time: %0.0f z: %0.2f";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];
            breakpointView.breakpointDescriptor = nil;
            breakpointView.yAxisMin = -1;
            breakpointView.yAxisMax = 1;
            breakpointView.xAxisMax = 0;
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Z";
           
            numOfBreakpointViews = 3;
            
            break;
            
        case rotationAngleType:
            breakpointView = [breakpointViews objectAtIndex:0];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];
            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f angle: %0.2f";
            breakpointView.breakpointDescriptor = @"Angle";
            breakpointView.yAxisMin = -360;
            breakpointView.yAxisMax = 360;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Angle";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            

            numOfBreakpointViews = 1;            
            break;

        case rotationSpeedType:           
            breakpointView = [breakpointViews objectAtIndex:0];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"Speed";
            breakpointView.yAxisMin = -360;
            breakpointView.yAxisMax = 360;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Speed";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            numOfBreakpointViews = 1;            
            break;

        case randomType:           
            breakpointView = [breakpointViews objectAtIndex:0];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"MaxSpeed";
            breakpointView.yAxisMin = 0;
            breakpointView.yAxisMax = 4.0;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = NO;
            breakpointView.label = @"Max Speed";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            breakpointView = [breakpointViews objectAtIndex:1];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"MinSpeed";
            breakpointView.yAxisMin = 0;
            breakpointView.yAxisMax = 4.0;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = NO;
            breakpointView.label = @"Min Speed";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            breakpointView = [breakpointViews objectAtIndex:2];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"Stability";
            breakpointView.yAxisMin = 0;
            breakpointView.yAxisMax = 10.0;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = NO;
            breakpointView.label = @"Stability";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            numOfBreakpointViews = 3;            
            break;
            
        case circularRandomType:           
            breakpointView = [breakpointViews objectAtIndex:0];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"MaxSpeed";
            breakpointView.yAxisMin = -360;
            breakpointView.yAxisMax = 360;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Max Speed";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            breakpointView = [breakpointViews objectAtIndex:1];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"MinSpeed";
            breakpointView.yAxisMin = -360;
            breakpointView.yAxisMax = 360;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = YES;
            breakpointView.label = @"Min Speed";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            breakpointView = [breakpointViews objectAtIndex:2];
            breakpointView.breakpointArray = [trajectory parameterBreakpointArray];            
            breakpointView.yAxisValueKeypath = @"value";
            breakpointView.toolTipString = @"time: %0.0f speed: %0.2f";
            breakpointView.breakpointDescriptor = @"Stability";
            breakpointView.yAxisMin = 0;
            breakpointView.yAxisMax = 10.0;
            breakpointView.xAxisMax = [[trajectory valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue];
            breakpointView.showMiddleLine = NO;
            breakpointView.label = @"Stability";
            [breakpointView setUpdateCallbackObject:editableTrajectory selector:@selector(updateModel)];            
            
            numOfBreakpointViews = 3;            
            break;
            
        default:
            numOfBreakpointViews = 0;
            break;
           
    }
}


- (void) dealloc
{
	NSLog(@"RadarEditorView: dealloc");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
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
	NSColor *backgroundColor = [NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];

	[backgroundColor set];
	NSRectFill([self frame]);
    
	
	// draw content
	// -----------------------------------------------------------------------------
	
    //EditorDisplayMode displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
    
    editorSelection = [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"];
    
	for(BreakpointView *bpView in breakpointViews)
	{
        [bpView setSelectedBreakpoints:editorSelection];
    }

	if([displayedTrajectories count] > 0)
    {
        float bpViewMininmumHeight = 100;
        
        NSRect r = [[self superview] bounds];

        // height
        float bpViewHeight = (r.size.height - 2) / 3;
        
        if(bpViewHeight < bpViewMininmumHeight)
        {
            bpViewHeight = bpViewMininmumHeight;
        }
        
        // width
        float zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];	
        NSUInteger time = [[[[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] positionBreakpoints] lastObject] valueForKey:@"time"] unsignedLongValue];
        float bpViewWidth = time * zoomFactorX + ARRANGER_OFFSET + [BreakpointBezierPath handleSize];
        
        if(bpViewWidth < r.size.width)
        {
            bpViewWidth = r.size.width;
        }
        
        r = NSMakeRect(0, 0, bpViewWidth, bpViewHeight * 3 + 2);
        [self setFrame:r];
        
        r.size.height = bpViewHeight;
        r.size.width -= ARRANGER_OFFSET;
        r.origin.x += ARRANGER_OFFSET;
        
        int i;
        for(i=0;i<numOfBreakpointViews;i++)
        {
            BreakpointView *bpView = [breakpointViews objectAtIndex:i];
            
            bpView.zoomFactorX = zoomFactorX;

            [bpView drawInRect:r];
            
            r.origin.y += bpViewHeight + 1;
        }
    }
}

- (void)redraw
{
    [self setNeedsDisplay:YES];
}



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

    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
//	[[[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"] updateModel];
}

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
    //	NSLog(@"timeline editor: flags changed (document %x)", document);
    
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


- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	NSLog(@"Timeline Editor key code: %d", keyCode);
    NSUInteger index;
    	
	BOOL update = NO;
    
	switch (keyCode)
	{
		case 51:	// BACKSPACE
		case 117:	// DELETE
            
            [[EditorContent sharedEditorContent] deleteSelectedPoints];
			break;

		case 48:	// TAB
            // cycle through trajectories, make one editable
            
            index = [displayedTrajectories indexOfObject:editableTrajectory];
            
            if([event modifierFlags] & NSShiftKeyMask)
            {
                [displayedTrajectories insertObject:[displayedTrajectories lastObject] atIndex:0];
                [displayedTrajectories removeLastObject];
            }
            else
            {
                [displayedTrajectories addObject:[displayedTrajectories objectAtIndex:0]];
                [displayedTrajectories removeObjectAtIndex:0];
            }
            
            [[EditorContent sharedEditorContent] setValue:[displayedTrajectories objectAtIndex:index] forKey:@"editableTrajectory"];
            [editorSelection removeAllObjects];
			break;

		case 123:	// ARROW keys
		case 124:
		case 125:
		case 126:
			[self nudge:event];
			update = YES;
			break;
			
			
		default:
			[[[[[[NSDocumentController sharedDocumentController] currentDocument] windowControllers] objectAtIndex:0] window] keyDown:event];
	}
	
	if(update)
	{
		[[EditorContent sharedEditorContent] updateModelForSelectedPoints];
	}
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}

- (void)nudge:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	
	float nudgeUnit = 0.01;//[[NSUserDefaults standardUserDefaults] integerForKey:@"radarEditorNudgeUnit"] * 0.001;
	float nudgeTime = 100; // [[NSUserDefaults standardUserDefaults] integerForKey:@"radarEditorNudgeAngle"] * 0.1;
    
    
    switch (keyCode)
    {
        case 123:	// ARROW left
            [self moveSelectedPointsBy:NSMakePoint(-nudgeTime, 0)];
            break;
        case 124:	// ARROW right
            [self moveSelectedPointsBy:NSMakePoint(nudgeTime, 0)];
            break;
        case 125:	// ARROW down
            [self moveSelectedPointsBy:NSMakePoint(0, -nudgeUnit)];
            break;
        case 126:	// ARROW up
            [self moveSelectedPointsBy:NSMakePoint(0, nudgeUnit)];
            break;
    }
}


#pragma mark -
#pragma mark editing
// -----------------------------------------------------------

- (void)moveSelectedPointsBy:(NSPoint)delta
{
	for(BreakpointView *bpView in breakpointViews)
	{
		[bpView moveSelectedPointsBy:delta];	
	}
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
	float zoomFactorX = [[[NSUserDefaults standardUserDefaults] valueForKey:@"timelineEditorZoomFactorX"] floatValue];

	return NSMakePoint(time * zoomFactorX, coordinate * TIMELINE_EDITOR_DATA_HEIGHT * 0.45 + TIMELINE_EDITOR_DATA_HEIGHT * 0.5);
}


@end
