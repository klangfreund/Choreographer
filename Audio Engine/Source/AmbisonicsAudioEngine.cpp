/*
 *  AmbisonicsAudioEngine.cpp
 *  AudioPlayer
 *
 *  Created by sam on 10 04 01.
 *  Copyright 2010 klangfreund.com. All rights reserved.
 *
 */

#include "AmbisonicsAudioEngine.h"
#include "SpeakerTestComponent.h"

#define AUDIOTRANSPORT_BUFFER 2048 // (choose a value >1024)
#define SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK 512

// constructor
AmbisonicsAudioEngine::AmbisonicsAudioEngine ()
    : audioDeviceManager(),
      audioSourcePlayer(),
      audioTransportSource(),
      audioRegionMixer(),
	  audioSpeakerGainAndRouting(&audioDeviceManager, &audioRegionMixer)
{
	
	DBG(T("AmbisonicsAudioEngine: constructor called."));


// OPTION 1:
	// initialise settings file
//	ApplicationProperties::getInstance()
//	->setStorageParameters (T("Choreographer Ambisonics Audio Engine"),
//							T("settings"), String::empty, 1000,
//							PropertiesFile::storeAsXML);
//	
//	// load the previously selected settings for the audio device
//	XmlElement* const savedAudioState = ApplicationProperties::getInstance()->getUserSettings()
//	->getXmlValue (T("audioDeviceState"));
//	String err;
//    err = audioDeviceManager.initialise (256, 256, savedAudioState, true);
//	    // If you ever intend to remove this initialising block here in the constructor:
//	    // Keep in mind that you still have to call audioDeviceManager.initialise once. This
//	    // is the only occurence of this call in the whole Choreographer code.
//    delete savedAudioState;
//	if (err != T(""))
//	{
//		DBG(T("AmbisonicsAudioEngine: audioDeviceManager, initialisation error = ") + err);
//	}

// OPTION 2:
//	String err;
//	err = audioDeviceManager.initialise (256, 256, 0, true);
//	    // This doesn't work :(. This way, the initial AudioDeviceSetup (thats used internally by the
//	    // audioDeviceManager) is kind of messed up.
//	    // E.g. AudioDeviceSetup.outputChannels.toInteger() = 268435455 .
//	    // The playhead of the Choreographer doesn't move, when initialised this way.

	
	// Initialize the audioDeviceManager (and with it the audioDevice).
	// ---------------------------------
	String errorString;
	int numInputChannelsNeeded = 256;
	int numOutputChannelsNeeded = 256;
	bool selectDefaultDeviceOnFailure = true;
	errorString = audioDeviceManager.initialise (numInputChannelsNeeded, 
										 numOutputChannelsNeeded, 
										 0, 
										 selectDefaultDeviceOnFailure);
	if (errorString.isNotEmpty())
	{
		DBG(T("AmbisonicsAudioEngine, constructor: audioDeviceManager, initialisation error = ") + errorString);
	}
	
	// TEMP: Select an audioDevice
	// ---------------------------
	
	// Get the audioDevices names
	StringArray deviceNames;
	deviceNames = getAvailableAudioDeviceNames();
	
	// Check if there are audioDevices available at all.
	if (deviceNames.size() < 1)
	{
		DBG(T("AmbisonicsAudioEngine, constructor: Can't find a Core Audio device."));
	}
	else
	{
		DBG(T("AmbisonicsAudioEngine, constructor: Available audio devices:"));
		for (int i = 0; i < deviceNames.size(); ++i)
		{
			DBG(deviceNames[i]);
			// Output on the console on my system:
			//	Built-in Output
			//	Soundflower (2ch)
			//	Soundflower (16ch)
		}
		
		// Select an audioDevice
		String chosenOutputDevice = deviceNames[0];
		//String chosenOutputDevice = T("bla");		
		String errorString;
		errorString = setAudioDevice(chosenOutputDevice);
		if (errorString.isNotEmpty())
		{
			DBG(T("AmbisonicsAudioEngine, constructor: Wasn't able to set the audio device ") + chosenOutputDevice);
			DBG(errorString);
		}		
	}
	
	
	
	// figure out the number of active output channels:
	AudioIODevice* audioIODevice = audioDeviceManager.getCurrentAudioDevice();
	    // This points to an object already existing, don't delete it!
//	const BigInteger activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = (audioIODevice->getActiveOutputChannels()).countNumberOfSetBits();

	
	// Connect the objects together (for a better understanding, please take a look at
	// the picture in the AmbisonicsAudioEngine Class Reference in the documentation):
	audioTransportSource.setSource (&audioRegionMixer,
									numberOfActiveOutputChannels,
									AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
	audioSpeakerGainAndRouting.setSource (&audioTransportSource);
    audioSourcePlayer.setSource (&audioSpeakerGainAndRouting);
	audioDeviceManager.addAudioCallback (&audioSourcePlayer);
	
	
	// temp (test) ----------------------
	
//	addAepChannel(0, 1.0, false, false, false, -1.0, 0.0, 0.0);
//	addAepChannel(1, 1.0, false, false, false, 0.0, 1.0, 0.0);
//	addAepChannel(2, 1.0, false, false, false, 1.0, 0.0, 0.0);
//	addAepChannel(3, 1.0, false, false, false, 0.0, -1.0, 0.0);
//	setNewRouting(0, 0);
//	setNewRouting(1, 1);
//	setNewRouting(2, 2);
//	setNewRouting(3, 3);	
//	enableNewRouting();
//	activatePinkNoise(1, true);
	
	// end temp (test) ------------------

	
}
	
// destructor
AmbisonicsAudioEngine::~AmbisonicsAudioEngine ()
{
	audioTransportSource.setSource (0, 1);
    audioSourcePlayer.setSource (0);
	audioDeviceManager.removeAudioCallback (&audioSourcePlayer);
	
	// close settings file
    ApplicationProperties::getInstance()->closeFiles();
	
}
	
// This opens a dialogWindow to set up the audioDeviceManager
void AmbisonicsAudioEngine::showAudioSettingsWindow()
{
	//stop();
	    // I know, it would be nicer to be able to change it when the music is
	    // playing, but without this it will crash when lowering the number of
	    // active output ports.
	int currentPosition = getCurrentPosition();
	
	const bool showMidiInputOptions = false;
	const bool showMidiOutputSelector = false;
	const bool showChannelsAsStereoPairs = false;
	const bool hideAdvancedOptionsWithButton = false;
	AudioDeviceSelectorComponent audioDeviceSelectorComponent (audioDeviceManager,
													0, 0,
													0, 256,
													showMidiInputOptions, 
													showMidiOutputSelector, 
													showChannelsAsStereoPairs, 
													hideAdvancedOptionsWithButton);
	
	audioDeviceSelectorComponent.setSize (500, 350);
	
	DialogWindow::showModalDialog (T("Audio Settings"),
								   &audioDeviceSelectorComponent,
								   0,
								   Colours::lightgrey,
								   true);
	// Alternative. Not working yet.
//	// Open the dialog window.
//	// Done the same way as in DialogWindow::showModalDialog
//	DialogWindow dialogWindow (T("Audio Settings"),
//							   Colours::lightgrey,
//							   true,
//							   false);
//	dialogWindow.setContentComponent(&audioDeviceSelectorComponent, true, true);
//	dialogWindow.centreAroundComponent (0, dialogWindow.getWidth(), dialogWindow.getHeight());
//	dialogWindow.setResizable(false, false);
//	dialogWindow.setUsingNativeTitleBar(true);
//	dialogWindow.setAlwaysOnTop(true);
//	dialogWindow.runModalLoop();
//	dialogWindow.setContentComponent(0, false);
	
	// store this settings...
//	XmlElement* const audioState = audioDeviceManager.createStateXml();
//	
//	ApplicationProperties::getInstance()->getUserSettings()
//	->setValue (T("audioDeviceState"), audioState);
//	
//	delete audioState;
//	
//	ApplicationProperties::getInstance()->getUserSettings()->saveIfNeeded();
	
	
	// figure out the number of active output channels:
	AudioIODevice* audioIODevice = audioDeviceManager.getCurrentAudioDevice();
	   // this points to a object used by the audioDeviceManager, don't delete it!
	BigInteger activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();

	// Since the numberOfActiveOutputChannels has changed, audioTransportSource needs to know this:
	audioTransportSource.setSource (&audioRegionMixer,
									numberOfActiveOutputChannels,
									2048); // tells it to buffer this many samples ahead (choose a value >1024)
	
	// audioTransportSource.setSource(..) puts the playhead to 0. This will put it to the
	// last position:
	setPosition(currentPosition);
	
	// Temp
//	addAepChannel(0, 1.0, false, false, false, -1.0, 0.0, 0.0);
//	addAepChannel(1, 1.0, false, false, false, 0.0, 1.0, 0.0);
//	addAepChannel(2, 1.0, false, false, false, 1.0, 0.0, 0.0);
//	addAepChannel(3, 1.0, false, false, false, 0.0, -1.0, 0.0);
//	setNewRouting(0, 0);
//	setNewRouting(1, 1);
//	setNewRouting(2, 2);
//	setNewRouting(3, 3);	
//	enableNewRouting();
	

}

StringArray AmbisonicsAudioEngine::getAvailableAudioDeviceNames()
{
	// Figure out if there is an audioIODeviceType called "CoreAudio".
	AudioIODeviceType* audioIODeviceTypeCoreAudio = 0;
	String coreAudioString("CoreAudio");
	for (int i = 0; i < audioDeviceManager.getAvailableDeviceTypes().size(); ++i)
	{
		if (audioDeviceManager.getAvailableDeviceTypes().getUnchecked(i)->getTypeName() == coreAudioString)
		{
			DBG(T("AmbisonicsAudioEngine::getAvailableCoreAudioDeviceNames(): Got the AudioIODeviceType for the CoreAudio."));
			audioIODeviceTypeCoreAudio = audioDeviceManager.getAvailableDeviceTypes().getUnchecked(i);			
		}
	}
	
	if (audioIODeviceTypeCoreAudio == 0)
	{
		DBG(T("AmbisonicsAudioEngine::getAvailableCoreAudioDeviceNames(): Couldn't find CoreAudio."));
		StringArray returnValue; // An empty StringArray.
		return returnValue;
	}
	else
	{
		audioIODeviceTypeCoreAudio->scanForDevices();
		StringArray deviceNames;
		bool wantInputNames = false;
		deviceNames = audioIODeviceTypeCoreAudio->getDeviceNames(wantInputNames);
		
		return deviceNames;
	}	
}

String AmbisonicsAudioEngine::setAudioDevice(String audioDeviceName)
{
	// Set the device as new output device
	AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
	audioDeviceSetup.outputDeviceName = audioDeviceName;
	bool treatAsChosenDevice = true;
	String errorString;
	errorString = audioDeviceManager.setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
	
	// On failure, initialise the audioDeviceManager again, such that there is at
	// least something available for audio output.
	if (errorString.isNotEmpty())
	{
		String errorString2;
		int numInputChannelsNeeded = 256;
		int numOutputChannelsNeeded = 256;
		bool selectDefaultDeviceOnFailure = true;
		errorString2 = audioDeviceManager.initialise (numInputChannelsNeeded, 
													  numOutputChannelsNeeded, 
													  0, 
													  selectDefaultDeviceOnFailure);
		if (errorString2.isNotEmpty())
		{
			DBG(T("AmbisonicsAudioEngine::setAudioDevice: audioDeviceManager, initialisation error = ") + errorString);
		}
	}
	
	return errorString;
}

String AmbisonicsAudioEngine::getNameOfCurrentAudioDevice ()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	return currentAudioIODevice->getName();
}

double AmbisonicsAudioEngine::getCurrentSampleRate ()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	return currentAudioIODevice->getCurrentSampleRate();
}

int AmbisonicsAudioEngine::getNumberOfHardwareOutputChannels()
{
	return audioSpeakerGainAndRouting.getNumberOfHardwareOutputChannels();
}

int AmbisonicsAudioEngine::getNumberOfAepChannels()
{
	return audioSpeakerGainAndRouting.getNumberOfAepChannels();
}

bool AmbisonicsAudioEngine::bounceToDisc(String absolutePathToAudioFile, 
										 int bitsPerSample, 
										 String description,
										 String originator,
										 String originatorRef,
										 int64 timeReferenceSamples,
										 String codingHistory,
										 int startSample,
										 int numberOfSamplesToRead)
{
	File fileToWriteTo(absolutePathToAudioFile);	
	// If this file exists, it needs to be deleted.
	// (Otherwise the bounced audio would be appended to the existing file.)
	fileToWriteTo.deleteFile();
	
	FileOutputStream* fileOutputStream = fileToWriteTo.createOutputStream();
	
	// Generate the metadataValues for the wav file.
	Time dateAndTime;
	dateAndTime.setSystemTimeToThisTime();
	const StringPairArray metadataValues = WavAudioFormat::createBWAVMetadata(description,
																			  originator, 
																			  originatorRef, 
																			  dateAndTime, 
																			  timeReferenceSamples, 
																			  codingHistory);
	// Set up the audioFormatWriter.
	WavAudioFormat wavAudioFormat;
	int qualityOptionIndex = 0; // no compression.
	AudioFormatWriter* audioFormatWriter = wavAudioFormat.createWriterFor(fileOutputStream, 
																		  getCurrentSampleRate(), 
																		  getNumberOfHardwareOutputChannels(), 
																		  bitsPerSample, 
																		  metadataValues, 
																		  qualityOptionIndex);
	
	// Remember the current playhead position.
	int currentPosition = getCurrentPosition();
	
	// Write the audio file.
	setPosition(startSample);	
	audioSpeakerGainAndRouting.prepareToPlay(SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK, getCurrentSampleRate());
	bool success = audioFormatWriter->writeFromAudioSource(audioSpeakerGainAndRouting, 
												   numberOfSamplesToRead, 
												   SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK);
	
	// Reset the playhead position
	setPosition(currentPosition);
	
	return success;
}

bool AmbisonicsAudioEngine::addAepChannel(int aepChannel, double gain, 
										  bool solo, bool mute,
										  bool activatePinkNoise, double x, 
										  double y, double z)
{
	return audioSpeakerGainAndRouting.addAepChannel(aepChannel, gain, solo, 
													mute, activatePinkNoise,
													x, y, z);
}

bool AmbisonicsAudioEngine::removeAepChannel(int aepChannel)
{
	return audioSpeakerGainAndRouting.removeAepChannel(aepChannel);
}

bool AmbisonicsAudioEngine::setSpeakerPosition(int aepChannel, double x, 
											   double y, double z)
{
	return audioSpeakerGainAndRouting.setSpeakerPosition(aepChannel, x, 
														 y, z);
}

bool AmbisonicsAudioEngine::setGain(int aepChannel, double gain)
{
	return audioSpeakerGainAndRouting.setGain(aepChannel, gain);
}

bool AmbisonicsAudioEngine::setSolo(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.setSolo(aepChannel, enable);
}

bool AmbisonicsAudioEngine::setMute(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.setMute(aepChannel, enable);
}

bool AmbisonicsAudioEngine::activatePinkNoise(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.activatePinkNoise(aepChannel, enable);
}

void AmbisonicsAudioEngine::setAmplitudeOfPinkNoiseGenerator(const double amplitude)
{
	audioSpeakerGainAndRouting.setAmplitudeOfPinkNoiseGenerator(amplitude);
}

bool AmbisonicsAudioEngine::enableMeasurement(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.enableMeasurement(aepChannel, enable);
}

bool AmbisonicsAudioEngine::resetMeasuredPeakValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.resetMeasuredPeakValue(aepChannel);
}

float AmbisonicsAudioEngine::getMeasuredDecayingValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.getMeasuredDecayingValue(aepChannel);
}

float AmbisonicsAudioEngine::getMeasuredPeakValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.getMeasuredPeakValue(aepChannel);
}

void AmbisonicsAudioEngine::setNewRouting(int aepChannel, int hardwareOutputChannel)
{
	audioSpeakerGainAndRouting.setNewRouting(aepChannel, hardwareOutputChannel);
}

void AmbisonicsAudioEngine::removeAllRoutings()
{
	audioSpeakerGainAndRouting.removeAllRoutings();
}

void AmbisonicsAudioEngine::enableNewRouting()
{
	// Since we're quite likely going to change the number of channels
	// in the audio callback, we have to stop these callbacks.
	bool wasPlaying = audioTransportSource.isPlaying();
	int64 currentPosition;
	if (wasPlaying)
	{
		currentPosition = getCurrentPosition();
		stop();
	}
	
	{
	const ScopedLock sl (lock);
	audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
	
	int numberOfActiveOutputChannels = audioSpeakerGainAndRouting.enableNewRouting();
	
	// Since the numberOfActiveOutputChannels has changed, audioTransportSource needs to know this:
	if (numberOfActiveOutputChannels > 0)
	{
		audioTransportSource.setSource (&audioRegionMixer,
										numberOfActiveOutputChannels,
										AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
		
		audioDeviceManager.addAudioCallback(&audioSourcePlayer);
		
		if (wasPlaying)
		{
			
			setPosition(currentPosition);
			start();
		}
	}
	else
	{
		// In the case of 0 channels,
		//		audioTransportSource.setSource (&audioRegionMixer,
		//										0,
		//										AUDIOTRANSPORT_BUFFER);
		// would lead to a crash because the audio buffer can't handle it.
		// With &audioRegionMixer = 0 the audioTransport doesn't create
		// an audio buffer at all.
//		audioTransportSource.setSource (0,
//										0,
//										AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
	}
	}
	

}

void AmbisonicsAudioEngine::removeAllRoutingsAndAllAepChannels()
{
	stop();
	audioTransportSource.setSource (0,0,AUDIOTRANSPORT_BUFFER);
	audioSpeakerGainAndRouting.removeAllRoutingsAndAllAepChannels();
}

int AmbisonicsAudioEngine::getCurrentPosition()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	double sampleRateOfTheAudioDevice = currentAudioIODevice->getCurrentSampleRate();
	return (int) (audioTransportSource.getCurrentPosition() * sampleRateOfTheAudioDevice);
}

void AmbisonicsAudioEngine::setPosition(int positionInSamples)
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	double sampleRateOfTheAudioDevice = currentAudioIODevice->getCurrentSampleRate();
	double positionInSeconds = (double)positionInSamples/sampleRateOfTheAudioDevice;
	audioTransportSource.setPosition(positionInSeconds);
}

void AmbisonicsAudioEngine::start()
{
	audioTransportSource.start();
}
	
void AmbisonicsAudioEngine::stop()
{
	if (audioTransportSource.isPlaying())
	{
		audioTransportSource.stop();
	}
	else
	{
		// jump back to the start, if audio wasn't playing before
		audioTransportSource.setPosition(0);
	}
}

bool AmbisonicsAudioEngine::enableArrangerLoop(int loopStartInSamples, int loopEndInSamples, int loopFadeTimeInSamples)
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	double oneOverSampleRate = 1.0 / currentAudioIODevice->getCurrentSampleRate();
	return audioTransportSource.enableArrangerLoop(oneOverSampleRate * loopStartInSamples, 
												   oneOverSampleRate * loopEndInSamples,
												   oneOverSampleRate * loopFadeTimeInSamples);
}

void AmbisonicsAudioEngine::disableArrangerLoop()
{
	audioTransportSource.disableArrangerLoop();
}

double AmbisonicsAudioEngine::getCpuUsage ()
{
	return audioDeviceManager.getCpuUsage();
}

bool AmbisonicsAudioEngine::addAudioRegion (const int regionID,
										    const int startPosition,
										    const int duration,
										    const int offsetInFile,
										    String absolutePathToAudioFile)
{
	int endPosition = startPosition + duration;
	int startPositionOfAudioFileInTimeline = startPosition - offsetInFile;
	
	double sampleRateOfTheAudioDevice = (audioDeviceManager.getCurrentAudioDevice())->getCurrentSampleRate();
	
	return audioRegionMixer.addRegion(regionID, startPosition, endPosition,
		        startPositionOfAudioFileInTimeline, absolutePathToAudioFile,
				sampleRateOfTheAudioDevice);
}

bool AmbisonicsAudioEngine::modifyAudioRegion(const int regionID, 
											  const int newStartPosition, 
											  const int newDuration,
											  const int newOffsetInFile)
{
	int newEndPosition = newStartPosition + newDuration;
	int newStartPositionOfAudioFileInTimeline = newStartPosition - newOffsetInFile;
	
	return audioRegionMixer.modifyRegion(regionID, newStartPosition, newEndPosition,
										 newStartPositionOfAudioFileInTimeline);
}

bool AmbisonicsAudioEngine::removeRegion (const int regionID)
{
	return audioRegionMixer.removeRegion(regionID);
}

void AmbisonicsAudioEngine::removeAllRegions ()
{
	audioRegionMixer.removeAllRegions();
}

bool AmbisonicsAudioEngine::setGainEnvelopeForRegion (const int regionID,
													  Array<void*> gainEnvelope)
{
	return audioRegionMixer.setGainEnvelopeForRegion(regionID, gainEnvelope);
}

void AmbisonicsAudioEngine::setMasterGain(const float newGain)
{
	audioTransportSource.setGain(newGain);
}

void AmbisonicsAudioEngine::setAEPOrder (const int order)
{
	AudioSourceAmbipanning::setOrder(order);
}

void setAEPDistanceModeTo0 ()
{
	AudioSourceAmbipanning::setDistanceModeTo0();
}

void setAEPDistanceModeTo1 (double centerRadius, 
							double centerExponent,
							double centerAttenuation,
							double dBFalloffPerUnit)
{
	AudioSourceAmbipanning::setDistanceModeTo1(centerRadius, 
											   centerExponent,
											   centerAttenuation,
											   dBFalloffPerUnit);
}

void setAEPDistanceModeTo2 (double centerRadius, 
							double centerExponent,
							double centerAttenuation,
							double outsideCenterExponent)
{
	AudioSourceAmbipanning::setDistanceModeTo1(centerRadius, 
											   centerExponent,
											   centerAttenuation,
											   outsideCenterExponent);
}

bool AmbisonicsAudioEngine::setSpacialEnvelopeForRegion (const int regionID,
													     Array<void*> spacialEnvelope)
{
	return audioRegionMixer.setSpacialEnvelopeForRegion(regionID, spacialEnvelope);
}
