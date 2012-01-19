//
//  Region.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.08.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "Region.h"
#import "AudioRegion.h"
#import "CHProjectDocument.h"
#import "Breakpoint.h"
#import "BreakpointBezierPath.h"

@implementation Region
/*
 the superclass for all regions
 - audio region
 - group region
 
 does graphic stuff too
 is a lightweight view class (not a subclass of NSView)

 */

@synthesize gainBreakpointArray;


- (void)awakeFromInsert
{
//	NSLog(@"Region %x awakeFromInsert", self);

	[self commonAwake];
	gainBreakpointArray = [[BreakpointArray alloc] init];
	[gainBreakpointView setValue:gainBreakpointArray forKey:@"breakpointArray"];

	frame = NSMakeRect(0, 0, 0, 0);
	contentOffset = 0;

	// set one gain breakpoint at 0 dB (= overall volume of this region)
	Breakpoint *bp;
	
	bp = [[[Breakpoint alloc] init] autorelease];
	[bp setValue:0];
	[bp setTime:0];
	[bp setBreakpointType:breakpointTypeNormal];
	[gainBreakpointArray addBreakpoint:bp];	
	
	[self archiveData];
}

- (void)awakeFromFetch
{
//	NSLog(@"Region %x awakeFromFetch", self);

	[self commonAwake];
	[self unarchiveData];
	
	frame = NSMakeRect(0, 0, 0, 0);
}

- (void)commonAwake
{
	displaysTrajectoryPlaceholder = NO;
	
	// initialize breakpoint view
	gainBreakpointView = [[BreakpointView alloc] init];
	[gainBreakpointView setValue:self forKey:@"owningRegion"];
	[gainBreakpointView setValue:[[NSColor whiteColor] colorWithAlphaComponent:0.25] forKey:@"backgroundColor"];
	[gainBreakpointView setValue:[NSColor blackColor] forKey:@"lineColor"];
	[gainBreakpointView setValue:[NSColor blackColor] forKey:@"handleColor"];
	[gainBreakpointView setUpdateCallbackObject:self selector:@selector(archiveData)];
	[gainBreakpointView setValue:@"time: %0.0f vol: %0.2f dB" forKey:@"toolTipString"];
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setZoom:)
												 name:@"arrangerViewZoomFactorDidChange"
											   object:nil];
}	

//- (void)prepareForDeletion
//{
//	NSLog(@"Region %x prepareForDeletion", self);
//}

- (void)dealloc
{
	NSLog(@"Region %@ dealloc", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[projectSettings release];	

	[gainBreakpointArray release];
	[gainBreakpointView release];

	[super dealloc];
}

#pragma mark -
#pragma mark copying
// -----------------------------------------------------------




#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{
	// get stored settings
	if(!projectSettings)
	{
		id document = [[NSDocumentController sharedDocumentController] currentDocument];
		projectSettings = [[document valueForKey:@"projectSettings"] retain];
	}
	
	// color
	NSColor *backgroundColor;
	NSColor *frameColor;
	
	color = [self color];
	frameColor	= color;

	if([[self valueForKey:@"selected"] boolValue])
	{
		color = [NSColor	colorWithCalibratedHue:[color hueComponent]
							saturation:[color saturationComponent] * 0.75
							brightness: [color brightnessComponent] * 1.5
							alpha: 0.85];

	}
	else
	{
		color = [NSColor	colorWithCalibratedHue:[color hueComponent]
							saturation:[color saturationComponent] * 0.75
							brightness: [color brightnessComponent] * 0.75
							alpha: 0.7];
	}

	backgroundColor = color;
	
	// locked / unlocked
	if([[self valueForKey:@"locked"] boolValue])
	{
	}
	
	// muted / unmuted
	if([[self valueForKey:@"muted"] boolValue])
	{
		backgroundColor = [NSColor	colorWithCalibratedHue:[color hueComponent]
												saturation:[color saturationComponent] * 0.5
												brightness: [color brightnessComponent] * 0.5
													 alpha: [color alphaComponent]];
	}
	
	

	// background
	if(![[self valueForKey:@"childRegions"] count])
	{
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		[backgroundColor set];
		[[NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5] fill];
	}
	
	// draw child regions
	Region *region;

	for(region in [self valueForKey:@"childRegions"])
	{
		[region drawRect:rect];
	}


	// draw trajectory
	if([self valueForKey:@"trajectoryItem"])// && ![[self valueForKey:@"trajectoryItem"] isFault] && !displaysTrajectoryPlaceholder)
	{
		// NSLog(@"region %x draws trajectory item %@", self, [self valueForKey:@"trajectoryItem"]);
		NSData *theData;
		NSColor *trajectoryRegionColor;
		
		if([self valueForKey:@"parentRegion"])
		{
			trajectoryRegionColor = [color colorWithAlphaComponent:1];
		}		
		else
		{
			theData = [[NSUserDefaults standardUserDefaults] dataForKey:@"trajectoryRegionColor"];
			trajectoryRegionColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
		}

		if([[self valueForKey:@"selected"] boolValue])
		{
			trajectoryRegionColor = [NSColor	colorWithCalibratedHue:[trajectoryRegionColor hueComponent]
										 saturation:[trajectoryRegionColor saturationComponent] * 0.75
										 brightness: [trajectoryRegionColor brightnessComponent] * 1.5
											  alpha: 0.85];
		}
		else
		{
			trajectoryRegionColor = [NSColor	colorWithCalibratedHue:[trajectoryRegionColor hueComponent]
										 saturation:[trajectoryRegionColor saturationComponent] * 0.75
										 brightness: [trajectoryRegionColor brightnessComponent] * 0.75
											  alpha: 0.7];
		}


		trajectoryRect.origin.x = frame.origin.x;
		trajectoryRect.origin.y = frame.origin.y + (frame.size.height > REGION_NAME_BLOCK_HEIGHT ? frame.size.height - REGION_TRAJECTORY_BLOCK_HEIGHT : frame.size.height * 0.5);
		trajectoryRect.size.height = frame.size.height > REGION_NAME_BLOCK_HEIGHT ? REGION_TRAJECTORY_BLOCK_HEIGHT : frame.size.height * 0.5;
		trajectoryRect.size.width = frame.size.width;

		trajectoryFrame = trajectoryRect;
		
		if([[self valueForKeyPath:@"trajectoryDurationMode"] intValue] != durationModeScaled)
		{
			trajectoryRect.size.width = [[self valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue] * zoomFactorX;
		}
		
		// minimum width
		if(trajectoryRect.size.width < 10)
		{
			trajectoryRect.size.width = frame.size.width < 10 ? frame.size.width * 0.5 : 10;
		}
		
		

		// draw trajectory region
		// ----------------------
		
		trajectoryFrame = NSInsetRect(trajectoryFrame, 2.0, 2.0);
		trajectoryRect = NSInsetRect(trajectoryRect, 2.0, 2.0);

		[trajectoryRegionColor set];		
		
		// draw loop

		if([[self valueForKeyPath:@"trajectoryDurationMode"] intValue] == durationModeLoop ||
		   [[self valueForKeyPath:@"trajectoryDurationMode"] intValue] == durationModePalindrome)
		{
			NSRect loopFrame = trajectoryFrame;
			
			[[trajectoryRegionColor colorWithAlphaComponent:0.35] set];
			[[NSBezierPath bezierPathWithRoundedRect:loopFrame xRadius:3 yRadius:3] fill];
			
			[trajectoryRegionColor set];		
		}
		
		

		// draw triangle if trajectory is longer then audio region

		if([[self valueForKeyPath:@"trajectoryDurationMode"] intValue] != durationModeScaled &&
		   [[self valueForKeyPath:@"trajectoryItem.duration"] unsignedIntValue] > [[self valueForKey:@"duration"] unsignedIntValue])
		{
			trajectoryRect.size.width = frame.size.width - 8;

			NSPoint p1 = NSMakePoint(trajectoryRect.origin.x + trajectoryRect.size.width - 2.5, trajectoryRect.origin.y + 2.0);
			NSPoint p2 = NSMakePoint(trajectoryRect.origin.x + trajectoryRect.size.width - 2.5, trajectoryRect.origin.y + REGION_TRAJECTORY_BLOCK_HEIGHT - 2.0);
			NSPoint p3 = NSMakePoint(trajectoryRect.origin.x + trajectoryRect.size.width + 8, trajectoryRect.origin.y + REGION_TRAJECTORY_BLOCK_HEIGHT * 0.5);
		
			NSBezierPath *triangle = [NSBezierPath bezierPath];
			[triangle moveToPoint:p1];
			[triangle lineToPoint:p2];
			[triangle lineToPoint:p3];
			[triangle lineToPoint:p1];
		
			[triangle fill];
		}
		else
		{
			[[NSBezierPath bezierPathWithRoundedRect:trajectoryFrame xRadius:3 yRadius:3] stroke];			
		}

		
		// draw trajectory region itself

		[[NSBezierPath bezierPathWithRoundedRect:trajectoryRect xRadius:3 yRadius:3] fill];

		

		// draw trajectory name
		
		trajectoryFrame = NSInsetRect(trajectoryFrame, 2.0, 1.0);
		
		if([self valueForKeyPath:@"trajectoryItem.node.name"])
		{
		   NSString *label = [NSString stringWithString:[self valueForKeyPath:@"trajectoryItem.node.name"]];
			NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
			[attrs setObject:[NSFont systemFontOfSize: 10] forKey:NSFontAttributeName];
			[attrs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
			[label drawInRect:trajectoryFrame withAttributes:attrs];
		}
	}

	
}

- (void)drawGainEnvelope:(NSRect)rect
{
	NSRect r = frame;
	if(![self valueForKey:@"trajectoryItem"] && !displaysTrajectoryPlaceholder)
	{
		r.origin.y += REGION_NAME_BLOCK_HEIGHT + 2;
		r.size.height -= REGION_NAME_BLOCK_HEIGHT + 4;
	}
	else
	{
		r.origin.y += REGION_NAME_BLOCK_HEIGHT + 2;
		r.size.height -= REGION_NAME_BLOCK_HEIGHT + REGION_TRAJECTORY_BLOCK_HEIGHT + 4;
	}
	
	
	gainBreakpointView.xAxisValueKeypath = @"time";
	gainBreakpointView.yAxisValueKeypath = @"value";
	
	gainBreakpointView.xAxisMax = [[self valueForKeyPath:@"duration"] intValue];
	gainBreakpointView.zoomFactorX = zoomFactorX;
	
	gainBreakpointView.yAxisMin = -72;
	gainBreakpointView.yAxisMax = 18;

	[gainBreakpointView drawInRect:r];
}

- (void)drawFrame:(NSRect)rect
{
	// color
	NSColor *frameColor = color;
	
	// locked / unlocked
	if([[self valueForKey:@"locked"] boolValue])
	{
		frameColor = [NSColor blackColor];
	}

	[frameColor set];
	[[NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5] stroke];	
}

- (NSColor *)color
{
	NSData *theData;

	if([self valueForKey:@"parentRegion"])
	{
		return [[self valueForKey:@"parentRegion"] valueForKey:@"color"];
	}		
	if([[self valueForKey:@"childRegions"] count])
	{
		theData = [[NSUserDefaults standardUserDefaults] dataForKey:@"groupRegionColor"];
		return (NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
	}
	else
	{
		theData = [[NSUserDefaults standardUserDefaults] dataForKey:@"audioRegionColor"];
		return (NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
	}
}

#pragma mark -
#pragma mark mouse
// -----------------------------------------------------------

- (void)mouseDown:(NSPoint)location
{
	if(![[self valueForKey:@"locked"] boolValue])
		[gainBreakpointView mouseDown:location];
}

- (NSPoint)proposedMouseDrag:(NSPoint)delta
{
	return [gainBreakpointView proposedMouseDrag:delta];
}

- (void)mouseDragged:(NSPoint)delta
{
	if(![[self valueForKey:@"locked"] boolValue])
		[gainBreakpointView mouseDragged:delta];
}

- (void)mouseUp:(NSEvent *)event
{
	if(![[self valueForKey:@"locked"] boolValue])
		[gainBreakpointView mouseUp:event];	

	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[managedObjectContext undoManager] setActionName:[NSString stringWithFormat:@"edit gain envelope"]];
}



#pragma mark -
#pragma mark drag & crop
// -----------------------------------------------------------

- (void)moveByDeltaX:(float)deltaX deltaY:(float)deltaY
{
	frame.origin.x += deltaX;
	frame.origin.y += deltaY;
	
	// move child views too	
    for(Region *region in [self valueForKey:@"childRegions"])
	{
		[region moveByDeltaX:deltaX deltaY:deltaY];
    }
}

- (void)cropByDeltaX1:(float)deltaX1 deltaX2:(float)deltaX2
{
	frame.origin.x += deltaX1;
	contentOffset += deltaX1;
	frame.size.width -= deltaX1 - deltaX2;
}


- (void)updateGainEnvelope
{
//	NSLog(@"Region: updateGainEnvelope");
	
	NSMutableArray *tempArray = [gainBreakpointArray.breakpoints copy];

    //	float lastValue = [(Breakpoint *)[gainBreakpointArray objectAtIndex:0] value];
	for(Breakpoint* bp in tempArray)
	{
        if(bp.time < contentOffset / zoomFactorX ||
		   bp.time > contentOffset / zoomFactorX + frame.size.width / zoomFactorX)
		{
			[gainBreakpointArray removeBreakpoint:bp];
		}
		else
		{
			bp.time -= contentOffset / zoomFactorX;
		}
	}
	
	// temp
	// make sure that the breakpoint array is not empty
	if(![gainBreakpointArray count])
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:0];
		[bp setTime:0];
		[gainBreakpointArray addBreakpoint:bp];	
	}
	
	[self archiveData];
}

- (void)updateTimeInModel
{
	NSLog(@"Region: updateTimeInModel");
	// synchronize data with new position of the regionView after dragging
	
	[self setValue:[NSNumber numberWithLong:(frame.origin.x - ARRANGER_OFFSET) / zoomFactorX] forKey:@"startTime"];
	[self setValue:[NSNumber numberWithLong:frame.origin.y / zoomFactorY] forKey:@"yPosInArranger"];

	if([self isKindOfClass:[AudioRegion class]])
	{
		[self setValue:[NSNumber numberWithLong:frame.size.width / zoomFactorX] forKeyPath:@"audioItem.duration"];
		[self setValue:[NSNumber numberWithLong:contentOffset / zoomFactorX] forKeyPath:@"audioItem.offsetInFile"];
	}
	
	// synchronize children
    for(Region *region in [self valueForKey:@"childRegions"])
	{
		[region updateTimeInModel];
    }
	
	// call the undoable refresh view method
//	[self undoableRefreshView];
	
}

//- (void)undoableRefreshView
//{	
//	// undo	
//	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
//	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self] undoableRefreshView];
//	
//	[self recalcFrame];
//}

#pragma mark -
#pragma mark gain envelope
// -----------------------------------------------------------

//- (void)setGainBreakpointArray:(NSArray *)array
//{
//	if(gainBreakpointArray != array)
//	{
//		[gainBreakpointArray release];
//		gainBreakpointArray = [array retain];
//		
//		[gainBreakpointView setValue:gainBreakpointArray forKey:@"breakpointArray"];
//	}
//}

- (void)removeSelectedGainBreakpoints
{
	[gainBreakpointView removeSelectedBreakpoints];
	
	if([gainBreakpointArray count] == 0)
	{
		Breakpoint *bp;
		
		bp = [[[Breakpoint alloc] init] autorelease];
		[bp setValue:0];
		[bp setTime:0];
		[gainBreakpointArray addBreakpoint:bp];	
	}
}


#pragma mark -
#pragma mark abstract methods
// -----------------------------------------------------------
- (void)recalcFrame {}
- (void)recalcWaveform {}
- (float)offset { return contentOffset; }
- (void)removeFromView {}
- (void)calculatePositionBreakpoints {}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setSelected:(BOOL)flag
{
	selected = flag;	
	if(!selected) [gainBreakpointView deselectAll];
}

- (NSRect)frame { return frame; }
- (void)setFrame:(NSRect)rect { frame = rect; }	

- (NSRect)trajectoryFrame { return trajectoryFrame; }

- (void)setSuperview:(ArrangerView *)view
{
	// the region is added to the arranger
	if(!superview && view)
	{	
		// register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(setZoom:)
													 name:@"arrangerViewZoomFactorDidChange"
												   object:nil];
		
		// initialize zoom
		zoomFactorX = [[view valueForKey:@"zoomFactorX"] floatValue];
		zoomFactorY = [[view valueForKey:@"zoomFactorY"] floatValue];		
	}

	// the region is removed from the arranger
	if(superview && !view)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}

	superview = view;
}


- (NSNumber *)duration { return nil; }


#pragma mark -
#pragma mark position
// -----------------------------------------------------------

- (void)modulateTrajectory
{}


#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoom:(NSNotification *)notification
{	
	zoomFactorX = [[notification object] zoomFactorX];
	zoomFactorY = [[notification object] zoomFactorY];		
	
	[self recalcFrame];
	[self recalcWaveform];
}


#pragma mark -
#pragma mark serialisation
// -----------------------------------------------------------

- (void)archiveData
{ 
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	// archive volume data
	data = [NSMutableData data];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:gainBreakpointArray forKey:@"gainBpArray"];
	[archiver finishEncoding];
	
	[self setValue:data forKey:@"gainEnvelopeData"];
	[archiver release];
}

- (void)unarchiveData
{
	//NSLog(@"Region: unarchiveData");

	NSMutableData *data;
	NSKeyedUnarchiver* unarchiver;
	
	// unarchive volume data
	[gainBreakpointArray release];
	data = [self valueForKey:@"gainEnvelopeData"];
	if(!data)
	{
		gainBreakpointArray = [[BreakpointArray alloc] init];
	}
	else
	{
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		gainBreakpointArray = [[unarchiver decodeObjectForKey:@"gainBpArray"] retain];
		[unarchiver finishDecoding];
		[unarchiver release];
	}

	[gainBreakpointView setValue:gainBreakpointArray forKey:@"breakpointArray"];
}	



@end



@implementation PlaceholderRegion

+ (PlaceholderRegion *)placeholderRegionWithFrame:(NSRect)rect
{
	PlaceholderRegion *region = [[[PlaceholderRegion alloc] init] autorelease];
	[region setFrame:rect];
	
	return region;
}

// drawing
- (void)draw
{
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5] stroke];
}

// accessors
- (NSRect)frame { return frame; }
- (void)setFrame:(NSRect)rect { frame = rect; }	

@end

