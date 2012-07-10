//
//  ArrangerRulerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ArrangerRulerView.h"
#import "ArrangerView.h"
#import "CHProjectDocument.h"
#import "PlaybackController.h"
#import "MarkersWindowController.h"

@implementation ArrangerRulerView


- (void)awakeFromNib
{
    // label attribute
    NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSBackgroundColorAttributeName, nil];
    NSArray *values = [NSArray arrayWithObjects:[NSFont systemFontOfSize:9], [NSColor whiteColor], [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:0.5], nil];
    labelAttribute = [[NSDictionary dictionaryWithObjects:values forKeys:keys] retain];

    
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(update:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setZoomFactor:)
                                                 name:@"arrangerViewZoomFactorDidChange" object:nil];		
	[super awakeFromNib];
	numOfAreas = 3;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)update:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];

	
	NSColor *selectionFrameColor	= [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
	NSColor *selectionFillColor		= [NSColor colorWithCalibratedRed: 0.35 green: 0.35 blue: 0.35 alpha: 0.5];
	NSColor *locatorColor			= [NSColor colorWithCalibratedRed: 0 green: 1.0 blue: 1.0 alpha: 1.0];
	NSColor *markerColor			= [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 0 alpha: 1.0];

	
	CHProjectDocument *document = [[[self window] windowController] document];

	float start = [[document valueForKeyPath:@"projectSettings.loopRegionStart"] integerValue] * zoomFactor;
	float end = [[document valueForKeyPath:@"projectSettings.loopRegionEnd"] integerValue] * zoomFactor;
	
	float locator, x, y;
	NSBezierPath *locatorPath;
	NSBezierPath *markerPath;
	NSRect r;
	
	
	// ---------------------------------
	// selected time span
	
	r = NSMakeRect(start + ARRANGER_OFFSET, 0, end - start, 40);

	[selectionFillColor set];
	[NSBezierPath fillRect:r];

	[selectionFrameColor set];
	[NSBezierPath strokeRect:r];
	
	// start locator
	
	locator = start;
	
	locatorPath = [[[NSBezierPath alloc] init] autorelease];
	
	[locatorPath moveToPoint:NSMakePoint(locator + ARRANGER_OFFSET, 40)];
	[locatorPath lineToPoint:NSMakePoint(locator + ARRANGER_OFFSET - 8, 40)];
	[locatorPath lineToPoint:NSMakePoint(locator + ARRANGER_OFFSET, 32)];
	[locatorPath closePath];
	
	[locatorColor set];
	[locatorPath fill];
	[[NSColor blackColor] set];
	[locatorPath stroke];
	
	
	// end locator
	
	locator = end;
	
	locatorPath = [[[NSBezierPath alloc] init] autorelease];
	
	[locatorPath moveToPoint:NSMakePoint(locator + ARRANGER_OFFSET, 40)];
	[locatorPath lineToPoint:NSMakePoint(locator + ARRANGER_OFFSET + 8, 40)];
	[locatorPath lineToPoint:NSMakePoint(locator + ARRANGER_OFFSET, 32)];
	[locatorPath closePath];

	[locatorColor set];
	[locatorPath fill];
	[[NSColor blackColor] set];
	[locatorPath stroke];


	// ---------------------------------
	// markers

    y = HEIGHT_1 + HEIGHT_2 * 0.2;
	
	float markerHandleSize = HEIGHT_2 * 0.8;
    NSString *string;
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];

    id markers = [[MarkersWindowController sharedMarkersWindowController] markers];
    for(id marker in markers)
    {
        if(marker == draggedMarker)
            x = tempMarkerTime * zoomFactor;
        else
            x = [[marker valueForKey:@"time"] unsignedIntegerValue] * zoomFactor;

        markerPath = [[[NSBezierPath alloc] init] autorelease];
        
        [markerPath moveToPoint:NSMakePoint(x + ARRANGER_OFFSET, y)];
        [markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET - markerHandleSize * 0.5, y + markerHandleSize * 0.5)];
        [markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET, y + markerHandleSize)];
        [markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET + markerHandleSize * 0.5, y + markerHandleSize * 0.5)];
        [markerPath closePath];
        
        [markerColor set];
        [markerPath fill];
        [[NSColor blackColor] set];
        [markerPath stroke];	

        string = [[NSString stringWithFormat:@" %@ ",[marker valueForKey:@"name"]] autorelease];
		[string drawAtPoint:NSMakePoint(x + 20, y - 2) withAttributes:labelAttribute];
    }


	// ---------------------------------
	// playback start

	x = [[playbackController valueForKey:@"startLocator"] floatValue] * zoomFactor;
	r = NSMakeRect(x + ARRANGER_OFFSET, 0, 1, HEIGHT_1);
	[[NSColor redColor] set];
	[NSBezierPath fillRect:r];
}
	

#pragma mark -
#pragma mark mouse events
// -----------------------------------------------------------

- (void)mouseDown:(NSEvent *)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	localPoint.x -= ARRANGER_OFFSET;
    BOOL dc = [event clickCount] > 1;

    if(localPoint.y > HEIGHT_1 + HEIGHT_2)
    {
        [self mouseDownInLoopRegionArea:localPoint doubleClick:dc];
    }
    else if(localPoint.y > HEIGHT_1)
    {
        [self mouseDownInMarkerArea:localPoint doubleClick:dc];
    }	
    else
    {
        [self mouseDownInPlayheadArea:localPoint doubleClick:dc];
    }	

    [self setNeedsDisplay:YES];
}


- (void)mouseDownInLoopRegionArea:(NSPoint)localPoint doubleClick:(BOOL)dc
{
	CHProjectDocument *document = [[[self window] windowController] document];

	if(dc)  // double click
	{
        if(document.keyboardModifierKeys == modifierCommand)
        {
            // command double click: set loop region to arranger selection
            
            NSUInteger selectionStart, selectionEnd;
            
            NSSet *selectedRegions = [arrangerView selectedAudioRegions];
            
            if([selectedRegions count])
            {
                selectionStart = [[[selectedRegions anyObject] valueForKey:@"startTime"] unsignedIntValue];
                selectionEnd = [[[selectedRegions anyObject] valueForKey:@"startTime"] unsignedIntValue] + [[[selectedRegions anyObject] valueForKey:@"duration"] unsignedIntValue];
                
                for(id region in selectedRegions)
                {
					
                    if(selectionStart > [[region valueForKey:@"startTime"] unsignedIntValue])
                    {
                        selectionStart = [[region valueForKey:@"startTime"] unsignedIntValue];
                    }
					
                    if(selectionEnd < [[region valueForKey:@"startTime"] unsignedIntValue] + [[region valueForKey:@"duration"] unsignedIntValue])
                    {
                        selectionEnd = [[region valueForKey:@"startTime"] unsignedIntValue] + [[region valueForKey:@"duration"] unsignedIntValue];
                    }
                }
                
                [document setValue:[NSNumber numberWithUnsignedInt:selectionStart] forKeyPath:@"projectSettings.loopRegionStart"];
                [document setValue:[NSNumber numberWithUnsignedInt:selectionEnd] forKeyPath:@"projectSettings.loopRegionEnd"];
                
                [playbackController setLoop];
                
                [self setNeedsDisplay:YES];
            }
        }
        else
        {
            // double click: synchronize marquee
            [arrangerView synchronizeMarquee];
        }
    }
    else // single click
    {
        if(document.keyboardModifierKeys == modifierCommand)
        {
            // command click, set new selection boundaries
            [document setValue:[NSNumber numberWithUnsignedInt:localPoint.x / zoomFactor] forKeyPath:@"projectSettings.loopRegionStart"];
            [document setValue:[NSNumber numberWithUnsignedInt:localPoint.x / zoomFactor] forKeyPath:@"projectSettings.loopRegionEnd"];
            mouseDraggingAction = rulerDragLoopRegionEnd;
        }
        else
        {
            // drag start or end handle
            float tempSelectionStart = [[document valueForKeyPath:@"projectSettings.loopRegionStart"] integerValue] * zoomFactor;
            float tempSelectionEnd = [[document valueForKeyPath:@"projectSettings.loopRegionEnd"] integerValue] * zoomFactor;

            if(localPoint.x > tempSelectionStart - 8 && localPoint.x < tempSelectionStart)	
                mouseDraggingAction = rulerDragLoopRegionStart;
        
            if(localPoint.x > tempSelectionEnd && localPoint.x < tempSelectionEnd + 8)
                mouseDraggingAction = rulerDragLoopRegionEnd;
        }
    }
}

- (void)mouseDownInMarkerArea:(NSPoint)localPoint doubleClick:(BOOL)dc
{
	mouseDraggingAction = rulerDragMarker;
    draggedMarker = nil;
    
	CHProjectDocument *document = [[[self window] windowController] document];
    float eventLocator = localPoint.x;
    float resolution = ceil(pow(10,round(log10(1 / zoomFactor))));

    if(dc)
    {
        // double click: set new marker
        if(document.keyboardModifierKeys == modifierCommand)
        {
            NSUInteger newLocator = [[arrangerView valueForKeyPath:@"playbackController.locator"] unsignedIntegerValue];            
            draggedMarker = [[MarkersWindowController sharedMarkersWindowController] newMarkerWithTime:newLocator];
        }
        else
        {
            NSUInteger newLocator = eventLocator < 0 ? 0 : eventLocator / zoomFactor;
            newLocator = round(newLocator / resolution) * resolution;
            
            draggedMarker = [[MarkersWindowController sharedMarkersWindowController] newMarkerWithTime:newLocator];
            tempMarkerTime = newLocator;
        }
    }
    else
    {
        id markers = [[MarkersWindowController sharedMarkersWindowController] markers];
        for(id marker in markers)
        {
            // find marker
            if(eventLocator / zoomFactor - resolution * 2 < [[marker valueForKey:@"time"] unsignedIntegerValue] &&
               eventLocator / zoomFactor + resolution * 2 > [[marker valueForKey:@"time"] unsignedIntegerValue])
            {
                draggedMarker = [marker retain];
                tempMarkerTime = [[marker valueForKey:@"time"] unsignedIntegerValue];
                break;
            }
        }
    }
}

- (void)mouseDownInPlayheadArea:(NSPoint)localPoint doubleClick:(BOOL)dc
{
	mouseDraggingAction = rulerDragNone;

	float resolution = ceil(pow(10,round(log10(1 / zoomFactor))));
	float eventLocator = localPoint.x;
	NSUInteger newLocator = eventLocator < 0 ? 0 : eventLocator / zoomFactor;
	newLocator = round(newLocator / resolution) * resolution;
	
	[playbackController setLocator:newLocator];	
}



- (void)mouseUp:(NSEvent *)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    if(mouseDraggingAction == rulerDragMarker)
    {
        if(draggedMarker && mouseDraggingAction == rulerDragMarker && localPoint.y < 0)
        [[MarkersWindowController sharedMarkersWindowController] deleteMarker:draggedMarker];

        [draggedMarker setValue:[NSNumber numberWithUnsignedInteger:tempMarkerTime] forKey:@"time"];
        
        [draggedMarker release];
        draggedMarker = nil;
        
        [[MarkersWindowController sharedMarkersWindowController] update];
    }
        
	mouseDraggingAction = rulerDragNone;
    
}

- (void)mouseDragged:(NSEvent *)event
{
	CHProjectDocument *document = [[[self window] windowController] document];
	NSDictionary *projectSettings = [document valueForKey:@"projectSettings"];

	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    localPoint.x = localPoint.x < ARRANGER_OFFSET ? ARRANGER_OFFSET : localPoint.x;
	NSUInteger proposedLocator = (localPoint.x - ARRANGER_OFFSET) / zoomFactor;
	
	NSUInteger loopRegionStart = [[projectSettings valueForKey:@"loopRegionStart"] integerValue];
	NSUInteger loopRegionEnd = [[projectSettings valueForKey:@"loopRegionEnd"] integerValue];

	if(mouseDraggingAction == rulerDragLoopRegionEnd)
	{		
		if(proposedLocator >= loopRegionStart)
		{
            [projectSettings setValue:[NSNumber numberWithUnsignedInt:proposedLocator] forKey:@"loopRegionEnd"];
		}
        else
		{
            [projectSettings setValue:[NSNumber numberWithUnsignedInt:loopRegionStart] forKey:@"loopRegionEnd"];
		}
	}
	else if(mouseDraggingAction == rulerDragLoopRegionStart)
	{
		if(proposedLocator <= loopRegionEnd)
		{
            [projectSettings setValue:[NSNumber numberWithUnsignedInt:proposedLocator] forKey:@"loopRegionStart"];
		}
        else
		{
            [projectSettings setValue:[NSNumber numberWithUnsignedInt:loopRegionEnd] forKey:@"loopRegionStart"];
		}
	}
	else if(mouseDraggingAction == rulerDragMarker)
	{
        if(document.keyboardModifierKeys == modifierCommand) proposedLocator = [[arrangerView valueForKeyPath:@"playbackController.locator"] unsignedIntegerValue];
        tempMarkerTime = proposedLocator;
    }
	
	[playbackController setLoop];
	[self setNeedsDisplay:YES];
}



#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoomFactor:(NSNotification *)aNotification
{
	id document = [[[self window] windowController] document];
	
	float newZoomFactor = [document zoomFactorX];
	
	if(newZoomFactor != zoomFactor)
	{
		zoomFactor = newZoomFactor;
		
		// new width
        [self setWidth:[[document valueForKey:@"arrangerView"] frame].size.width];
	}
}

@end
