//
//  AudioRegion.m
//  Choreographer
//
//  Created by Philippe Kocher on 15.05.08.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "AudioRegion.h"
#import "ArrangerView.h"
#import "AudioEngine.h"

@implementation AudioRegion

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"AudioRegion %x awakeFromInsert", self);
	position = [[SpatialPosition alloc] init];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	position = [[SpatialPosition alloc] init];
	[position setX:[[self valueForKey:@"positionX"] floatValue]];
	[position setY:[[self valueForKey:@"positionY"] floatValue]];
	[position setZ:[[self valueForKey:@"positionZ"] floatValue]];

	// update audio engine
	[[AudioEngine sharedAudioEngine] addAudioRegion:self];
}


- (void)dealloc
{
	NSLog(@"AudioRegion %x dealloc", self);
	[position release];
	[playbackBreakpointArray release];
	[super dealloc];
}

#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	// colors
	NSColor *textColor, *textBackgroundColor;

	textBackgroundColor	= [NSColor	colorWithCalibratedHue:[color hueComponent]
									saturation:[color saturationComponent]
									brightness:[color brightnessComponent]
									alpha:1];
	
	textColor = [NSColor blackColor];
	if([[self valueForKey:@"muted"] boolValue])
	{
		textColor = [textColor colorWithAlphaComponent:0.25];
	}
	
	// audio region name
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	NSRect name_r = frame;
	name_r.size.height = frame.size.height > REGION_NAME_BLOCK_HEIGHT ? REGION_NAME_BLOCK_HEIGHT : frame.size.height;

	name_r = NSInsetRect(name_r, 2.0, 1.0);
	[textBackgroundColor set];
	[[NSBezierPath bezierPathWithRoundedRect:name_r xRadius:2 yRadius:2] fill];

	name_r = NSInsetRect(name_r, 2.0, 1.0);

	NSString *label = [NSString stringWithString:[self valueForKeyPath:@"audioItem.node.name"]];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:[NSFont systemFontOfSize: 10] forKey:NSFontAttributeName];
	[attrs setObject:textColor forKey:NSForegroundColorAttributeName];
	[label drawInRect:name_r withAttributes:attrs];
	
	// waveform
	NSImage *waveformImage = [self valueForKeyPath:@"audioItem.audioFile.waveformImage"];
	if(waveformImage && frame.size.height > 20)
	{
		float x = contentOffset / zoomFactorX;
		float width = frame.size.width / zoomFactorX;
		NSRect image_r = frame;
		float opacity = [[projectSettings valueForKeyPath:@"projectSettingsDictionary.projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain ? 0.5 : 1.0;
				
		if(![self valueForKey:@"trajectoryItem"] && !displaysTrajectoryPlaceholder)
		{
			image_r.origin.y += REGION_NAME_BLOCK_HEIGHT + 5;
			image_r.size.height -= REGION_NAME_BLOCK_HEIGHT + 10;
		}
		else
		{
			image_r.origin.y += REGION_NAME_BLOCK_HEIGHT + 5;
			image_r.size.height -= REGION_NAME_BLOCK_HEIGHT + REGION_TRAJECTORY_BLOCK_HEIGHT + 10;
		}
		[waveformImage drawInRect:image_r
					   fromRect:NSMakeRect(x, 0, width, [waveformImage size].height)
					   operation:NSCompositeSourceOver
						 fraction:opacity];
	}
	
	// draw gain rubberband
	if([[projectSettings valueForKeyPath:@"projectSettingsDictionary.arrangerDisplayMode"] integerValue] == arrangerDisplayModeGain)
	{
		[self drawGainEnvelope:rect];
	}
	
}


- (void)recalcFrame
{
//	NSLog(@"AudioRegion: recalcFrame");
	if(zoomFactorX == 0)
		zoomFactorX = [[superview valueForKeyPath:@"document.zoomFactorX"] floatValue];	
	
	frame.origin.x = [[self valueForKey:@"startTime"] longLongValue] * zoomFactorX + ARRANGER_OFFSET;
	frame.origin.y = [[self valueForKey:@"yPosInArranger"] floatValue] * zoomFactorY;
	frame.size.width = [[self valueForKeyPath:@"duration"] longLongValue] * zoomFactorX;
	frame.size.height = AUDIO_BLOCK_HEIGHT * zoomFactorY - 1;
	
	contentOffset = [[self valueForKeyPath:@"audioItem.offsetInFile"] longValue] * zoomFactorX;
}

- (void)removeFromView
{
	[superview removeRegionFromView:self];
}


#pragma mark -
#pragma mark breakpoints/handles for visualisation
// -----------------------------------------------------------


#pragma mark -
#pragma mark position
// -----------------------------------------------------------

- (SpatialPosition *)regionPosition
{
	if(![self valueForKey:@"trajectoryItem"])
	{
		return position;
	}
	else
	{
		return [playbackBreakpointArray objectAtIndex:0];
	}
}
	   

- (SpatialPosition *)regionPositionAtTime:(NSUInteger)time
{	
	if(time < [[self valueForKey:@"startTime"] unsignedIntValue] || time > [[self valueForKey:@"startTime"] unsignedIntValue] + [[self valueForKey:@"duration"] unsignedIntValue])
		return nil;

	
//	if(![self valueForKey:@"trajectoryItem"])
//	{
//		return position;
//	}
	
	
	time -= [[self valueForKey:@"startTime"] unsignedIntValue];
	
	if([playbackBreakpointArray count] == 1)
	{
		return [(Breakpoint *)[playbackBreakpointArray objectAtIndex:0] position];
	}
	
	if(!tempBp1)
	{
		tempBp1 = [playbackBreakpointArray objectAtIndex:0];
		tempBp2 = [playbackBreakpointArray objectAtIndex:1];
	}
	
	if(time >= [tempBp1 time] && time < [tempBp2 time]) // interpolation, no array search
	{
		return [self interpolatedPosition:time breakpoint1:tempBp1 breakpoint2:tempBp2];
	}
	
	if(time < [tempBp1 time]) // search array from the beginning
	{
		int index = 1;
		
		tempBp1 = [playbackBreakpointArray objectAtIndex:0];
		tempBp2 = [playbackBreakpointArray objectAtIndex:1];
		
		while (time > [tempBp2 time] && [playbackBreakpointArray lastObject] != tempBp2)
		{
			tempBp1 = tempBp2;
			tempBp2 = [playbackBreakpointArray objectAtIndex:++index];			
		}
		
		return [self interpolatedPosition:time breakpoint1:tempBp1 breakpoint2:tempBp2];
	}
	
	// search array from current location
	int index = [playbackBreakpointArray indexOfObject:tempBp2];
	
	while (time > [tempBp2 time] && [playbackBreakpointArray lastObject] != tempBp2)
	{
		tempBp1 = tempBp2;
		tempBp2 = [playbackBreakpointArray objectAtIndex:++index];		
	}
	
	if(time > [tempBp2 time])
	{
		return [tempBp2 position];
	}
	
	return [self interpolatedPosition:time breakpoint1:tempBp1 breakpoint2:tempBp2];
}

- (SpatialPosition *)interpolatedPosition:(NSUInteger)time
							  breakpoint1:(Breakpoint *)bp1
							  breakpoint2:(Breakpoint *)bp2
{
	SpatialPosition *pos1, *pos2;
	
	pos1 = [bp1 position];
	pos2 = [bp2 position];
	
	float factor = [bp2 time] == [bp1 time] ? 1 : (float)(time - [bp1 time]) / ([bp2 time] - [bp1 time]);
	
	return [SpatialPosition positionWithX:[pos1 x] * (1 - factor) + [pos2 x] * factor
										Y:[pos1 y] * (1 - factor) + [pos2 y] * factor
										Z:[pos1 z] * (1 - factor) + [pos2 z] * factor];
}

/*	returns the audio region's spatial trajectory as a array of breakpoints
 no matter if the trajectory is an automated rotation or a random walk */
//- (NSArray *)playbackBreakpointArray
//{
//	return playbackBreakpointArray;
//}

- (void)calculatePositionBreakpoints
{
	[playbackBreakpointArray release];
	tempBp1 = tempBp2 = nil;

	if(![self valueForKey:@"trajectoryItem"])
	{
		Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
		[bp setTime:0];
		[bp setPosition:position];
		
		playbackBreakpointArray = [[NSArray arrayWithObject:bp] retain];
	}
	else
	{
		playbackBreakpointArray = [[[self valueForKey:@"trajectoryItem"] playbackBreakpointArrayWithInitialPosition:position duration:[[self duration] longValue] mode:0] retain];		
	}


	if([self valueForKey:@"parentRegion"] && [self valueForKeyPath:@"parentRegion.playbackBreakpointArray"])
	{
		[self modulateTrajectory];
	}
}

- (void)modulateTrajectory
{
	NSLog(@"audio region %x --- modulate breakpoints", self);
	
	NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
	NSArray *ctlArray = [self valueForKeyPath:@"parentRegion.playbackBreakpointArray"];
	
	NSLog(@"last time %d %d",[[playbackBreakpointArray lastObject] time], [[ctlArray lastObject] time]);

	NSUInteger time = 0;
	NSUInteger ctlTimeOffset = [[self valueForKey:@"startTime"] unsignedIntValue] - [[self valueForKeyPath:@"parentRegion.startTime"] unsignedIntValue];
	int index = 0, ctlIndex = 0;
	BOOL done = NO;

	Breakpoint *bp1, *bp2, *ctlBp1, *ctlBp2;
	SpatialPosition *pos, *ctlPos, *modPos;

	bp1 = [playbackBreakpointArray objectAtIndex:index];
	bp2 = [playbackBreakpointArray count] == 1 ? [playbackBreakpointArray objectAtIndex:index] :
												 [playbackBreakpointArray objectAtIndex:++index];
	
	ctlBp1 = [ctlArray objectAtIndex:ctlIndex];
	ctlBp2 = [ctlArray objectAtIndex:++ctlIndex];
	

	while(!done)
	{
		// search breakpoint array from the beginning to find the next pair of control breakpoints
		if (time >= [bp2 time] && [playbackBreakpointArray lastObject] != bp2)
		{
			bp1 = bp2;
			bp2 = [playbackBreakpointArray objectAtIndex:++index];			
		}
	
		// search control array from the beginning to find the next pair of control breakpoints
		if (time + ctlTimeOffset >= [ctlBp2 time] && [ctlArray lastObject] != ctlBp2)
		{
			ctlBp1 = ctlBp2;
			ctlBp2 = [ctlArray objectAtIndex:++ctlIndex];			
		}
	

		// calculate position
		pos = [self interpolatedPosition:time breakpoint1:bp1 breakpoint2:bp2];
		ctlPos = [self interpolatedPosition:time + ctlTimeOffset breakpoint1:ctlBp1 breakpoint2:ctlBp2];
		
		modPos = [SpatialPosition positionWithX:pos.x + ctlPos.x
											  Y:pos.y + ctlPos.y
											  Z:pos.z + ctlPos.z];
		
		[tempArray addObject:[Breakpoint breakpointWithTime:time position:modPos]];
		
		
		// update time
		NSLog(@"time %d bp1 %d bp2 %d ctlBp1 %d ctlBp2 %d", time, [bp1 time], [bp2 time], [ctlBp1 time], [ctlBp2 time]);
		if(time >= [bp2 time] && [playbackBreakpointArray lastObject] == bp2 &&
		   time >= [ctlBp2 time] - ctlTimeOffset && [ctlArray lastObject] == ctlBp2)
		{
			done = YES;
			
			[playbackBreakpointArray release];
			playbackBreakpointArray = [tempArray retain];
		}
		else
		{
			if([playbackBreakpointArray lastObject] != bp2 && [ctlArray lastObject] == ctlBp2)
				time = [bp2 time];
			
			else if([playbackBreakpointArray lastObject] == bp2 && [ctlArray lastObject] != ctlBp2)
				time = [ctlBp2 time] - ctlTimeOffset;
			
			else if(time < [bp2 time] && [bp2 time] < [ctlBp2 time])
				time = [bp2 time];

			else
				time = [ctlBp2 time] - ctlTimeOffset;
		}
	}
		

	NSLog(@"modulated breakpoints %@", playbackBreakpointArray);
	
	
//	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
//	NSArray *breakpointsArraySorted = [tempArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

}


#pragma mark -
#pragma mark update model
// -----------------------------------------------------------

- (void)updatePositionInModel
{
	// synchronize data with new position

	// get position stored in model
	SpatialPosition *oldPosition = [[[SpatialPosition alloc] init] autorelease];
	[oldPosition setX:[[self valueForKey:@"positionX"] floatValue]];
	[oldPosition setY:[[self valueForKey:@"positionY"] floatValue]];
	[oldPosition setZ:[[self valueForKey:@"positionZ"] floatValue]];

	// store actual position in model
	[self setValue:[NSNumber numberWithFloat:[position x]] forKey:@"positionX"];
	[self setValue:[NSNumber numberWithFloat:[position y]] forKey:@"positionY"];
	[self setValue:[NSNumber numberWithFloat:[position z]] forKey:@"positionZ"];

	// for undo:
	// 1. reset position to old position
	SpatialPosition *newPosition = position;
	position = [oldPosition retain];
	
	// 2. call the undoable method
	[self undoableSetPositionX:[newPosition x] y:[newPosition y] z:[newPosition z]];
	[newPosition release];
}

- (void)undoableSetPositionX:(float)newX y:(float)newY z:(float)newZ;
{
	// undo	
	NSManagedObjectContext *managedObjectContext = [[[NSDocumentController sharedDocumentController] currentDocument] managedObjectContext];
	[[[managedObjectContext undoManager] prepareWithInvocationTarget:self]
		undoableSetPositionX:[position x] y:[position y] z:[position z]];
	
	[position setX:newX];
	[position setY:newY];
	[position setZ:newZ];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateEditors" object:nil userInfo:nil];
}

#pragma mark -
#pragma mark accessor
// -----------------------------------------------------------
// override base class

- (NSNumber *)duration
{
	return [self valueForKeyPath:@"audioItem.duration"];
}



@end
