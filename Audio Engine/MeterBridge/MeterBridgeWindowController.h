//
//  MeterBridgeWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 22.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MeterBridgeWindowController : NSWindowController
{
	IBOutlet NSView *meterBridgeView;
	NSMutableArray *meterBridgeChannelStripControllers;
}

+ (id)sharedMeterBridgeWindowController;

- (void)updateGUI;

@end
