//
//  AudioEngine.h
//  Choreographer
//
//  Created by Philippe Kocher on 28.03.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SpatialPosition.h"
#import "SpeakerSetupWindowController.h"

#ifdef __cplusplus
#include "AmbisonicsAudioEngine.h"
#endif

@interface AudioEngine : NSObject
{
	#ifdef __cplusplus
	AmbisonicsAudioEngine *ambisonicsAudioEngine;
	#endif
	
	SpeakerSetupWindowController *speakerSetupWindowController;
	
	IBOutlet NSMenu *menu;

	unsigned int regionIndex;
	
	BOOL isPlaying;
}

+ (AudioEngine *)sharedAudioEngine;

- (void)setup;

// Menu (UI Actions)
- (IBAction)showHardwareSetup:(id)sender;
- (IBAction)showSpeakerSetup:(id)sender;


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
- (void)updateSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;


// Settings

- (void)setPersistentSetting:(id)data forKey:(NSString *)key;
- (id)persistentSettingForKey:(NSString *)key;


//  Real Time
/*
- (void)setVolume:(float)volume forVoice:(unsigned int)voice;
- (void)setPosition:(Position *)position forVoice:(unsigned int)voice;
*/

@end
