//
//  SpeakerSetupChannelStrip.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpeakerSetups.h"


@interface SpeakerSetupChannelStrip : NSObjectController
{
	id speakerSetupWindowController;
	SpeakerChannel *speakerChannel;
	int channelIndex;

	BOOL test;
}

- (void)setTest:(BOOL)val;

@end
