//
//  OutputChannelStripController.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "OutputChannelStripController.h"
#import "SpeakerSetupWindowController.h"

@implementation OutputChannelStripController

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

@end
