//
//  PatchbayView.h
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpeakerSetups.h"

typedef enum _PatchCordDraggingType
{
	fromChannelToHardware = 1,
	fromHardwareToChannel
} PatchCordDraggingType;

@interface PatchbayView : NSView
{
	SpeakerSetupPreset *speakerSetupPreset;
	
	NSUInteger numberOfOutputChannels;
	NSUInteger numberOfhardwareDeviceOutputChannels;
	NSUInteger expectedNumberOfhardwareDeviceOutputChannels;
		
	int selectedOutputChannel;
	int selectedOutputChannelPin;
	int selectedhardwareDeviceOutputChannelPin;
	int selectedPatchCord;
	
	NSPoint draggingCurrentPosition;
	PatchCordDraggingType patchCordDraggingType;
}

- (void)reset;

- (int)outputPinUnderPoint:(NSPoint)localPoint;
- (int)hardwarePinUnderPoint:(NSPoint)localPoint;
- (int)patchCordUnderPoint:(NSPoint)localPoint;

@end
