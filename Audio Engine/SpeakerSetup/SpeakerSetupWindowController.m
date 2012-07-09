//
//  SpeakerSetupWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "SpeakerSetupWindowController.h"
#import "SpeakerSetups.h"
#import "SpeakerSetupChannelStrip.h"
#import "AudioEngine.h"


@implementation SpeakerSetupWindowController

@synthesize availableOutputDeviceNames;

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)init
{
	self = [self initWithWindowNibName:@"SpeakerSetupWindow"];
	if(self)
	{		
        audioEngine = [AudioEngine sharedAudioEngine];
		speakerSetups = [[SpeakerSetups alloc] init];
		[speakerSetups unarchiveData];
		[[speakerSetups selectedPreset] updateEngine];
		selectedIndex = [[speakerSetups valueForKey:@"selectedIndex"] unsignedIntValue];
		selectedSetup = [speakerSetups selectedPreset];

		[self setWindowFrameAutosaveName:@"SpeakerSetupWindow"];
		testNoiseChannel = -1;
	}

	return self;
}
		
- (void)awakeFromNib
{
    [self setValue:[speakerSetups selectedPreset] forKey:@"selectedSetup"];		// needed to enable bindings
	[self updateGUI];
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateGUI)
												 name:@"hardwareDidChange" object:nil];		
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];	

    [speakerSetups release];
	[speakerSetupChannelStripControllers release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark window
// -----------------------------------------------------------

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self run];

	[[AudioEngine sharedAudioEngine] volumeLevelMeasurementClient:YES];
    
    [self updateGUI];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[refreshGUITimer invalidate];
	refreshGUITimer = nil;
	
	[[AudioEngine sharedAudioEngine] volumeLevelMeasurementClient:NO];
}


#pragma mark -
#pragma mark update gui
// -----------------------------------------------------------

- (void)setSelectedIndex:(NSUInteger)index
{
	if(index != selectedIndex)
	{
		selectedIndex = index;
		[speakerSetups setValue:[NSNumber numberWithUnsignedInt:selectedIndex] forKey:@"selectedIndex"];
	
		[self setValue:[speakerSetups selectedPreset] forKey:@"selectedSetup"];
	
		// send notification
		[[NSNotificationCenter defaultCenter] postNotificationName:@"hardwareDidChange" object:self];
	}
}


- (void)updateGUI
{
	// stop any running test noise

	if(testNoiseChannel > -1)
		[[speakerSetupChannelStripControllers objectAtIndex:testNoiseChannel] setValue:[NSNumber numberWithBool:NO] forKey:@"test"];

    
    // remove all channel strips

	[speakerSetupChannelStripControllers release];
	
	NSArray *subviews = [[[patchbayView subviews] copy] autorelease];
	for(NSView *view in subviews)
	{
		[view removeFromSuperview];
	}
	
	// patchbay view settings
	
	NSUInteger numberOfOutputChannels = [[speakerSetups selectedPreset] countSpeakerChannels];
	NSUInteger numberOfhardwareDeviceOutputChannels = [[AudioEngine sharedAudioEngine] numberOfHardwareDeviceOutputChannels];
	NSUInteger expectedNumberOfhardwareDeviceOutputChannels = 0;
	
	for(SpeakerChannel *channel in [[speakerSetups selectedPreset] speakerChannels])
	{
		if([[channel valueForKey:@"hardwareDeviceOutputChannel"] intValue] + 1 > expectedNumberOfhardwareDeviceOutputChannels)
			expectedNumberOfhardwareDeviceOutputChannels = [[channel valueForKey:@"hardwareDeviceOutputChannel"] intValue] + 1;
	}
		
		
	[patchbayView reset];
	[patchbayView setValue:[speakerSetups selectedPreset] forKey:@"speakerSetupPreset"];
	[patchbayView setValue:[NSNumber numberWithInt:numberOfOutputChannels] forKey:@"numberOfOutputChannels"];
	[patchbayView setValue:[NSNumber numberWithInt:numberOfhardwareDeviceOutputChannels] forKey:@"numberOfhardwareDeviceOutputChannels"];
	[patchbayView setValue:[NSNumber numberWithInt:expectedNumberOfhardwareDeviceOutputChannels] forKey:@"expectedNumberOfhardwareDeviceOutputChannels"];

	
	// add the speaker channels

	NSNib* nib = [[[NSNib alloc] initWithNibNamed:@"SpeakerSetupChannelStrip" bundle:nil] autorelease];
	
	NSRect r = [patchbayView frame];
	id item;
	int i;
	
	speakerSetupChannelStripControllers = [[NSMutableArray alloc] init];

	unsigned short maxNumberOfChannels = numberOfOutputChannels > numberOfhardwareDeviceOutputChannels ? numberOfOutputChannels : numberOfhardwareDeviceOutputChannels;
	r.size.height = maxNumberOfChannels * 25 + 6;
	[patchbayView setFrame:r];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		SpeakerSetupChannelStrip *controller = [[[SpeakerSetupChannelStrip alloc] init] autorelease];
		NSArray *theArray;

		[speakerSetupChannelStripControllers addObject:controller];
		
		[controller setValue:self forKey:@"speakerSetupWindowController"];
		[controller setValue:[NSNumber numberWithInt:i] forKey:@"channelIndex"];
		[controller setValue:[[speakerSetups selectedPreset] speakerChannelAtIndex:i] forKey:@"speakerChannel"];
		
		[nib instantiateNibWithOwner:controller topLevelObjects:&theArray];

		for(item in theArray)
		{
			if([item isKindOfClass:[NSView class]])
			{
				[item setFrameOrigin:NSMakePoint(0, i * 25 + 5)];
				[patchbayView addSubview:item];
			}
		}
	}
	
	[patchbayView setNeedsDisplay:YES];

}

- (void)testNoise:(BOOL)enable channelIndex:(int)index
{
	if(!enable)
	{
		[[AudioEngine sharedAudioEngine] testNoise:NO forChannelatIndex:testNoiseChannel];
		testNoiseChannel = -1;
	}
	else
	{
		if(testNoiseChannel > -1)
		{
			[[AudioEngine sharedAudioEngine] testNoise:NO forChannelatIndex:testNoiseChannel];
			[[speakerSetupChannelStripControllers objectAtIndex:testNoiseChannel] setValue:[NSNumber numberWithBool:NO] forKey:@"test"];
		}

		testNoiseChannel = index;
		[[AudioEngine sharedAudioEngine] testNoise:YES forChannelatIndex:testNoiseChannel];
	}
}

//- (void)resetAllPeaks
//{
//	int i;
//	
//	for(i=0;i<[speakerSetupChannelStripControllers count];i++)
//	{
//		SpeakerSetupChannelStrip *strip = [speakerSetupChannelStripControllers objectAtIndex:i];
//		[strip resetPeak];
//		[strip update];
//	}
//}

- (void)run
{
	if(refreshGUITimer)
	{
		[refreshGUITimer invalidate];
	}
		
	refreshGUITimer = [NSTimer timerWithTimeInterval:0.05
											  target:self
											selector:@selector(tick)
											userInfo:nil
											 repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:refreshGUITimer forMode:NSRunLoopCommonModes];
}

- (void)tick
{
	int i;
	
	for(i=0;i<[speakerSetupChannelStripControllers count];i++)
	{
		SpeakerSetupChannelStrip *strip = [speakerSetupChannelStripControllers objectAtIndex:i];
		[strip update];
	}
}


#pragma mark -
#pragma mark window delegate methods
// -----------------------------------------------------------

- (BOOL)windowShouldClose:(NSNotification *)notification
{
	if([speakerSetups dirtyPresets])
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"There are unsaved speaker setup presets"
										 defaultButton:@"Save All"
									   alternateButton:@"Cancel"
										   otherButton:@"Discard Changes"
							 informativeTextWithFormat:@"%@",[[speakerSetups selectedPreset] valueForKey:@"name"]];

		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(unsavedPresetsAlertDidEnd: returnCode: contextInfo:)
							contextInfo:nil];

		return NO;
	}
	
	return YES;
}

- (void)unsavedPresetsAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSCancelButton) return;
	
	
	if(returnCode == NSOKButton)
	{
		[speakerSetups saveAllPresets];
	}
	else
	{
		[speakerSetups discardAllChanges];	
	}

	[[self window] close];
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

- (void)addSpeakerChannel
{
	[[speakerSetups selectedPreset] newSpeakerChannel];

	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"hardwareDidChange" object:self];
}

- (void)removeSpeakerChannel
{
	int i = [[patchbayView valueForKey:@"selectedOutputChannel"] intValue];
	
	if(-1 == i)
	{
		// if no channel is selected remove the last one
		i = [[speakerSetups selectedPreset] countSpeakerChannels] - 1;
	}

	if(-1 != i)
	{
		// only if there is at least one channel
		[[speakerSetups selectedPreset] removeSpeakerChannelAtIndex:i];

		// send notification
		[[NSNotificationCenter defaultCenter] postNotificationName:@"hardwareDidChange" object:self];
	}
}

- (void)newPreset
{	
	// initalize a new setup
	
	tempSetupPreset = [[SpeakerSetupPreset alloc] init];
	[tempSetupPreset setValue:@"Untitled Speaker Setup" forKey:@"name"];
								   
	// show the rename sheet
	
	[self setValue:@"New Speaker Setup Preset" forKey:@"renameSheetMessage"];
	[self setValue:@"New" forKey:@"renameSheetOkButtonText"];
	[self setValue:@"Untitled Speaker Setup"
			forKey:@"renameSheetTextInput"];
	
	[NSApp beginSheet:renameSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(renameSheetDidEnd: returnCode: contextInfo:)
		  contextInfo:nil];
}

- (void)renamePreset
{
	[self setValue:@"Rename Speaker Setup Preset" forKey:@"renameSheetMessage"];
	[self setValue:@"Rename" forKey:@"renameSheetOkButtonText"];

	[self setValue:nil forKey:@"renameSheetTextInput"]; // reset text input (necessary to update text box in gui) 
	
	[self setValue:[[speakerSetups selectedPreset] valueForKey:@"name"]
			forKey:@"renameSheetTextInput"];
	
	[NSApp beginSheet:renameSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(renameSheetDidEnd: returnCode: contextInfo:)
		  contextInfo:nil];
}

- (void)copyPreset
{
	// copy the currently selected setup
	
	tempSetupPreset = [[[speakerSetups selectedPreset] copy] retain];
	
	[tempSetupPreset setValue:[NSString stringWithFormat:@"%@ Copy",[tempSetupPreset valueForKey:@"name"]]
					   forKey:@"name"];
	

	// show the rename sheet
	
	[self setValue:@"Copy Speaker Setup Preset" forKey:@"renameSheetMessage"];
	[self setValue:@"Copy" forKey:@"renameSheetOkButtonText"];
	[self setValue:[tempSetupPreset valueForKey:@"name"]
			forKey:@"renameSheetTextInput"];

	[NSApp beginSheet:renameSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(renameSheetDidEnd: returnCode: contextInfo:)
		  contextInfo:nil];
}

- (void)renameSheetOK
{
	[NSApp endSheet:renameSheet returnCode:NSOKButton];
	[renameSheet orderOut:nil];
}

- (void)renameSheetCancel
{
	[NSApp endSheet:renameSheet returnCode:NSCancelButton];
	[renameSheet orderOut:nil];
}

- (void)renameSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		if(tempSetupPreset) // copy and new
		{
			[tempSetupPreset setValue:renameSheetTextInput forKey:@"name"];
			[speakerSetups addPreset:tempSetupPreset];
			[tempSetupPreset release];
			tempSetupPreset = nil;
		}
		else // rename
		{
			[[speakerSetups selectedPreset] setValue:renameSheetTextInput forKey:@"name"];
		}

		// update the popup button whose selection is bound to selectedSetupIndex 
		[self setValue:[speakerSetups valueForKey:@"selectedIndex"] forKey:@"selectedIndex"];
	}
}


- (void)deletePreset
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Do you really want to delete the speaker setup preset"
									 defaultButton:@"Delete"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"%@",[[speakerSetups selectedPreset] valueForKey:@"name"]];
	
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteAlertDidEnd: returnCode: contextInfo:)
						contextInfo:nil];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		[speakerSetups deleteSelectedPreset];

		// update the popup button whose selection is bound to selectedSetupIndex 
		[self setValue:[speakerSetups valueForKey:@"selectedIndex"] forKey:@"selectedIndex"];
	}
}


- (void)import
{
	// choose audio file in an open panel
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [NSArray arrayWithObjects: @"xml", NULL];
	
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowedFileTypes:fileTypes];
	
	[openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            [speakerSetups importXMLData:[openPanel URLs]];
            [openPanel orderOut:self];
        }
	}];
}

- (void)export
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];

	//    [savePanel setAllowsMultipleSelection:NO];

    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            [speakerSetups exportDataAsXML:[savePanel URL]];
            [savePanel orderOut:self];
        }
    }];
}

- (void)saveSelectedPreset
{
	[speakerSetups saveSelectedPreset];
}

- (void)saveSelectedPresetAs
{
	// copy the currently selected setup
	
	tempSetupPreset = [[[speakerSetups selectedPreset] copy] retain];
	[tempSetupPreset setValue:@"Untitled Speaker Setup" forKey:@"name"];
	
	
	// show the rename sheet
	
	[self setValue:@"Save Speaker Setup Preset as" forKey:@"renameSheetMessage"];
	[self setValue:@"Save" forKey:@"renameSheetOkButtonText"];
	[self setValue:[tempSetupPreset valueForKey:@"name"]
			forKey:@"renameSheetTextInput"];
	
	[NSApp beginSheet:renameSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(saveAsSheetDidEnd: returnCode: contextInfo:)
		  contextInfo:nil];
}

- (void)saveAsSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		[speakerSetups selectedPresetRevertToSaved];
		
		[tempSetupPreset setValue:renameSheetTextInput forKey:@"name"];
		[speakerSetups addPreset:tempSetupPreset];
		[tempSetupPreset release];
		tempSetupPreset = nil;
		
		// update the popup button whose selection is bound to selectedSetupIndex 
		[self setValue:[speakerSetups valueForKey:@"selectedIndex"] forKey:@"selectedIndex"];

		// send notification
		[[NSNotificationCenter defaultCenter] postNotificationName:@"hardwareDidChange" object:self];
	}
}

- (void)selectedPresetRevertToSaved
{
	[speakerSetups selectedPresetRevertToSaved];

	// update the popup button whose selection is bound to selectedSetupIndex 
	[self setValue:[speakerSetups valueForKey:@"selectedIndex"] forKey:@"selectedIndex"];

	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"hardwareDidChange" object:self];
}

- (void)saveAllPresets
{
	[speakerSetups saveAllPresets];
}


@end
