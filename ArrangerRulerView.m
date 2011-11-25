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

@implementation ArrangerRulerView


- (void)awakeFromNib
{
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
	NSManagedObject *projectSettings = [document valueForKey:@"projectSettings"];

	float start = [[projectSettings valueForKey:@"loopRegionStart"] integerValue] * zoomFactor;
	float end = [[projectSettings valueForKey:@"loopRegionEnd"] integerValue] * zoomFactor;
	
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

	x = 5000 * zoomFactor;
	y = HEIGHT_1 + HEIGHT_2 * 0.2;
	
	float markerHandleSize = HEIGHT_2 * 0.8; 
	
	markerPath = [[[NSBezierPath alloc] init] autorelease];
	
	[markerPath moveToPoint:NSMakePoint(x + ARRANGER_OFFSET, y)];
	[markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET - markerHandleSize * 0.5, y + markerHandleSize * 0.5)];
	[markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET, y + markerHandleSize)];
	[markerPath lineToPoint:NSMakePoint(x + ARRANGER_OFFSET + markerHandleSize * 0.5, y + markerHandleSize * 0.5)];
	[markerPath closePath];
	
	[markerColor set];
/*	[markerPath fill];
	[[NSColor blackColor] set];
	[markerPath stroke];	
*/

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
	
	if([event clickCount] > 1)
	{
		CHProjectDocument *document = [[[self window] windowController] document];
		NSManagedObject *projectSettings = [document valueForKey:@"projectSettings"];

		if(localPoint.y > HEIGHT_1 + HEIGHT_2) // loop region area
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

					[projectSettings setValue:[NSNumber numberWithUnsignedInt:selectionStart] forKey:@"loopRegionStart"];
					[projectSettings setValue:[NSNumber numberWithUnsignedInt:selectionEnd] forKey:@"loopRegionEnd"];

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
		return;
	}
	else
	{
		if(localPoint.y > HEIGHT_1 + HEIGHT_2)
		{
			[self mouseDownInLoopRegionArea:localPoint];
		}
		else if(localPoint.y > HEIGHT_1)
		{
			[self mouseDownInMarkerArea:localPoint];
		}	
		else
		{
			[self mouseDownInPlayheadArea:localPoint];
		}	
	
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDownInLoopRegionArea:(NSPoint)localPoint
{
	CHProjectDocument *document = [[[self window] windowController] document];
	NSManagedObject *projectSettings = [document valueForKey:@"projectSettings"];

	if(document.keyboardModifierKeys == modifierCommand)
	{
		// command click, set new selection boundaries
		[projectSettings setValue:[NSNumber numberWithUnsignedInt:localPoint.x / zoomFactor] forKey:@"loopRegionStart"];
		[projectSettings setValue:[NSNumber numberWithUnsignedInt:localPoint.x / zoomFactor] forKey:@"loopRegionEnd"];
		mouseDraggingAction = rulerDragLoopRegionEnd;
	}
	else
	{
		// drag start or end handle
		float tempSelectionStart = [[projectSettings valueForKey:@"loopRegionStart"] integerValue] * zoomFactor;
		float tempSelectionEnd = [[projectSettings valueForKey:@"loopRegionEnd"] integerValue] * zoomFactor;

		if(localPoint.x > tempSelectionStart - 8 && localPoint.x < tempSelectionStart)	
			mouseDraggingAction = rulerDragLoopRegionStart;
	
		if(localPoint.x > tempSelectionEnd && localPoint.x < tempSelectionEnd + 8)
			mouseDraggingAction = rulerDragLoopRegionEnd;
	}
}

- (void)mouseDownInMarkerArea:(NSPoint)localPoint
{
	mouseDraggingAction = rulerDragMarker;

}

- (void)mouseDownInPlayheadArea:(NSPoint)localPoint
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
	mouseDraggingAction = rulerDragNone;

//	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event
{
	CHProjectDocument *document = [[[self window] windowController] document];
	NSManagedObject *projectSettings = [document valueForKey:@"projectSettings"];

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
		NSSize s = [self frame].size;
		s.width = [[document valueForKey:@"arrangerView"] frame].size.width * 2;
		[self setFrameSize:s];
	}
}

@end
