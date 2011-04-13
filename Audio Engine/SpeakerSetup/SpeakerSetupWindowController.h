//
//  SpeakerSetupWindowController.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.09.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpeakerSetupWindowController.h"
#import "PatchbayView.h"


@interface SpeakerSetupWindowController : NSWindowController
{
	id speakerSetups;
	NSUInteger selectedIndex;
	id selectedSetup;
	
	IBOutlet NSPopUpButton *setupChoicePopupButton;
	IBOutlet PatchbayView *patchbayView;
	IBOutlet NSTextField *hardwareOutputTextField;
	
	// rename, copy, new
	IBOutlet NSPanel *renameSheet;
	NSString *renameSheetOkButtonText;
	NSString *renameSheetMessage;
	NSString *renameSheetTextInput;
	id tempSetupPreset;
	
	NSMutableArray *speakerSetupChannelStripControllers;

	int testNoiseChannel;
}

+ (id)sharedSpeakerSetupWindowController;

- (void)setSelectedIndex:(NSUInteger)index;
- (void)updateGUI;
- (void)testNoise:(BOOL)enable channelIndex:(int)index;

// window delegate methods
- (void)unsavedPresetsAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

// actions
- (void)addSpeakerChannel;
- (void)removeSpeakerChannel;

- (void)newPreset;
- (void)renamePreset;
- (void)copyPreset;
- (void)renameSheetOK;
- (void)renameSheetCancel;
- (void)renameSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)deletePreset;
- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (void)import;
- (void)importPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)export;
- (void)exportPanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;


- (void)saveSelectedPreset;
- (void)saveSelectedPresetAs;
- (void)saveAsSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)selectedPresetRevertToSaved;
- (void)saveAllPresets;

@end
