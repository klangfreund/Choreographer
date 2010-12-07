//
//  OutputChannelStripController.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpeakerSetups.h"


@interface OutputChannelStripController : NSObjectController
{
	id speakerSetupWindowController;
	SpeakerChannel *speakerChannel;
	int channelIndex;

	BOOL test;
}

- (void)setTest:(BOOL)val;

@end
