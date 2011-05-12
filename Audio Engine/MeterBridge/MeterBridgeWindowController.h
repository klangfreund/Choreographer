//
//  MeterBridgeWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 22.12.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MeterBridgeWindowController : NSWindowController
{
	IBOutlet NSView *channelStripView;
	NSMutableArray	*meterBridgeChannelStrips;

	NSTimer			*refreshGUITimer;
}

- (void)updateGUI;

- (void)resetAllPeaks;

- (void)run;
- (void)tick;

@end