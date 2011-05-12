//
//  MeterBridgeChannelStrip.h
//  Choreographer
//
//  Created by Philippe Kocher on 13.04.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LevelMeterView.h"

@interface MeterBridgeChannelStrip : NSObject
{
	IBOutlet LevelMeterView *levelMeterView;
	id meterBridgeWindowController;
	int channelIndex;
}

- (void)update;
- (void)resetPeak;
- (void)resetAllPeaks;
//- (void)resetDisplay;

@end
