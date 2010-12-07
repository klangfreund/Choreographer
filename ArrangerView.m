//
//  ArrangerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "ArrangerView.h"
#import "CHGlobals.h"
#import "AudioRegion.h"
#import "GroupRegion.h"
#import "CHProjectDocument.h"
#import "SelectionRectangle.h"
#import "PlaybackController.h"
#import "SettingsMenu.h"

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
		RegionForSelectedTrajectories = nil;
		placeholderRegions = [[NSMutableArray alloc] init]; // Array, these must be ordered
		arrangerTabStops = [[NSMutableIndexSet alloc] init];
		
		marqueeView = [[MarqueeView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
		[self addSubview:marqueeView];
	}
    return self;
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
	[horizontalGridPath release];
	[verticalGridPath release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];	

	[super dealloc];
}


- (void)awakeFromNib
{
	horizontalGridPath = nil;
	verticalGridPath = nil;

	arrangerEditMode = arrangerModeNone;

	dragging = 0;
	arrangerSizeX = arrangerSizeY = 0;


	// register for dragging from pool
	[self registerForDraggedTypes:[NSArray arrayWithObjects:CHAudioItemType, CHTrajectoryType, nil]];

	// register for notifications

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(update:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(update:)
												 name:@"projectSettingsDidChange" object:nil];		
	
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
	horizontalGridAmount = [[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue];
	
	// initialise context menus & popup buttons
	[nudgeAmountMenu setModel:projectSettings key:@"projectSettingsDictionary.arrangerNudgeAmount"];
	[verticalGridModeMenu setModel:projectSettings key:@"projectSettingsDictionary.arrangerVerticalGridMode"];
	[horizontalGridModeMenu setModel:projectSettings key:@"projectSettingsDictionary.arrangerHorizontalGridMode"];
	[horizontalGridAmountMenu setModel:projectSettings key:@"projectSettingsDictionary.arrangerHorizontalGridAmount"];

	[arrangerDisplayModePopupButton setModel:projectSettings key:@"projectSettingsDictionary.arrangerDisplayMode"];
	
	// init zoom factor
	zoomFactorX = [document zoomFactorX];

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
		
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	while(region = [enumerator nextObject])
	{
		// set superview for all regions
		[region setValue:self forKey:@"superview"];
		[region recalcFrame];
	}
	
	
	[self recalculateArrangerProperties];
	[self recalculateArrangerSize];
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{	
	// colors
	NSColor *backgroundColor	= [NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1];

	NSColor *hGridColor			= [NSColor colorWithCalibratedRed: 0.6 green: 0.5 blue: 0.6 alpha: 0.15];  
	NSColor *hGridColorMagnetic	= [NSColor colorWithCalibratedRed: 0.95 green: 0.8 blue: 1 alpha: 0.25];  
	
	NSColor *vGridColor			= [NSColor colorWithCalibratedRed: 0.5 green: 0.6 blue: 0.6 alpha: 0.15];  
	NSColor *vGridColorMagnetic	= [NSColor colorWithCalibratedRed: 0.8 green: 0.95 blue: 1 alpha: 0.25];  
	
	// background
	[backgroundColor set];
	NSRectFill([self bounds]);
	
	// grid
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue] == 0 && horizontalGridPath
	   || [[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue] != 0 && !horizontalGridPath
	   || horizontalGridAmount != [[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue])
	{
		[self recalculateHorizontalGridPath];
	}	
		
	if(horizontalGridPath)
	{
		if([self inLiveResize])
		{
			[self recalculateHorizontalGridPath];
		}
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue] == 2)
			[hGridColorMagnetic set];
		else
			[hGridColor set];
		[horizontalGridPath stroke];
	}

	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue] == 0 && verticalGridPath
	   || [[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue] != 0 && !verticalGridPath)
	{
		[self recalculateVerticalGridPath];
	}	

	if(verticalGridPath)
	{
		if([self inLiveResize])
		{
			[self recalculateVerticalGridPath];
		}
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue] == 2)
			[vGridColorMagnetic set];
		else
			[vGridColor set];
		[verticalGridPath stroke];
	}
	
	// region
    NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	
    while (region = [enumerator nextObject])
	{
        if ([self needsToDrawRect:[region frame]])
		{
            [region drawRect:rect];
        }
    }
	
	// placeholder regions
    enumerator = [placeholderRegions objectEnumerator];
	PlaceholderRegion *placeholderRegion;
	
    while (placeholderRegion = [enumerator nextObject])
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

- (void)resetCursorRects
{
	NSRect r = [self bounds];
	
	if(document.keyboardModifierKeys == modifierCommand)
		[self addCursorRect:r cursor:[NSCursor crosshairCursor]];
	else if(document.keyboardModifierKeys == modifierAlt)
		[self addCursorRect:r cursor:[NSCursor dragCopyCursor]];
	else if(document.keyboardModifierKeys == modifierAltCommand)
		[self addCursorRect:r cursor:[NSCursor resizeLeftCursor]];
	else if(document.keyboardModifierKeys == modifierShiftAltCommand)
		[self addCursorRect:r cursor:[NSCursor resizeRightCursor]];
	else
		[self addCursorRect:r cursor:[NSCursor arrowCursor]];
}	


- (void)recalculateVerticalGridPath
{
	[verticalGridPath release];
	
	float i;
	float step = AUDIO_BLOCK_HEIGHT * zoomFactorY;
	switch([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue])
	{
		case 0:
			verticalGridPath = nil;
			break;
		default:
			verticalGridPath = [[NSBezierPath bezierPath] retain];
			[verticalGridPath setLineWidth:0.0];
			
			for(i=0; i<[self frame].size.height;i += step)
			{
				[verticalGridPath moveToPoint:NSMakePoint(0, i)];
				[verticalGridPath lineToPoint:NSMakePoint([self bounds].size.width, i)];
			}
	}
}

- (void)recalculateHorizontalGridPath
{
	[horizontalGridPath release];
	
	float i;
	float step = zoomFactorX * [[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue];
	switch([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue])
	{
		case 0:
			horizontalGridPath = nil;
			break;
		default:
			horizontalGridPath = [[NSBezierPath bezierPath] retain];
			[horizontalGridPath setLineWidth:0.0];
			
			for(i=ARRANGER_OFFSET; i<[self frame].size.width;i += step)
			{
				[horizontalGridPath moveToPoint:NSMakePoint(i, 0)];
				[horizontalGridPath lineToPoint:NSMakePoint(i, [self bounds].size.height)];
			}
	}
}

- (void)recalculateArrangerProperties
{	
	arrangerSizeX = arrangerSizeY = 0;
	NSUInteger value;
	
	[arrangerTabStops removeAllIndexes];
	
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	
	while (region = [enumerator nextObject])
	{		
		value = ([region frame].origin.x - ARRANGER_OFFSET) / zoomFactorX;			
		[arrangerTabStops addIndex:value];

		value += [region frame].size.width / zoomFactorX;		
		[arrangerTabStops addIndex:value];

		if(value > arrangerSizeX)
			arrangerSizeX = value;

		value = [[region valueForKeyPath:@"yPosInArranger"] unsignedLongValue] + AUDIO_BLOCK_HEIGHT;			
		if(value > arrangerSizeY)
			arrangerSizeY = value;
	}
}

- (void)recalculateArrangerSize
{
	NSSize frameSize;	
	NSSize clipFrameSize = [[self superview] bounds].size;
			
	if(arrangerSizeX * zoomFactorX <= clipFrameSize.width)
		frameSize.width = clipFrameSize.width * 1.5;
	else
		frameSize.width = arrangerSizeX * zoomFactorX * 1.5;
	
	if(arrangerSizeY * zoomFactorY <= clipFrameSize.height)
		frameSize.height = clipFrameSize.height * 1.2;
	else
		frameSize.height = arrangerSizeY * zoomFactorY * 1.2;
	
	[self setFrameSize:frameSize];

	[marqueeView recalcFrame];

	[self setNeedsDisplay:YES];
}
	
#pragma mark -
#pragma mark dragging from pool
// -----------------------------------------------------------

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info
{
	NSLog(@"ArrangerView: draggingEntered");

	if([[document valueForKey:@"draggedTrajectories"] count])
			return NSDragOperationNone;
	
	NSArray *draggedItems = [document valueForKey:@"draggedAudioRegions"];

	NSEnumerator *enumerator = [draggedItems objectEnumerator];
	id item;
 
	while (item = [enumerator nextObject])
	{
		if(![[item valueForKey:@"isLeaf"] boolValue])  // all proposed items must be leaves
			return NSDragOperationNone;
	}

	enumerator = [draggedItems objectEnumerator];
 
	while (item = [enumerator nextObject])
	{
		unsigned long long dur = [[item valueForKeyPath:@"item.duration"] longLongValue];
		float height = AUDIO_BLOCK_HEIGHT * zoomFactorY - 1;

		NSRect r = NSMakeRect(0, -height, dur * zoomFactorX, height);
		PlaceholderRegion *placeholderRegion = [PlaceholderRegion placeholderRegionWithFrame:r];

		[placeholderRegions addObject:placeholderRegion];
	}

	return NSDragOperationGeneric;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)info
{
	NSArray *draggedTrajectories = [document valueForKey:@"draggedTrajectories"];
	NSArray *draggedAudioItems = [document valueForKey:@"draggedAudioRegions"];

	if([draggedTrajectories count] == 1 && [draggedAudioItems count] == 0)
		[self trajectoryDraggingUpdated:info];
	else if([draggedTrajectories count] == 0 && [draggedAudioItems count] > 0)
		[self audioDraggingUpdated:info];
	else
		return NSDragOperationNone;
	
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
		[placeholderRegions count] && [[placeholderRegions objectAtIndex:0] frame].origin.x != [region frame].origin.x)
	{
		for(Region *rg in placeholderRegions)
		{
			[rg setValue:[NSNumber numberWithBool:NO] forKeyPath:@"region.displaysTrajectoryPlaceholder"];		
		}
		[placeholderRegions removeAllObjects];
		return;
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
	
	return;
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
	else if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue] == 2)
	{
		insertionPoint.x = ([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue] * zoomFactorX) * round(insertionPoint.x / ([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue] * zoomFactorX));
	}
	// on y axis
	// - by magnetic grid
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue] == 2)
	{
		insertionPoint.y = (AUDIO_BLOCK_HEIGHT * zoomFactorY) * round(insertionPoint.y / (AUDIO_BLOCK_HEIGHT * zoomFactorY));
	}

	NSRect r = NSMakeRect(insertionPoint.x + ARRANGER_OFFSET, insertionPoint.y, 0, 0);

	NSEnumerator *enumerator = [placeholderRegions objectEnumerator];
	PlaceholderRegion *placeholderRegion;
	NSPoint maxPoint = NSMakePoint(0, 0);
 
	while (placeholderRegion = [enumerator nextObject])
	{
		r.size.width = [placeholderRegion frame].size.width;
		r.size.height = [placeholderRegion frame].size.height;
		[placeholderRegion setFrame:r];

		if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.poolDropOrder"] integerValue] == 0)
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
	NSLog(@"ArrangerView: draggingExited");

	for(Region *rg in placeholderRegions)
	{
		[rg setValue:[NSNumber numberWithBool:NO] forKeyPath:@"region.displaysTrajectoryPlaceholder"];		
	}
	[placeholderRegions removeAllObjects];

	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info
{
//	NSLog(@"performDragOperation");
	
	NSArray *draggedTrajectories = [document valueForKey:@"draggedTrajectories"];
	NSArray *draggedAudioItems = [document valueForKey:@"draggedAudioRegions"];

	if([draggedTrajectories count] == 1 && [draggedAudioItems count] == 0)
		return [self performTrajectoryDragOperation:info];
	else if([draggedTrajectories count] == 0 && [draggedAudioItems count] > 0)
		return [self performAudioDragOperation:info];
	else
		return NO;
}
	
- (BOOL)performTrajectoryDragOperation:(id <NSDraggingInfo>)info
{
	NSLog(@"performTrajectoryDragOperation");

	NSArray *draggedTrajectories = [document valueForKey:@"draggedTrajectories"];

	NSPoint localPoint = [self convertPoint:[info draggingLocation] fromView:nil];
	Region *region = [self pointInRegion:localPoint];

	if(!region)
	{
		[placeholderRegions removeAllObjects];
		return NO;
	}
	
	[region setValue:[[draggedTrajectories objectAtIndex:0] valueForKey:@"item"] forKey:@"trajectoryItem"];
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
	
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)performAudioDragOperation:(id <NSDraggingInfo>)info
{
	NSArray *draggedItems = [document valueForKey:@"draggedAudioRegions"];

	NSEnumerator *enumerator1 = [placeholderRegions objectEnumerator];
	NSEnumerator *enumerator2 = [draggedItems objectEnumerator];
	AudioRegion *newRegion;
	id view, item;
 
	while ((view = [enumerator1 nextObject]) && (item = [enumerator2 nextObject]))
	{
		newRegion = [NSEntityDescription insertNewObjectForEntityForName:@"AudioRegion" inManagedObjectContext:context];
		[self addRegionToView:newRegion];

		id audioItem = [item valueForKey:@"item"];
		NSNumber *insertTime = [NSNumber numberWithUnsignedLong:([view frame].origin.x - ARRANGER_OFFSET) / zoomFactorX]; 
		NSNumber *insertYPosition = [NSNumber numberWithUnsignedLong:[view frame].origin.y / zoomFactorY]; 

		[newRegion setFrame:[view frame]];
		[newRegion setValue:audioItem forKey:@"audioItem"];
		[newRegion setValue:insertTime forKey:@"startTime"];
		[newRegion setValue:insertYPosition forKey:@"yPosInArranger"];
		[newRegion setValue:self forKey:@"superview"];
		
		[self addRegionToSelection:newRegion];
	}

	[placeholderRegions removeAllObjects];

	// make first responder
	[[self window] makeFirstResponder:self];

	// undo
	[[context undoManager] setActionName:@"add audio region to arranger"];
	
	// notification
	[document selectionInArrangerDidChange];
	
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
	
	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];
	
	[self updateZIndexInModel];
	
	// undo
//	[[context undoManager] registerUndoWithTarget:self
//										selector:@selector(removeRegionFromView:)
//										object:region];
}

- (void)removeRegionFromView:(Region *)region
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	[temp removeObject:region];
	
	[audioRegions release];
	audioRegions = [[NSArray arrayWithArray:temp] retain];		

	[self updateZIndexInModel];

	[context deleteObject:region];

	// undo
//	[[context undoManager]	registerUndoWithTarget:self
//							selector:@selector(addRegionToView:)
//							object:region];
}	

- (void)updateZIndexInModel
{
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	int zIndex;
	
	while(region = [enumerator nextObject])
	{
		zIndex = [audioRegions indexOfObject:region];
		[region setValue:[NSNumber numberWithInt:zIndex] forKey:@"zIndexInArranger"];
	}
}


- (NSPoint)moveSelectedRegionsBy:(NSPoint)delta restricted:(BOOL)magnetism
{
	NSRect r;
	NSEnumerator *enumerator;
	id region;
	
	if(![self selectionIsEditable])
		return NSMakePoint(0,0);

	if(!dragging < 2) // this method is called is the first time in a dragging session
					  // or there is no dragging session
	{
		//NSPoint minPoint, maxPoint;
		BOOL first = YES;
	
		enumerator = [selectedRegions objectEnumerator] ;
		while ((region = [enumerator nextObject]))
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
	else if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridMode"] integerValue] == 2 && magnetism)
	{
		delta.x = ([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue] * zoomFactorX)
					* round((draggingParameter[0] + delta.x) / ([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerHorizontalGridAmount"] integerValue] * zoomFactorX))
					- draggingParameter[0] + ARRANGER_OFFSET;
	}
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerVerticalGridMode"] integerValue] == 2 && magnetism)
	{
		delta.y = (AUDIO_BLOCK_HEIGHT * zoomFactorY) * round((draggingParameter[1] + delta.y) / (AUDIO_BLOCK_HEIGHT * zoomFactorY)) - draggingParameter[1];
	}
	
	// move all selected regions by delta
	enumerator = [selectedRegions objectEnumerator] ;
	while ((region = [enumerator nextObject]))
	{
		[region moveByDeltaX:delta.x deltaY:delta.y];	
	}
	
	[self setNeedsDisplayInRect:NSMakeRect(draggingParameter[0] - 1,
										   draggingParameter[1] - 1,
										   draggingParameter[2] - draggingParameter[0] + 2,
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
	NSEnumerator *enumerator;
	Region *region;
	float width, minWidth = -1;
	float extendRight, maxExtendRight = -1;
	float offset, maxExtendLeft = -1;
	
	if(![self selectionIsEditable])
		return 0.0;

	enumerator = [selectedRegions objectEnumerator] ;
	while ((region = [enumerator nextObject]))
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
		if(maxExtendRight == -1 || maxExtendRight > extendRight);
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
	
	
	enumerator = [selectedRegions objectEnumerator] ;
	while ((region = [enumerator nextObject]))
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
		NSEnumerator *enumerator = [selectedRegions objectEnumerator];
		AudioRegion *region;

		while((region = [enumerator nextObject]))
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
    NSEnumerator *enumerator = [[region valueForKey:@"childRegions"] objectEnumerator];
	Region *child;
		
    while (child = [enumerator nextObject])
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

		[newRegion setValue:[[originalRegion valueForKey:@"position"] copy] forKey:@"position"];

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
		[newRegion setValue:self forKey:@"superview"];

		NSEnumerator *enumerator = [[originalRegion valueForKey:@"childRegions"] objectEnumerator];
		Region *region;
		
		while (region = [enumerator nextObject])
		{
			[(GroupRegion *)newRegion addChildRegion:[self makeCopyOf:region]];
		}
	}
	

	NSMutableArray *gainBreakpointArray = [[NSMutableArray alloc] init];
	
	for(Breakpoint *bp in [originalRegion valueForKey:@"gainBreakpointArray"])
	{
		[gainBreakpointArray addObject:[bp copy]];
	}
	
	[newRegion setValue:gainBreakpointArray forKey:@"gainBreakpointArray"];

	return newRegion;
}



#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (void)flagsChanged:(NSEvent *)event
{
//	NSLog(@"ArrangerView flagsChanged");
	[[self window] invalidateCursorRectsForView:self];

	[super flagsChanged:event];
}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
	NSLog(@"ArrangerView key code: %d ", keyCode);

	NSUInteger locator;

	switch(keyCode)
	{
		// delete
		case 117:
		// backspace
		case 51:
			if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
				[self removeSelectedRegions];
			if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
				[self removeSelectedGainBreakpoints];
			break;

		// tab
		case 48:
			if([event modifierFlags] & NSShiftKeyMask)
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
			[self nudge:NSMakePoint([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerNudgeAmount"] integerValue] * zoomFactorX * -1, 0)];
			break;
		case 124:	// arrow right
			[self nudge:NSMakePoint([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerNudgeAmount"] integerValue] * zoomFactorX, 0)];
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
	[self moveSelectedRegionsBy:p restricted:NO];

	NSEnumerator *enumerator;
	id aRegion;
		
	enumerator = [selectedRegions objectEnumerator];
	while ((aRegion = [enumerator nextObject]))
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

#pragma mark -
#pragma mark mouse events
// -----------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
	NSLog(@"ArrangerView -- becomeFirstResponder...");
	[self flagsChanged:nil]; // reset all modifier keys
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
	
	while (region = [enumerator nextObject])
	{
		if (NSPointInRect(point, [region frame]))
		{
			return region;
		}
	}
	
	return NULL;
}

- (void)rightMouseDown:(NSEvent *)event
{
	// show context menu only when mouse inside a region
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	hitRegion = [self pointInRegion:localPoint];

	if(hitRegion)
		[NSMenu popUpContextMenu:regionMenu withEvent:event forView:self];
	else
		[NSMenu popUpContextMenu:arrangerMenu withEvent:event forView:self];
		
}

- (void)mouseDown:(NSEvent *)event
{
	/* handle double clicks
		- open special editors
		- not yet implemented
	*/
	
	if([event clickCount] > 1)
	{
		NSLog(@"double click");
		return;
	}

	
	/* convert the mouse location
	   and find out if the click hits a region
	*/
	
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	storedEventLocation = localPoint;
	
	hitRegion = [self pointInRegion:localPoint];
	

	switch(document.keyboardModifierKeys)
	{
		case modifierControl:	
			if(hitRegion)
			{
				if(![[hitRegion valueForKeyPath:@"selected"] boolValue])
				{
					[self deselectAllRegions];
					[self deselectAllTrajectories];
				}
				[self addRegionToSelection:hitRegion];

				[self setNeedsDisplay:YES]; // before context menu is shown!
				[NSMenu popUpContextMenu:regionMenu withEvent:event forView:self];
			}
			else
			{
				[NSMenu popUpContextMenu:arrangerMenu withEvent:event forView:self];
			}
			break;

		case modifierNone:		// selection or ordinary dragging
		case modifierAlt:		// duplicate
		case modifierCommand:	// marquee or magnetic cursor

			if(hitRegion)
			{
				if(![[hitRegion valueForKeyPath:@"selected"] boolValue])
				{
					[self deselectAllRegions];
					[self deselectAllTrajectories];
				}
				[self addRegionToSelection:hitRegion];
				dragging = 1;
			}
			else
			{
				[self deselectAllRegions];
				[self deselectAllTrajectories];

				if(document.keyboardModifierKeys == modifierAlt)
					[marqueeView dismiss];

				[[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:[self convertPoint:[event locationInWindow] fromView:nil] forView:self];
			}
			break;
	
		case modifierAltCommand:
		case modifierShiftAltCommand:

			[self addRegionToSelection:hitRegion];
			dragging = 1;
			break;
	}


	/*	arranger is in region mode
	 -----------------------------------------------------------------------------
	 
	 */

	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
	{
		switch(document.keyboardModifierKeys)
		{				
			case modifierShift:		// multiple selection
				
				if(hitRegion)
				{
					if([[hitRegion valueForKeyPath:@"selected"] boolValue])
						[self removeRegionFromSelection:hitRegion];
					else
						[self addRegionToSelection:hitRegion];
					
					dragging = 1;
				}
				else
				{
					[[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:[self convertPoint:[event locationInWindow] fromView:nil] forView:self];
				}
				break;
		}
		
		// notification
		[document selectionInArrangerDidChange];
	}
	

	/*	arranger is in gain mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		
		switch(document.keyboardModifierKeys)
		{				
			case modifierShift:		// multiple selection
				
				if(hitRegion)
				{
					[self addRegionToSelection:hitRegion];
					
					dragging = 1;
				}
				else
				{
					[[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:[self convertPoint:[event locationInWindow] fromView:nil] forView:self];
				}
				break;
		}

		// pass the mouse event
		[hitRegion mouseDown:localPoint];
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

	/*	arranger is in region mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
	{
		if(dragging < 2)
		{
			switch(document.keyboardModifierKeys)
			{
				case modifierNone:
				case modifierShift:
					arrangerEditMode = arrangerModeNone; break;
				case modifierAlt:
					arrangerEditMode = arrangerModeDuplicate; break;
				case modifierCommand:
					if(dragging) arrangerEditMode = arrangerModeCursor;
					else arrangerEditMode = arrangerModeMarquee;
					break;
				case modifierAltCommand:
					arrangerEditMode = arrangerModeCropRight; break;
				case modifierShiftAltCommand:
					arrangerEditMode = arrangerModeCropLeft; break;
				default:
					return;
			}
		}
		
		
		if(arrangerEditMode == arrangerModeCropLeft)
		{
			delta.x = [self cropSelectedRegionsBy:NSMakePoint(delta.x, 0)];
		}

		else if(arrangerEditMode == arrangerModeCropRight)
		{
			delta.x = [self cropSelectedRegionsBy:NSMakePoint(0, delta.x)];
		}

		else if(dragging == 0)
		{
			[self showSelectionRectangle:event];
			return;
		}

		else if(dragging == 1 && arrangerEditMode == arrangerModeDuplicate)
		{
			NSEnumerator *enumerator = [selectedRegions objectEnumerator];
			Region *region1, *region2;
			NSMutableSet *tempSelection = [[[NSMutableSet alloc] init] autorelease];
			
			while ((region1 = [enumerator nextObject]))
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
		}
		
		else
			delta = [self moveSelectedRegionsBy:delta restricted:YES];


		if(dragging == 1)
		{
			dragging = 2;
		}
		
		// support automatic scrolling during a drag
		NSRect r = NSMakeRect(localPoint.x - 10, localPoint.y - 10, 20, 20);
		[self scrollRectToVisible:r];
		
		// reflect altered start time in editors
		[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
	}

	/*	arranger is in gain mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	else if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		for(Region *region in selectedRegions)
		{
			delta = [region proposedMouseDrag:delta];
		}

		for(Region *region in selectedRegions)
		{
			[region mouseDragged:delta];
		}
		
		if([selectedRegions count])
			dragging = 2;
		
		[self setNeedsDisplay:YES];
	}

	storedEventLocation.x += delta.x;
	storedEventLocation.y += delta.y;
}
		

- (void)mouseUp:(NSEvent *)theEvent
{
	NSEnumerator *enumerator;
	id aRegion, region1;
	
	/*	arranger is in region mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeRegions)
	{
		if(dragging == 2)
		{
			if(arrangerEditMode == arrangerModeNone)
			{
				enumerator = [selectedRegions objectEnumerator];
				while ((aRegion = [enumerator nextObject]))
				{
					[aRegion updateTimeInModel];
				}
				
				// undo
				if([selectedRegions count] == 1)
					[[context undoManager] setActionName:@"drag audio region"];
				else if([selectedRegions count] > 1)
					[[context undoManager] setActionName:@"drag audio regions"];
			}
			else if(arrangerEditMode == arrangerModeDuplicate)
			{
				enumerator = [selectedRegions objectEnumerator] ;
				while ((aRegion = [enumerator nextObject]))
				{
					[aRegion updateTimeInModel];
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
				NSMutableSet *tempSet = [[[NSMutableSet alloc] init] autorelease];
				
				for (aRegion in selectedRegions)
				{
					region1 = [self makeUniqueCopyOf:aRegion];
					
					[self removeRegionFromView:aRegion];

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
	}
	
	/*	arranger is in gain mode
	 -----------------------------------------------------------------------------
	 
	 */
	
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		// pass the mouse event
		[hitRegion mouseUp:theEvent];
	}
	

	
	[SelectionRectangle release];
	
	[tempSelectedRegions release];
	tempSelectedRegions = nil;

	dragging = 0;
	arrangerEditMode = arrangerModeNone;
	
	
	// re-enable cursor rects (after a dragging session)
	[[self window] enableCursorRects];
	
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
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	id region;
	NSRect r;

	while(region = [enumerator nextObject])
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
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
 
	while(region = [enumerator nextObject])
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

	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	Region *region;
	while((region = [enumerator nextObject]))
	{
		if([[region valueForKey:@"locked"] boolValue])
		{
			NSBeep();
			return NO;
		}
	}
	
	return YES;
}


- (void)deselectAllRegions
{
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	id aRegion;
 
	while(aRegion = [enumerator nextObject])
	{
		[aRegion setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
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
{
	[self deselectAllRegions];

	if([aRegion valueForKey:@"Region"] != RegionForSelectedTrajectories)
	{
		[self deselectAllTrajectories];
		RegionForSelectedTrajectories = [aRegion valueForKey:@"Region"];
	}
	
	[selectedTrajectories addObject:aRegion];
	[aRegion setValue:[NSNumber numberWithBool:YES] forKey:@"selected"];
}

- (void)removeTrajectoryFromSelection:(id)aRegion
{
	[selectedTrajectories removeObject:aRegion];
	[aRegion setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
}

- (void)selectAllTrajectories
{}

- (void)deselectAllTrajectories
{
	NSEnumerator *enumerator = [selectedTrajectories objectEnumerator];
	id aRegion;
 
	while(aRegion = [enumerator nextObject])
	{
		[aRegion setValue:[NSNumber numberWithBool:NO] forKey:@"selected"];
	}
	
	[selectedTrajectories removeAllObjects];
}

- (void)synchronizeSelection
{
	[self deselectAllRegions];
	[self setNeedsDisplay:YES];
}

- (void)synchronizeMarquee
{
	float start = [[projectSettings valueForKeyPath:@"projectSettingsDictionary.loopRegionStart"] integerValue] * zoomFactorX;
	float end = [[projectSettings valueForKeyPath:@"projectSettingsDictionary.loopRegionEnd"] integerValue] * zoomFactorX + 0.5;

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
	
	TrajectoryItem *trajectory = [document newTrajectoryItem:trajectoryName];
	if (!trajectory) return; // user canceled
	
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	Region *region;
	
	while((region = [enumerator nextObject]))
	{
		[region setValue:trajectory forKey:@"trajectoryItem"];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)removeTrajectory:(id)sender
{
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	Region *region;
	
	while((region = [enumerator nextObject]))
	{
		[region setValue:NULL forKey:@"trajectoryItem"];
	}

	// notification
	[document selectionInArrangerDidChange];

	[self setNeedsDisplay:YES];
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
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	int status = -1;
	Region *region;
	
	while((region = [enumerator nextObject]))
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
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	int status = -1;
	Region *region;
 
	while((region = [enumerator nextObject]))
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
	NSEnumerator *enumerator;
	id aRegion;
	float y, minY = -1;
	NSRect frame;
	
	enumerator = [selectedRegions objectEnumerator] ;
	while ((aRegion = [enumerator nextObject]))
	{
		y = [aRegion frame].origin.y;
		
		if(y < minY || minY == -1)
			minY = y;
	}
	
	enumerator = [selectedRegions objectEnumerator] ;
	while ((aRegion = [enumerator nextObject]))
	{
		frame = [aRegion frame];
		frame.origin.y = minY;
		[aRegion setFrame:frame];
		[aRegion updateTimeInModel];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	[[context undoManager] setActionName:@"audio regions: align horizontally"];
}

- (void)alignX:(id)sender
{
	NSEnumerator *enumerator;
	id aRegion;
	float x, minX = -1;
	NSRect frame;

	enumerator = [selectedRegions objectEnumerator] ;
	while ((aRegion = [enumerator nextObject]))
	{
		x = [aRegion frame].origin.x;
		
		if(x < minX || minX == -1)
			minX = x;
	}
		
	enumerator = [selectedRegions objectEnumerator] ;
	while ((aRegion = [enumerator nextObject]))
	{
		frame = [aRegion frame];
		frame.origin.x = minX;
		[aRegion setFrame:frame];
		[aRegion updateTimeInModel];
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
	
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	id aRegion;
	
	while((aRegion = [enumerator nextObject]))
	{
		newRegion = [self makeCopyOf:aRegion];
		if(!newRegion)
			return;
		
		//r = [aRegion frame];
		//[self setNeedsDisplayInRect:r];
		
		[newRegion moveByDeltaX:delta.x deltaY:delta.y];
		[newRegion updateTimeInModel];
		
		[newRegions addObject:newRegion];
	}
	
	[self deselectAllRegions];
	
	enumerator = [newRegions objectEnumerator];
	while((aRegion = [enumerator nextObject]))
	{
		[self addRegionToSelection:aRegion];
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
	Region *newRegion;
	NSMutableSet *newRegions = [[[NSMutableSet alloc] init] autorelease];
	NSPoint delta = NSMakePoint(0, 0);
	
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	id aRegion;
	
	while((aRegion = [enumerator nextObject]))
	{
		newRegion = [self makeCopyOf:aRegion];
		if(!newRegion)
			return;
		
		delta.x = [[aRegion valueForKey:@"duration"] unsignedLongValue] * zoomFactorX;
				
		[newRegion moveByDeltaX:delta.x deltaY:delta.y];
		[newRegion updateTimeInModel];
		
		[newRegions addObject:newRegion];
	}
	
	[self deselectAllRegions];
	
	enumerator = [newRegions objectEnumerator];
	while((aRegion = [enumerator nextObject]))
	{
		[self addRegionToSelection:aRegion];
	}
	
	[self recalculateArrangerProperties];
	[self setNeedsDisplay:YES];
	
	// undo
	if([selectedRegions count] == 1)
		[[context undoManager] setActionName:@"repeat audio region"];
	else if([selectedRegions count] > 1)
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
	
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	Region *region0, *region1, *region2;
	
	while(region0 = [enumerator nextObject])
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
			[region1 updateTimeInModel];
			

			if(r.origin.x < marqueeRect.origin.x && r.origin.x + r.size.width > marqueeRect.origin.x + marqueeRect.size.width)
			{
				region2 = [self makeUniqueCopyOf:region0];

				deltaX3 = marqueeRect.origin.x + marqueeRect.size.width - r.origin.x;

				[region2 cropByDeltaX1:deltaX3 deltaX2:0];
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

	NSRect r, marqueeRect = [marqueeView frame];
	float deltaX1, deltaX2;
	
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	id aRegion, region1;
	
	while(aRegion = [enumerator nextObject])
	{
		r = [aRegion frame];
		if(NSIntersectsRect(r, marqueeRect))
		{
			region1 = [self makeUniqueCopyOf:aRegion];
			
			[self removeRegionFromView:aRegion];

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
	NSLog(@"split");
	
	if(![self selectionIsEditable])
		return;

	float cursor = [playbackController locator] * zoomFactorX + ARRANGER_OFFSET;
	NSRect r;
	BOOL dirty = NO;
	
	Region *region0, *region1, *region2;
	
	for(region0 in selectedRegions)
	{
		r = [region0 frame];
		
		if(cursor > r.origin.x && cursor < r.origin.x + r.size.width)
		{
			dirty = YES;
			
			// make copies of the original region
			region1 = [self makeUniqueCopyOf:region0];
			region2 = [self makeUniqueCopyOf:region0];
			
			[self removeRegionFromView:region0];
			
			[region1 cropByDeltaX1:0 deltaX2:cursor - r.origin.x - r.size.width];
			[region1 updateGainEnvelope];
			[region1 updateTimeInModel];

			[region2 cropByDeltaX1:cursor - r.origin.x deltaX2:0];
			[region2 updateGainEnvelope];
			[region2 updateTimeInModel];
		}
	}
	
	if(dirty)
	{
		[self deselectAllRegions];
		
		[self recalculateArrangerProperties];
		[self setNeedsDisplayInRect:r];

		// notification
		[document selectionInArrangerDidChange];

		// undo
		if([selectedRegions count] == 1)
			[[context undoManager] setActionName:@"split audio region"];
		else if([selectedRegions count] > 1)
			[[context undoManager] setActionName:@"split audio regions"];
	}
}

- (IBAction)heal:(id)sender
{}


- (void)bringToFront:(id)sender
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:audioRegions];
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	
	while (region = [enumerator nextObject])
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
	NSEnumerator *enumerator = [audioRegions reverseObjectEnumerator];
	Region *region;
	
	while (region = [enumerator nextObject])
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
	[newGroupRegion setValue:self forKey:@"superview"];

	// turn all selected regions into children
	NSEnumerator *enumerator = [selectedRegions objectEnumerator];
	Region *region;

	while((region = [enumerator nextObject]))
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
	





- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([item action] == @selector(nudgeAmountMenu:) ||
		[item action] == @selector(verticalGridModeMenu:) ||
		[item action] == @selector(horizontalGridModeMenu:) ||
		[item action] == @selector(horizontalGridAmountMenu:))
		return YES;

	if(![audioRegions count])
		return NO;
	
	if (![selectedRegions count] &&
		([item action] == @selector(delete:) ||
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
		
		NSEnumerator *enumerator;
		Region *region;
	
		// all selected regions have to be groups
		enumerator = [selectedRegions objectEnumerator];
		while((region = [enumerator nextObject]))
		{		
			if(![region isKindOfClass:[GroupRegion class]])
			return NO;
		}
	}
	
	return YES;
}


#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoom:(NSNotification *)notification
{
	// get start time (time at the left edge of the view)
	unsigned long startTime = [[self superview] bounds].origin.x / zoomFactorX;
	
	// X zoom factor
	zoomFactorX = [document zoomFactorX];
	
	// restore start time 
	NSRect r = NSMakeRect(startTime * zoomFactorX, [[self superview] bounds].origin.y, [[self superview] bounds].size.width, 1);
	[self scrollRectToVisible:r];
	
	// Y zoom factor
	zoomFactorY = [document zoomFactorY];

	[self recalculateArrangerSize];
	
	// grid
	[self recalculateHorizontalGridPath];
	[self recalculateVerticalGridPath];
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
	
	
	NSEnumerator *enumerator = [audioRegions objectEnumerator];
	Region *region;
	while(region = [enumerator nextObject])
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
