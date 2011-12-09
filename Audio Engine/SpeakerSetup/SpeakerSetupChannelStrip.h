//
//  SpeakerSetupChannelStrip.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpeakerSetups.h"
#import "LevelMeterView.h"


@interface SpeakerSetupChannelStrip : NSObjectController
{
	IBOutlet LevelMeterView *levelMeterView;

	id speakerSetupWindowController;
	SpeakerChannel *speakerChannel;
	int channelIndex;

	BOOL test;
}

- (void)setTest:(BOOL)val;
- (void)update;

@end
