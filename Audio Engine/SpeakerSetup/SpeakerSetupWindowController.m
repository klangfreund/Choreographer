//
//  SpeakerSetupWindowController.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.09.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "SpeakerSetupWindowController.h"
#import "SpeakerSetups.h"
#import "OutputChannelStripController.h"
#import "AudioEngine.h"


@implementation SpeakerSetupWindowController

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)init
{
	self = [self initWithWindowNibName:@"SpeakerSetupWindow"];
	if(self)
	{
		speakerSetups = [[SpeakerSetups alloc] init];
		[speakerSetups unarchiveData];
		[[speakerSetups selectedPreset] updateEngine];
		selectedIndex = [[speakerSetups valueForKey:@"selectedIndex"] unsignedIntValue];

		[self setWindowFrameAutosaveName:@"SpeakerSetupWindow"];
		testNoiseChannel = -1;
	}
	return self;
}
		
- (void)awakeFromNib
{
	[self setValue:[NSNumber numberWithUnsignedInt:selectedIndex] forKey:@"selectedIndex"]; // init popup button
	[self updateGUI];
}

- (void) dealloc
{
	[speakerSetups release];
	[outputChannelStripControllers release];
	[super dealloc];
}


#pragma mark -
#pragma mark refresh gui
// -----------------------------------------------------------

- (void)setSelectedIndex:(NSUInteger)index
{
	if(index != selectedIndex)
	{
		selectedIndex = index;
		[speakerSetups setValue:[NSNumber numberWithUnsignedInt:selectedIndex] forKey:@"selectedIndex"];
	
		[self setValue:[speakerSetups selectedPreset] forKey:@"selectedSetup"];
	
		[self updateGUI];
	}
}


- (void)updateGUI
{
	[hardwareOutputTextField setStringValue:[[AudioEngine sharedAudioEngine] nameOfHardwareOutputDevice]];
	
	// stop any running test noise

	if(testNoiseChannel > -1)
		[[outputChannelStripControllers objectAtIndex:testNoiseChannel] setValue:[NSNumber numberWithBool:NO] forKey:@"test"];

	// remove all channel strips

	[outputChannelStripControllers release];
	
	NSArray *subviews = [[patchbayView subviews] copy];
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

	NSNib* nib = [[NSNib alloc] initWithNibNamed:@"OutputChannelStrip" bundle:nil] ;
	
	NSRect r = [patchbayView frame];
	id item;
	int i;
	
	outputChannelStripControllers = [[NSMutableArray alloc] init];

	unsigned short maxNumberOfChannels = numberOfOutputChannels > numberOfhardwareDeviceOutputChannels ? numberOfOutputChannels : numberOfhardwareDeviceOutputChannels;
	r.size.height = maxNumberOfChannels * 25 + 6;
	[patchbayView setFrame:r];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		OutputChannelStripController *controller = [[[OutputChannelStripController alloc] init] autorelease];
		NSArray *theArray;

		[outputChannelStripControllers addObject:controller];
		
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
			[[outputChannelStripControllers objectAtIndex:testNoiseChannel] setValue:[NSNumber numberWithBool:NO] forKey:@"test"];
			[[AudioEngine sharedAudioEngine] testNoise:NO forChannelatIndex:testNoiseChannel];
		}

		testNoiseChannel = index;
		[[AudioEngine sharedAudioEngine] testNoise:YES forChannelatIndex:testNoiseChannel];
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
	[self updateGUI];
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
		[self updateGUI];
	}
}

- (void)newPreset
{
	NSLog(@"new");
	
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
	NSLog(@"rename");

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
	NSLog(@"copy");

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
	NSLog(@"delete");

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
	NSLog(@"import");

	// choose audio file in an open panel
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [NSArray arrayWithObjects: @"xml", NULL];
	
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
	
	[openPanel beginSheetForDirectory:nil
								 file:nil
								types:fileTypes
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(importPanelDidEnd:
												returnCode:
												contextInfo:)
						  contextInfo:nil];
}

- (void)importPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		NSLog(@"...do import");
		[speakerSetups importXMLData:[openPanel filenames]];
	}
}

- (void)export
{
	NSLog(@"export");

	NSSavePanel *savePanel = [NSSavePanel savePanel];

	//    [savePanel setAllowsMultipleSelection:NO];

	[savePanel beginSheetForDirectory:nil
								 file:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(exportPanelDidEnd:
												returnCode:
												contextInfo:)
						  contextInfo:nil];
}

- (void)exportPanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		[speakerSetups exportDataAsXML:[savePanel URL]];
	}
}

- (void)saveSelectedPreset
{
	[speakerSetups saveSelectedPreset];
}

- (void)saveSelectedPresetAs
{
	NSLog(@"saveSelectedPresetAs");
	
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

		[self updateGUI];
	}
}

- (void)selectedPresetRevertToSaved
{
	[speakerSetups selectedPresetRevertToSaved];

	// update the popup button whose selection is bound to selectedSetupIndex 
	[self setValue:[speakerSetups valueForKey:@"selectedIndex"] forKey:@"selectedIndex"];

	[self updateGUI];
}

- (void)saveAllPresets
{
	[speakerSetups saveAllPresets];
}


@end
