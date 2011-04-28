//
//  MeterBridgeWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 22.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MeterBridgeWindowController.h"
#import "SpeakerSetupWindowController.h"
#import "AudioEngine.h"

@implementation MeterBridgeWindowController

static MeterBridgeWindowController *sharedMeterBridgeWindowController = nil;

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

+ (id)sharedMeterBridgeWindowController
{
    if (!sharedMeterBridgeWindowController)
	{
        sharedMeterBridgeWindowController = [[MeterBridgeWindowController alloc] init];
    }
    return sharedMeterBridgeWindowController;
}

- (id)init
{
	self = [self initWithWindowNibName:@"MeterBridgeWindow"];
	if(self)
	{
		[self setWindowFrameAutosaveName:@"MeterBridgeWindow"];
	}
	return self;
}

- (void)awakeFromNib
{
	[self updateGUI];
}

- (void) dealloc
{
	[meterBridgeChannelStripControllers release];
	[super dealloc];
}

#pragma mark -
#pragma mark refresh gui
// -----------------------------------------------------------

- (void)updateGUI
{
	NSLog(@"Meter Bridge Window Controller: update GUI");

	// remove all channel strips

	[meterBridgeChannelStripControllers release];

	// add new channel strips

	NSUInteger numberOfOutputChannels =  [[[SpeakerSetupWindowController sharedSpeakerSetupWindowController] valueForKey:@"selectedSetup"] countSpeakerChannels];

	NSNib* nib = [[NSNib alloc] initWithNibNamed:@"MeterBridgeChannelStrip" bundle:nil] ;
	
	NSRect r = [meterBridgeView frame];
	id item;
	int i;
	
	meterBridgeChannelStripControllers = [[NSMutableArray alloc] init];
	
	r.size.width = numberOfOutputChannels * 50;
	[meterBridgeView setFrame:r];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		NSObjectController *controller = [[[NSObjectController alloc] init] autorelease];
		NSArray *theArray;
		
		[meterBridgeChannelStripControllers addObject:controller];
		
//		[controller setValue:self forKey:@"speakerSetupWindowController"];
//		[controller setValue:[NSNumber numberWithInt:i] forKey:@"channelIndex"];
		
		[nib instantiateNibWithOwner:controller topLevelObjects:&theArray];

		for(item in theArray)
		{
			if([item isKindOfClass:[NSView class]])
			{
				[item setFrameOrigin:NSMakePoint(i * 50,0)];
				[meterBridgeView addSubview:item];
			}
		}
	}
}	

@end
