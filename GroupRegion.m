//
//  GroupRegion.m
//  Choreographer
//
//  Created by Philippe Kocher on 26.08.09.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "GroupRegion.h"
#import "CHProjectDocument.h"


@implementation GroupRegion

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"GroupRegion %x awakeFromInsert", self);

	duration = 0;
	height = 0;
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog(@"GroupRegion %x awakeFromFetch", self);

	duration = 0;
	height = 0;
}

- (void)dealloc
{
//	NSLog(@"GroupRegion %x dealloc", self);
	[super dealloc];
}


#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
}

- (void)recalcFrame
{
//	NSLog(@"group %@: recalc frame (duration %d height %d)", self, duration, height);
	if(duration == 0) // duration + height have never been calculated...
	{
		NSEnumerator *enumerator = [[self valueForKey:@"childRegions"] objectEnumerator];
		Region *region;
		
		NSUInteger regionStartTime;
		NSUInteger startTime = NSUIntegerMax;
		
		NSUInteger regionEndTime;
		NSUInteger endTime = 0;
		
		float minYPos = [[self valueForKey:@"yPosInArranger"] floatValue];
		float maxYPos = minYPos;
		float regionYPos;
		
		height = AUDIO_BLOCK_HEIGHT;
		
		while(region = [enumerator nextObject])
		{
			regionStartTime = [[region valueForKey:@"startTime"] unsignedIntValue];
			regionEndTime = [[region valueForKeyPath:@"duration"] unsignedIntValue] + regionStartTime;

			if(regionStartTime < startTime)
				startTime = regionStartTime;
			
			if(regionEndTime > endTime)
				endTime = regionEndTime;
			
			regionYPos = [[region valueForKey:@"yPosInArranger"] floatValue];
			
			if(regionYPos < minYPos)
				minYPos = regionYPos;
			
			if(regionYPos > maxYPos)
				maxYPos = regionYPos;
			
		}
			
		[self setValue:[NSNumber numberWithLongLong:startTime] forKey:@"startTime"];
		[self setValue:[NSNumber numberWithFloat:minYPos] forKey:@"yPosInArranger"];

		duration = endTime - startTime;
		height = maxYPos - minYPos + AUDIO_BLOCK_HEIGHT;
	}
	
	frame.origin.x = [[self valueForKey:@"startTime"] longLongValue] * zoomFactorX + ARRANGER_OFFSET;
	frame.origin.y = [[self valueForKey:@"yPosInArranger"] floatValue] * zoomFactorY;
	frame.size.width = duration * zoomFactorX;
	frame.size.height = height * zoomFactorY;
}

#pragma mark -
#pragma mark position
// -----------------------------------------------------------

- (void)calculatePositionBreakpoints
{
	[playbackBreakpointArray release];
	
	playbackBreakpointArray = [[[self valueForKey:@"trajectoryItem"] playbackBreakpointArrayWithInitialPosition:nil duration:[[self duration] longValue]] retain];

	if([self valueForKey:@"parentRegion"] && [self valueForKeyPath:@"parentRegion.playbackBreakpointArray"])
	{
		NSLog(@"group region %x playback breakpoints to be modulated", self);
	}

	for(Region *child in [self valueForKey:@"childRegions"])
	{
		[child calculatePositionBreakpoints];
	}
}


#pragma mark -
#pragma mark child views
// -----------------------------------------------------------

- (void)addChildRegion:(Region *)aRegion
{
	[aRegion setValue:self forKey:@"parentRegion"];
	duration = 0; // reset duration
	[self setValue:[aRegion valueForKey:@"yPosInArranger"] forKey:@"yPosInArranger"];
	
	[self recalcFrame];
	//
//
//	if(duration == 0) // the first region being added
//	{
//		[self setValue:[aRegion valueForKey:@"startTime"] forKey:@"startTime"];
//		[self setValue:[aRegion valueForKey:@"yPosInArranger"] forKey:@"yPosInArranger"];
//		duration = [[aRegion valueForKeyPath:@"duration"] longLongValue];
//		height = AUDIO_BLOCK_HEIGHT;
//	}
//	else
//	{
//		NSUInteger startTime = [[self valueForKey:@"startTime"] longLongValue];
//		NSUInteger regionStartTime = [[aRegion valueForKey:@"startTime"] longLongValue];
//
//		NSUInteger endTime = duration + startTime;
//		NSUInteger regionEndTime = [[aRegion valueForKeyPath:@"duration"] longLongValue] + regionStartTime;
//
//		float minYPos = [[self valueForKey:@"yPosInArranger"] floatValue];
//		float regionMinYPos = [[aRegion valueForKey:@"yPosInArranger"] floatValue];
//		
//		float maxYPos = height + minYPos;
//		float regionMaxYPos = [aRegion frame].size.height / zoomFactorY + regionMinYPos;
//		
//		
//		if(regionStartTime < startTime)
//			startTime = regionStartTime;
//		
//		if(regionEndTime > endTime)
//			endTime = regionEndTime;
//		
//		if(regionMinYPos < minYPos)
//			minYPos = regionMinYPos;
//		
//		if(regionMaxYPos > maxYPos)
//			maxYPos = regionMaxYPos;
//		
//		
//		[self setValue:[NSNumber numberWithLongLong:startTime] forKey:@"startTime"];
//		[self setValue:[NSNumber numberWithFloat:minYPos] forKey:@"yPosInArranger"];
//		duration = endTime - startTime;
//		height = maxYPos - minYPos;
//	}
//
//		
//	if(frame.size.width == 0)
//		frame = [aRegion frame];
//	else
//		frame = NSUnionRect(frame, [aRegion frame]);
}

- (void)removeAllChildRegions;
{
	[self setValue:nil forKey:@"childRegions"];
	frame = NSMakeRect(0, 0, 0, 0);
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setSelected:(BOOL)flag
{
//    [self willChangeValueForKey: @"selected"];
//    [self setPrimitiveValue: value forKey: @"selected"];
//    [self didChangeValueForKey: @"selected"];

	[super setSelected:flag];
	
	// select all child views too
    for(Region *region in [self valueForKey:@"childRegions"])
	{
		[region setSelected:flag];
    }
}

- (NSNumber *)duration { return [NSNumber numberWithInt:duration]; }


#pragma mark -
#pragma mark notifications
// -----------------------------------------------------------

- (void)setZoom:(NSNotification *)notification
{	
	frame.origin.x *= [[notification object] zoomFactorX] / zoomFactorX;
	frame.origin.y *= [[notification object] zoomFactorY] / zoomFactorY;
	
	frame.size.width *= [[notification object] zoomFactorX] / zoomFactorX;
	frame.size.height *= [[notification object] zoomFactorY] / zoomFactorY;
	
	zoomFactorX = [[notification object] zoomFactorX];
	zoomFactorY = [[notification object] zoomFactorY];
	
	[self recalcFrame];
	[self recalcWaveform];
}

@end
