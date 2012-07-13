//
//  RadarEditorView.h
//  Choreographer
//
//  Created by Philippe Kocher on 18.02.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//


#import "RadarEditorView.h"
#import "CHGlobals.h"
#import "EditorContent.h"
#import "ToolTip.h"
#import "SelectionRectangle.h"
#import "SmallTimelinePanel.h"
#import "BreakpointBezierPath.h"
#import "SettingsMenu.h"
#import "AudioRegion.h"
#import "Breakpoint.h"

#define DRAW_XZ(X) if(viewMode != 0) X	// todo: more optimization


@implementation RadarEditorView

#pragma mark -
#pragma mark initialisation
// -----------------------------------------------------------

- (void)awakeFromNib
{
	originalPosition = nil;
	
	gridPath = nil;

	// initialise context menu
	[nudgeAngleMenu setModel:[NSUserDefaults standardUserDefaults] key:@"radarEditorNudgeAngle"];
	[nudgeUnitMenu setModel:[NSUserDefaults standardUserDefaults] key:@"radarEditorNudgeUnit"];

	// initialise variables
	gridMode = 0;
	draggingOrigin.x = -1;

    tempEditorSelection = [[NSMutableSet alloc] init];

	// colors
	backgroundColor		= [[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.3 alpha: 1] retain];
	circleColor			= [[NSColor colorWithCalibratedRed: 0.85 green: 0.85 blue: 0.85 alpha: 1.0] retain];  
	gridColor			= [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 0.25] retain];

	handleFrameColorEditable		= [[NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1.0] retain];
	handleFrameColorNonEditable		= [[NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 0.3] retain];  
	handleFillColorEditable			= [[NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1.0] retain];
	handleFillColorNonEditable		= [[NSColor colorWithCalibratedRed: 0.85 green: 0.85 blue: 0.85 alpha: 1.0] retain];  
	handleFillColorSelected			= [[NSColor blackColor] retain];
	lineColorEditable				= [[NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 0.2 alpha: 1.0] retain];  
	lineColorNonEditable			= [[NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 0.2 alpha: 0.3] retain];

	// string attributes
	NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSBackgroundColorAttributeName, nil];
	NSArray *values = [NSArray arrayWithObjects:[NSFont systemFontOfSize:11], [NSColor blackColor], [NSColor colorWithCalibratedWhite:0.75 alpha:0.75], nil];
	attributesRegion = [[NSDictionary dictionaryWithObjects:values forKeys:keys] retain];
	values = [NSArray arrayWithObjects:[NSFont systemFontOfSize:11], [NSColor blackColor], [NSColor colorWithCalibratedWhite:0.75 alpha:0.75], nil];
	attributesEditable = [[NSDictionary dictionaryWithObjects:values forKeys:keys] retain];
	values = [NSArray arrayWithObjects:[NSFont systemFontOfSize:11], [NSColor colorWithCalibratedWhite:0.0 alpha:0.3], [NSColor colorWithCalibratedWhite:0.75 alpha:0.75], nil];
	attributesNonEditable = [[NSDictionary dictionaryWithObjects:values forKeys:keys] retain];
}

- (void) dealloc
{
	NSLog(@"RadarEditorView: dealloc");
	
	[tempEditorSelection release];

	[originalPosition release];
	[gridPath release];
	
	[backgroundColor release];
	[circleColor release];
	[gridColor release];

	[handleFrameColorEditable release];
	[handleFrameColorNonEditable release];
	[handleFillColorEditable release];
	[handleFillColorNonEditable release];
	[handleFillColorSelected release];
	[lineColorEditable release];
	[lineColorNonEditable release];

	[attributesRegion release];
	[attributesEditable release];
	[attributesNonEditable release];

	[super dealloc];
}


#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{
	radarSize = [self frame].size.width;
	offset = ([self bounds].size.height / radarSize - 2) * radarSize;
	
	// set antialias for all drawing
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];

	// draw the background
	// -----------------------------------------------------------------------------

	[backgroundColor set];
	NSRectFill([self bounds]);


	// draw circle
	// -----------------------------------------------------------------------------

	NSRect aRect;
	[circleColor set];

	// xy display
	aRect = NSMakeRect(5,
					   offset + 5,
					   radarSize - 10,
					   radarSize - 10);
    [[NSBezierPath bezierPathWithOvalInRect:aRect] fill];
	
	// xz display
	aRect = NSMakeRect(5,
					radarSize + offset + 5,
					radarSize - 10,
					radarSize - 10);
    [[NSBezierPath bezierPathWithOvalInRect:aRect] fill];


	// draw grid
	// -----------------------------------------------------------------------------
	if(gridPath)
	{
		if([self inLiveResize])
		{
			[self recalculateGridPath];
		}
		
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		[gridColor set];
		[gridPath stroke];
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	}

	// draw content
	// -----------------------------------------------------------------------------

	displayMode = [[[EditorContent sharedEditorContent] valueForKey:@"displayMode"] intValue];
	editorSelection = [[EditorContent sharedEditorContent] valueForKey:@"editorSelection"];
	displayedTrajectories = [[EditorContent sharedEditorContent] valueForKey:@"displayedTrajectories"];
	editableTrajectory = [[EditorContent sharedEditorContent] valueForKey:@"editableTrajectory"];
	
	if(displayMode == regionDisplayMode || displayMode == playheadDisplayMode)
	{
		[self drawRegionPositions:rect];
	}
	else if(displayMode == trajectoryDisplayMode)
	{
		[self drawTrajectories:rect];
	}
}

- (void)drawRegionPositions:(NSRect)rect
{
    // NSLog(@"draw region position.....");

	RadarPoint		regionPositionHandle;
	NSString		*string;												
	SpatialPosition	*pos;
	
	BreakpointBezierPath *regionPositionPathXY, *regionPositionPathXZ;
 
	for(AudioRegion *region in [[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"])
	{		
		if([[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] == 0)
		{
			pos = [region regionPositionAtTime:[[[EditorContent sharedEditorContent] valueForKey:@"locator"] unsignedIntValue]];
		}
		else
		{
			pos = [region regionPosition];
		}

		regionPositionHandle = [self makePointX:[[pos valueForKey:@"x"] floatValue] Y:[[pos valueForKey:@"y"] floatValue] Z:[[pos valueForKey:@"z"] floatValue]];
		
		// draw the trajecory associated with this region
        TrajectoryItem *trajectoryItem = [region valueForKey:@"trajectoryItem"];
		if(trajectoryItem)
		{
			[self drawPositionBreakpoints:[region valueForKey:@"trajectoryItem"] forRegion:region];
			[self drawAdditionalShapes:[region valueForKey:@"trajectoryItem"] forRegion:region];
			[self drawAdditionalHandles:[region valueForKey:@"trajectoryItem"]];
		}
		
		// draw handle
		regionPositionPathXY = [BreakpointBezierPath breakpointBezierPathWithType:breakpointTypeAudioRegion location:NSMakePoint(regionPositionHandle.x, regionPositionHandle.y1)];
		regionPositionPathXZ = [BreakpointBezierPath breakpointBezierPathWithType:breakpointTypeAudioRegion location:NSMakePoint(regionPositionHandle.x, regionPositionHandle.y2)];

		if([editorSelection containsObject:region])
			[handleFillColorSelected set];
		else if(![[trajectoryItem valueForKey:@"adaptiveInitialPosition"] boolValue])
			[handleFillColorNonEditable set];
		else
			[handleFillColorEditable set];				

		[regionPositionPathXY fill];
		DRAW_XZ([regionPositionPathXZ fill]);

		if(![[trajectoryItem valueForKey:@"adaptiveInitialPosition"] boolValue])
			[handleFrameColorNonEditable set];
		else
			[handleFrameColorEditable set];

		[regionPositionPathXY stroke];
		DRAW_XZ([regionPositionPathXZ stroke]);

		// draw text
		string = [NSString stringWithFormat:@"%@",[region valueForKeyPath:@"audioItem.node.name"]];
		[string drawAtPoint:NSMakePoint(regionPositionHandle.x - 5, regionPositionHandle.y1 + 7) withAttributes:attributesRegion];
		DRAW_XZ([string drawAtPoint:NSMakePoint(regionPositionHandle.x - 5, regionPositionHandle.y2 + 7) withAttributes:attributesRegion]);
	}
}

- (void)drawTrajectories:(NSRect)rect
{
	NSEnumerator *trajectoryEnumerator = [displayedTrajectories reverseObjectEnumerator];
	// reverse: first trajectory (= editable) is drawn last, i.e. frontmost
	id trajectoryItem;
	
	while((trajectoryItem = [trajectoryEnumerator nextObject]))
	{
		[self drawPositionBreakpoints:trajectoryItem forRegion:nil];
		[self drawAdditionalShapes:trajectoryItem forRegion: nil];
		[self drawAdditionalHandles:trajectoryItem];

		[self drawTrajectoryName:trajectoryItem];
	}
}

- (void)drawTrajectoryName:(TrajectoryItem *)trajectory
{
	SpatialPosition *namePosition = [trajectory valueForKeyPath:@"namePosition"];
	RadarPoint p1 = [self makePointX:[namePosition x] Y:[namePosition y] Z:[namePosition z]];
	
	NSString *string = [NSString stringWithFormat:@"%@", [trajectory valueForKeyPath:@"node.name"]];
	if(trajectory == editableTrajectory)
	{
		[string drawAtPoint:NSMakePoint(p1.x - 5, p1.y1 + 7) withAttributes:attributesEditable];
		DRAW_XZ([string drawAtPoint:NSMakePoint(p1.x - 5, p1.y2 + 7) withAttributes:attributesEditable]);
	}
	else
	{
		[string drawAtPoint:NSMakePoint(p1.x - 5, p1.y1 + 7) withAttributes:attributesNonEditable];
		DRAW_XZ([string drawAtPoint:NSMakePoint(p1.x - 5, p1.y2 + 7) withAttributes:attributesNonEditable]);
	}
}



- (void)drawPositionBreakpoints:(TrajectoryItem *)trajectory forRegion:(AudioRegion *)region
{
	Breakpoint *breakpoint;
	BreakpointBezierPath *handleBezierPathXY, *handleBezierPathXZ;
	RadarPoint p1,p2;
	p1.x = -2; // initialise
	

	// draw lines
	if(trajectory == editableTrajectory)
		[lineColorEditable set];
	else
		[lineColorNonEditable set];

	for(breakpoint in [trajectory positionBreakpointsWithInitialPosition:[region valueForKey:@"position"]])
	{
		if(p1.x == -2)
		{
			p1 = [self makePointX:[breakpoint x] Y:[breakpoint y] Z:[breakpoint z]];
			continue;
		}

		p2 = [self makePointX:[breakpoint x] Y:[breakpoint y] Z:[breakpoint z]];
			
		[NSBezierPath strokeLineFromPoint:NSMakePoint(p1.x, p1.y1) toPoint:NSMakePoint(p2.x, p2.y1)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(p1.x, p1.y2) toPoint:NSMakePoint(p2.x, p2.y2)];
			
		p1 = p2;
	}
	
	// draw breakpoint handles

	for(breakpoint in [trajectory positionBreakpointsWithInitialPosition:[region valueForKey:@"position"]])
	{
		p1 = [self makePointX:[breakpoint x] Y:[breakpoint y] Z:[breakpoint z]];
	
		handleBezierPathXY = [BreakpointBezierPath breakpointBezierPathWithType:breakpoint.breakpointType location:NSMakePoint(p1.x, p1.y1)];
		handleBezierPathXZ = [BreakpointBezierPath breakpointBezierPathWithType:breakpoint.breakpointType location:NSMakePoint(p1.x, p1.y2)];
	
		if([editorSelection containsObject:breakpoint])
			[handleFillColorSelected set];
		else if(trajectory == editableTrajectory)
			[handleFillColorEditable set];
		else
			[handleFillColorNonEditable set];
	
		[handleBezierPathXY fill];
		DRAW_XZ([handleBezierPathXZ fill]);
	
		if(trajectory == editableTrajectory && displayMode != playheadDisplayMode)
			[handleFrameColorEditable set];
		else
			[handleFrameColorNonEditable set];
	
		[handleBezierPathXY stroke];
		DRAW_XZ([handleBezierPathXZ stroke]);
	}
}

- (void)drawAdditionalHandles:(TrajectoryItem *)trajectory
{
	RadarPoint p1;
	BreakpointBezierPath *breakpointBezierPathXY, *breakpointBezierPathXZ;
    Breakpoint* bp;
    SpatialPosition *pos;
	
	for(bp in [trajectory valueForKeyPath:@"parameterBreakpoints"])
	{
        if([bp breakpointType] == breakpointTypeValue ||
           ([[bp descriptor] isEqualToString:@"Init"] && [[trajectory valueForKey:@"adaptiveInitialPosition"] boolValue])) continue;
        
		pos = [bp position];

        p1 = [self makePointX:[pos x] Y:[pos y] Z:[pos z]];
		
		breakpointBezierPathXY = [BreakpointBezierPath breakpointBezierPathWithType:breakpointTypeAuxiliary location:NSMakePoint(p1.x, p1.y1)];
		breakpointBezierPathXZ = [BreakpointBezierPath breakpointBezierPathWithType:breakpointTypeAuxiliary location:NSMakePoint(p1.x, p1.y2)];
		
		if([editorSelection containsObject:bp])
			[handleFillColorSelected set];
		else if(trajectory == editableTrajectory && displayMode != playheadDisplayMode)
			[handleFillColorEditable set];
		else
			[handleFillColorNonEditable set];
		
		[breakpointBezierPathXY fill];
		DRAW_XZ([breakpointBezierPathXZ fill]);
		
		if(trajectory == editableTrajectory && displayMode != playheadDisplayMode)
			[handleFrameColorEditable set];
		else
			[handleFrameColorNonEditable set];
		
		[breakpointBezierPathXY stroke];
		DRAW_XZ([breakpointBezierPathXZ stroke]);
	}
	
}

- (void)drawAdditionalShapes:(TrajectoryItem *)trajectoryItem forRegion:(AudioRegion *)region
{
	NSBezierPath *rotationPath;
	NSBezierPath *boundingVolumePathXY;//, *boundingVolumePathXZ;

	id position, centre;
	float radius;
	RadarPoint cp, pt1, pt2;

	switch([[trajectoryItem valueForKey:@"trajectoryType"] intValue])
	{
		case rotationSpeedType:
		case rotationAngleType:
        case circularRandomType:
			rotationPath = [NSBezierPath bezierPath];
			
			centre = [trajectoryItem valueForKeyPath:@"trajectory.rotationCentre.position"];
			cp = [self makePointX:[centre x] Y:[centre y] Z:[centre z]];									  
			
			if(![[trajectoryItem valueForKey:@"adaptiveInitialPosition"] boolValue])
			{
				position = [trajectoryItem valueForKeyPath:@"trajectory.initialPosition.position"];
				radius = pow(pow([centre x] - [position x],2)+pow([centre y] - [position y],2), 0.5) * (radarSize - 10) * 0.5;
				[rotationPath appendBezierPathWithArcWithCenter:NSMakePoint(cp.x, cp.y1) radius:radius startAngle:0 endAngle:360];
			}
			else if (region)	// initial breakpoint is adaptive and this trajectory is drawn
								// together with an associated audio region
			{
				radius = pow(pow([centre x] - [[region regionPosition] x],2)+pow([centre y] - [[region regionPosition] y],2), 0.5) * (radarSize - 10) * 0.5;
				[rotationPath appendBezierPathWithArcWithCenter:NSMakePoint(cp.x, cp.y1) radius:radius startAngle:0 endAngle:360];
			}
			else
			{
				CGFloat array[2];
				array[0] = 1.0; // segment painted with stroke color
				array[1] = 2.0; // segment not painted with a color
				[rotationPath setLineDash: array count: 2 phase: 0.0];
				[rotationPath appendBezierPathWithArcWithCenter:NSMakePoint(cp.x, cp.y1) radius:radarSize * 0.1 startAngle:0 endAngle:360];
			}
			if(trajectoryItem == editableTrajectory && [[NSUserDefaults standardUserDefaults] integerForKey:@"editorContentMode"] != 0)
				[lineColorEditable set];
			else
				[lineColorNonEditable set];
			
			[rotationPath stroke];
			break;

	
		case randomType:
			position = [[trajectoryItem trajectory] performSelector:@selector(point1AtTime:) withObject:[NSNumber numberWithInt:0]];
			pt1 = [self makePointX:[position x] Y:[position y] Z:[position z]];									  

			position = [[trajectoryItem trajectory] performSelector:@selector(point2AtTime:) withObject:[NSNumber numberWithInt:0]];
			pt2 = [self makePointX:[position x] Y:[position y] Z:[position z]];									  

			NSRect r;
							
			if(trajectoryItem == editableTrajectory)
				[lineColorEditable set];
			else
				[lineColorNonEditable set];
			
            r = NSMakeRect(pt1.x, pt1.y1, pt2.x - pt1.x, pt2.y1 - pt1.y1);
			boundingVolumePathXY = [NSBezierPath bezierPathWithRect:r];
			[boundingVolumePathXY stroke];
            
            DRAW_XZ(    r = NSMakeRect(pt1.x, pt1.y2, pt2.x - pt1.x, pt2.y2 - pt1.y2);
                        boundingVolumePathXY = [NSBezierPath bezierPathWithRect:r];
                        [boundingVolumePathXY stroke];
                    )
            
            
			break;
	}
	
}

- (BOOL)isOpaque
{
    return YES;
	// This views doesn't need any of the views behind it.
	// This is a performance optimization hint for the display subsystem.
}

- (void)recalculateGridPath
{
	[gridPath release];
	
	int i;
	float step = (radarSize - 10) * 0.05;
	float gridUnitAE = 6.0, gridUnitD = 0.1;
	float x;

	switch(gridMode)
	{
		// aed grid
		// --------
		case 1:				
			gridPath = [[NSBezierPath bezierPath] retain];
			[gridPath setLineWidth:0.0];

			x = 0;
			while(x <= (radarSize - 10) * 0.5 + 0.5)
			{

				[gridPath appendBezierPathWithOvalInRect:NSMakeRect(radarSize * 0.5 - x,
																	offset + radarSize * 1.5 - x,
																	x * 2,
																	x * 2)];
				
				if([[controller valueForKey:@"viewMode"] intValue] > 0)
				{
					[gridPath appendBezierPathWithOvalInRect:NSMakeRect(radarSize * 0.5 - x,
																		offset + radarSize * 0.5 - x,
																		x * 2,
																		x * 2)];
				}

				x += gridUnitD * (radarSize - 10) * 0.5;
			}
			
			for(i=0;i<gridUnitAE;i++)
			{
				[gridPath moveToPoint:NSMakePoint(cos((i+gridUnitAE) * pi / gridUnitAE) * (radarSize - 10) * 0.5 + radarSize * 0.5,
												  sin((i+gridUnitAE) * pi / gridUnitAE) * (radarSize - 10) * 0.5 + offset + radarSize * 1.5)];
				[gridPath lineToPoint:NSMakePoint(cos(i * pi / gridUnitAE) * (radarSize - 10) * 0.5 + radarSize * 0.5,
												  sin(i * pi / gridUnitAE) * (radarSize - 10) * 0.5 + offset + radarSize * 1.5)];
	
				if([[controller valueForKey:@"viewMode"] intValue] > 0)
				{
					[gridPath moveToPoint:NSMakePoint(cos((i+gridUnitAE) * pi / gridUnitAE) * (radarSize - 10) * 0.5 + radarSize * 0.5,
													  sin((i+gridUnitAE) * pi / gridUnitAE) * (radarSize - 10) * 0.5 + offset + radarSize * 0.5)];
					[gridPath lineToPoint:NSMakePoint(cos(i * pi / gridUnitAE) * (radarSize - 10) * 0.5 + radarSize * 0.5,
													  sin(i * pi / gridUnitAE) * (radarSize - 10) * 0.5 + offset + radarSize * 0.5)];
				}
			}
			
			break;


		// xyz grid
		// --------
		case 2:
			gridPath = [[NSBezierPath bezierPath] retain];
			[gridPath setLineWidth:0.0];
			
			for(x=5; x<radarSize;x += step)
			{
				[gridPath moveToPoint:NSMakePoint(x, 0)];
				[gridPath lineToPoint:NSMakePoint(x, (radarSize * 2))];
			}
			for(x=5; x<radarSize;x += step)
			{
				[gridPath moveToPoint:NSMakePoint(0, offset + x)];
				[gridPath lineToPoint:NSMakePoint(radarSize, offset + x)];
			}
			for(x=radarSize + 5; x<radarSize*2;x += step)
			{
				[gridPath moveToPoint:NSMakePoint(0, offset + x)];
				[gridPath lineToPoint:NSMakePoint(radarSize, offset + x)];
			}
			break;

		default:
			gridPath = nil;
	}
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	[self recalculateGridPath];
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark IB actions
// -----------------------------------------------------------

- (IBAction)gridModeMenu:(id)sender
{
	if(gridMode != [[sender selectedItem] tag])
	{
		gridMode = [[sender selectedItem] tag];
		[self recalculateGridPath];
		[self setNeedsDisplay:YES];
	}
}

- (void)selectAll:(id)sender
{
	[editorSelection removeAllObjects];
	[editorSelection addObjectsFromArray:[editableTrajectory positionBreakpoints]];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
}


#pragma mark -
#pragma mark editing
// -----------------------------------------------------------

- (BOOL)moveSelectedPointsBy:(NSPoint)delta
{
	SpatialPosition *pos;
	BOOL inside = YES;
	
	NSEnumerator *enumerator;
	id item; 
	
	enumerator = [editorSelection objectEnumerator];
	while ((item = [enumerator nextObject]) && inside)
	{
		pos = [item valueForKey:@"position"];
		
		if([pos x] + delta.x < -1 || [pos x] + delta.x > 1 ||
		   (activeAreaOfDisplay == 0 &&
		   ([pos y] + delta.y < -1 || [pos y] + delta.y > 1)) ||
		   (activeAreaOfDisplay == 1 &&
		   ([pos z] + delta.y < -1 || [pos z] + delta.y > 1)))
			inside = NO;
	}
	
	if(!inside) return NO;
	
	enumerator = [editorSelection objectEnumerator];
	while ((item = [enumerator nextObject]))
	{
		pos = [item valueForKey:@"position"];
		
		[pos setX:[pos x] + delta.x];
		if(activeAreaOfDisplay == 0)
			[pos setY:[pos y] + delta.y];
		else
			[pos setZ:[pos z] + delta.y];
	}
	
	return YES;
}

- (BOOL)rotateSelectedPointsBy:(NSPoint)delta
{	
	SpatialPosition *pos;
	double d;
	BOOL inside = YES;
	
	NSEnumerator *enumerator;
	id item; 
	
	enumerator = [editorSelection objectEnumerator];
	while ((item = [enumerator nextObject]) && inside)
	{
		pos = [item valueForKey:@"position"];
		
		if([pos d] + delta.y > 1)
			inside = NO;
	}
	
	if(!inside) return NO;
	
	enumerator = [editorSelection objectEnumerator];
	while ((item = [enumerator nextObject]))
	{
		pos = [item valueForKey:@"position"];
		
		d = [pos d] + delta.y;
		if(d < 0) d = 0.0;
		
		[pos setA:[pos a] + delta.x];
		[pos setD:d];
	}
	
	return YES;
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
	if(displayMode == noDisplayMode) return;

	SpatialPosition *showToolTip = nil;
									   			 				   
	// get event location and convert it to the view's coordinate system
    NSPoint eventLocationInView = [self convertPoint:[event locationInWindow] fromView:nil];
	storedEventLocationInView = eventLocationInView;
	
	if([self frame].size.height - eventLocationInView.y < radarSize)
		activeAreaOfDisplay = 0; // top (xy)
	else
		activeAreaOfDisplay = 1; // bottom (xz)

	NSRect r;
	NSPoint p;
	SpatialPosition *pos;
	
	r.origin.x = (eventLocationInView.x - 5 - MOUSE_POINTER_SIZE * 0.5) / (radarSize - 10) * 2 - 1;
	r.origin.y = activeAreaOfDisplay == 0 ?
				(eventLocationInView.y - radarSize - offset - 5 - MOUSE_POINTER_SIZE * 0.5) / (radarSize - 10) * 2 - 1
				: (eventLocationInView.y - offset - 5 - MOUSE_POINTER_SIZE * 0.5) / (radarSize - 10) * 2 - 1; 
	
	r.size.width = MOUSE_POINTER_SIZE / (radarSize - 10) * 2;
	r.size.height = r.size.width;

	
	// displayed points are region positions
	if(displayMode == regionDisplayMode)
	{
		NSEnumerator *enumerator = [[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] objectEnumerator];
		id region;
 
		while ((region = [enumerator nextObject]) && !hit)
		{
			pos = [region valueForKey:@"position"];
			p.x = [[pos valueForKey:@"x"] floatValue];
			p.y = activeAreaOfDisplay == 0 ?
					[[pos valueForKey:@"y"] floatValue] : [[pos valueForKey:@"z"] floatValue];


			// SHIFT key pressed
			if([event modifierFlags] & NSShiftKeyMask)
			{				
				if(NSPointInRect(p, r))
				{
					if([editorSelection containsObject:region])
					{
						[editorSelection removeObject:region];
					}
					else
					{
						[editorSelection addObject:region];
						hit = region;
					}
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
				}
			}

			// no modifier key pressed
			else
			{
				if(NSPointInRect(p, r))
				{
					hit = region;
					if(![editorSelection containsObject:region])
					{
						[editorSelection removeAllObjects];
						[editorSelection addObject:region];
					}
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
				}
			}
		}
	}
	
	
	// displayed points are trajectory breakpoints
	else if(displayMode == trajectoryDisplayMode)
	{
		NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
		[tempArray addObjectsFromArray:[editableTrajectory positionBreakpoints]];
		[tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];
		
		
		// COMMAND click sets new point
		if([event modifierFlags] & NSCommandKeyMask)
		{
			SpatialPosition *newPos = [SpatialPosition positionWithX:r.origin.x Y:r.origin.y Z:0];
			[editableTrajectory addBreakpointAtPosition:newPos time:-1];
		}

		for(Breakpoint* breakpoint in tempArray)
		{
			if(![breakpoint position] ||
               ([[breakpoint descriptor] isEqualToString:@"Init"] && [[editableTrajectory valueForKey:@"adaptiveInitialPosition"] boolValue])) continue;
            
            p.x = [breakpoint x];
			p.y = activeAreaOfDisplay == 0 ? [breakpoint y] : [breakpoint z];
			
			// ALT click opens alternativeTimelinePanel
            /*
			if([event modifierFlags] & NSAlternateKeyMask)
			{
				if(NSPointInRect(p, r))
				{
					[editorSelection removeAllObjects];
					[editorSelection addObject:breakpoint];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
					[[SmallTimelinePanel sharedSmallTimelinePanel] editBreakpoint:breakpoint trajectory:editableTrajectory event:event];
					return;
				}
			}
            */

			// SHIFT key pressed
			if([event modifierFlags] & NSShiftKeyMask)
			{				
				if(NSPointInRect(p, r))
				{
					if([editorSelection containsObject:breakpoint])
					{
						[editorSelection removeObject:breakpoint];
					}
					else
					{
						[editorSelection addObject:breakpoint];
						hit = breakpoint;
					}
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
				}
			}
			
			// no modifier key pressed
			else
			{
				if(NSPointInRect(p, r))
				{
					hit = breakpoint;
					if(![editorSelection containsObject:breakpoint])
					{
						[editorSelection removeAllObjects];
						[editorSelection addObject:breakpoint];
					}
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
				}
			}
		}
	}

	// no hit and shift not pressed - deselect all handles
	if(!hit && !([event modifierFlags] & NSShiftKeyMask))
	{
		[editorSelection removeAllObjects];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
	}
	if(hit)
	{
		// start dragging handles
		draggingOrigin = eventLocationInView;
		showToolTip = [hit valueForKey:@"position"];
		originalPosition = [showToolTip copy];
	}
	else if(!hit)
	{
		// start selection rectangle
		[tempEditorSelection setSet:editorSelection];
		[[SelectionRectangle sharedSelectionRectangle] addRectangleWithOrigin:eventLocationInView forView:self];
		showSelectionRectangle = YES;
	}
	

	if(showToolTip)
	{
		[[ToolTip sharedToolTip] setString:[NSString stringWithFormat:@"x: %0.2f y: %0.2f z: %0.2f",
											[showToolTip x],
											[showToolTip y],
											[showToolTip z]]
									inView: self];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	// on mouse up (after a dragging session)
	// the data model has to be sychronized
	
	if(dirty)
	{
		dirty = NO;
		[[EditorContent sharedEditorContent] updateModelForSelectedPoints];
	}
	
	draggingOrigin.x = -1;

	[SelectionRectangle dispose];
	showSelectionRectangle = NO;

	[ToolTip dispose];

	hit = nil;
}

- (void)mouseDragged:(NSEvent *)event
{	
	id showToolTip;

	NSPoint eventLocationInView = [self convertPoint:[event locationInWindow] fromView:nil];

	// continue dragging handles
	if(draggingOrigin.x != -1)
	{
		NSPoint delta;

		delta.x = eventLocationInView.x - storedEventLocationInView.x;
		delta.y = eventLocationInView.y - storedEventLocationInView.y;

		// scale location to view's size
		delta.x /= (radarSize - 10) * 0.5;
		delta.y /= (radarSize - 10) * 0.5;
		
		if([self moveSelectedPointsBy:delta])
			storedEventLocationInView = eventLocationInView;

		dirty = YES;
	
		[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
		
		// tool tip
		showToolTip = [hit valueForKey:@"position"];

		if([editorSelection count] == 1)
		{
			[[ToolTip sharedToolTip] setString: [NSString stringWithFormat:@"x: %0.2f y: %0.2f z: %0.2f", 
												[[showToolTip valueForKey:@"x"] floatValue],
												[[showToolTip valueForKey:@"y"] floatValue],
												[[showToolTip valueForKey:@"z"] floatValue]]
									 inView: self];
		}
		else if([editorSelection count] > 1)
		{
			[[ToolTip sharedToolTip] setString: [NSString stringWithFormat:@"delta x: %0.2f y: %0.2f z: %0.2f", 
												[[showToolTip valueForKey:@"x"] floatValue] - [[originalPosition valueForKey:@"x"] floatValue],
												[[showToolTip valueForKey:@"y"] floatValue] - [[originalPosition valueForKey:@"y"] floatValue],
												[[showToolTip valueForKey:@"z"] floatValue] - [[originalPosition valueForKey:@"z"] floatValue]]
										inView: self];
		}
	}

	// selection rectangle
	else if(showSelectionRectangle)
	{
		[[SelectionRectangle sharedSelectionRectangle] setCurrentMousePosition:eventLocationInView];
		NSRect selectionRect = [[SelectionRectangle sharedSelectionRectangle] frame];

		// hit test
		NSPoint p1, p2;
		id item;
		SpatialPosition *pos;

		NSEnumerator *enumerator; 

		if(displayMode == regionDisplayMode)
		{
			enumerator = [[[EditorContent sharedEditorContent] valueForKey:@"displayedAudioRegions"] objectEnumerator];
		}
		else
		{
			NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
			[tempArray addObjectsFromArray:[editableTrajectory positionBreakpoints]];
			[tempArray addObjectsFromArray:[editableTrajectory parameterBreakpoints]];

			enumerator = [tempArray objectEnumerator];
		}
		
		while ((item = [enumerator nextObject]))
		{			
            if(displayMode == trajectoryDisplayMode &&
               ([item breakpointType] == breakpointTypeValue || ([[item valueForKey:@"descriptor"] isEqualToString:@"Init"] && [[editableTrajectory valueForKey:@"adaptiveInitialPosition"] boolValue]))) continue;

			pos = [item valueForKey:@"position"];

            p1 = NSMakePoint(([pos x] + 1) * (radarSize - 10) * 0.5 + 5,
							 ([pos y] + 1) * (radarSize - 10) * 0.5 + radarSize + offset + 5);
			p2.x = p1.x;
			p2.y = ([pos z] + 1) * (radarSize - 10) * 0.5 + offset + 5;
			
			if(NSPointInRect(p1, selectionRect) || NSPointInRect(p2, selectionRect))
			{
				[editorSelection addObject:item];
				[tempEditorSelection removeObject:item];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
			}
			else if(![tempEditorSelection containsObject:item])
			{
				[editorSelection removeObject:item];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:self];
			}
		}
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

//- (BOOL)becomeFirstResponder
//{
//	return YES;
//}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
//	NSLog(@"Radar key code: %d", keyCode);

	activeAreaOfDisplay = (([event modifierFlags] & NSShiftKeyMask) == 0) ? 0 : 1;
	
	BOOL update = NO;

	switch (keyCode)
	{
		case 51:	// BACKSPACE
		case 117:	// DELETE
		
			if(displayMode == regionDisplayMode)
			{
				[[EditorContent sharedEditorContent] setSelectedPointsTo:[SpatialPosition positionWithX:0 Y:0 Z:0]];
			}
			else if(displayMode == trajectoryDisplayMode)
			{
				[[EditorContent sharedEditorContent] deleteSelectedPoints];
			}
			break;
			
			
		case 48:	// TAB
					// cycle through trajectories, make one editable
						
			if(displayMode == trajectoryDisplayMode)
			{
				NSUInteger index = [displayedTrajectories indexOfObject:editableTrajectory];

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
			}
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
	
	float nudgeUnit = [[NSUserDefaults standardUserDefaults] integerForKey:@"radarEditorNudgeUnit"] * 0.001;
	float nudgeAngle = [[NSUserDefaults standardUserDefaults] integerForKey:@"radarEditorNudgeAngle"] * 0.1;

	if([event modifierFlags] & NSAlternateKeyMask)
	{
		// NSPoint usage: x = a (rotation angle) / y = d (distance unit)
		switch (keyCode)
		{
			case 123:	// ARROW left
				[self rotateSelectedPointsBy:NSMakePoint(-nudgeAngle, 0)];
				break;
			case 124:	// ARROW right
				[self rotateSelectedPointsBy:NSMakePoint(nudgeAngle, 0)];
				break;
			case 125:	// ARROW down
				[self rotateSelectedPointsBy:NSMakePoint(0, -nudgeUnit)];
				break;
			case 126:	// ARROW up
				[self rotateSelectedPointsBy:NSMakePoint(0, nudgeUnit)];
				break;
		}
	}
	else
	{
		switch (keyCode)
		{
			case 123:	// ARROW left
				[self moveSelectedPointsBy:NSMakePoint(-nudgeUnit, 0)];
				break;
			case 124:	// ARROW right
				[self moveSelectedPointsBy:NSMakePoint(nudgeUnit, 0)];
				break;
			case 125:	// ARROW down
				[self moveSelectedPointsBy:NSMakePoint(0, -nudgeUnit)];
				break;
			case 126:	// ARROW up
				[self moveSelectedPointsBy:NSMakePoint(0, nudgeUnit)];
				break;
		}
	}
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setViewMode:(int)value { viewMode = value; }

#pragma mark -
#pragma mark utility
// -----------------------------------------------------------
- (RadarPoint)makePointX:(float)xCoordinate Y:(float)yCoordinate Z:(float)zCoordinate;
{
	RadarPoint p;
	p.x  = (xCoordinate + 1) * (radarSize - 10) * 0.5 + 5;
	p.y1 = (yCoordinate + 1) * (radarSize - 10) * 0.5 + radarSize + offset + 5;
	p.y2 = (zCoordinate + 1) * (radarSize - 10) * 0.5 + offset + 5;
	
	return p;
}



@end
