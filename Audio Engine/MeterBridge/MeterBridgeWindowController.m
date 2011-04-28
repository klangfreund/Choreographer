//
//  MeterBridgeWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 22.12.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "MeterBridgeWindowController.h"
#import "MeterBridgeChannelStrip.h"
#import "AudioEngine.h"

@implementation MeterBridgeWindowController

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)init
{
	self = [self initWithWindowNibName:@"MeterBridgeWindow"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"MeterBridgeWindow"];
	}
	return self;
}

- (void)awakeFromNib
{
	[self updateGUI];

	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateGUI)
												 name:@"hardwareDidChange" object:nil];		
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];	

	[meterBridgeChannelStrips release];
	[super dealloc];
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	
	if([[AudioEngine sharedAudioEngine] isPlaying])
		[self run];
}

#pragma mark -
#pragma mark refresh gui
// -----------------------------------------------------------

- (void)updateGUI
{
//	NSLog(@"Meter Bridge Window Controller: update GUI");

	// remove all channel strips

	[meterBridgeChannelStrips release];

	NSArray *subviews = [[channelStripView subviews] copy];
	for(NSView *view in subviews)
	{
		[view removeFromSuperview];
	}

	// add new channel strips

	NSUInteger numberOfOutputChannels =  [[AudioEngine sharedAudioEngine] numberOfSpeakerChannels];

	NSNib* nib = [[NSNib alloc] initWithNibNamed:@"MeterBridgeChannelStrip" bundle:nil] ;
	
	NSRect r = [[self window] frame];
	id item;
	int i;
	
	meterBridgeChannelStrips = [[NSMutableArray alloc] init];
	
	r.size.width = 55 + numberOfOutputChannels * 30;
	[[self window] setFrame:r display:YES];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		MeterBridgeChannelStrip *strip = [[[MeterBridgeChannelStrip alloc] init] autorelease];
		NSArray *theArray;
		
		[meterBridgeChannelStrips addObject:strip];
		
		[strip setValue:[NSNumber numberWithInt:i + 1] forKey:@"channelIndex"];
		
		[nib instantiateNibWithOwner:strip topLevelObjects:&theArray];

		for(item in theArray)
		{
			if([item isKindOfClass:[NSView class]])
			{
				[item setFrameOrigin:NSMakePoint(i * 30,0)];
				[channelStripView addSubview:item];
			}
		}
	}
}

- (void)run
{
	if(refreshGUITimer)
	{
		[refreshGUITimer invalidate];
	}
	
	if([[self window] isVisible])
	{
		[[AudioEngine sharedAudioEngine] enableVolumeLevelMeasurement:YES];

		refreshGUITimer = [NSTimer timerWithTimeInterval:0.01
												  target:self
												selector:@selector(tick)
												userInfo:nil
												 repeats:YES];

		[[NSRunLoop currentRunLoop] addTimer:refreshGUITimer forMode:NSRunLoopCommonModes];
	}
	else
	{
		[[AudioEngine sharedAudioEngine] enableVolumeLevelMeasurement:NO];
	}

}

- (void)tick
{
	int i;
	
	if(![[AudioEngine sharedAudioEngine] isPlaying] || ![[self window] isVisible])
	{
		[refreshGUITimer invalidate];
		refreshGUITimer = nil;
		for(i=0;i<[meterBridgeChannelStrips count];i++)
		{
			MeterBridgeChannelStrip *strip = [meterBridgeChannelStrips objectAtIndex:i];
			[strip resetDisplay];
		}
	}
	else
	{
		for(i=0;i<[meterBridgeChannelStrips count];i++)
		{
			MeterBridgeChannelStrip *strip = [meterBridgeChannelStrips objectAtIndex:i];
			[strip update];
		}
	}
}


@end
