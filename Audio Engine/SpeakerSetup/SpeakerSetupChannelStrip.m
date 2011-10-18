//
//  SpeakerSetupChannelStrip.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SpeakerSetupChannelStrip.h"
#import "SpeakerSetupWindowController.h"
#import "AudioEngine.h"

@implementation SpeakerSetupChannelStrip

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		speakerChannel = nil;
	}
	return self;
}

- (void)setTest:(BOOL)val
{
	[speakerSetupWindowController testNoise:val channelIndex:channelIndex];
	test = val;
}

- (void)update
{
//	levelMeterView.peakLevel = [[AudioEngine sharedAudioEngine] volumePeakLevel:channelIndex]; 			
	levelMeterView.level = [[AudioEngine sharedAudioEngine] volumeLevel:channelIndex];
}

@end
