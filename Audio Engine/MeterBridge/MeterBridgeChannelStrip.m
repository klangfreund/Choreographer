//
//  MeterBridgeChannelStrip.m
//  Choreographer
//
//  Created by Philippe Kocher on 13.04.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "MeterBridgeChannelStrip.h"
#import "AudioEngine.h"
#import "MeterBridgeWindowController.h"


@implementation MeterBridgeChannelStrip

- (void)update
{
	levelMeterPeakView.level = [[AudioEngine sharedAudioEngine] volumePeakLevel:channelIndex - 1]; 			
	levelMeterView.level = [[AudioEngine sharedAudioEngine] volumeLevel:channelIndex - 1];
	
	if([[AudioEngine sharedAudioEngine] isPlaying])
		levelMeterView.peakLevel = [[AudioEngine sharedAudioEngine] volumeLevel:channelIndex - 1];
	else
		levelMeterView.peakLevel = -100;
}

- (void)resetPeak
{
	[[AudioEngine sharedAudioEngine] resetVolumePeakLevel:channelIndex - 1];
}

- (void)resetAllPeaks
{
	[meterBridgeWindowController resetAllPeaks];
}

@end
