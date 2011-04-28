//
//  SpeakerSetups.h
//  Choreographer
//
//  Created by Philippe Kocher on 06.10.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpatialPosition.h"


@interface SpeakerChannel : NSObject
{
	float dbGain;
	
	BOOL solo;
	BOOL mute;

	SpatialPosition *position;
	
	float delay;	

	int hardwareDeviceOutputChannel;
	
	id observer;
}

@property float dbGain;
@property BOOL solo, mute;
@property (assign) SpatialPosition *position;
@property int hardwareDeviceOutputChannel;



- (void)registerObserver:(id)object;
- (void)unregisterObserver:(id)object;


@end

@interface SpeakerSetupPreset : NSObject
{
	NSString *name;
	NSString *displayedName;
	NSMutableArray *speakerChannels;
	
	BOOL dirty;
}

- (void)synchronizeWith:(SpeakerSetupPreset *)preset;

// actions
- (void)newSpeakerChannel;
- (void)addSpeakerChannel:(SpeakerChannel *)channel;
- (void)removeSpeakerChannelAtIndex:(NSUInteger)i;

// update engine
- (void)updateEngine;
- (void)updateEngineForChannel:(SpeakerChannel *)channel;
- (void)updateEngineRoutingForChannel:(SpeakerChannel *)channel;

// accessors
- (void)setName:(NSString *)string;
- (void)setDirty:(BOOL)val;
- (NSUInteger)countSpeakerChannels;
- (NSArray *)speakerChannels;
- (SpeakerChannel *)speakerChannelAtIndex:(NSUInteger)i;

@end

@interface SpeakerSetups : NSObject
{
	NSMutableArray *presets;
	NSMutableArray *storedPresets;
	
	NSUInteger selectedIndex;
}

// serialisation
- (void)archiveData;
- (void)unarchiveData;

// import / export
- (void)exportDataAsXML:(NSURL *)url;
- (void)importXMLData:(NSArray*)filenames;

// actions
- (void)addPreset:(SpeakerSetupPreset *)preset;
- (void)deleteSelectedPreset;

- (void)saveSelectedPreset;
- (void)selectedPresetRevertToSaved;
- (void)saveAllPresets;
- (void)discardAllChanges;

// accessors
- (void)setSelectedIndex:(NSUInteger)index;
- (SpeakerSetupPreset *)selectedPreset;
- (BOOL)dirtyPresets;

// misc
- (NSMutableArray *)copyPreset:(NSArray *)presetArray;

@end
