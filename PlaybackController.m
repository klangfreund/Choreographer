//
//  PlaybackController.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.03.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "PlaybackController.h"
#import "AudioRegion.h"
#import "GroupRegion.h"
#import "TrajectoryItem.h"
#import "EditorContent.h"


@implementation PlaybackController

- (id) init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)awakeFromNib
{
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateAudioEngine:)
												 name:NSManagedObjectContextObjectsDidChangeNotification object:nil];		
	
	// initialise variables
	locator = 0;
}

- (void)dealloc
{
	NSLog(@"PlaybackController: dealloc");
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[updateRegions release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark accessors
// -----------------------------------------------------------

- (void)setProjectSettings:(NSManagedObject *)settings
{
	[projectSettings release];
	[settings retain];
	projectSettings = settings;
	
	// update local variables and gui objects that observe it
	[self setMasterVolume:[[projectSettings valueForKey:@"projectMasterVolume"] floatValue]];
	[self setLoopMode:[[projectSettings valueForKey:@"loopMode"] boolValue]];
	[self setLoop];
}


- (void)setLoopMode:(BOOL)val
{
	//	NSLog(@"setLoopMode: %i", val);
	
	loopMode = val;
	
	if(loopMode != [[projectSettings valueForKey:@"loopMode"] boolValue])
	{
		[projectSettings setValue:[NSNumber numberWithBool:loopMode] forKey:@"loopMode"];
		[self setLoop];
	}
}


- (void)setIsPlaying:(BOOL)val
{
	//	NSLog(@"setIsPlaying: %i", val);
	
	isPlaying = val;
	
	if([[AudioEngine sharedAudioEngine] isPlaying] != val)
		[self startStop];
}

- (BOOL)isPlaying { return isPlaying; }


- (void)setLocator:(unsigned long)sampleTime
{
	//NSLog(@"setLocator: %d", sampleTime);
	locator = sampleTime;
	[self updateLocator];

	if(![[AudioEngine sharedAudioEngine] isPlaying] && !loopMode)
	{
		startLocator = sampleTime;
	}
}

- (unsigned long)locator
{
	return locator;
}

- (void)setMasterVolume:(float)value
{
	masterVolume = value;
	
	[projectSettings setValue:[NSNumber numberWithFloat:masterVolume] forKey:@"projectMasterVolume"];

	[[AudioEngine sharedAudioEngine] setMasterVolume:value];
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)startStop // spacebar
{
	if(![[AudioEngine sharedAudioEngine] isPlaying])
	{
		[self startPlayback];
	}
	else
	{
		[self pausePlayback];
	}

	// update local variable and all gui objects that observe it
	[self setValue:[NSNumber numberWithBool:[[AudioEngine sharedAudioEngine] isPlaying]] forKey:@"isPlaying"];
}

- (void)startPlayback
{	
	if(playbackTimer)
	{
		[playbackTimer invalidate];
	}
	
	playbackTimer = [NSTimer timerWithTimeInterval:0.01
											target:self
										  selector:@selector(tick:)
										  userInfo:nil
										   repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:playbackTimer forMode:NSRunLoopCommonModes];

	[[AudioEngine sharedAudioEngine] startAudio:locator];

	// update local variable and all gui objects that observe it
	[self setValue:[NSNumber numberWithBool:[[AudioEngine sharedAudioEngine] isPlaying]] forKey:@"isPlaying"];
}

- (void)stopPlayback
{
	[[AudioEngine sharedAudioEngine] stopAudio];
	[playbackTimer invalidate];
	playbackTimer = nil;
	
	// return to start position / loop start
	locator = startLocator;
	[self updateLocator];

	// update local variable and all gui objects that observe it
	[self setValue:[NSNumber numberWithBool:[[AudioEngine sharedAudioEngine] isPlaying]] forKey:@"isPlaying"];
}

- (void)pausePlayback
{
	[[AudioEngine sharedAudioEngine] stopAudio];
	[playbackTimer invalidate];
	playbackTimer = nil;

	locator = [[AudioEngine sharedAudioEngine] playbackLocation];

	[self updateLocator];

	// update local variable and all gui objects that observe it
	[self setValue:[NSNumber numberWithBool:[[AudioEngine sharedAudioEngine] isPlaying]] forKey:@"isPlaying"];
}

- (void)returnToZero
{
	[self stopPlayback];
	[self setLocator:0];
}

- (void)tick:(id)sender
{
	if(!rulerPlayhead.inDraggingSession)
	{
		if(![[AudioEngine sharedAudioEngine] isPlaying])
		{
			[playbackTimer invalidate];
			playbackTimer = nil;
		}
		else
		{
			[self setValue:[NSNumber numberWithUnsignedInt:[[AudioEngine sharedAudioEngine] playbackLocation]]
					forKey:@"locator"];
			[self updateLocator];
		}
	}
}

- (void)setLoop
{
//	NSLog(@"mode:%d bounds:%d %d",  [[projectSettings valueForKey:@"loopMode"] integerValue],
//									[[projectSettings valueForKey:@"loopRegionStart"] integerValue],
//									[[projectSettings valueForKey:@"loopRegionEnd"] integerValue]);
//
	[loopCounter setLocators];
	
	if([[projectSettings valueForKey:@"loopMode"] integerValue] &&
	   [[projectSettings valueForKey:@"loopRegionStart"] integerValue] < [[projectSettings valueForKey:@"loopRegionEnd"] integerValue])
	{
		[[AudioEngine sharedAudioEngine] setLoopStart:[[projectSettings valueForKey:@"loopRegionStart"] integerValue] end:[[projectSettings valueForKey:@"loopRegionEnd"] integerValue]];
		startLocator = [[projectSettings valueForKey:@"loopRegionStart"] integerValue];

	}
	else
	{
		[[AudioEngine sharedAudioEngine] unsetLoop];			
	}
}

#pragma mark -
#pragma mark audio engine
// -----------------------------------------------------------

- (void)updateAudioEngine:(NSNotification *)notification
{
	[updateRegions release];
	updateRegions = [[NSMutableSet alloc] init];
	
	NSDictionary *info = [notification userInfo];

	for (id key in info)
	{
		if(key == NSInsertedObjectsKey)
		{
			// NSLog(@"INSERT  --  %@",[info objectForKey:key]);
			for(id object in [info objectForKey:key])
			{		
				if([object isKindOfClass:[TrajectoryItem class]])
				{
					for(id region in [object valueForKey:@"regions"])
					{
						// if the trajectory is newly created and immediately
						// attached to a region, the regions position breakpoint
						// have to be calculated
						[region calculatePositionBreakpoints];
					}
				}
				else if([object isKindOfClass:[AudioRegion class]])
				{
					// update audio engine for this region
					[object calculatePositionBreakpoints];
					[[AudioEngine sharedAudioEngine] addAudioRegion:object];
				}
			}
		}
		else if(key == NSUpdatedObjectsKey)
		{
			// NSLog(@"UPDATE  --  %@",[info objectForKey:key]);
			for(id object in [info objectForKey:key])
			{		
				if([object isKindOfClass:[TrajectoryItem class]])
				{
					// update audio engine for all regions this trajectory
					// is attached to
					for(Region *region in [object valueForKey:@"regions"])
					{
						[region calculatePositionBreakpoints];
						[self recursivelyAddUpdateRegions:region];
					}
				}
				else if([object isKindOfClass:[GroupRegion class]] &&
						[object valueForKey:@"trajectoryItem"] == NULL)
				{
					// after a trajectory has been removed from a group region
					// it can't be found by iterating through the trajectory's
					// regions (as above)

					[object calculatePositionBreakpoints];

					for(Region *region in [object valueForKey:@"childRegions"])
					{
						[self recursivelyAddUpdateRegions:region];
					}
				}
				else if([object isKindOfClass:[AudioRegion class]])
				{
					[updateRegions addObject:object];
					
					if([object valueForKey:@"trajectoryItem"] == NULL)
					{
						// after a trajectory has been removed from a group region
						// it can't be found by iterating through the trajectory's
						// regions (as above)
						
						[object calculatePositionBreakpoints];						
					}
				}
			}
		}
		else if(key == NSDeletedObjectsKey)
		{
			// NSLog(@"DELETE  --  %@",[info objectForKey:key]);
			for(id object in [info objectForKey:key])
			{		
				if([object isKindOfClass:[TrajectoryItem class]])
				{
					// update audio engine for all regions this trajectory
					// is attached to
					for(Region *region in [object valueForKey:@"regions"])
					{
						[region calculatePositionBreakpoints];
						[self recursivelyAddUpdateRegions:region];
					}
				}
				else if([object isKindOfClass:[AudioRegion class]])
				{
					// update audio engine for these regions
					[[AudioEngine sharedAudioEngine] deleteAudioRegion:object];
				}	
			}
		}
	}
	
	for(id region in updateRegions)
	{
		// update audio engine
		[[AudioEngine sharedAudioEngine] modifyAudioRegion:region];			
		[region calculatePositionBreakpoints];
	}
	
}


- (void)recursivelyAddUpdateRegions:(Region *)region
{
	if([region isKindOfClass:[AudioRegion class]])
	{
		[updateRegions addObject:region];
	}
	else if([region isKindOfClass:[GroupRegion class]])
	{
		for(Region *region1 in [region valueForKey:@"childRegions"])
		{
			[self recursivelyAddUpdateRegions:region1];
		}
	}
}


#pragma mark -
#pragma mark update GUI
// -----------------------------------------------------------

- (void)updateLocator
{
	[mainCounter setLocator:locator];
	[rulerPlayhead setLocator:locator];
	[playhead setLocator:locator];
	
	[[EditorContent sharedEditorContent] synchronizeWithLocator:locator];
}

@end
