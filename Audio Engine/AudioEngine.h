//
//  AudioEngine.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.03.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SpatialPosition.h"
#import "SpeakerSetupWindowController.h"
#import "MeterBridgeWindowController.h"

#ifdef __cplusplus
#include "AmbisonicsAudioEngine.h"
#endif

@interface AudioEngine : NSObject
{
	#ifdef __cplusplus
	AmbisonicsAudioEngine *ambisonicsAudioEngine;
	#endif
	
	SpeakerSetupWindowController *speakerSetupWindowController;
	MeterBridgeWindowController *meterBridgeWindowController;
	
	IBOutlet NSMenu *menu;

	BOOL isPlaying;

	NSUInteger regionIndex;
	NSUInteger volumeLevelMeasurementClientCount;
}

+ (AudioEngine *)sharedAudioEngine;

- (void)setup;

// Menu (UI Actions)
- (IBAction)showHardwareSetup:(id)sender;
- (IBAction)showSpeakerSetup:(id)sender;
- (IBAction)showMeterBridge:(id)sender;


// Auxiliary Playback

- (void)audioRegionPreview:(id)region;
- (void)testNoise:(BOOL)enable forChannelatIndex:(NSUInteger)index;

// Transport

- (void)startAudio:(unsigned long)playbackLocation;
- (void)stopAudio;

- (void)setLoopStart:(unsigned long)start end:(unsigned long)end;
- (void)unsetLoop;


// Getter

- (BOOL)isPlaying;
- (unsigned long)playbackLocation;
- (unsigned int)sampleRate;
- (unsigned short)numberOfSpeakerChannels;
- (unsigned short)numberOfHardwareDeviceOutputChannels;
- (NSString *)nameOfHardwareOutputDevice;
- (double)cpuUsage;


// Setter

- (void)setMasterVolume:(float)dbValue;

- (void)setAmbisonicsOrder:(short)order;
- (void)setdBUnit:(double)unit;

- (void)setUseHipassFilter:(BOOL)filter;
- (void)setUseDelay:(BOOL)delay;


//  Schedule Playback

- (void)addAudioRegion:(id)audioRegion;
- (void)modifyAudioRegion:(id)audioRegion;
- (void)deleteAudioRegion:(id)audioRegion;
- (void)deleteAllAudioRegions;


//  Speaker Setup

- (void)removeAllSpeakerChannels;
- (void)addSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)validateSpeakerSetup;
//- (void)updateSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)updateParametersForChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)updateRoutingForChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;


//  Level Meter

- (void)volumeLevelMeasurementClient:(BOOL)val;
- (void)enableVolumeLevelMeasurement:(BOOL)val;
- (void)resetVolumePeakLevel:(NSUInteger)channel;
- (float)volumeLevel:(NSUInteger)channel;
- (float)volumePeakLevel:(NSUInteger)channel;


//  Settings

- (void)setPersistentSetting:(id)data forKey:(NSString *)key;
- (id)persistentSettingForKey:(NSString *)key;


//  Real Time
/*
- (void)setVolume:(float)volume forVoice:(unsigned int)voice;
- (void)setPosition:(Position *)position forVoice:(unsigned int)voice;
*/

@end
