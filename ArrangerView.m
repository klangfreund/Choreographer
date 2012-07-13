//
//  ArrangerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ArrangerView.h"
#import "CHGlobals.h"
#import "AudioFile.h"
#import "AudioRegion.h"
#import "GroupRegion.h"
#import "CHProjectDocument.h"
#import "SelectionRectangle.h"
#import "PlaybackController.h"
#import "SettingsMenu.h"
#import "MarkersWindowController.h"

@implementation ArrangerView

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
    if(self)
	{
		selectedRegions = [[NSMutableSet alloc] init];
		tempSelectedRegions = nil;
		selectedTrajectories = [[NSMutableSet alloc] init];
		regionForSelectedTrajectories = nil;
		placeholderRegions = [[NSMutableArray alloc] init]; // Array, these must be ordered
		arrangerTabStops = [[NSMutableIndexSet alloc] init];
		
		marqueeView = [[MarqueeView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
		[self addSubview:marqueeView];
	}
    return self;
}

- (void)awakeFromNib
{
	xGridPath = nil;
	yGridPath = nil;

	arrangerEditMode = arrangerModeNone;

	draggingDirtyFlag = NO;
	arrangerContentStart = arrangerContentEnd = arrangerMinY = arrangerMaxY = 0;


	// register for dragging from pool

	[self registerForDraggedTypes:[NSArray arrayWithObjects:CHAudioItemType, CHTrajectoryType, NSFilenamesPboardType, nil]];

	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(update:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
	
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(update:)
//												 name:@"projectSettingsDidChange" object:nil];		
// not necessary, as there is a notification when the context did change
	
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setZoom:)
												 name:@"arrangerViewZoomFactorDidChange" object:nil];


	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(undoNotification:)
												 name:@"NSUndoManagerDidUndoChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(undoNotification:)
												 name:@"NSUndoManagerDidRedoChangeNotification" object:nil];
}

- (void)setup
{	
	document = [[[self window] windowController] document];
	context = [document managedObjectContext];
	
	// get stored settings
	projectSettings = [[document valueForKey:@"projectSettings"] retain];
	xGridAmount = [[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue];
	
	// initialise context menus & popup buttons
	[nudgeAmountMenu setModel:projectSettings key:@"arrangerNudgeAmount"];
	[yGridLinesMenu setModel:projectSettings key:@"arrangerYGridLines"];
	[xGridLinesMenu setModel:projectSettings key:@"arrangerXGridLines" index:0];
	[xGridLinesMenu setModel:projectSettings key:@"arrangerXGridAmount" index:1];

	[arrangerDisplayModePopupButton setModel:projectSettings key:@"arrangerDisplayMode"];
	
	// init zoom factor
	zoomFactorX = [document zoomFactorX];
	zoomFactorY = [document zoomFactorY];
	
	// get stored data
	NSFetchRequest *request;
	NSError *error;
	NSEntityDescription *entityDescription;
    NSSortDescriptor *sortDescriptor;
    
	request = [[[NSFetchRequest alloc] init] autorelease];
    entityDescription = [NSEntityDescription entityForName:@"Region" inManagedObjectContext:context];
	sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"zIndexInArranger" ascending:YES] autorelease];

    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[request setEntity:entityDescription];
	[request setReturnsObjectsAsFaults:NO];
	
	[audioRegions release];
	audioRegions = [[context executeFetchRequest:request error:&error] retain];
		
    for (Region *region in audioRegions)
	{
		// set superview for all regions
		[region setValue:self forKey:@"superview"];
		[region recalcFrame];
	}
	

	[self recalculateArrangerProperties];
	[self recalculateArrangerSize];

	// init window scroll position
	NSPoint p = NSMakePoint([[projectSettings valueForKey:@"arrangerScrollOriginX"] floatValue],
							[[projectSettings valueForKey:@"arrangerScrollOriginY"] floatValue]);
	
	[self scrollPoint:p];
	
	
	
	// init playhead position
	[playbackController setLocator:0];
	
	[self setNeedsDisplay:YES];
}

- (void)close
{
	for(Region *region in audioRegions)
	{
		[region setValue:nil forKey:@"superview"];
	}
}


- (void)dealloc
{
	NSLog(@"ArrangerView: dealloc");
	
	[projectSettings release];	
	[selectedRegions release];
	[selectedTrajectories release];
	[audioRegions release];
	[placeholderRegions release];
	[arrangerTabStops release];
	
	[marqueeView release];
	[xGridPath release];
	[yGridPath release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	
	[super dealloc];
}



#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{	
    // colors
	NSColor *backgroundColor	= [NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];

	NSColor *xGridColor			= [NSColor colorWithCalibratedRed: 0.5 green: 0.6 blue: 0.6 alpha: 0.15];  
	NSColor *xGridColorMagnetic	= [NSColor colorWithCalibratedRed: 0.99 green: 0.99 blue: 0.7 alpha: 0.5];  
	
	NSColor *yGridColor			= [NSColor colorWithCalibratedRed: 0.5 green: 0.6 blue: 0.6 alpha: 0.15];  
	NSColor *yGridColorMagnetic	= [NSColor colorWithCalibratedRed: 0.99 green: 0.99 blue: 0.7 alpha: 0.5];  
	
	// background
	[backgroundColor set];
	NSRectFill([self bounds]);
	
	// grid
	if(([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue] == 0 && xGridPath)
	   || ([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue] != 0 && !xGridPath)
	   || xGridAmount != [[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue])
	{
		[self recalculateXGridPath];
	}	
		
	if(xGridPath)
	{
		if([self inLiveResize])
		{
			[self recalculateXGridPath];
		}
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		if([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue] == 2)
			[xGridColorMagnetic set];
		else
			[xGridColor set];
		[xGridPath stroke];
	}

	if(([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue] == 0 && yGridPath)
	   || ([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue] != 0 && !yGridPath))
	{
		[self recalculateYGridPath];
	}	

	if(yGridPath)
	{
		if([self inLiveResize])
		{
			[self recalculateYGridPath];
		}
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		if([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue] == 2)
			[yGridColorMagnetic set];
		else
			[yGridColor set];
		[yGridPath stroke];
	}
	
	// regions
    for (Region *region in audioRegions)
	{
        if ([self needsToDrawRect:[region frame]])
		{
            [region drawRect:rect];
        }
    }
	
	// placeholder regions
    for (PlaceholderRegion *placeholderRegion in placeholderRegions)
	{
		[placeholderRegion draw];
    }	
}

- (BOOL)isOpaque
{
    return YES;
	// This views doesn't need any of the views behind it.
	// This is a performance optimization hint for the display subsystem.
}

-(BOOL)isFlipped
{
	return YES;
	// this view uses a flipped coordinate system
	// i.e. the top left corner is the origin
}

//- (void)resetCursorRects
//{
//}	


- (void)recalculateYGridPath
{
	[yGridPath release];
	
	float i;
	float step = AUDIO_BLOCK_HEIGHT * zoomFactorY;
	switch([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue])
	{
		case 0:
			yGridPath = nil;
			break;
		default:
			yGridPath = [[NSBezierPath bezierPath] retain];
			[yGridPath setLineWidth:0.0];
			
			for(i=0; i<[self frame].size.height;i += step)
			{
				[yGridPath moveToPoint:NSMakePoint(0, i)];
				[yGridPath lineToPoint:NSMakePoint([self bounds].size.width, i)];
			}
	}
}

- (void)recalculateXGridPath
{
	[xGridPath release];
	
	xGridAmount = [[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue];

	float i;
	float step = zoomFactorX * xGridAmount;
    step = step < 1 ? 1 : step;
	switch([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue])
	{
		case 0:
			xGridPath = nil;
			break;
		default:
			xGridPath = [[NSBezierPath bezierPath] retain];
			[xGridPath setLineWidth:0.0];
			
			for(i=ARRANGER_OFFSET; i<[self frame].size.width;i += step)
			{
				[xGridPath moveToPoint:NSMakePoint(i, 0)];
				[xGridPath lineToPoint:NSMakePoint(i, [self bounds].size.height)];
			}
	}

}

- (void)recalculateArrangerProperties
{	
	arrangerContentStart = arrangerMinY = -1;
    arrangerContentEnd = arrangerMaxY = 0;
	NSUInteger value;
	
	[arrangerTabStops removeAllIndexes];
	
	for(Region *region in audioRegions)
	{		
		value = ([region frame].origin.x - ARRANGER_OFFSET) / zoomFactorX;			
		[arrangerTabStops addIndex:value];
        
        if(arrangerContentStart == -1 || value < arrangerContentStart)
            arrangerContentStart = value;

		value += [region frame].size.width / zoomFactorX;		
		[arrangerTabStops addIndex:value];

		if(value > arrangerContentEnd)
			arrangerContentEnd = value;

		value = [[region valueForKeyPath:@"yPosInArranger"] unsignedLongValue];

        if(arrangerMinY == -1 || value < arrangerMinY)
            arrangerMinY = value;
        
        value += AUDIO_BLOCK_HEIGHT;			
		
        if(value > arrangerMaxY)
			arrangerMaxY = value;
	}
}

- (void)recalculateArrangerSize
{
	NSSize frameSize;	
	NSSize clipFrameSize = [[self superview] bounds].size;
			
	if(arrangerContentEnd * zoomFactorX <= clipFrameSize.width)
		frameSize.width = clipFrameSize.width * 1.5;
	else
		frameSize.width = arrangerContentEnd * zoomFactorX * 1.5;
	
	if(arrangerMaxY * zoomFactorY <= clipFrameSize.height)
		frameSize.height = clipFrameSize.height * 1.2;
	else
		frameSize.height = arrangerMaxY * zoomFactorY * 1.2;
	
	[self setFrameSize:frameSize];

	[marqueeView recalcFrame];

	[self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [arrangerRuler setWidth:newSize.width];
}

- (void)zoomToFitContent
{    
    // calculate zoom factors
    zoomFactorX = ([self visibleRect].size.width - ARRANGER_OFFSET - 10) / (arrangerContentEnd - arrangerContentStart);
    zoomFactorY = ([self visibleRect].size.height - 10) / (arrangerMaxY - arrangerMinY);
    
	[projectSettings setValue:[NSNumber numberWithFloat:zoomFactorX] forKey:@"arrangerZoomFactorX"];    
	[projectSettings setValue:[NSNumber numberWithFloat:zoomFactorY] forKey:@"arrangerZoomFactorY"];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"arrangerViewZoomFactorDidChange" object:document];	
    
    // set origin
    [self scrollPoint:NSMakePoint(arrangerContentStart * zoomFactorX, arrangerMinY * zoomFactorY)];

    [self setNeedsDisplay:YES];
}


- (void)zoomToFitSelection
{
    if([[self selectedAudioRegions] count] == 0) return;
    
    NSUInteger start, end;
    NSUInteger minY, maxY;
    
    start = minY = -1;
    end = maxY = 0;
	
    NSUInteger value;

	for(Region *region in [self selectedAudioRegions])
	{		
		value = ([region frame].origin.x - ARRANGER_OFFSET) / zoomFactorX;			
        
        if(start == -1 || value < start)
            start = value;
        
		value += [region frame].size.width / zoomFactorX;		
        
		if(value > end)
			end = value;
        
		value = [[region valueForKeyPath:@"yPosInArranger"] unsignedLongValue];
        
        if(arrangerMinY == -1 || value < minY)
            minY = value;
        
        value += AUDIO_BLOCK_HEIGHT;			
		
        if(value > maxY)
			maxY = value;
	}

    // calculate zoom factors
    zoomFactorX = ([self visibleRect].size.width - ARRANGER_OFFSET - 10) / (end - start);
    zoomFactorY = ([self visibleRect].size.height - 10) / (maxY - minY);
    
	[projectSettings setValue:[NSNumber numberWithFloat:zoomFactorX] forKey:@"arrangerZoomFactorX"];    
	[projectSettings setValue:[NSNumber numberWithFloat:zoomFactorY] forKey:@"arrangerZoomFactorY"];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"arrangerViewZoomFactorDidChange" object:document];	
    
    // set origin
    [self scrollPoint:NSMakePoint(start * zoomFactorX, minY * zoomFactorY)];
}

	
#pragma mark -
#pragma mark drag and drop
// -----------------------------------------------------------

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info
{
	//NSLog(@"ArrangerView: draggingEntered");

	// trajectory from pool

	if([[document valueForKey:@"draggedTrajectories"] count] && ![[document valueForKey:@"draggedAudioRegions"] count])
	{
		arrangerViewDragAndDropAction = arrangerViewDragTrajectoryFromPool;
		return NSDragOperationGeneric;
	}

	
	// audio region from pool
	
	if([[document valueForKey:@"draggedAudioRegions"] count] && ![[document valueForKey:@"draggedTrajectories"] count])
	{
		for (id item in [document valueForKey:@"draggedAudioRegions"])
		{
			if(![[item valueForKey:@"isLeaf"] boolValue])  // all proposed items must be leaves
			{
				arrangerViewDragAndDropAction = arrangerViewDragInvalid;
				return NSDragOperationNone;
			}
		}
		
		for (id item in [document valueForKey:@"draggedAudioRegions"])
		{
			NSUInteger dur = [[item valueForKeyPath:@"item.duration"] longLongValue];
			float height = AUDIO_BLOCK_HEIGHT * zoomFactorY - 1;
			
			NSRect r = NSMakeRect(0, -height, dur * zoomFactorX, height);
			PlaceholderRegion *placeholderRegion = [PlaceholderRegion placeholderRegionWithFrame:r];
			
			[placeholderRegion setValue:[item valueForKey:@"item"] forKey:@"audioItem"];
			[placeholderRegions addObject:placeholderRegion];
		}
		
		arrangerViewDragAndDropAction = arrangerViewDragAudioFromPool;
		return NSDragOperationGeneric;
	}

	// audio file from finder

	AudioFileID audioFileID;
	AudioStreamBasicDescription basicDescription;

	if ([[info.draggingPasteboard types] containsObject:NSFilenamesPboardType])
	{
        for(id filePath in [info.draggingPasteboard propertyListForType:NSFilenamesPboardType])
		{
			audioFileID = [AudioFile idOfAudioFileAtPath:filePath];
			basicDescription = [AudioFile descriptionOfAudioFile:audioFileID];

			// if any of the proposed files is unreadable
			// or doesn't have the appropriate sampling rate or number of channels
			// the drag operation is invalidated and aborded
			if(!audioFileID ||
			   basicDescription.mSampleRate != [[[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument.projectSettings.projectSampleRate"] intValue] ||
			   basicDescription.mChannelsPerFrame != 1)
			{
				arrangerViewDragAndDropAction = arrangerViewDragInvalid;
				return NSDragOperationNone;
			}
		}

		for(id filePath in [info.draggingPasteboard propertyListForType:NSFilenamesPboardType])
		{
			NSUInteger dur = [AudioFile durationOfAudioFileAtPath:filePath];
			
			float height = AUDIO_BLOCK_HEIGHT * zoomFactorY - 1;
		
			NSRect r = NSMakeRect(0, -height, dur * zoomFactorX, height);
			PlaceholderRegion *placeholderRegion = [PlaceholderRegion placeholderRegionWithFrame:r];
		
			[placeholderRegion setValue:filePath forKey:@"filePath"];
			[placeholderRegion setValue:nil forKey:@"audioItem"];
			[placeholderRegions addObject:placeholderRegion];
		}

		arrangerViewDragAndDropAction = arrangerViewDragAudioFromFinder;
		return NSDragOperationGeneric;
	}
	

	// invalid drag

	arrangerViewDragAndDropAction = arrangerViewDragInvalid;
	return NSDragOperationNone;
	
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)info
{
	switch(arrangerViewDragAndDropAction)
	{
		case arrangerViewDragTrajectoryFromPool:
			[self trajectoryDraggingUpdated:info];
			break;
		case arrangerViewDragAudioFromPool:
		case arrangerViewDragAudioFromFinder:
			[self audioDraggingUpdated:info];
			break;
		default:
			return NSDragOperationNone;
	}
	
	[self setNeedsDisplay:YES];
	return NSDragOperationGeneric;
}

- (void)trajectoryDraggingUpdated:(id <NSDraggingInfo>)info
{
//	NSLog(@"trajectoryDraggingUpdated");

	NSPoint localPoint = [self convertPoint:[info draggingLocation] fromView:nil];
	localPoint.x -= ARRANGER_OFFSET;
	Region *region = [self pointInRegion:localPoint];
	
	if(!region || // or when mouse moves directly from one region to another:
		([placeholderRegions count] && [[placeholderRegions objectAtIndex:0] frame].origin.x != [region frame].origin.x))
	{
		for(Region *rg in placeholderRegions)
		{
			[rg setValue:[NSNumber numberWithBool:NO] forKeyPath:@"region.displaysTrajectoryPlaceholder"];		
		}
		[placeholderRegions removeAllObjects];
	}

	if([placeholderRegions count] == 0)
	{		
		NSRect r = [region frame];
		r.size.height = REGION_TRAJECTORY_BLOCK_HEIGHT;
		r.origin.y += [region frame].size.height - REGION_TRAJECTORY_BLOCK_HEIGHT;

		PlaceholderRegion *placeholderRegion = [PlaceholderRegion placeholderRegionWithFrame:r];

		[placeholderRegions addObject:placeholderRegion];

		[placeholderRegion setValue:region forKey:@"region"];
		[placeholderRegion setValue:[NSNumber numberWithBool:YES] forKeyPath:@"region.displaysTrajectoryPlaceholder"];
	}
}


- (void)audioDraggingUpdated:(id <NSDraggingInfo>)info
{
//	NSLog(@"audioDraggingUpdated");
	
	NSPoint insertionPoint = [self convertPoint:[info draggingLocation] fromView:[[[self superview] superview] superview]];

	insertionPoint.x -= 20; // convenient for mouse handling
	insertionPoint.y -= 20; // convenient for mouse handling

	insertionPoint.x = insertionPoint.x < 0 ? 0 : insertionPoint.x;
	insertionPoint.y = insertionPoint.y < 0 ? 0 : insertionPoint.y;
	
	// restrict position
	// on x axis
	// - by magnetic playhead cursor
	if([info draggingSourceOperationMask] == NSDragOperationGeneric) // i.e. command key pressed
	{
		insertionPoint.x = [playbackController locator] * zoomFactorX;
	}
	// - or magnetic grid
	else if([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue] == 2)
	{
		insertionPoint.x = ([[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue] * zoomFactorX)
							* round(insertionPoint.x / ([[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue] * zoomFactorX));
	}
	// on y axis
	// - by magnetic grid
	if([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue] == 2)
	{
		insertionPoint.y = (AUDIO_BLOCK_HEIGHT * zoomFactorY) * round(insertionPoint.y / (AUDIO_BLOCK_HEIGHT * zoomFactorY));
	}

	NSRect r = NSMakeRect(insertionPoint.x + ARRANGER_OFFSET, insertionPoint.y, 0, 0);

	NSPoint maxPoint = NSMakePoint(0, 0);
 
    for(Region *placeholderRegion in placeholderRegions)
	{
		r.size.width = [placeholderRegion frame].size.width;
		r.size.height = [placeholderRegion frame].size.height;
		[placeholderRegion setFrame:r];

		if([[projectSettings valueForKey:@"poolDropOrder"] integerValue] == 0)
			r.origin.y += [placeholderRegion frame].size.height;
		else
			r.origin.x += [placeholderRegion frame].size.width;
			
		if(r.origin.x + r.size.width > maxPoint.x)
			maxPoint.x = r.origin.x + r.size.width;
		
		if(r.origin.y + r.size.height > maxPoint.y)
			maxPoint.y = r.origin.y + r.size.height;			
	}

	// extend arranger view automatically
	maxPoint.x += 20; // (see above: 20 have been subtracted from the dragging location)
	if(!NSPointInRect(maxPoint, [self frame]))
	{
		NSSize frameSize = [self frame].size;
		if(frameSize.width < maxPoint.x)
			frameSize.width = maxPoint.x;
		if(frameSize.height < maxPoint.y)
			frameSize.height = maxPoint.y;
		
		[self setFrameSize:frameSize];
	}
 }

- (void)draggingExited:(id <NSDraggingInfo>)info
{
//	NSLog(@"ArrangerView: draggingExited");

	for(Region *rg in placeholderRegions)
	{
		[rg setValue:[NSNumber numberWithBool:NO] forKeyPath:@"region.displaysTrajectoryPlaceholder"];		
	}
	[placeholderRegions removeAllObjects];

	[self setNeedsDisplay:YES];

	arrangerViewDragAndDropAction = arrangerViewDragNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info
{
//	NSLog(@"performDragOperation");
	
	switch(arrangerViewDragAndDropAction)
	{
		case arrangerViewDragTrajectoryFromPool:
			return [self performTrajectoryDragOperation:info];;

		case arrangerViewDragAudioFromPool:
		case arrangerViewDragAudioFromFinder:
			return [self performAudioDragOperation:info];

		default:
			return NO;
	}
}
	
- (BOOL)performTrajectoryDragOperation:(id <NSDraggingInfo>)info
{
	// NSLog(@"performTrajectoryDragOperation");

	NSArray *draggedTrajectories = [document valueForKey:@"draggedTrajectories"];

	NSPoint localPoint = [self convertPoint:[info draggingLocation] fromView:nil];
	Region *region = [self pointInRegion:localPoint];

	if(!region)
	{
		[placeholderRegions removeAllObjects];
		return NO;
	}
	
	[region setValue:[[draggedTrajectories objectAtIndex:0] valueForKey:@"item"] forKey:@"trajectoryItem"];
    [region setValue:[NSNumber numberWithInt:1] forKey:@"trajectoryDurationMode"]; // reset duration mode
	[self addRegionToSelection:region];
	
	for(Region *rg in placeholderRegions)
	{
		[rg setValue:[NSNumber numberWithBool:NO] forKeyPath:@"region.displaysTrajectoryPlaceholder"];		
	}
	[placeholderRegions removeAllObjects];

	// make first responder
	[[self window] makeFirstResponder:self];
	
	// undo
	[[context undoManager] setActionName:@"add trajectory to arranger"];
	
	// notification
	[document selectionInArrangerDidChange];
	
	// clear memory of dragged items
	[document setValue:nil forKey:@"draggedAudioRegions"];
	[document setValue:nil forKey:@"draggedTrajectories"];

	
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)performAudioDragOperation:(id <NSDraggingInfo>)info
{
	AudioRegion *newRegion;
	AudioItem *audioItem;
	NSURL *url;
 
	for (id placeholder in placeholderRegions)
	{
		audioItem = [placeholder valueForKey:@"audioItem"];
		
		if(!audioItem) // drag from the finder, this audio file has yet to be imported
		{
            url = [NSURL URLWithString:[[placeholder valueForKey:@"filePath"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

			audioItem = [[document poolViewController] importFile:url];
		}
		
		newRegion = [NSEntityDescription insertNewObjectForEntityForName:@"AudioRegion" inManagedObjectContext:context];
		[self addRegionToView:newRegion];

		NSNumber *insertTime = [NSNumber numberWithUnsignedLong:([placeholder frame].origin.x - ARRANGER_OFFSET) / zoomFactorX]; 
		NSNumber *insertYPosition = [NSNumber numberWithUnsignedLong:[placeholder frame].origin.y / zoomFactorY]; 

		[newRegion setFrame:[placeholder frame]];
		[newRegion setValue:audioItem forKey:@"audioItem"];
		[newRegion setValue:insertTime forKey:@"startTime"];
		[newRegion setValue:insertYPosition forKey:@"yPosInArranger"];
		
		[self addRegionToSelection:newRegion];
	}

	// make first responder
	[[self window] makeFirstResponder:self];

    // undo
    if([placeholderRegions count] == 1)
        [[context undoManager] setActionName:@"add audio region to arranger"];
    else if([placeholderRegions count] > 1)
        [[context undoManager] setActionName:@"add audio regions to arranger"];
	
	// notification
	[document selectionInArrangerDidChange];
	
	// clear memory of dragged items
	[document setValue:nil forKey:@"draggedAudioRegions"];
	[document setValue:nil forKey:@"draggedTrajectories"];
	[placeholderRegions removeAllObjects];
    
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];

	return YES;
}


#pragma mark -
#pragma mark editing
// -----------------------------------------------------------

- (void)addRegionToView:(Region *)region
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	[temp addObject:region];
	
	[region setValue:self forKey:@"superview"];

	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];
	
	[self updateZIndexInModel];
}

- (void)removeRegionFromView:(Region *)region
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	[temp removeObject:region];
	
	[region setValue:nil forKey:@"superview"];

	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];		

	[self updateZIndexInModel];

	[context deleteObject:region];
}	

- (void)updateZIndexInModel
{
	int zIndex;
	
	for(Region *region in audioRegions)
	{
		zIndex = [audioRegions indexOfObject:region];
		[region setValue:[NSNumber numberWithInt:zIndex] forKey:@"zIndexInArranger"];
	}
}


- (NSPoint)moveSelectedRegionsBy:(NSPoint)delta restricted:(BOOL)magnetism
{
	NSRect r;
	
	if(![self selectionIsEditable])
		return NSMakePoint(0,0);

    BOOL first = YES;

	for(Region *region in selectedRegions)
    {
        r = [region frame];
    
        if(first)
        {
            draggingParameter[0] = r.origin.x;
            draggingParameter[1] = r.origin.y;
            draggingParameter[2] = r.origin.x + r.size.width;
            draggingParameter[3] = r.origin.y + r.size.height;
            first = NO;
        }
        else
        {
            if(r.origin.x < draggingParameter[0]) // min X
                draggingParameter[0] = r.origin.x;		
        
            if(r.origin.y < draggingParameter[1]) // min Y
                draggingParameter[1] = r.origin.y;		
        
            if(r.origin.x + r.size.width > draggingParameter[2])	// max X
                draggingParameter[2] = r.origin.x + r.size.width;
        
            if(r.origin.y + r.size.height > draggingParameter[3])	// max Y
                draggingParameter[3] = r.origin.y + r.size.height;			
        }
    }


	// restrict minimum to 0
	if(draggingParameter[0] + delta.x < 0 + ARRANGER_OFFSET)
	{
		delta.x = draggingParameter[0] * -1 + ARRANGER_OFFSET;
	}
	if(draggingParameter[1] + delta.y < 0)
	{
		delta.y = draggingParameter[1] * -1;
	}

	// restrict position
	// on x axis
	// - by magetic playhead cursor
	if(document.keyboardModifierKeys == modifierCommand)
	{
		delta.x = [playbackController locator] * zoomFactorX - draggingParameter[0] + ARRANGER_OFFSET;
	}
	// - or magetic grid
	else if([[projectSettings valueForKey:@"arrangerXGridLines"] integerValue] == 2 && magnetism)
	{
		delta.x = ([[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue] * zoomFactorX)
		* floor((draggingParameter[0] + delta.x) / ([[projectSettings valueForKey:@"arrangerXGridAmount"] integerValue] * zoomFactorX))
		- draggingParameter[0] + ARRANGER_OFFSET;
	}
	if([[projectSettings valueForKey:@"arrangerYGridLines"] integerValue] == 2 && magnetism)
	{
		delta.y = (AUDIO_BLOCK_HEIGHT * zoomFactorY) * round((draggingParameter[1] + delta.y) / (AUDIO_BLOCK_HEIGHT * zoomFactorY)) - draggingParameter[1];
	}
	
	// move all selected regions by delta
	for(Region *region in selectedRegions)
	{
		[region moveByDeltaX:delta.x deltaY:delta.y];	
	}
	
	[self setNeedsDisplayInRect:NSMakeRect(draggingParameter[0] - 4,
										   draggingParameter[1] - 1,
										   draggingParameter[2] - draggingParameter[0] + 8,
										   draggingParameter[3] - draggingParameter[1] + 2)];

	// move parameters too
	draggingParameter[0] += delta.x;
	draggingParameter[1] += delta.y;
	draggingParameter[2] += delta.x;
	draggingParameter[3] += delta.y;
	
	
	[self setNeedsDisplayInRect:NSMakeRect(draggingParameter[0],
										   draggingParameter[1],
										   draggingParameter[2] - draggingParameter[0],
										   draggingParameter[3] - draggingParameter[1])];

	
	// extend arranger view automatically
	if(!NSPointInRect(NSMakePoint(draggingParameter[2], draggingParameter[3]), [self frame]))
	{
		NSSize frameSize = [self frame].size;
		if(frameSize.width < draggingParameter[2])
			frameSize.width = draggingParameter[2];
		if(frameSize.height < draggingParameter[3])
			frameSize.height = draggingParameter[3];
		
		[self setFrameSize:frameSize];
	}

	return delta;
}

- (float)cropSelectedRegionsBy:(NSPoint)delta
{
	float width, minWidth = -1;
	float extendRight, maxExtendRight = -1;
	float offset, maxExtendLeft = -1;
	
	if(![self selectionIsEditable])
		return 0.0;

	for(Region *region in selectedRegions)
	{
		// find minimum width
		width = [region frame].size.width;
		if(minWidth == -1 || minWidth > width)
				minWidth = width;
		
		// find max possible extension to the left
		offset = [region offset];
		if(offset < maxExtendLeft || maxExtendLeft == -1)
			maxExtendLeft = offset;

		// find max possible extension to the right
		extendRight = [[region valueForKeyPath:@"audioItem.audioFile.duration"] unsignedLongValue] * zoomFactorX - width - offset;
		if(maxExtendRight == -1 || maxExtendRight > extendRight)
			maxExtendRight = extendRight;		
	}

	// minimum width is 1
	if(minWidth - delta.x + delta.y < 1)
	{
		if(delta.x == 0)
			delta.y = 1 - minWidth;
		else
			delta.x = minWidth - 1;
	}
	
	// max width
	if((delta.x * -1) > maxExtendLeft)
		delta.x = (-1 * maxExtendLeft);
	if(delta.y > maxExtendRight)
		delta.y = maxExtendRight;
	

	for(Region *region in selectedRegions)
	{
		[region cropByDeltaX1:delta.x deltaX2:delta.y];	
	}
	
	[self setNeedsDisplay:YES];

	return delta.x + delta.y;		
}

- (void)removeSelectedRegions
{	
	if(![self selectionIsEditable])
		return;

	if([selectedRegions count])
	{
        for(Region *region in selectedRegions)
		{
			[self recursivelyDeleteRegions:region];
		}
		
		// undo
		if([selectedRegions count] == 1)
			[[context undoManager] setActionName:@"remove audio region"];
		else if([selectedRegions count] > 1)
			[[context undoManager] setActionName:@"remove audio regions"];

		[self deselectAllRegions];
		[self recalculateArrangerProperties];
	}
	else if([selectedTrajectories count])
	{
	}
	
	// notification
	[document selectionInArrangerDidChange];

	[self setNeedsDisplay:YES];
}

- (void)recursivelyDeleteRegions:(Region *)region
{		
    for(Region *child in [region valueForKey:@"childRegions"])
	{
		[self recursivelyDeleteRegions:child];
    }
	
	[self removeRegionFromView:region];
}

- (void)removeSelectedGainBreakpoints
{
	for(Region *region in selectedRegions)
	{
		[region removeSelectedGainBreakpoints];
	}

	[self setNeedsDisplay:YES];
}

// -----------------------------------------------------------
#pragma mark -
#pragma mark copying regions 

- (Region *)makeUniqueCopyOf:(Region *)originalRegion
{
//	NSLog(@"********* original %i, regions %i", [[originalRegion valueForKeyPath:@"audioItem.isOriginal"] boolValue], [[originalRegion mutableSetValueForKeyPath:@"audioItem.audioRegions"] count]);
	
	if(![[originalRegion valueForKeyPath:@"audioItem.isOriginal"] boolValue] &&
	   [[originalRegion mutableSetValueForKeyPath:@"audioItem.audioRegions"] count] == 1)
		return [self makeCopyOf:originalRegion]; 
	// this audio region/item is unique, thus can be manipulated
	
//	NSLog(@"********* make unique");
	Region *newRegion = [self makeCopyOf:originalRegion];
	
	NSManagedObject *newNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node" 
															 inManagedObjectContext:context];
	AudioItem *newAudioItem = [NSEntityDescription insertNewObjectForEntityForName:@"AudioItem"
															inManagedObjectContext:context]; 
	
	[newNode setValue:[originalRegion valueForKeyPath:@"audioItem.node.parent"] forKey:@"parent"]; 
	[newNode setValue:[NSNumber numberWithBool:YES] forKey:@"isLeaf"];				
	[newNode setValue:CHAudioItemType forKey:@"type"];
	[newNode setValue:newAudioItem forKey:@"item"];
	
	// set a new unique name (<name>-<index>)
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"AudioItem" inManagedObjectContext:context];
	[request setEntity:entityDescription];
	NSString *name = [originalRegion valueForKeyPath:@"audioItem.node.name"];
	NSError *error;
	BOOL unique = NO;
	int i;
	
	NSRange range = [name rangeOfString:@"-" options:NSBackwardsSearch];
	if(range.length)
		name = [name substringToIndex:range.location];
	
	for(i=1;!unique;i++)
	{
		[request setPredicate:[NSPredicate predicateWithFormat:@"node.name == %@", [name stringByAppendingString:[NSString stringWithFormat:@"-%i", i]]]];
		
		if([context countForFetchRequest:request error:&error] == 0)
		{
			[newNode setValue:[name stringByAppendingString:[NSString stringWithFormat:@"-%i", i]] forKey:@"name"];
			unique = YES;
		}
	}
	
	[newAudioItem setValue:[originalRegion valueForKeyPath:@"audioItem.audioFile"] forKey:@"audioFile"];
	[newAudioItem setValue:[originalRegion valueForKeyPath:@"audioItem.duration"] forKey:@"duration"];
	
	[newRegion setValue:newAudioItem forKey:@"audioItem"];

	return newRegion;
}

- (Region *)makeCopyOf:(Region *)originalRegion
{
	Region *newRegion;
	
	if([originalRegion isKindOfClass:[AudioRegion class]])
	{
		newRegion = [NSEntityDescription insertNewObjectForEntityForName:@"AudioRegion" inManagedObjectContext:context];
		[self addRegionToView:newRegion];
		
		[newRegion setFrame:[originalRegion frame]];
		[newRegion setValue:[originalRegion valueForKey:@"contentOffset"] forKey:@"contentOffset"];
		[newRegion setValue:[originalRegion valueForKey:@"audioItem"] forKey:@"audioItem"];
		[newRegion setValue:[originalRegion valueForKey:@"startTime"] forKey:@"startTime"];

		[newRegion setValue:[[[originalRegion valueForKey:@"position"] copy] autorelease] forKey:@"position"];

		[newRegion setValue:[originalRegion valueForKey:@"yPosInArranger"] forKey:@"yPosInArranger"];
		[newRegion setValue:[originalRegion valueForKey:@"trajectoryItem"] forKey:@"trajectoryItem"];
		[newRegion setValue:self forKey:@"superview"];
	}
	else if([originalRegion isKindOfClass:[GroupRegion class]])
	{
		newRegion = [NSEntityDescription insertNewObjectForEntityForName:@"GroupRegion" inManagedObjectContext:context];
		[self addRegionToView:newRegion];
		
//		[newRegion setFrame:[originalRegion frame]];
//		[newRegion setValue:[originalRegion valueForKey:@"startTime"] forKey:@"startTime"];
//		[newRegion setValue:[originalRegion valueForKey:@"yPosInArranger"] forKey:@"yPosInArranger"];
		[newRegion setValue:[originalRegion valueForKey:@"trajectoryItem"] forKey:@"trajectoryItem"];
//		[newRegion setValue:self forKey:@"superview"];

		for(Region *region in [originalRegion valueForKey:@"childRegions"])
		{
			[(GroupRegion *)newRegion addChildRegion:[self makeCopyOf:region]];
		}
	}
	
    // copy gain curve
	BreakpointArray *gainBreakpointArray = [[originalRegion valueForKey:@"gainBreakpointArray"] copy];
	[newRegion setValue:gainBreakpointArray forKey:@"gainBreakpointArray"];


	return newRegion;
}



#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
//	NSLog(@"ArrangerView key code: %d ", keyCode);

	NSUInteger locator;

	switch(keyCode)
	{
		// delete
		case 117:
		// backspace
		case 51:
			if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
				[self removeSelectedRegions];
			if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
				[self removeSelectedGainBreakpoints];
			break;

		// tab
		case 48:
            if([event modifierFlags] & NSAlternateKeyMask)
            {
                if(!([event modifierFlags] & NSShiftKeyMask))
                   locator = [[MarkersWindowController sharedMarkersWindowController] locatorGreaterThan:[playbackController locator]];
                else
                    locator = [[MarkersWindowController sharedMarkersWindowController] locatorLessThan:[playbackController locator]];
				
                if(locator != NSNotFound)
					[playbackController setLocator:locator];
            }
			else if([event modifierFlags] & NSShiftKeyMask)
			{
				locator = [arrangerTabStops indexLessThanIndex:[playbackController locator]];
				if(locator == NSNotFound)
					[playbackController setLocator:0];
				else
					[playbackController setLocator:locator];
			}
			else
			{
				locator = [arrangerTabStops indexGreaterThanIndex:[playbackController locator]];
				if(locator != NSNotFound)
					[playbackController setLocator:locator];
			}
			break;
			
		// esc
		case 53:
			[marqueeView dismiss];
			[self selectNone:self];
			break;
			
		// nudge selected regions
		case 123:	// arrow left
			[self nudge:NSMakePoint([[projectSettings valueForKey:@"arrangerNudgeAmount"] integerValue] * zoomFactorX * -1, 0)];
			break;
		case 124:	// arrow right
			[self nudge:NSMakePoint([[projectSettings valueForKey:@"arrangerNudgeAmount"] integerValue] * zoomFactorX, 0)];
			break;
		case 125:	// arrow down
			[self nudge:NSMakePoint(0, AUDIO_BLOCK_HEIGHT * zoomFactorY * 0.1)];
			break;
		case 126:	// arrow up
			[self nudge:NSMakePoint(0, AUDIO_BLOCK_HEIGHT * zoomFactorY * -0.1)];
			break;
		
		default:
			[[self nextResponder] keyDown:event];
	}
}

- (void)nudge:(NSPoint)p
{
	if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		// TODO: nudge gain handles
	}
	else
	{
		[self moveSelectedRegionsBy:p restricted:NO];

		for(id aRegion in selectedRegions)
		{
			[aRegion updateTimeInModel];
		}
		
		[self recalculateArrangerProperties];
		
		// undo
		if([selectedRegions count] == 1)
			[[context undoManager] setActionName:@"nudge audio region"];
		else if([selectedRegions count] > 1)
			[[context undoManager] setActionName:@"nudge audio regions"];
	}
}

#pragma mark -
#pragma mark mouse events
// -----------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
//	NSLog(@"ArrangerView -- becomeFirstResponder...");
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self deselectAllRegions];
	return YES;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
	// first click activates the window automatically
	// so the user can immediately start manipulating
}

- (id)pointInRegion:(NSPoint)point
{
	NSEnumerator *enumerator = [audioRegions reverseObjectEnumerator]; // reverse = frontmost first
	Region *region;
	
	while ((region = [enumerator nextObject]))
	{
		if (NSPointInRect(point, [region frame]))
		{
			return region;
		}
	}
	
	return NULL;
}

- (int)detailsAboutPoint:(NSPoint)point inRegion:(id)region
{
    NSRect frame = [region frame];
    
    if(frame.size.height < REGION_NAME_BLOCK_HEIGHT + 5 ||
       frame.size.width < 10)
        return 1;
    
    if(point.y < frame.origin.y + REGION_NAME_BLOCK_HEIGHT)
        return 1;
    
    if(point.x < frame.origin.x + 5) return 2;
    if(point.x > frame.origin.x + frame.size.width - 5) return 3;
    
    
    return 0;
    
    // 0 = anywhere, 1 = name, 2 = left edge, 3 = right edge
}


- (void)rightMouseDown:(NSEvent *)event
{
	// show context menu only when mouse inside a region
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	hitAudioRegion = [self pointInRegion:localPoint];

	if(hitAudioRegion)
	{
		if([hitAudioRegion valueForKey:@"trajectoryItem"] && NSPointInRect(localPoint, [hitAudioRegion trajectoryFrame]))
		{
			[trajectoryContextMenu setModel:hitAudioRegion
										key:@"trajectoryDurationMode"
									  index:0];
			[NSMenu popUpContextMenu:trajectoryContextMenu withEvent:event forView:self];
		}
		else
		{
			[NSMenu popUpContextMenu:regionContextMenu withEvent:event forView:self];
		}
	}
	else
		[NSMenu popUpContextMenu:arrangerContextMenu withEvent:event forView:self];
		
}

- (void)mouseDown:(NSEvent *)event
{
	// control click  ==  right mouse
	if([event modifierFlags] & NSControlKeyMask)
	{
		[self rightMouseDown:event];
		return;
	}
	
	
	/* handle double clicks
		- open special editors
		- not yet implemented
	
	if([event clickCount] > 1)
	{
		NSLog(@"double click");
		return;
	}
     */

    
	// find out if the click hits a region
	
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	storedEventLocation = localPoint;
	
	hitAudioRegion = [self pointInRegion:localPoint];
    

    // select / deselect regions
    
    if([event modifierFlags] & NSShiftKeyMask)
    {
        if(hitAudioRegion)
        {
            if([[hitAudioRegion valueForKeyPath:@"selected"] boolValue])
            {
                [self removeRegionFromSelection:hitAudioRegion];
            }
            else
            {
                [self addRegionToSelection:hitAudioRegion];
            }
        }
        else
        {
            [[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:[self convertPoint:[event locationInWindow] fromView:nil] forView:self];
        }    
    }
    else
    {
        if(hitAudioRegion)
        {
            if(![[hitAudioRegion valueForKeyPath:@"selected"] boolValue])
            {
                [self deselectAllRegions];
                [self deselectAllTrajectories];
            }
            [self addRegionToSelection:hitAudioRegion];
        }
        else
        {
            [self deselectAllRegions];
            [self deselectAllTrajectories];

            [[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:[self convertPoint:[event locationInWindow] fromView:nil] forView:self];
        }
    }
    
    // notification
    [document selectionInArrangerDidChange];

    
    // decide upon the type of mouse action
    // and set the cursor accordingly
    if(hitAudioRegion && [[hitAudioRegion valueForKeyPath:@"selected"] boolValue])
    {
        if([event modifierFlags] & NSAlternateKeyMask)        
        {    
            [[NSCursor dragCopyCursor] push];
            arrangerEditMode = arrangerModeDuplicate;
        }
        else
        {    
            if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
            {
                // arranger is in region mode
                switch ([self detailsAboutPoint:localPoint inRegion:hitAudioRegion])
                {
                    case 2:
                        [[NSCursor resizeRightCursor] push];
                        arrangerEditMode = arrangerModeCropLeft;
                        break;
                    case 3:
                        [[NSCursor resizeLeftCursor] push];
                        arrangerEditMode = arrangerModeCropRight;
                        break;
                        
                    default:
                        [[NSCursor openHandCursor] push];
                        arrangerEditMode = arrangerModeDrag;
                }
            }
            if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
            {
                // arranger is in gain mode
                switch ([self detailsAboutPoint:localPoint inRegion:hitAudioRegion])
                {
                    case 1:
                        [[NSCursor openHandCursor] push];
                        arrangerEditMode = arrangerModeDrag;
                        break;
                    default:
                        [[NSCursor pointingHandCursor] push];
                        arrangerEditMode = arrangerModeGain;
                        break;
                }
            }            
        }
	}
    else if(hitAudioRegion && ![[hitAudioRegion valueForKeyPath:@"selected"] boolValue])
    {
        // region deselected by a shift click
        arrangerEditMode = arrangerModeNone;
    }
    else
    {
        if([event modifierFlags] & NSCommandKeyMask)
        {
            [marqueeView dismiss];
            [[NSCursor crosshairCursor] push];
            [[self window] disableCursorRects]; // needed only here
            arrangerEditMode = arrangerModeMarquee;        
        }
        else
        {
            arrangerEditMode = arrangerModeSelectMultiple;
        }
    }
    
    // pass the mouse event
    // if arranger in gain mode
    
	if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
        [hitAudioRegion mouseDown:localPoint];
	}

	// on mouse down always redraw everything
    
	[self setNeedsDisplay:YES];
}


- (void)mouseDragged:(NSEvent *)event
{
	NSPoint delta;
	NSPoint eventLocation = [event locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
	
	delta.x = localPoint.x - storedEventLocation.x;
	delta.y = localPoint.y - storedEventLocation.y;

    if(arrangerEditMode == arrangerModeCropLeft)
    {
        delta.x = [self cropSelectedRegionsBy:NSMakePoint(delta.x, 0)];
    }

    else if(arrangerEditMode == arrangerModeCropRight)
    {
        delta.x = [self cropSelectedRegionsBy:NSMakePoint(0, delta.x)];
    }

    else if(arrangerEditMode == arrangerModeSelectMultiple || arrangerEditMode == arrangerModeMarquee)
    {
        [self showSelectionRectangle:event];
        return;
    }

    else if(arrangerEditMode == arrangerModeDuplicate)
    {
        Region *region1, *region2;
        NSMutableSet *tempSelection = [[[NSMutableSet alloc] init] autorelease];
        
        for(region1 in selectedRegions)
        {
            region2 = [self makeCopyOf:region1];
            [tempSelection addObject: region2];
            [region1 setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
            [region2 setValue:[NSNumber numberWithBool:YES] forKey:@"selected"];
        }
        
        [selectedRegions removeAllObjects];
        [selectedRegions unionSet:tempSelection];

        // start undo group (combined duplication and dragging)
        [[context undoManager] beginUndoGrouping];
        
        arrangerEditMode = arrangerModeDuplicateDrag;
    }
    
    else if(arrangerEditMode == arrangerModeDrag || arrangerEditMode == arrangerModeDuplicateDrag)
    {
        delta = [self moveSelectedRegionsBy:delta restricted:YES];
    }
    
    else if(arrangerEditMode == arrangerModeGain)
    {
		for(Region *region in selectedRegions)
		{
			delta = [region proposedMouseDrag:delta];
		}
        
		for(Region *region in selectedRegions)
		{
			[region mouseDragged:delta];
		}

        [self setNeedsDisplay:YES];    
    }


   // support automatic scrolling during a drag
    NSRect r = NSMakeRect(localPoint.x - 10, localPoint.y - 10, 20, 20);
    [self scrollRectToVisible:r];

    // reflect altered start time in editors
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];

	storedEventLocation.x += delta.x;
	storedEventLocation.y += delta.y;
    
    draggingDirtyFlag = YES;
}
		

- (void)mouseUp:(NSEvent *)event
{
	Region *aRegion, *region1;

    if(draggingDirtyFlag)
    {
        if(arrangerEditMode == arrangerModeDrag)
        {
            for (aRegion in selectedRegions)
            {
                [aRegion updateTimeInModel];
            }
            
            // undo
            if([selectedRegions count] == 1)
                [[context undoManager] setActionName:@"drag audio region"];
            else if([selectedRegions count] > 1)
                [[context undoManager] setActionName:@"drag audio regions"];
        }
        else if(arrangerEditMode == arrangerModeDuplicateDrag)
        {
            for (aRegion in selectedRegions)
            {
                [aRegion updateTimeInModel];
                [aRegion archiveData];
            }
            
            // undo
            if([selectedRegions count] == 1)
                [[context undoManager] setActionName:@"duplicate audio region"];
            else if([selectedRegions count] > 1)
                [[context undoManager] setActionName:@"duplicate audio regions"];
            [[context undoManager] endUndoGrouping];
        }
        else if(arrangerEditMode == arrangerModeCropLeft || arrangerEditMode == arrangerModeCropRight)
        {   
            Region *anyRegion = [selectedRegions anyObject];
            
            // proceed only if the duration has actually changed
            if([[anyRegion valueForKey:@"duration"] intValue] != (int)(anyRegion.frame.size.width / zoomFactorX))
            {                
                NSMutableSet *tempSet = [[[NSMutableSet alloc] init] autorelease];
                
                for (aRegion in selectedRegions)
                {
                    region1 = [self makeUniqueCopyOf:aRegion];
                    
                    [self removeRegionFromView:aRegion];

                    [region1 archiveData];
                    [region1 updateTimeInModel];
                    
                    [tempSet addObject:region1];
                }
                
                [self deselectAllRegions];
                for (aRegion in tempSet)
                {
                    [self addRegionToSelection:region1];
                }
            
                
                // undo
                if([selectedRegions count] == 1)
                    [[context undoManager] setActionName:@"crop audio region"];
                else if([selectedRegions count] > 1)
                    [[context undoManager] setActionName:@"crop audio regions"];
                                
            }
        }
        
        draggingDirtyFlag = NO;
        [self recalculateArrangerProperties];
    }

    if(arrangerEditMode == arrangerModeMarquee)
    {
        NSRect frame = [[SelectionRectangle sharedSelectionRectangle] frame];
        
        [marqueeView setStart:frame.origin.x
                    yPosition:frame.origin.y
                    duration:frame.size.width
                    height:frame.size.height];
    }

	
	/*	arranger is in gain mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	if([[projectSettings valueForKey:@"arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		// pass the mouse event
		[hitAudioRegion mouseUp:event];
	}
	

	
	[SelectionRectangle release];
	
	[tempSelectedRegions release];
	tempSelectedRegions = nil;

	arrangerEditMode = arrangerModeNone;
	
	
	// reset the cursor
	[NSCursor pop];
	
	// notification
	[document selectionInArrangerDidChange];
	
	// on mouse up redraw everything
	[self setNeedsDisplay:YES];
}

- (void)showSelectionRectangle:(NSEvent *)event
{
	[[SelectionRectangle sharedSelectionRectangle] setCurrentMousePosition:[self convertPoint:[event locationInWindow] fromView:nil]];
	
	if(tempSelectedRegions == nil)
	{
		tempSelectedRegions = [[NSMutableSet alloc] init];
		[tempSelectedRegions unionSet:selectedRegions];
	}

	// hit test
	NSRect r;

	for(id region in audioRegions)
	{
		if([region valueForKey:@"parentRegion"])
			continue;
		
		r = [region frame];
		if(NSIntersectsRect([[SelectionRectangle sharedSelectionRectangle] frame], r))
		{			
			if(![selectedRegions containsObject:region])
			{
				[self addRegionToSelection:region];

				// notification
				[document selectionInArrangerDidChange];
			}
			[tempSelectedRegions removeObject:region];
		}
		else if([selectedRegions containsObject:region] && ![tempSelectedRegions containsObject:region])
		{
			[self removeRegionFromSelection:region];

			// notification
			[document selectionInArrangerDidChange];
		}
	}
	[self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark track pad events
// -----------------------------------------------------------


- (void)magnifyWithEvent:(NSEvent *)event
{
	[projectSettings setValue:[NSNumber numberWithFloat:zoomFactorX * ([event magnification] + 1.0)] forKey:@"arrangerZoomFactorX"];	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"arrangerViewZoomFactorDidChange" object:document];	
}


#pragma mark -
#pragma mark selection
// -----------------------------------------------------------

- (void)addRegionToSelection:(id)aRegion
{
	[self deselectAllTrajectories];
	
	[selectedRegions addObject:aRegion];
	[aRegion setValue:[NSNumber numberWithBool:YES] forKey:@"selected"];
}

- (void)removeRegionFromSelection:(id)aRegion
{
	[selectedRegions removeObject:aRegion];
	[aRegion setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
}

- (void)selectAllRegions
{
	for(Region *region in audioRegions)
	{
		[region setValue:[NSNumber numberWithBool:YES] forKey:@"selected"];
		[selectedRegions addObject:region];
	}

	[self setNeedsDisplay:YES];
}

- (BOOL)selectionIsEditable
{
	// make sure that the
	// selection contains only unlocked files

	for(Region *region in selectedRegions)
	{
		if([[region valueForKey:@"locked"] boolValue])
		{
			return NO;
		}
	}
	
	return YES;
}


- (void)deselectAllRegions
{
	for(Region *region in selectedRegions)
	{
		[region setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
	}
	
	[selectedRegions removeAllObjects];
}


- (NSSet *)selectedAudioRegions
{
	NSMutableSet *tempSet = [[[NSMutableSet alloc] init] autorelease];
	
	for(id region in selectedRegions)
	{
		if([region isKindOfClass:[GroupRegion class]])
		{
			for(id child in [region valueForKey:@"childRegions"])
			{
				[tempSet addObject:child];
			}
		}
		else
		{
			[tempSet addObject:region];
		}
	}

	return tempSet;
}



- (void)addTrajectoryToSelection:(id)aRegion
{}

- (void)removeTrajectoryFromSelection:(id)aRegion
{}

- (void)selectAllTrajectories
{}

- (void)deselectAllTrajectories
{}

- (void)synchronizeSelection
{
	[self deselectAllRegions];
	[self setNeedsDisplay:YES];
}

- (void)synchronizeMarquee
{
	float start = [[projectSettings valueForKey:@"loopRegionStart"] integerValue] * zoomFactorX;
	float end = [[projectSettings valueForKey:@"loopRegionEnd"] integerValue] * zoomFactorX + 0.5;

//	NSLog(@"synchronizeMarquee %f %f", start, end);
	
	[marqueeView setStart:start + ARRANGER_OFFSET yPosition:-2 duration:end - start height:[self frame].size.height + 2];
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark menu actions
// received as first responder
// -----------------------------------------------------------

- (void)addNewTrajectory:(id)sender
{
	NSString *trajectoryName = nil;
	if([selectedRegions count] == 1)
	{
		trajectoryName = [NSString stringWithString:@"trajectory for "];
		trajectoryName = [trajectoryName stringByAppendingString:[[selectedRegions anyObject] valueForKeyPath:@"audioItem.node.name"]];
	}
    else
    {
        trajectoryName = @"trajectory for multiple regions";
    }
	
	[document newTrajectoryItem:trajectoryName forRegions:selectedRegions];

	[self setNeedsDisplay:YES];
}

- (void)removeTrajectory:(id)sender
{
	int dirty = 0;
	
	for(Region *region in selectedRegions)
	{
		if([region valueForKey:@"trajectoryItem"])
		{
			dirty++;
			[region setValue:nil forKey:@"trajectoryItem"];
		}
	}

	// notification
	[document selectionInArrangerDidChange];

	[self setNeedsDisplay:YES];

	// undo
	if(dirty == 1)
		[[context undoManager] setActionName:@"remove trajectory"];
	else if(dirty > 1)
		[[context undoManager] setActionName:@"remove trajectories"];
}

- (void)remove:(id)sender
{
	[self removeSelectedRegions];
}

- (IBAction)selectAll:(id)sender
{
	[self selectAllRegions];

	// notification
	[document selectionInArrangerDidChange];
}


- (IBAction)selectNone:(id)sender
{
	[self deselectAllRegions];

	// notification
	[document selectionInArrangerDidChange];
	
	[self setNeedsDisplay:YES];
}


- (void)mute:(id)sender
{
	int status = -1;
	
	for(Region *region in selectedRegions)
	{
		if(status == -1)
			status = 1 - [[region valueForKey:@"muted"] intValue];

		[region setValue:[NSNumber numberWithBool:status] forKey:@"muted"];
	}
	
	[self setNeedsDisplay:YES];

	// undo
	if([selectedRegions count] == 1)
		[[context undoManager] setActionName:@"mute/unmute audio region"];
	else if([selectedRegions count] > 1)
		[[context undoManager] setActionName:@"mute/unmute audio regions"];
}

- (void)lock:(id)sender
{
	int status = -1;
 
	for(Region *region in selectedRegions)
	{
		if(status == -1)
			status = 1 - [[region valueForKey:@"locked"] intValue];
		
		[region setValue:[NSNumber numberWithBool:status] forKey:@"locked"];
	}
	
	[self setNeedsDisplay:YES];

	// undo
	if([selectedRegions count] == 1)
		[[context undoManager] setActionName:@"lock/unlock audio region"];
	else if([selectedRegions count] > 1)
		[[context undoManager] setActionName:@"lock/unlock audio regions"];
}

- (void)alignY:(id)sender
{
	float y, minY = -1;
	NSRect frame;
	
	for(Region *region in selectedRegions)
	{
		y = [region frame].origin.y;
		
		if(y < minY || minY == -1)
			minY = y;
	}
	
	for(Region *region in selectedRegions)
	{
		frame = [region frame];
		frame.origin.y = minY;
		[region setFrame:frame];
		[region updateTimeInModel];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"audio regions: align horizontally"];
}

- (void)alignX:(id)sender
{
	float x, minX = -1;
	NSRect frame;

	for(Region *region in selectedRegions)
	{
		x = [region frame].origin.x;
		
		if(x < minX || minX == -1)
			minX = x;
	}
		
	for(Region *region in selectedRegions)
	{
		frame = [region frame];
		frame.origin.x = minX;
		[region setFrame:frame];
		[region updateTimeInModel];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"audio regions: align vertically"];
}

- (void)duplicate:(id)sender
{
	Region *newRegion;
	NSMutableSet *newRegions = [[[NSMutableSet alloc] init] autorelease];
	//NSRect r;
	NSPoint delta = NSMakePoint(20, 20); // offset of duplicate
		
	for(Region *region in selectedRegions)
	{
		newRegion = [self makeCopyOf:region];
		if(!newRegion)
			return;
		
		[newRegion moveByDeltaX:delta.x deltaY:delta.y];
        [newRegion archiveData];
		[newRegion updateTimeInModel];
		
		[newRegions addObject:newRegion];
	}
	
	[self deselectAllRegions];
	
	for(Region *region in newRegions)
	{
		[self addRegionToSelection:region];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	if([selectedRegions count] == 1)
		[[context undoManager] setActionName:@"duplicate audio region"];
	else if([selectedRegions count] > 1)
		[[context undoManager] setActionName:@"duplicate audio regions"];
}

- (void)repeat:(id)sender
{
    int i, count = 1;
    int dirty = [selectedRegions count];
    if(dirty == 0) return;
    
    NSModalSession session = [NSApp beginModalSessionForWindow:repeatRegionPanel];

    NSPoint origin = [[self window] frame].origin;
    origin.x += [[self window] frame].size.width * 0.5 - [repeatRegionPanel frame].size.width * 0.5;
    origin.y += [[self window] frame].size.height * 0.5 - [repeatRegionPanel frame].size.height * 0.5;
    [repeatRegionPanel setFrameOrigin:origin];

    [repeatRegionTextField setIntegerValue:count];
    
    for (;;)
    {
        if ([NSApp runModalSession:session] != NSRunContinuesResponse)
            break;
    }
    [NSApp endModalSession:session];
	[repeatRegionPanel orderOut:nil];

    if ([NSApp runModalSession:session] == NSRunAbortedResponse)
        return;
    if ([NSApp runModalSession:session] == NSRunStoppedResponse)
        count = [repeatRegionTextField intValue];
	
    Region *newRegion;
	NSMutableSet *newRegions = [[[NSMutableSet alloc] init] autorelease];
	NSPoint delta = NSMakePoint(0, 0);
		
	for(id aRegion in selectedRegions)
	{
        delta.x = [[aRegion valueForKey:@"duration"] unsignedLongValue] * zoomFactorX;

		for(i=0;i<count;i++)
        {
            newRegion = [self makeCopyOf:aRegion];
            if(!newRegion)
                return;

				
            [newRegion moveByDeltaX:delta.x * (i + 1) deltaY:delta.y];
            [newRegion archiveData];
            [newRegion updateTimeInModel];
		
            [newRegions addObject:newRegion];
        }
    }
	
	[self deselectAllRegions];
	
	for(id aRegion in newRegions)
	{
		[self addRegionToSelection:aRegion];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	if(dirty == 1)
		[[context undoManager] setActionName:@"repeat audio region"];
	else if(dirty > 1)
		[[context undoManager] setActionName:@"repeat audio regions"];
}

// delete everything that is inside the marquee AND selected
// add new regions/items if necessary
- (void)delete:(id)sender
{
	if(![self selectionIsEditable])
		return;

	NSRect r, intersection, marqueeRect = [marqueeView frame];
	float deltaX1, deltaX2, deltaX3;
	
	Region *region0, *region1, *region2;
	
	for(region0 in selectedRegions)
	{
		r = [region0 frame];
		intersection = NSIntersectionRect(r, marqueeRect);
		if(intersection.size.height * zoomFactorY >= AUDIO_BLOCK_HEIGHT - 1 && intersection.size.width >= [[region0 duration] unsignedIntValue] * zoomFactorX)
		{
			[self recursivelyDeleteRegions:region0];
		}

		else if(intersection.size.height  * zoomFactorY >= AUDIO_BLOCK_HEIGHT - 1)
		{
			region1 = [self makeUniqueCopyOf:region0];
						
			if(r.origin.x < marqueeRect.origin.x)
			{
				deltaX1 = 0;
 				deltaX2 = marqueeRect.origin.x - (r.origin.x + r.size.width);
			}
			else
			{
				deltaX1 = marqueeRect.origin.x + marqueeRect.size.width - r.origin.x;
				deltaX2 = 0;
			}
						
			[region1 cropByDeltaX1:deltaX1 deltaX2:deltaX2];
            [region1 archiveData];
            [region1 updateTimeInModel];
			

			if(r.origin.x < marqueeRect.origin.x && r.origin.x + r.size.width > marqueeRect.origin.x + marqueeRect.size.width)
			{
				region2 = [self makeUniqueCopyOf:region0];

				deltaX3 = marqueeRect.origin.x + marqueeRect.size.width - r.origin.x;

				[region2 cropByDeltaX1:deltaX3 deltaX2:0];
                [region2 archiveData];
                [region2 updateTimeInModel];
			}
			
			[self recursivelyDeleteRegions:region0];
			[self setNeedsDisplayInRect:r];
		}
	}

	// undo
	[[context undoManager] setActionName:@"delete selection"];
}

// trim all selected regions to the marquee's boundaries (inverse delete)
// add new regions/items if necessary
- (void)trim:(id)sender
{
	if(![self selectionIsEditable])
		return;

	NSRect r = NSMakeRect(0,0,0,0);
    NSRect marqueeRect = [marqueeView frame];
	float deltaX1, deltaX2;
	
	id region1;
	
	for(Region *region in selectedRegions)
	{
		r = [region frame];
		if(NSIntersectsRect(r, marqueeRect))
		{
			region1 = [self makeUniqueCopyOf:region];
			
			[self removeRegionFromView:region];

			if(r.origin.x < marqueeRect.origin.x)
				deltaX1 = marqueeRect.origin.x - r.origin.x;
			else
				deltaX1 = 0;
			
			if(r.origin.x + r.size.width > marqueeRect.origin.x + marqueeRect.size.width)
				deltaX2 = (marqueeRect.origin.x + marqueeRect.size.width) - (r.origin.x + r.size.width);
			else
				deltaX2 = 0;
			
			[region1 cropByDeltaX1:deltaX1 deltaX2:deltaX2];
			[region1 updateTimeInModel];
		}
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplayInRect:r];

	// undo
	if([selectedRegions count] == 1)
		[[context undoManager] setActionName:@"trim audio region"];
	else if([selectedRegions count] > 1)
		[[context undoManager] setActionName:@"trim audio regions"];
}


- (void)split:(id)sender
{
//	NSLog(@"split");
	
	if(![self selectionIsEditable])
		return;

	float cursor = [playbackController locator] * zoomFactorX + ARRANGER_OFFSET;
	NSRect r;
	int dirty = 0;
	
	Region *region0, *region1, *region2;
	
	for(region0 in selectedRegions)
	{
		r = [region0 frame];
		
		if(cursor > r.origin.x && cursor < r.origin.x + r.size.width)
		{
			dirty++;
			
			// make copies of the original region
			region1 = [self makeUniqueCopyOf:region0];
			region2 = [self makeUniqueCopyOf:region0];
			
			[self removeRegionFromView:region0];
			
			[region1 cropByDeltaX1:0 deltaX2:cursor - r.origin.x - r.size.width];
			[region1 archiveData];
			[region1 updateTimeInModel];

			[region2 cropByDeltaX1:cursor - r.origin.x deltaX2:0];
			[region2 archiveData];
			[region2 updateTimeInModel];
		}
	}
	
	if(0 < dirty)
	{
		[self deselectAllRegions];
		
		[self recalculateArrangerProperties];
		[self setNeedsDisplayInRect:r];

		// notification
		[document selectionInArrangerDidChange];

		// undo
		if(dirty == 1)
			[[context undoManager] setActionName:@"split audio region"];
		else if(dirty > 1)
			[[context undoManager] setActionName:@"split audio regions"];
	}
}

- (void)bringToFront:(id)sender
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	
	for (Region *region in audioRegions)
	{
		if([selectedRegions containsObject:region])
		{
			[temp removeObject:region];
			[temp addObject:region];
			[self setNeedsDisplayInRect:[region frame]];
		}
	}
	
	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];
	
	[self updateZIndexInModel];
}

- (void)sendToBack:(id)sender
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	
	for (Region *region in audioRegions)
	{
		if([selectedRegions containsObject:region])
		{
			[temp removeObject:region];
			[temp insertObject:region atIndex:0];
			[self setNeedsDisplayInRect:[region frame]];
		}
	}
	
	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];
	
	[self updateZIndexInModel];
}


- (void)group:(id)sender
{
	if([selectedRegions count] < 2)
		return;

	if(![self selectionIsEditable])
		return;
		
	// add new group region
	GroupRegion *newGroupRegion = [NSEntityDescription insertNewObjectForEntityForName:@"GroupRegion" inManagedObjectContext:context];
	[self addRegionToView:newGroupRegion];
//	[newGroupRegion setValue:self forKey:@"superview"];

	// turn all selected regions into children

	for (Region *region in selectedRegions)
	{		
		[newGroupRegion addChildRegion:region];
	}
	
	[self deselectAllRegions];
	[self addRegionToSelection:newGroupRegion];

	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"group regions"];
}

- (void)ungroup:(id)sender
{
	if(![self selectionIsEditable])
		return;

	NSEnumerator *enumerator1, *enumerator2;
	Region *groupRegion, *region;
	NSSet *tempGroups;// *tempRegions;
	
	// all selected regions have to be groups
	enumerator1 = [selectedRegions objectEnumerator];
	while((groupRegion = [enumerator1 nextObject]))
	{		
		if(![groupRegion isKindOfClass:[GroupRegion class]])
			return;
	}

	tempGroups = [NSSet setWithSet:selectedRegions];
	[self deselectAllRegions];	

	enumerator1 = [tempGroups objectEnumerator];
	while((groupRegion = [enumerator1 nextObject]))
	{	
		enumerator2 = [[groupRegion valueForKey:@"childRegions"] objectEnumerator];
		while((region = [enumerator2 nextObject]))
		{		
			[self addRegionToSelection:region];
		}
		
		[self removeRegionFromView:groupRegion];
	}

	[self setNeedsDisplay:YES];

	// undo
	[[context undoManager] setActionName:@"ungroup regions"];
}	
	

#pragma mark -
#pragma mark context menu actions

- (IBAction)contextAddNewTrajectory:(id)sender
{
	NSString *trajectoryName = nil;
	trajectoryName = [NSString stringWithString:@"trajectory for "];
	trajectoryName = [trajectoryName stringByAppendingString:[hitAudioRegion valueForKeyPath:@"audioItem.node.name"]];
	
	[document newTrajectoryItem:trajectoryName forRegions:[NSSet setWithObject:hitAudioRegion]];

	[self setNeedsDisplay:YES];
}

- (IBAction)contextRemoveTrajectory:(id)sender
{
	[hitAudioRegion setValue:nil forKey:@"trajectoryItem"];

	// notification
	[document selectionInArrangerDidChange];
		
	[self setNeedsDisplay:YES];
}

- (void)contextMute:(id)sender
{
	int status = 1 - [[hitAudioRegion valueForKey:@"muted"] intValue];
	
	[hitAudioRegion setValue:[NSNumber numberWithBool:status] forKey:@"muted"];
	
	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"mute/unmute audio region"];
}

- (void)contextLock:(id)sender
{
	int status = 1 - [[hitAudioRegion valueForKey:@"locked"] intValue];

	[hitAudioRegion setValue:[NSNumber numberWithBool:status] forKey:@"locked"];
	
	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"lock/unlock audio region"];
}



- (BOOL)validateUserInterfaceItem:(id)item
{
	if ([item action] == @selector(nudgeAmountMenu:) ||
		[item action] == @selector(YGridLinesMenu:) ||
		[item action] == @selector(XGridLinesMenu:) ||
		[item action] == @selector(XGridAmountMenu:))
		return YES;

	if(![audioRegions count])
		return NO;
	
	if (![selectedRegions count] &&
		([item action] == @selector(repeat:) ||
         [item action] == @selector(duplicate:) ||
         
		 [item action] == @selector(remove:) ||
         [item action] == @selector(delete:) ||
		 [item action] == @selector(split:) ||
		 [item action] == @selector(trim:) ||
		
		 [item action] == @selector(addNewTrajectory:) ||
		 [item action] == @selector(mute:) ||
		 [item action] == @selector(lock:) ||
		 [item action] == @selector(bringToFront:) ||
		 [item action] == @selector(sendToBack:)))
		return NO;
	
	if ([selectedRegions count] < 2 &&
		([item action] == @selector(alignX:) ||
		 [item action] == @selector(alignY:) ||
		 [item action] == @selector(group:)))
		return NO;

	
	if ([item action] == @selector(removeTrajectory:))
	{
		if(![selectedRegions count])
			return NO;
		
		for(Region *region in selectedRegions)
		{
			if([region valueForKey:@"trajectoryItem"])
				return YES;
	
		}
		return NO;
	}

	if ([item action] == @selector(ungroup:))
	{
		if(![selectedRegions count])
			return NO;

		// all selected regions have to be groups
        for (Region *region in selectedRegions)
		{		
			if(![region isKindOfClass:[GroupRegion class]])
			return NO;
		}
	}
	
	// region context menu
	// -------------------
	
	if([item action] == @selector(contextRemoveTrajectory:))
	{
		if([hitAudioRegion valueForKey:@"trajectoryItem"])
			return YES;
		else
			return NO;
	}
	

	// default...:
	// -------------------
	
	return YES;
}


#pragma mark -
#pragma mark markers
// -----------------------------------------------------------

- (void)recallMarker:(NSNumber *)time
{
    [playbackController setLocator:[time unsignedIntegerValue]];
}


#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoom:(NSNotification *)notification
{
	// get start time (time at the left edge of the view)
	double zoomAmount = zoomFactorX / [document zoomFactorX];

	// new zoom factors
	zoomFactorX = [document zoomFactorX];
	zoomFactorY = [document zoomFactorY];
	
	// restore screen origin 
	NSRect r = NSMakeRect([[self superview] bounds].origin.x / zoomAmount, [[self superview] bounds].origin.y, [[self superview] bounds].size.width, 1);
	[self scrollRectToVisible:r];
	
	[self recalculateArrangerSize];
	
	// grid
	[self recalculateXGridPath];
	[self recalculateYGridPath];
}

- (void)update:(NSNotification *)notification
{
//	NSLog(@"arranger update");
	[self setNeedsDisplay:YES];
}

- (void)undoNotification:(NSNotification *)notification
{
//	NSLog(@"arranger undo");

	// get stored data
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSError *error;
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Region" inManagedObjectContext:context];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"zIndexInArranger" ascending:YES] autorelease];
	
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[request setEntity:entityDescription];
	[request setReturnsObjectsAsFaults:NO];
	
	[audioRegions release];
	audioRegions = [[context executeFetchRequest:request error:&error] retain];
		
    for (Region *region in audioRegions)
	{
		// set superview for all regions
		[region setValue:self forKey:@"superview"];
		[region recalcFrame];
		[region unarchiveData];
	}
	
	
	if([selectedRegions count])
	{
		// send the selectionInArrangerDidChange notification
		// only when there actually is a change
		
		[self deselectAllRegions];
		[document selectionInArrangerDidChange];
	}
	
	[self recalculateArrangerProperties];
	[self recalculateArrangerSize];
	[self setNeedsDisplay:YES];
}


@end


#pragma mark -
#pragma mark -
// -----------------------------------------------------------


@implementation MarqueeView

- (void)drawRect:(NSRect)rect
{    
	NSColor *selectionFrameColor	= [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
	NSColor *selectionFillColor		= [NSColor colorWithCalibratedRed: 0.35 green: 0.35 blue: 0.35 alpha: 0.5];
	
	[selectionFillColor set];
	NSRectFillUsingOperation([self bounds], 2);
	[selectionFrameColor set];
	[NSBezierPath strokeRect:[self bounds]];
}

- (void)setStart:(NSUInteger)start yPosition:(float)y duration:(NSInteger)dur height:(float)h
{
	startTime = start;
	yPosition = y;
	duration = dur;
	height = h;

	[self recalcFrame];
}

- (void)dismiss
{
	startTime = yPosition = duration = height = 0;
	[self setFrame:NSMakeRect(0, 0, 0, 0)];
}

- (void)recalcFrame
{
	NSRect frame;
	float zoomFactorX, zoomFactorY;

	zoomFactorX = [[[[self window] windowController] document] zoomFactorX];
	zoomFactorY = [[[[self window] windowController] document] zoomFactorY];		

	frame.origin.x = startTime;
	frame.origin.y = yPosition;
	frame.size.width = duration;
	frame.size.height = height;
	
	[self setFrame:frame];
}

@end
