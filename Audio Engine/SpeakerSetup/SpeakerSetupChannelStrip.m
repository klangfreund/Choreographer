//
//  SpeakerSetupChannelStrip.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "SpeakerSetupChannelStrip.h"
#import "SpeakerSetupWindowController.h"

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

// text field delegate method
// remove fokus when user hits return/enter
//- (void)controlTextDidEndEditing:(NSNotification *)notification
//{
//	NSLog(@"controlTextDidEndEditing");
//	[[[notification object] window] performSelectorOnMainThread:@selector(makeFirstResponder:) withObject:nil waitUntilDone:NO];
//}	
	
	

@end
