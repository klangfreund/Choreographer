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
#import "HardwareSettingsWindowController.h"
#import "ProjectAudioSettingsWindowController.h"

#ifdef __cplusplus
#include "Source/AmbisonicsAudioEngine.h"
#endif

@interface AudioEngine : NSObject
{
	#ifdef __cplusplus
	AmbisonicsAudioEngine *ambisonicsAudioEngine;
	#endif
	
	SpeakerSetupWindowController *speakerSetupWindowController;
	MeterBridgeWindowController *meterBridgeWindowController;
    HardwareSettingsWindowController *hardwareSettingsWindowController;
    ProjectAudioSettingsWindowController *projectAudioSettingsWindowController;
    
	IBOutlet NSMenu *menu;
    IBOutlet NSPanel *bounceProgressPanel;
    IBOutlet NSProgressIndicator *bounceProgressIndicator;
    IBOutlet NSTextField *bounceElapsedTimeTextField;

	BOOL isPlaying;
    
    NSURL *bounceURL;
    unsigned long bounceStart, bounceDuration;

	NSUInteger regionIndex;
	NSUInteger volumeLevelMeasurementClientCount;

    NSUInteger selectedOutputDeviceIndex;
}

+ (AudioEngine *)sharedAudioEngine;

- (void)setup;

// Menu (UI Actions)

//- (IBAction)showHardwareSetup:(id)sender;
- (IBAction)showMeterBridge:(id)sender;
- (IBAction)showHardwareSettings:(id)sender;
- (IBAction)showProjectAudioSettings:(id)sender;
- (IBAction)showSpeakerSetup:(id)sender;


// Auxiliary Playback

- (void)audioRegionPreview:(id)region;
- (void)testNoise:(BOOL)enable forChannelatIndex:(NSUInteger)index;

// Transport

- (void)startAudio:(unsigned long)playbackLocation;
- (void)stopAudio;

- (void)setLoopStart:(unsigned long)start end:(unsigned long)end;
- (void)unsetLoop;

- (void)bounceToDisk:(NSURL *)URL start:(NSUInteger)start end:(NSUInteger)end;


// Getter

- (BOOL)isPlaying;
- (unsigned long)playbackLocation;
- (NSUInteger)sampleRate;
- (unsigned short)numberOfSpeakerChannels;
- (unsigned short)numberOfHardwareDeviceOutputChannels;
- (double)cpuUsage;


// Setter

- (void)setMasterVolume:(float)dbValue;


// Project specific audio settings

- (void)setAmbisonicsOrder:(float)order;

- (void)setDistanceBasedAttenuation:(int)type
                     centreZoneSize:(double)cRadius 
                     centreExponent:(double)cExponent
                  centreAttenuation:(double)cAttenuation
                   dBFalloffPerUnit:(double)dBFalloff
                attenuationExponent:(double)exponent;


- (void)setUseHipassFilter:(BOOL)filter;
- (void)setUseDelay:(BOOL)delay;

- (void)setTestNoiseVolume:(float)dbValue;

- (void)setSampleRate:(NSUInteger)sr;



//  Schedule Playback

- (void)addAudioRegion:(id)audioRegion;
- (void)modifyAudioRegion:(id)audioRegion;
- (void)deleteAudioRegion:(id)audioRegion;
- (void)deleteAllAudioRegions;


// Hardware

- (NSArray *)availableOutputDeviceNames;
- (void)setHardwareOutputDevice:(NSString *)deviceName;
- (void)setSelectedOutputDeviceIndex:(NSUInteger)val;
//- (NSString *)nameOfHardwareOutputDevice;
- (NSArray *)availableBufferSizes;
- (void)setBufferSize:(NSUInteger)size;
- (NSUInteger)bufferSize;


//  Speaker Setup

- (void)removeAllSpeakerChannels;
- (void)addSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)validateSpeakerSetup;
//- (void)updateSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)updateParametersForChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)updatePositionForChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;
- (void)updateRoutingForChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index;


//  Level Meter

- (void)volumeLevelMeasurementClient:(BOOL)status;
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
