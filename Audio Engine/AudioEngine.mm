//
//  AudioEngine.m
//  Choreographer
//
//  Created by Philippe Kocher on 28.03.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "AudioEngine.h"


@interface AudioEngine ()

// private methods
- (void)setGainAutomation:(id)audioRegion;
- (void)setSpatialAutomation:(id)audioRegion;

@end




@implementation AudioEngine

static AudioEngine *sharedAudioEngine = nil;


+ (AudioEngine *)sharedAudioEngine
{
    if (!sharedAudioEngine)
	{
        sharedAudioEngine = [[AudioEngine alloc] init];
		[sharedAudioEngine setup];
    }
    return sharedAudioEngine;
}

+ (void)release
{
	[sharedAudioEngine release];
    sharedAudioEngine = nil;
}


- (id) init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)setup
{
	[NSBundle loadNibNamed:@"AudioEngineMainMenu" owner:self];
	
	// insert a menu item in the application's main menu
	NSMenuItem *newItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
	[newItem setSubmenu:menu];
	
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSInteger index = [mainMenu numberOfItems] - 2;
	
	[mainMenu insertItem:newItem atIndex:index];
	
	// Juce
	initialiseJuce_GUI();
	
	// instantiate ambisonicsAudioEngine
	ambisonicsAudioEngine = new AmbisonicsAudioEngine();
	
	// instantiate the Speaker Setup Window
	speakerSetupWindowController = [[SpeakerSetupWindowController alloc] init];
	
	regionIndex = 0;	
}

- (void)dealloc
{
	delete ambisonicsAudioEngine;

	[speakerSetupWindowController release];
	[super dealloc];
}


#pragma mark -
#pragma mark Menu (UI Actions)
// -----------------------------------------------------------

- (IBAction)showHardwareSetup:(id)sender
{
	[self stopAudio];
	
	ambisonicsAudioEngine->showAudioSettingsWindow();
}

- (IBAction)showSpeakerSetup:(id)sender
{	
	[speakerSetupWindowController showWindow:nil];
}


#pragma mark -
#pragma mark auxiliary playback
// -----------------------------------------------------------

- (void)audioRegionPreview:(id)region;
{
	// play a single audio region
	// output through physical channels 1 + 2
}

- (void)testNoise:(BOOL)enable forChannelatIndex:(NSUInteger)index
{
	NSLog(@"test noise %i in channel %i", enable, index);
	ambisonicsAudioEngine->activatePinkNoise(index, enable);
}

#pragma mark -
#pragma mark transport
// -----------------------------------------------------------

- (void)startAudio:(unsigned long)value
{
	// [value] = milliseconds.
	// [value * 0.001] = seconds.
	int positionInSamples = (int)(ambisonicsAudioEngine->getCurrentSampleRate() * 0.001 * (double)value);
	ambisonicsAudioEngine->setPosition(positionInSamples);
	isPlaying = YES;
	
	ambisonicsAudioEngine->start();
}

- (void)stopAudio
{
	isPlaying = NO;

	ambisonicsAudioEngine->stop();
}

- (void)setLoopStart:(unsigned long)start end:(unsigned long)end
{
	ambisonicsAudioEngine->enableArrangerLoop(ambisonicsAudioEngine->getCurrentSampleRate() * 0.001 * (double)start, ambisonicsAudioEngine->getCurrentSampleRate() * 0.001 * (double)end, 0.005);
}

- (void)unsetLoop
{
	ambisonicsAudioEngine->disableArrangerLoop();
}


#pragma mark -
#pragma mark getter
// -----------------------------------------------------------


- (BOOL)isPlaying
{
	return isPlaying;
}

- (unsigned long)playbackLocation
{
	return ambisonicsAudioEngine->getCurrentPosition()     // in samples
	       / ambisonicsAudioEngine->getCurrentSampleRate() // now in seconds
		   * 1000;									       // and now in ms.
}

- (unsigned int)sampleRate
{
	return (int)ambisonicsAudioEngine->getCurrentSampleRate();
}

- (unsigned short)numberOfHardwareDeviceOutputChannels
{
	return ambisonicsAudioEngine->getNumberOfHardwareOutputChannels();
}

- (NSString *)nameOfHardwareOutputDevice
{
	int bufferSize = 20;
	char audioDeviceName[bufferSize];
	
	ambisonicsAudioEngine->getNameOfCurrentAudioDevice (audioDeviceName, bufferSize);

	return [NSString stringWithCString:audioDeviceName encoding:NSUTF8StringEncoding];
//	return @"AudioIODriver";
}

- (double)cpuUsage
{
	return ambisonicsAudioEngine->getCpuUsage();
}


#pragma mark -
#pragma mark setter
// -----------------------------------------------------------

- (void)setMasterVolume:(float)dbValue
{
	float gain = pow(10, 0.05 * dbValue);
	ambisonicsAudioEngine->setMasterGain(gain);
}

- (void)setAmbisonicsOrder:(short)order
{
	ambisonicsAudioEngine->setAEPOrder(order);
}

- (void)setdBUnit:(double)unit
{
}

- (void)setUseHipassFilter:(BOOL)filter
{
}

- (void)setUseDelay:(BOOL)delay
{
}



#pragma mark -
#pragma mark scheduled playback
// -----------------------------------------------------------  

- (void)addAudioRegion:(id)audioRegion
{
	// first this region is given a unique index to identify it in the future
	unsigned int index = regionIndex++;
	
	NSLog(@"addAudioRegion(%d) %@", index, [audioRegion valueForKeyPath:@"audioItem.node.name"]);
	
	[audioRegion setValue:[NSNumber numberWithInt:index] forKey:@"playbackIndex"];
	
	unsigned long  startTime = [[audioRegion valueForKey:@"startTime"] unsignedLongValue] * 44.1;
	unsigned long  duration = [[audioRegion valueForKey:@"duration"] unsignedLongValue] * 44.1;
	unsigned long  offsetInFile = [[audioRegion valueForKeyPath:@"audioItem.offsetInFile"] unsignedLongLongValue] * 44.1;

	NSString *filePath = [audioRegion valueForKeyPath:@"audioItem.audioFile.filePath"];
	

	
	// add the audio region to the scheduler	
	ambisonicsAudioEngine->addAudioRegion(index,
										  startTime,
										  duration,
										  offsetInFile,
										  [filePath UTF8String]);
	
	
	[self setGainAutomation:audioRegion];	
	[self setSpatialAutomation:audioRegion];	
}

- (void)modifyAudioRegion:(id)audioRegion
{
	unsigned int index = [[audioRegion valueForKey:@"playbackIndex"] unsignedIntValue];

	NSLog(@"modifyAudioRegion(%d) %@", index, [audioRegion valueForKeyPath:@"audioItem.node.name"]);

	unsigned long  newStartTime = [[audioRegion valueForKey:@"startTime"] unsignedLongValue] * 44.1;
	unsigned long  newDuration = [[audioRegion valueForKey:@"duration"] unsignedLongValue] * 44.1;
	unsigned long  newOffsetInFile = [[audioRegion valueForKeyPath:@"audioItem.offsetInFile"] unsignedLongLongValue] * 44.1;

	ambisonicsAudioEngine->modifyAudioRegion(index, newStartTime, newDuration, newOffsetInFile);

	[self setGainAutomation:audioRegion];	
	[self setSpatialAutomation:audioRegion];	
}

- (void)deleteAudioRegion:(id)audioRegion
{
	unsigned int index = [[audioRegion valueForKey:@"playbackIndex"] unsignedIntValue];
	NSLog(@"deleteAudioRegion(%d) %@", index, [audioRegion valueForKeyPath:@"audioItem.node.name"]);
	
	ambisonicsAudioEngine->removeRegion(index);
}

- (void)deleteAllAudioRegions
{
	ambisonicsAudioEngine->removeAllRegions();
}


- (void)setGainAutomation:(id)audioRegion
{
	unsigned int index = [[audioRegion valueForKey:@"playbackIndex"] unsignedIntValue];
	Array<void*> gainEnvelope;
	float gain;
	
	if([[audioRegion valueForKey:@"muted"] boolValue])
	{
		AudioEnvelopePoint* audioEnvelopePoint = new AudioEnvelopePoint(0, 0.0);
		gainEnvelope.add(audioEnvelopePoint);
	}
	else
	{
		int sampleRate = (int)ambisonicsAudioEngine->getCurrentSampleRate();
		for(id bp in [audioRegion valueForKey:@"gainBreakpointArray"])
		{
			//NSLog(@"gain bp: %d %f", [[bp valueForKey:@"time"] longValue], [[bp valueForKey:@"value"] floatValue]);
			gain = pow(10, 0.05 * [[bp valueForKey:@"value"] floatValue]);
			AudioEnvelopePoint* audioEnvelopePoint = new AudioEnvelopePoint([[bp valueForKey:@"time"] longValue] * 0.001 * sampleRate, gain);
			gainEnvelope.add(audioEnvelopePoint);		
		}
	}
	
	ambisonicsAudioEngine->setGainEnvelopeForRegion(index, gainEnvelope);
	// The gainEnvelope will be deleted in the setGainEnvelope(..) of AudioSourceGainEnvelope
	// or in the destructor of AudioSourceGainEnvelope
}

- (void)setSpatialAutomation:(id)audioRegion
{
	unsigned int index = [[audioRegion valueForKey:@"playbackIndex"] unsignedIntValue];
	Array<void*> spacialEnvelope;
	
//	NSLog(@"setSpatialAutomation for AudioRegion(%d) %@", index, [audioRegion valueForKeyPath:@"audioItem.node.name"]);
	
	int sampleRate = (int)ambisonicsAudioEngine->getCurrentSampleRate();
	for(id bp in [audioRegion valueForKey:@"playbackBreakpointArray"])
	{
		SpacialEnvelopePoint* spacialEnvelopePoint 
		  = new SpacialEnvelopePoint([[bp valueForKey:@"time"] longValue] * 0.001 * sampleRate,
									 [[bp valueForKey:@"x"] floatValue],
									 [[bp valueForKey:@"y"] floatValue],
									 [[bp valueForKey:@"z"] floatValue]);
		spacialEnvelope.add(spacialEnvelopePoint);
		
//		NSLog(@"time: %ld x: %f y: %f z: %f",
//		[[bp valueForKey:@"time"] longValue],
//		[[bp valueForKey:@"x"] floatValue],
//		[[bp valueForKey:@"y"] floatValue],
//		[[bp valueForKey:@"z"] floatValue]);
	}
	
	ambisonicsAudioEngine->setSpacialEnvelopeForRegion(index, spacialEnvelope);
	// The spacialEnvelope will be deleted by AudioSourceAmbipanning
}	


#pragma mark -
#pragma mark speaker setup
// -----------------------------------------------------------

- (void)removeAllSpeakerChannels
{
	ambisonicsAudioEngine->removeAllRoutingsAndAllAepChannels();
	  // Philippe: Ich verstehe nicht, weshalb das beim Programmstart aufgerufen wird.
}

- (void)addSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index
{	
	double gainLinear = pow(10, 0.05 * channel.gain);
	ambisonicsAudioEngine->addAepChannel(index,
										 gainLinear,
										 channel.solo,
										 channel.mute,
										 false,
										 channel.position.x,
										 channel.position.y,
										 channel.position.z);

	
	if(channel.hardwareDeviceOutputChannel < [self numberOfHardwareDeviceOutputChannels])
	{
		ambisonicsAudioEngine->setNewRouting(index, channel.hardwareDeviceOutputChannel);
		ambisonicsAudioEngine->enableNewRouting();
		    // An Philippe: Kannst du das hier so aendern, dass enableRouting nur
		    // einmal aufgerufen wird, wenn alle Routings gesetzt worden sind?
		    // Denn beim Aufruf von enableNewRouting muessen alle Buffer neu initialisiert
		    // werden und der Audiograph neu erstellt werden. Das kann unter anderem zu
		    // laestigen Knacksern fuehren.
	}
}

- (void)updateSpeakerChannel:(SpeakerChannel *)channel atIndex:(NSUInteger)index
{
	ambisonicsAudioEngine->setSpeakerPosition(index,
											  channel.position.x,
											  channel.position.y,
											  channel.position.z);
	
	double gainLinear = pow(10, 0.05 * channel.gain);	
	ambisonicsAudioEngine->setGain(index, gainLinear);
	ambisonicsAudioEngine->setSolo(index, channel.solo);
	ambisonicsAudioEngine->setMute(index, channel.mute);
	
	if(channel.hardwareDeviceOutputChannel < [self numberOfHardwareDeviceOutputChannels])
	{
		ambisonicsAudioEngine->setNewRouting(index, channel.hardwareDeviceOutputChannel);
		ambisonicsAudioEngine->enableNewRouting();
		    // An Philippe: Kannst du das hier so aendern, dass enableRouting nur
		    // einmal aufgerufen wird, wenn alle Routings gesetzt worden sind?
		    // Denn beim Aufruf von enableNewRouting muessen alle Buffer neu initialisiert
		    // werden und der Audiograph neu erstellt werden. Das kann unter anderem zu
		    // laestigen Knacksern fuehren.
	}
}


#pragma mark -
#pragma mark settings
// -----------------------------------------------------------

- (void)setPersistentSetting:(id)data forKey:(NSString *)key
{
	NSDictionary *dict = [NSDictionary dictionaryWithObject:data forKey:@"speakerSetups"];
	NSUserDefaults *def = [[NSUserDefaults alloc] init];
	[def setPersistentDomain:dict forName:@"net.icst.choreographer.audioEngine"];
	[def release];	
}

- (id)persistentSettingForKey:(NSString *)key
{
	NSUserDefaults *def = [[NSUserDefaults alloc] init];
	NSDictionary *dict = [def persistentDomainForName:@"net.icst.choreographer.audioEngine"];
	id data = [dict objectForKey:@"speakerSetups"];
	[def release];
	return data;
}


#pragma mark -
#pragma mark real time playback
// -----------------------------------------------------------
//  
/*
- (void)setVolume:(float)volume forVoice:(unsigned int)voice
{
}

- (void)setPosition:(Position *)position forVoice:(unsigned int)voice
{
}
*/

@end