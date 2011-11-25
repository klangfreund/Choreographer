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


#pragma mark -
#pragma mark window
// -----------------------------------------------------------

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self run];

	[[AudioEngine sharedAudioEngine] volumeLevelMeasurementClient:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[refreshGUITimer invalidate];
	refreshGUITimer = nil;

	[[AudioEngine sharedAudioEngine] volumeLevelMeasurementClient:NO];
}

#pragma mark -
#pragma mark update gui
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
	[[self window] setContentMaxSize:NSMakeSize(r.size.width, FLT_MAX)];
	[[self window] setContentMinSize:NSMakeSize(r.size.width, 200)];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		MeterBridgeChannelStrip *strip = [[[MeterBridgeChannelStrip alloc] init] autorelease];
		NSArray *theArray;
		
		[meterBridgeChannelStrips addObject:strip];
		
		[strip setValue:self forKey:@"meterBridgeWindowController"];
		[strip setValue:[NSNumber numberWithInt:i + 1] forKey:@"channelIndex"];
		
		[nib instantiateNibWithOwner:strip topLevelObjects:&theArray];

		for(item in theArray)
		{
			if([item isKindOfClass:[NSView class]])
			{
				r = [item frame];
				r.origin = NSMakePoint(i * 30,0);
				r.size.height = [channelStripView frame].size.height;
				[item setFrame:r];
				
				[channelStripView addSubview:item];
			}
		}
	}


	[[AudioEngine sharedAudioEngine] enableVolumeLevelMeasurement:YES];
}


- (void)resetAllPeaks
{
	int i;

	for(i=0;i<[meterBridgeChannelStrips count];i++)
	{
		MeterBridgeChannelStrip *strip = [meterBridgeChannelStrips objectAtIndex:i];
		[strip resetPeak];
		[strip update];
	}
}

- (void)run
{
	if(refreshGUITimer)
	{
		[refreshGUITimer invalidate];
	}
	
	refreshGUITimer = [NSTimer timerWithTimeInterval:0.05
											  target:self
											selector:@selector(tick)
											userInfo:nil
											 repeats:YES];

	[[NSRunLoop currentRunLoop] addTimer:refreshGUITimer forMode:NSRunLoopCommonModes];
}

- (void)tick
{
	int i;
	
	for(i=0;i<[meterBridgeChannelStrips count];i++)
	{
		MeterBridgeChannelStrip *strip = [meterBridgeChannelStrips objectAtIndex:i];
		[strip update];
	}
}


@end