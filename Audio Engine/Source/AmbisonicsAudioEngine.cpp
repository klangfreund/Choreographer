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

#define AUDIOTRANSPORT_BUFFER 2048

// constructor
AmbisonicsAudioEngine::AmbisonicsAudioEngine ()
    : audioDeviceManager(),
      audioSourcePlayer(),
      audioTransportSource(),
      audioRegionMixer(),
	  audioSpeakerGainAndRouting(&audioDeviceManager)
{

	
	// initialise settings file
	ApplicationProperties::getInstance()
	->setStorageParameters (T("Choreographer Ambisonics Audio Engine"),
							T("settings"), String::empty, 1000,
							PropertiesFile::storeAsXML);
	
	// load the previously selected settings for the audio device
	XmlElement* const savedAudioState = ApplicationProperties::getInstance()->getUserSettings()
	->getXmlValue (T("audioDeviceState"));	
    audioDeviceManager.initialise (256, 256, savedAudioState, true);	
    delete savedAudioState;
	
	// figure out the number of active output channels:
	AudioIODevice* audioIODevice = audioDeviceManager.getCurrentAudioDevice();
	    // this points to a needed object, don't delete it!
	BigInteger activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();

	
	audioSpeakerGainAndRouting.setSource (&audioRegionMixer);
	audioTransportSource.setSource (&audioSpeakerGainAndRouting,
									numberOfActiveOutputChannels,
									2048); // tells it to buffer this many samples ahead (choose a value >1024)
    audioSourcePlayer.setSource (&audioTransportSource);
	audioDeviceManager.addAudioCallback (&audioSourcePlayer);
	
	
	// temp (test) ----------------------
	
//	addAepChannel(1, 1.0, false, false, false, -1.0, 0.0, 0.0);
//	addAepChannel(2, 1.0, false, false, false, 0.0, 1.0, 0.0);
//	addAepChannel(3, 1.0, false, false, false, 1.0, 0.0, 0.0);
//	addAepChannel(6, 1.0, false, false, false, 0.0, -1.0, 0.0);
//	setNewRouting(1, 1);
//	setNewRouting(2, 2);
//	setNewRouting(3, 4);
//	setNewRouting(6, 3);	
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
	AudioDeviceSelectorComponentMod audioDeviceSelectorComponent (audioDeviceManager,
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
	XmlElement* const audioState = audioDeviceManager.createStateXml();
	
	ApplicationProperties::getInstance()->getUserSettings()
	->setValue (T("audioDeviceState"), audioState);
	
	delete audioState;
	
	ApplicationProperties::getInstance()->getUserSettings()->saveIfNeeded();
	
	
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
	
	setSpeakerPositions (positionOfSpeaker);
	  // To make sure that the number of speakers is smaller or equal than the number of active
	  // output channels
	
	// Temp
	activatePinkNoise(1, true);

}

void AmbisonicsAudioEngine::getNameOfCurrentAudioDevice (char* audioDeviceName,
														 int maxBufferSizeBytes)
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	String audioDeviceNameString = currentAudioIODevice->getName();
	audioDeviceNameString.copyToCString(audioDeviceName, maxBufferSizeBytes);
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

bool AmbisonicsAudioEngine::setSolo(int aepChanel, bool enable)
{
	return audioSpeakerGainAndRouting.setSolo(aepChanel, enable);
}

bool AmbisonicsAudioEngine::setMute(int aepChanel, bool enable)
{
	return audioSpeakerGainAndRouting.setMute(aepChanel, enable);
}

bool AmbisonicsAudioEngine::activatePinkNoise(int aepChanel, bool enable)
{
	return audioSpeakerGainAndRouting.activatePinkNoise(aepChanel, enable);
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
	// without this it might crash when lowering the number of
	// active output ports.
	bool wasPlaying = audioTransportSource.isPlaying();
	int currentPosition;
	if (wasPlaying)
	{
		currentPosition = getCurrentPosition();
		stop();
	}
	
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

void AmbisonicsAudioEngine::setSpeakerPositions (Array<void*> positionOfSpeaker_)
{
	DBG(T("AmbisonicsAudioEngine.setSpeakerPositions called"));

	positionOfSpeaker = positionOfSpeaker_;

	positionOfSpeakerMaybeReduced = positionOfSpeaker;
	
	AudioIODevice* currentAudioDevice = audioDeviceManager.getCurrentAudioDevice();
	BigInteger activeOutputChannels = currentAudioDevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();
	
	// The number of speakers must be smaller or equal than the 
	// numberOfActiveOutputChannels. Otherwise the program will crash 
	// because getNextAudioBlock(..) in AudioSouceAmbipanning will access
	// an undefined memory location.
	
	// To prevent this:
	// If "number of speakers" > numberOfActiveOutputChannels)
	// remove speakers until these numbers are equal.
	while (positionOfSpeakerMaybeReduced.size() > numberOfActiveOutputChannels)
	{
		DBG(T("AmbisonicsAudioEngine.setSpeakerPositions: remove a speaker because there are more speakers than active outputs"))
		positionOfSpeakerMaybeReduced.remove(positionOfSpeakerMaybeReduced.size() - 1);
	}
	DBG(T("AmbisonicsAudioEngine.setSpeakerPositions: positionOfSpeaker.size() = ") 
		+ String(positionOfSpeaker.size()));
	DBG(T("AmbisonicsAudioEngine.setSpeakerPositions: positionOfSpeakerMaybeReduced.size() = ") 
		+ String(positionOfSpeakerMaybeReduced.size()));

	audioRegionMixer.setSpeakerPositions(positionOfSpeakerMaybeReduced);
}

bool AmbisonicsAudioEngine::setSpacialEnvelopeForRegion (const int regionID,
													     Array<void*> spacialEnvelope)
{
	return audioRegionMixer.setSpacialEnvelopeForRegion(regionID, spacialEnvelope);
}
