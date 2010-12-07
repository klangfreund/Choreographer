/*
 *  AudioRegionMixer.cpp
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 101014.
 *  Copyright 2010. All rights reserved.
 *
 */


#include "AudioSpeakerGainAndRouting.h"

//==============================================================================
AudioSpeakerGainAndRouting::AudioSpeakerGainAndRouting()
: audioRegionMixer (0),
  audioDeviceManager (0),
  aepChannelHardwareOutputPairs (),
  aepChannelSettingsAscending (),
  aepChannelSettingsOrderedByActiveHardwareChannels (),
  numberOfMutedChannels (0),
  numberOfSoloedChannels (0),
  numberOfChannelsWithActivatedPinkNoise (0),
  pinkNoiseGeneratorAudioSource (),
  pinkNoiseBuffer (1, 0)
{
	DBG(T("AudioSpeakerGainAndRouting: constructor (without any argument) called."));
}

AudioSpeakerGainAndRouting::AudioSpeakerGainAndRouting(AudioDeviceManager* audioDeviceManager_)
: audioRegionMixer (0),
  audioDeviceManager (audioDeviceManager_),
  aepChannelHardwareOutputPairs (),
  aepChannelSettingsAscending (),
  aepChannelSettingsOrderedByActiveHardwareChannels (),
  numberOfMutedChannels (0),
  numberOfSoloedChannels (0),
  numberOfChannelsWithActivatedPinkNoise (0),
  pinkNoiseGeneratorAudioSource (),
  pinkNoiseBuffer (1, 0)
{
	DBG(T("AudioSpeakerGainAndRouting: constructor (with AudioDeviceManager argument) called."));
}

AudioSpeakerGainAndRouting::~AudioSpeakerGainAndRouting()
{
	DBG(T("AudioSpeakerGainAndRouting: destructor called."));
	
	removeAllRoutingsAndAllAepChannels();
}

void AudioSpeakerGainAndRouting::setSource (AudioRegionMixer* const newAudioRegionMixer)
{
	DBG(T("AudioSpeakerGainAndRouting: setSource called."));
	
	// sam: This part is copied from the AudioTransportSource
    if (audioRegionMixer == newAudioRegionMixer)
    {
        if (audioRegionMixer == 0)
            return;
		
        setSource (0); // deselect and reselect to avoid releasing resources wrongly
    }
	
	PositionableAudioSource* oldAudioRegionMixer = audioRegionMixer;

	audioRegionMixer = newAudioRegionMixer;
	
	if (oldAudioRegionMixer != 0) {
		oldAudioRegionMixer->releaseResources();
	}
}

void AudioSpeakerGainAndRouting::setAudioDeviceManager(AudioDeviceManager* audioDeviceManager_)
{
	audioDeviceManager = audioDeviceManager_;
}

int AudioSpeakerGainAndRouting::getNumberOfAepChannels()
{
	return aepChannelSettingsAscending.size();
}

int AudioSpeakerGainAndRouting::getNumberOfHardwareOutputChannels()
{
	AudioIODevice* currentAudioDevice = audioDeviceManager->getCurrentAudioDevice();
	StringArray outputChannelNames = currentAudioDevice->getOutputChannelNames();
	return outputChannelNames.size();
}

bool AudioSpeakerGainAndRouting::addAepChannel(int aepChannel, double gain, bool solo, 
											   bool mute, bool activatePinkNoise, 
											   double x, double y, double z)
{
	if (aepChannelSettingsAscending.size() > aepChannel)
	{
		// The specified AEP channel already exists.
		DBG(T("addAepChannel can't add the AEP channel because it already exists."));
		return false;
	}
	if (aepChannel < 0)
	{
		// The specified AEP channel is too small (< 0).
		DBG(T("addAepChannel can't add the AEP channel because aepChannel is smaller than zero."));
		return false;
	}
	
	// Add missing aepChannels - if there needs to be any.
	while (aepChannelSettingsAscending.size() < aepChannel)
	{
		aepChannelSettings* defaultAepChannelSettings = new aepChannelSettings;
		defaultAepChannelSettings->gain = 0.0;
		defaultAepChannelSettings->solo = FALSE;
		defaultAepChannelSettings->mute = FALSE;
		defaultAepChannelSettings->activatePinkNoise = FALSE;
		defaultAepChannelSettings->speakerPosition.setXYZ(0.0, 1.0, 0.0);
		defaultAepChannelSettings->enableOutputMeasurement = FALSE; //TODO: THINK ABOUT THIS!
		defaultAepChannelSettings->resetPeakValue = FALSE;
		defaultAepChannelSettings->measuredRootMeanSquareValue = 0.0;
		defaultAepChannelSettings->measuredPeakValue = 0.0;
		
		aepChannelSettingsAscending.add(defaultAepChannelSettings);
	}
	
	// Add the specified AEP channel
	aepChannelSettings* specifiedAepChannelSettings = new aepChannelSettings;
	specifiedAepChannelSettings->gain = gain;
	specifiedAepChannelSettings->solo = solo;
	specifiedAepChannelSettings->mute = mute;
	specifiedAepChannelSettings->activatePinkNoise = activatePinkNoise;
	specifiedAepChannelSettings->speakerPosition.setXYZ(x, y, z);
	specifiedAepChannelSettings->enableOutputMeasurement = FALSE; //TODO: THINK ABOUT THIS!
	specifiedAepChannelSettings->resetPeakValue = FALSE;
	specifiedAepChannelSettings->measuredRootMeanSquareValue = 0.0;
	specifiedAepChannelSettings->measuredPeakValue = 0.0;
	
	aepChannelSettingsAscending.add(specifiedAepChannelSettings);
	
	return true;
}

bool AudioSpeakerGainAndRouting::removeAepChannel(int aepChannel)
{
	// THIS FUNCTION IS NOT YET IMPLEMENTED.
	return false;
}

bool AudioSpeakerGainAndRouting::setSpeakerPosition(int aepChannel, double x, double y, double z)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsAscending.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size() -1.
		return false;
	}
	aepChannelSettingsAscending[aepChannel]->speakerPosition.setXYZ(x, y, z);
	return true;
}

bool AudioSpeakerGainAndRouting::setGain(int aepChannel, double gain)
{
	DBG(T("AudioSpeakerGainAndRouting.setGain on aepChannel ") + String(aepChannel) + T(" with gain ") + String(gain));

	if (aepChannel < 0 || aepChannel >= aepChannelSettingsAscending.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size() -1.
		return false;
	}
		
	aepChannelSettingsAscending[aepChannel]->gain = gain;
	return true;
}

bool AudioSpeakerGainAndRouting::setSolo(int aepChannel, bool enable)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsAscending.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size() -1.
		return false;
	}
	else
	{
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfSoloedChannels wouldn't
		// be accurate)
		if (aepChannelSettingsAscending[aepChannel]->solo != enable)
		{
			if (enable)
			{
				numberOfSoloedChannels++;
			}
			else
			{
				numberOfSoloedChannels--;
			}
			aepChannelSettingsAscending[aepChannel]->solo = enable;
		}
		
		DBG(T("AudioSpeakerGainAndRouting: setSolo called. numberOfSoloedChannels = ") + String(numberOfSoloedChannels));

		return true;
		}
}

bool AudioSpeakerGainAndRouting::setMute(int aepChannel, bool enable)
{
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsAscending.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size() -1.
		return false;
	}
	else
	{
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfMutedChannels wouldn't
		// be accurate)
		if (aepChannelSettingsAscending[aepChannel]->mute != enable)
		{
			if (enable)
			{
				numberOfMutedChannels++;
			}
			else
			{
				numberOfMutedChannels--;
			}
			aepChannelSettingsAscending[aepChannel]->mute = enable;
		}
		return true;
	}
}

bool AudioSpeakerGainAndRouting::activatePinkNoise(int aepChannel, bool enable)
{	
	if (aepChannel < 0 || aepChannel >= aepChannelSettingsAscending.size()) 
	{
		// the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size()-1.
		DBG(T("AudioSpeakerGainAndRouting.activatePinkNoise: the given AEP channel is out of the possible range 0, ..., aepChannelSettingsAscending.size()-1."));
		return false;
	}
	else
	{
		// Only do something, if there is a change to made.
		// (Otherwise the counter numberOfMutedChannels wouldn't
		// be accurate)
		if (aepChannelSettingsAscending[aepChannel]->activatePinkNoise != enable)
		{
			if (enable)
			{
				numberOfChannelsWithActivatedPinkNoise++;
			}
			else
			{
				numberOfChannelsWithActivatedPinkNoise--;
			}
			aepChannelSettingsAscending[aepChannel]->activatePinkNoise = enable;
		}
		return true;
	}
}

void AudioSpeakerGainAndRouting::removeAllRoutings()
{
	aepChannelHardwareOutputPairs.clear();
}


void AudioSpeakerGainAndRouting::setNewRouting(int aepChannel, int hardwareOutputChannel)
{
	// check if the arguments define a valid configuration.
	if (aepChannel < 0 && hardwareOutputChannel < 0)
	{
		DBG(T("Error. Both arguments (aepChannel and hardwareOutputChannel) are smaller than zero. \
			  This is not a valid set of arguments!"));
		return;
	}
	if (aepChannel >= getNumberOfAepChannels())
	{
		DBG(T("Error. The aepChannel argument is bigger than the available AEP channels. Please configure \
			  the number of AEP channels needed by calling setSpeakerPosition the appropriate \
			  number of times before calling connectAepChannelWithHardwareOutputChannel."));
		return;
	}
	if (hardwareOutputChannel >= getNumberOfHardwareOutputChannels())
	{
		DBG(T("Error. The hardwareOutputChannel argument is bigger than the available number of \
			  hardware device outputs."));
		return;		
	}
	// ... now we are sure to have a valid configuration.
	
	
	if (aepChannel < 0)
	{
		// Remove the pair with the given hardwareOutputChannel.
		aepChannelHardwareOutputPairs.deletePairIfItContainsHardwareOutputChannel(hardwareOutputChannel);
	}
	else if (hardwareOutputChannel < 0)
	{
		// Remove the pair with the given aepChannel.
		aepChannelHardwareOutputPairs.deletePairIfItContainsAEPChannel(aepChannel);
	}
	else
	{	
		// Add the pair.
		aepChannelHardwareOutputPairs.add(aepChannel, hardwareOutputChannel);
	}
}

int AudioSpeakerGainAndRouting::enableNewRouting()
{	
	// This section is scope locked.
	const ScopedLock sl (connectionLock);
	
	// Activate (and deactivate) the hardware device output channels as needed
	AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
	audioDeviceManager->getAudioDeviceSetup(audioDeviceSetup);
	DBG(T("Number of hardware output channels = ") + String(getNumberOfHardwareOutputChannels()));
	
	// temp:
	DBG(T("OutputChannels (before) = ") + String(audioDeviceSetup.outputChannels.toInteger()));
	
	audioDeviceSetup.outputChannels.clear();
	for (int i=0; i < getNumberOfHardwareOutputChannels(); i++)
	{
		if (aepChannelHardwareOutputPairs.containsHardwareOutputChannel(i))
		{
			audioDeviceSetup.outputChannels.setBit(i);
		}
		// temp:
		DBG(T("OutputChannels (set bits) = ") + String(audioDeviceSetup.outputChannels.toInteger()));
	}
	
	// temp
	AudioIODevice* audioIODevice = audioDeviceManager->getCurrentAudioDevice();
	BigInteger activeOutputChannels = audioIODevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();
	DBG(T("Number of active output channels (before) = ") + String(numberOfActiveOutputChannels));
	// end temp
	
	audioDeviceSetup.useDefaultOutputChannels = false;
		// This needs to be set. Otherwise the desired changes of the active
		// channels won't take effect.
	bool treatAsChosenDevice = true;
	String error = audioDeviceManager->setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
	if (error != T(""))
	{
		DBG(T("Error message of setAudioDeviceSetup: ") + error);
	}
	
	// temp
	activeOutputChannels = audioIODevice->getActiveOutputChannels();
	numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();
	DBG(T("Number of active output channels (after) = ") + String(numberOfActiveOutputChannels));
	// end temp
	
	// Let the audioSpeakerGainAndRouting know about the new connections.
	// The audioSpeakerGainAndRouting will tell the audioRegionMixer
	// which speaker setting to use on which (active) hardware/buffer
	// channel
	
	// Remove all elements from the array (which will be filled with
	// the most recent routing configuration in the following loop).
	aepChannelSettingsOrderedByActiveHardwareChannels.clear();
	
	double x, y, z;
	Array<void*> positionOfSpeakers;
	
	// The pairs in aepChannelHardwareOutputPairs are in ascending order,
	// sorted by their hardware output channel values.
	// This loop fills the arrays aepChannelSettingsOrderedByActiveHardwareChannels
	// and positionOfSpeakers.
	for (int i=0; i < aepChannelHardwareOutputPairs.size(); i++)
	{
		// Fill the aepChannelSettingsOrderedByActiveHardwareChannels array.
		int AepChannelConnectedWithTheIthActiveHardwareOutput
		    = aepChannelHardwareOutputPairs.getAepChannel(i);
		aepChannelSettingsOrderedByActiveHardwareChannels.add(
		    aepChannelSettingsAscending[AepChannelConnectedWithTheIthActiveHardwareOutput]);
		
		// Fill the positionOfSpeakers array.
		x = aepChannelSettingsOrderedByActiveHardwareChannels[i]->speakerPosition.getX();
		y = aepChannelSettingsOrderedByActiveHardwareChannels[i]->speakerPosition.getY();
		z = aepChannelSettingsOrderedByActiveHardwareChannels[i]->speakerPosition.getZ();
		SpeakerPosition* theIthSpeaker = new SpeakerPosition(x,y,z);
		positionOfSpeakers.add(theIthSpeaker);
	}
	
	// Let the audioRegionMixer know about the new speaker configurations.
	audioRegionMixer->setSpeakerPositions(positionOfSpeakers);
	
	// Return the number of active hardware output channels.
	return aepChannelHardwareOutputPairs.size();
}

void AudioSpeakerGainAndRouting::removeAllRoutingsAndAllAepChannels()
{
	removeAllRoutings();
	enableNewRouting();
	
	// Clear the first AEP array.
	aepChannelSettingsOrderedByActiveHardwareChannels.clear();
	
	// Delete the ressources.
	for (int i=0; i < aepChannelSettingsAscending.size(); i++)
	{
		delete aepChannelSettingsAscending[i];
	}
	// And clear the second AEP array. 
	aepChannelSettingsAscending.clear();	
}


void AudioSpeakerGainAndRouting::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
	DBG(T("AudioSpeakerGainAndRouting: prepareToPlay called."));
	
	if (audioRegionMixer != 0) {
		audioRegionMixer->prepareToPlay(samplesPerBlockExpected_, sampleRate_);
	}
	
	pinkNoiseGeneratorAudioSource.prepareToPlay(samplesPerBlockExpected_, sampleRate_);
	
}

// Implementation of the AudioSource method.
void AudioSpeakerGainAndRouting::releaseResources()
{
	DBG(T("AudioSpeakerGainAndRouting: releaseResources called."));
	
	if (audioRegionMixer != 0) {
		audioRegionMixer->releaseResources();
	}

}

// Implementation of the AudioSource method.
void AudioSpeakerGainAndRouting::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	
	// DBG(T("AudioSpeakerGainAndRouting: nr of channels = ") + String(info.buffer->getNumChannels()));

	if (audioRegionMixer != 0)
	{
		// To save some typing and make tho code more readable.
		int nrOfActiveHWChannels = aepChannelSettingsOrderedByActiveHardwareChannels.size();

		// Aquire a buffer of samples from the audioRegionMixer into the AudioSourceChannelInfo info.
		audioRegionMixer->getNextAudioBlock(info);
		
		// Before gain, mute or solo is applied to the audio stream, pink noise is
		// added if desired. Pink noise comes before the gain, so it is controllable 
		// on each channel via the corresponding gain.
		// pink noise
		// ----------
		if (numberOfChannelsWithActivatedPinkNoise != 0)
		{
			// At least one of the AEP channels (maybe not even a hardware output channel)
			// has pink noise engaged.
			
			// There is only one mono noise source for all channels.
			// Or stated differently: The noise on all channels is correlated
			// (which is good to judge the balance in loudness).
			
			// Generate the pink noise.
			pinkNoiseBuffer.setSize(1, info.buffer->getNumSamples());
			pinkNoiseInfo.buffer = &pinkNoiseBuffer;
			pinkNoiseInfo.startSample = 0;
			pinkNoiseGeneratorAudioSource.getNextAudioBlock(pinkNoiseInfo);
			
			for (int n = 0; n < nrOfActiveHWChannels; n++)
			{
				// Add the pink noise to the channels that wants it.
				if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->activatePinkNoise)
				{
					info.buffer->addFrom(n, info.startSample, 
										 pinkNoiseBuffer, 0, 0, info.numSamples);
				}
			}
		}

		// gain	(only gain, nothing else)	
		if (numberOfMutedChannels == 0 && numberOfSoloedChannels == 0)
		{
			// neither a solo nor a mute
			for (int n = 0; n < nrOfActiveHWChannels; n++)
			{
				info.buffer->applyGain(n, info.startSample, info.numSamples, 
				    aepChannelSettingsOrderedByActiveHardwareChannels[n]->gain);
			}
		}
		else
		{
			// mute or solo is engaged
			if (numberOfSoloedChannels > 0) 
			{
				// solo
				// ----
				// There is at least one solo in one channel enabled.
				// Soloing has a higher priority than muting. Meaning:
				// As soon as there is a channel soloed, muting doesn't
				// affect any channel anymore.
				for (int n = 0; n < nrOfActiveHWChannels; n++)
				{
					if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->solo)
					{
						info.buffer->applyGain(n, info.startSample, info.numSamples, 
					        aepChannelSettingsOrderedByActiveHardwareChannels[n]->gain);
					}
					else
					{
						info.buffer->clear(n, info.startSample, info.numSamples);						
					}
				}
				
			}
			else
			{
				// mute
				// ----
				for (int n = 0; n < nrOfActiveHWChannels; n++)
				{
					if (aepChannelSettingsOrderedByActiveHardwareChannels[n]->mute)
					{
						info.buffer->clear(n, info.startSample, info.numSamples);
					}
					else
					{
						info.buffer->applyGain(n, info.startSample, info.numSamples, 
							aepChannelSettingsOrderedByActiveHardwareChannels[n]->gain);
					}
				}				
			}
		}
	}
}

// Implements the PositionableAudioSource method.
void AudioSpeakerGainAndRouting::setNextReadPosition (int newPosition)
{
	// DBG(T("AudioSpeakerGainAndRouting: setNextReadPosition called."));
	
	if (audioRegionMixer != 0)
	{
		audioRegionMixer->setNextReadPosition(newPosition);
	}
}	

/** Implements the PositionableAudioSource method. */
int AudioSpeakerGainAndRouting::getNextReadPosition() const
{
	if (audioRegionMixer != 0)
	{
		return audioRegionMixer->getNextReadPosition();
	}
	else 
	{
		return 0;
	}
}

/** Implements the PositionableAudioSource method. */
int AudioSpeakerGainAndRouting::getTotalLength() const
{
	if (audioRegionMixer != 0)
	{
		return audioRegionMixer->getTotalLength();
	}
	else 
	{
		return 0;
	}
}

bool AudioSpeakerGainAndRouting::isLooping() const
{
	if (audioRegionMixer != 0)
	{
		return audioRegionMixer->isLooping();
	}
	else 
	{
		return false;
	}
}